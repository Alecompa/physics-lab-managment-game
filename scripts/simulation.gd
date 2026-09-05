class_name LabSimulation
extends Node
## Hourly agents, typed evidence, paper ideas, review and permanent development.

signal updated
signal announcement(message: String)
signal paper_resolved(result: Dictionary)
signal ideas_changed
signal idea_discovered(idea: Dictionary)

const Layout = preload("res://scripts/lab_layout.gd")
const Events = preload("res://scripts/lab_events.gd")
const Catalog = preload("res://scripts/catalog.gd")
const FIELDS = Catalog.FIELDS
const EQUIPMENT = Catalog.EQUIPMENT
const ROLES = Catalog.ROLES
const JOURNALS = Catalog.JOURNALS
const UPGRADES = Catalog.UPGRADES
const SAVE_PATH = "user://fieldwork_autosave_v3.json"
const V2_PATH = "user://fieldwork_lab_v2.json"
const LEGACY_PATH = "user://fieldwork_lab.json"
const GRID_SIZE = Layout.SIZE
const DAY_SECONDS = 48.0
const HOUR_SECONDS = DAY_SECONDS / 24.0
const WALK_SPEED = 4.0

var funds = 14500.0
var raw_by_field: Dictionary = {}
var analyzed_by_field: Dictionary = {}
var raw_data: float:
	get: return total(raw_by_field)
var analyzed_data: float:
	get: return total(analyzed_by_field)
var prestige = 0
var lifetime_impact = 0
var published = 0
var day = 1
var hour = 8
var speed = 1
var paused = true
var experiments: Array = []
var staff: Array = []
var candidates: Dictionary = {}
var active_paper: Dictionary = {}
var pending_result: Dictionary = {}
var ideas: Array = []
var unlocked: Array = []
var history: Array = []
var log_entries: Array = []
var next_staff_id = 1
var next_experiment_id = 1
var next_idea_id = 1
var accumulated_time = 0.0
var total_grants = 0.0
var rescue_count = 0
var study_points = 0.0
var last_produced = 0.0
var last_analyzed = 0.0
var last_written = 0.0
var autosave_days = 0
var autosave_enabled = true
var rng = RandomNumberGenerator.new()
var navigation = AStarGrid2D.new()
var desks: Array = []
var next_desk_id = 4
var lab_name = "The North Annex"
var resource_history: Array = []
var flavor_rng = RandomNumberGenerator.new()
var recent_flavor: Array = []
var next_flavor_hour = 14
var discoveries_without_legendary = 0

func empty_data() -> Dictionary:
	return {"nuclear": 0.0, "quantum": 0.0, "materials": 0.0, "optics": 0.0}

func total(pool: Dictionary) -> float:
	var result = 0.0
	for amount in pool.values(): result += amount
	return result

func new_lab() -> void:
	rng.randomize()
	flavor_rng.randomize()
	funds = 14500.0
	raw_by_field = empty_data()
	analyzed_by_field = empty_data()
	prestige = 0
	lifetime_impact = 0
	published = 0
	day = 1
	hour = 8
	speed = 1
	paused = true
	accumulated_time = 0.0
	experiments = [{"id": 1, "kind": "optics", "x": 2, "y": 2, "level": 1, "condition": 100.0}]
	desks = []
	for index in range(3): desks.append({"id": index + 1, "kind": "desk", "x": Layout.DESK_STARTS[index].x, "y": Layout.DESK_STARTS[index].y})
	next_desk_id = 4
	lab_name = "The North Annex"
	resource_history = []
	recent_flavor = []
	next_flavor_hour = 14
	discoveries_without_legendary = 0
	staff = []
	for id in range(1, 4):
		var person = make_person(id, "researcher" if id == 3 else "phd")
		person.specialty = "optics"
		person.personality = "early" if id != 2 else "social"
		person.desk = id
		staff.append(person)
	next_staff_id = 4
	next_experiment_id = 2
	next_idea_id = 1
	active_paper = {}
	pending_result = {}
	ideas = []
	unlocked = []
	history = []
	log_entries = []
	total_grants = 0.0
	rescue_count = 0
	study_points = 0.0
	last_produced = 0.0
	last_analyzed = 0.0
	last_written = 0.0
	autosave_days = 0
	for field in ["optics", "materials", "quantum", "nuclear"]: add_idea(field, "letter")
	add_idea("optics", "article")
	candidates = {}
	for role in ROLES: candidates[role] = make_person(next_staff_id + ROLES.keys().find(role), role)
	rebuild_navigation()
	record_resources()
	announce("The North Annex opens its doors. Three desks, one bench, and several unanswered questions.")
	updated.emit()

func make_person(id: int, role: String) -> Dictionary:
	var rest = 8
	var acquire = 8 if role == "phd" else 0
	var analyze = 8 if role == "phd" else 0
	return {"id": id, "name": Catalog.NAMES[(id - 1) % Catalog.NAMES.size()] + (" %d" % (id / Catalog.NAMES.size() + 1) if id > Catalog.NAMES.size() else ""), "role": role,
		"specialty": FIELDS.keys()[rng.randi_range(0, 3)], "trait": Catalog.TRAITS.keys()[rng.randi_range(0, 3)], "personality": Catalog.PERSONALITIES.keys()[rng.randi_range(0, 3)],
		"rest": rest, "acquire": acquire, "analyze": analyze, "duty": "maintain" if role == "technician" else "auto",
		"focus": "any", "experiment": -1, "energy": 100.0, "x": float(Layout.ENTRANCE.x), "y": float(Layout.ENTRANCE.y), "desk": -1, "motion": [], "working": false, "last_field": "", "route": [], "destination": [], "status": "Ready", "task": "rest", "target_id": -1}

func _process(delta: float) -> void:
	if paused or not pending_result.is_empty(): return
	accumulated_time += delta * speed
	while accumulated_time >= HOUR_SECONDS and not paused and pending_result.is_empty():
		accumulated_time -= HOUR_SECONDS
		advance_hour()
	if paused: accumulated_time = 0.0

func role_count(role: String) -> int:
	var count = 0
	for person in staff:
		if person.role == role: count += 1
	return count

func activity_hours(person: Dictionary) -> int:
	return 24 - int(person.rest) - int(person.acquire) - int(person.analyze)

func scheduled_task(person: Dictionary, at_hour: int = -1) -> String:
	var local_hour = posmod((hour if at_hour < 0 else at_hour) - Catalog.PERSONALITIES[person.personality].shift, 24)
	if local_hour < person.rest: return "rest"
	if local_hour < person.rest + person.acquire: return "acquire"
	if local_hour < person.rest + person.acquire + person.analyze: return "analyze"
	if person.duty == "auto":
		return "write" if not active_paper.is_empty() and active_paper.stage == "writing" else "study"
	return person.duty

func set_schedule(id: int, block: String, hours: int) -> void:
	if block not in ["rest", "acquire", "analyze"]: return
	for person in staff:
		if person.id != id: continue
		person[block] = clampi(hours, 0, 24)
		var overflow = maxi(0, person.rest + person.acquire + person.analyze - 24)
		# The edited block wins. Remove excess from the other work blocks, then rest.
		for other in ["analyze", "acquire", "rest"]:
			if other == block: continue
			var reduction = mini(overflow, person[other])
			person[other] -= reduction
			overflow -= reduction
		updated.emit()

func set_assignment(id: int, key: String, value: Variant) -> void:
	for person in staff:
		if person.id != id: continue
		if key == "focus" and (value == "any" or FIELDS.has(value)): person.focus = value
		if key == "duty" and value in ["auto", "write", "study", "maintain"]: person.duty = value
		if key == "desk" and (value == -1 or not desk_by_id(value).is_empty()): person.desk = value
		if key == "experiment" and (value == -1 or not experiment_by_id(value).is_empty()): person.experiment = value
		person.destination = []
		person.route = []
		updated.emit()

func performance(person: Dictionary, task: String, field: String = "") -> float:
	var factor = (0.4 + 0.6 * person.energy / 100.0) * Catalog.TRAITS[person.trait].get(task, 1.0)
	if field == person.specialty: factor *= 1.25
	if person.personality == "early" and hour < 12 or person.personality == "night" and hour >= 16: factor *= 1.1
	if person.personality in ["social", "quiet"]:
		var nearby = false
		for colleague in staff:
			if colleague.id != person.id and Vector2(person.x, person.y).distance_to(Vector2(colleague.x, colleague.y)) < 1.5:
				nearby = true
				break
		factor *= (1.1 if nearby else 1.0) if person.personality == "social" else (0.9 if nearby else 1.1)
	return factor

func capacity_for(experiment: Dictionary) -> float:
	return EQUIPMENT[experiment.kind].capacity * (1.0 + 0.5 * (experiment.level - 1)) * experiment.condition / 100.0

func capacity() -> float:
	var amount = 0.0
	for experiment in experiments: amount += capacity_for(experiment)
	return amount

func collection_power() -> float:
	var amount = 0.0
	for person in staff: amount += person.acquire * 0.6
	return amount

func analysis_power() -> float:
	var amount = 0.0
	for person in staff: amount += person.analyze * 0.65 * (1.25 if "compute" in unlocked else 1.0)
	return amount

func writing_power() -> float:
	var amount = 0.0
	for person in staff:
		if person.duty in ["auto", "write"]: amount += activity_hours(person) * (0.3 if person.role == "researcher" else 0.12)
	return amount

func income() -> float:
	return 60.0 + lifetime_impact * 3.0

func expenses() -> float:
	var amount = 0.0
	for person in staff: amount += ROLES[person.role].salary
	for experiment in experiments: amount += EQUIPMENT[experiment.kind].upkeep * (1.0 + 0.25 * (experiment.level - 1))
	return amount

func output_mix(experiment: Dictionary) -> Dictionary:
	var spec = EQUIPMENT[experiment.kind]
	if "mixed_mode" in unlocked and experiment.level >= 2:
		var secondary = 0.25 if experiment.level == 2 else 0.4
		return {spec.field: 1.0 - secondary, spec.secondary: secondary}
	return {spec.field: 1.0}

func build_navigation(extra_kind: String = "", extra_cell: Vector2i = Vector2i.ZERO) -> AStarGrid2D:
	var grid = AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, Layout.SIZE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for x in range(Layout.SIZE.x):
		for y in range(Layout.SIZE.y):
			var cell = Vector2i(x, y)
			if Layout.wall(cell) or Layout.fixed_furniture(cell): grid.set_point_solid(cell)
	for object in experiments + desks:
		for cell in Layout.cells(object.kind, Vector2i(object.x, object.y)): grid.set_point_solid(cell)
	if extra_kind != "":
		for cell in Layout.cells(extra_kind, extra_cell): grid.set_point_solid(cell)
	return grid

func rebuild_navigation() -> void:
	navigation = build_navigation()
	for person in staff:
		person.route = []
		person.destination = []
		person.motion = []
		var cell = Vector2i(roundi(person.x), roundi(person.y))
		if not navigation.is_in_boundsv(cell) or navigation.is_point_solid(cell):
			person.x = float(Layout.ENTRANCE.x)
			person.y = float(Layout.ENTRANCE.y)

func interaction_cell(person: Dictionary, experiment: Dictionary) -> Vector2i:
	var origin = Vector2i(roundi(person.x), roundi(person.y))
	var best = Vector2i(-1, -1)
	var best_distance = INF
	for target in Layout.perimeter(experiment):
		if not navigation.is_in_boundsv(target) or navigation.is_point_solid(target): continue
		var route = navigation.get_point_path(origin, target)
		if not route.is_empty() and route.size() < best_distance:
			best_distance = route.size()
			best = target
	return best

func desk_by_id(id: int) -> Dictionary:
	for desk in desks:
		if desk.id == id: return desk
	return {}

func choose_desk(person: Dictionary, reserved: Dictionary = {}) -> Dictionary:
	var best: Dictionary = {}
	var distance = INF
	for desk in desks:
		if person.get("desk", -1) != -1 and person.desk != desk.id: continue
		if reserved.has(desk.id) and reserved[desk.id] != person.id: continue
		var route = navigation.get_point_path(Vector2i(roundi(person.x), roundi(person.y)), Layout.chair(desk))
		if not route.is_empty() and route.size() < distance:
			distance = route.size()
			best = desk
	return best

func placement_error(kind: String, cell: Vector2i) -> String:
	if kind != "desk" and not equipment_unlocked(kind): return "Unlock this instrument in Development."
	if not Layout.room_allows(kind, cell): return "Desks belong in the office." if kind == "desk" else "Experiments belong in the two laboratory rooms."
	if funds < (600.0 if kind == "desk" else EQUIPMENT[kind].cost): return "Not enough research funds."
	for point in Layout.cells(kind, cell):
		if navigation.is_point_solid(point): return "This space is occupied."
		for desk in desks:
			if point == Layout.chair(desk): return "Leave space for this desk's chair."
	if kind == "desk" and navigation.is_point_solid(cell + Vector2i.DOWN): return "Leave a free chair space below the desk."
	var proposed = build_navigation(kind, cell)
	var objects = experiments.duplicate()
	if kind != "desk": objects.append({"kind": kind, "x": cell.x, "y": cell.y})
	for object in objects:
		var reachable = false
		for target in Layout.perimeter(object):
			if not proposed.is_in_boundsv(target) or proposed.is_point_solid(target): continue
			if not proposed.get_point_path(Layout.ENTRANCE, target).is_empty(): reachable = true; break
		if not reachable: return "Keep a route from the corridor to every experiment."
	var chairs: Array = Layout.REST_SEATS.duplicate()
	for desk in desks: chairs.append(Layout.chair(desk))
	if kind == "desk": chairs.append(cell + Vector2i.DOWN)
	for chair in chairs:
		if proposed.is_point_solid(chair) or proposed.get_point_path(Layout.ENTRANCE, chair).is_empty(): return "Keep the desks and common room accessible."
	return ""

func place_desk(cell: Vector2i) -> bool:
	if placement_error("desk", cell) != "": return false
	funds -= 600
	desks.append({"id": next_desk_id, "kind": "desk", "x": cell.x, "y": cell.y})
	next_desk_id += 1
	rebuild_navigation()
	announce("A desk is ready in the office. Assign it in People.")
	updated.emit()
	return true

func remove_desk(id: int) -> bool:
	var desk = desk_by_id(id)
	if desk.is_empty(): return false
	desks.erase(desk)
	funds += 210
	for person in staff:
		if person.get("desk", -1) == id: person.desk = -1
	rebuild_navigation()
	announce("Desk removed. Its users will look for a shared desk.")
	updated.emit()
	return true

func travel(person: Dictionary, target: Vector2i) -> float:
	person.motion = [[person.x, person.y]]
	if target.x < 0:
		person.status = "No accessible workstation"
		return 0.0
	if person.destination != [target.x, target.y]:
		person.destination = [target.x, target.y]
		person.route = []
		var route = navigation.get_point_path(Vector2i(roundi(person.x), roundi(person.y)), target)
		if route.is_empty():
			person.status = "Route blocked"
			person.destination = []
			return 0.0
		for point in route: person.route.append([point.x, point.y])
	var budget = WALK_SPEED
	while not person.route.is_empty() and budget > 0.00001:
		var next = Vector2(person.route[0][0], person.route[0][1])
		var current = Vector2(person.x, person.y)
		var distance = current.distance_to(next)
		var used = minf(distance, budget)
		var position = current.move_toward(next, used)
		person.x = position.x
		person.y = position.y
		person.motion.append([position.x, position.y])
		budget -= used
		if distance <= used + 0.00001: person.route.pop_front()
	if not person.route.is_empty(): person.status = "Walking to " + person.task
	return budget / WALK_SPEED if person.route.is_empty() else 0.0

func choose_experiment(person: Dictionary, maintaining: bool = false) -> Dictionary:
	var best: Dictionary = {}
	var score = INF
	for experiment in experiments:
		if person.experiment != -1 and person.experiment != experiment.id: continue
		if not maintaining and person.focus != "any" and not output_mix(experiment).has(person.focus): continue
		if interaction_cell(person, experiment).x < 0: continue
		var distance = Vector2(person.x, person.y).distance_to(Vector2(experiment.x, experiment.y))
		var value = experiment.condition + distance * 0.05 if maintaining else distance
		if value < score:
			score = value
			best = experiment
	return best

func advance_hour() -> void:
	# The pending feedback is a hard simulation stop, including direct test calls.
	if not pending_result.is_empty(): return
	var capacities = {}
	var occupancy = {}
	var desk_reservations = {}
	for experiment in experiments:
		capacities[experiment.id] = capacity_for(experiment) / 24.0
		occupancy[experiment.id] = 0
	# Rotate work order to avoid giving one person permanent priority at a shared bench.
	for index in range(staff.size()):
		var person = staff[(index + hour) % staff.size()]
		person.working = false
		person.motion = []
		var task = scheduled_task(person)
		if person.energy < 8.0: task = "rest"
		person.task = task
		person.target_id = -1
		var target = Layout.REST_SEATS[int(person.id) % Layout.REST_SEATS.size()]
		if task in ["analyze", "write", "study"]:
			var desk = choose_desk(person, desk_reservations)
			if desk.is_empty():
				person.status = "Waiting: no free, reachable desk"
				continue
			desk_reservations[desk.id] = person.id
			target = Layout.chair(desk)
		var experiment: Dictionary = {}
		if task in ["acquire", "maintain"]:
			experiment = choose_experiment(person, task == "maintain")
			if experiment.is_empty():
				person.status = "No matching accessible experiment"
				continue
			person.target_id = experiment.id
			target = interaction_cell(person, experiment)
		var time_left = travel(person, target)
		if task == "rest":
			person.energy = minf(100.0, person.energy + time_left * (10.0 if "lounge" in unlocked else 7.0))
			if time_left > 0: person.status = "Resting in the common room"; person.working = true
			continue
		person.energy = maxf(0.0, person.energy - 2.0)
		if time_left <= 0: continue
		person.working = true
		match task:
			"acquire":
				if occupancy[experiment.id] >= 2:
					person.working = false
					person.status = "Waiting: both bench positions occupied"
					continue
				occupancy[experiment.id] += 1
				var work = minf(capacities[experiment.id], time_left * 0.6 * performance(person, task, EQUIPMENT[experiment.kind].field))
				capacities[experiment.id] -= work
				for field in output_mix(experiment): raw_by_field[field] += work * output_mix(experiment)[field]
				person.working = work > 0
				person.last_field = EQUIPMENT[experiment.kind].field
				last_produced += work
				person.status = "Collecting at %s #%d" % [EQUIPMENT[experiment.kind].name, experiment.id] if work > 0 else "Waiting: experiment at capacity"
			"analyze":
				var field = person.focus
				if field == "any":
					field = person.specialty if raw_by_field[person.specialty] > 0 else FIELDS.keys()[0]
					if raw_by_field[field] <= 0:
						for candidate in FIELDS:
							if raw_by_field[candidate] > raw_by_field[field]: field = candidate
				var amount = minf(raw_by_field[field], time_left * 0.65 * performance(person, task, field) * (1.25 if "compute" in unlocked else 1.0))
				raw_by_field[field] -= amount
				analyzed_by_field[field] += amount
				person.working = amount > 0
				person.last_field = field
				last_analyzed += amount
				person.status = "Analyzing " + FIELDS[field].name if amount > 0 else "Waiting for " + ("raw data" if person.focus == "any" else FIELDS[field].name + " data")
			"write":
				if active_paper.is_empty() or active_paper.stage != "writing":
					person.working = false
					person.status = "Waiting for a manuscript"
					continue
				var work = time_left * (0.3 if person.role == "researcher" else 0.12) * performance(person, task, active_paper.field)
				work = minf(work, active_paper.work - active_paper.progress)
				active_paper.progress += work
				person.last_field = active_paper.field
				last_written += work
				person.status = "Writing " + FIELDS[active_paper.field].name
			"study":
				study_points += time_left * (0.35 if person.role == "researcher" else 0.12) * performance(person, task, person.specialty)
				person.status = "Studying " + FIELDS[person.specialty].name
			"maintain":
				experiment.condition = minf(100.0, experiment.condition + time_left * 0.8 * performance(person, task))
				person.status = "Servicing %s #%d" % [EQUIPMENT[experiment.kind].name, experiment.id]
	if not active_paper.is_empty():
		if active_paper.stage == "review":
			active_paper.review_left -= 1
			if active_paper.review_left <= 0: resolve_review()
		elif active_paper.progress >= active_paper.work - 0.00001:
			active_paper.stage = "review"
			announce("Submitted '%s'. Peer review has begun." % active_paper.title)
	maybe_flavor_event()
	hour += 1
	if hour >= 24:
		hour = 0
		day += 1
		for experiment in experiments: experiment.condition = maxf(35.0, experiment.condition - 0.45)
		funds += income() - expenses()
		if funds < 0:
			rescue_count += 1
			funds += 4000
			prestige = maxi(0, prestige - 2)
			paused = true
			announce("University rescue: $4,000 added, 2 available impact spent. Review your budget before resuming.")
		record_resources()
		autosave_days += 1
		last_produced = 0.0
		last_analyzed = 0.0
		last_written = 0.0
		if autosave_enabled and autosave_days >= 5:
			autosave_days = 0
			save_lab(false)
	updated.emit()

func advance_day() -> void:
	for i in range(24):
		advance_hour()
		if not pending_result.is_empty(): break

func experiment_at(cell: Vector2i) -> Dictionary:
	for experiment in experiments:
		if cell in Layout.cells(experiment.kind, Vector2i(experiment.x, experiment.y)): return experiment
	return {}

func object_at(cell: Vector2i) -> Dictionary:
	for object in experiments + desks:
		if cell in Layout.cells(object.kind, Vector2i(object.x, object.y)): return object
	return {}

func experiment_by_id(id: int) -> Dictionary:
	for experiment in experiments:
		if experiment.id == id: return experiment
	return {}

func equipment_unlocked(kind: String) -> bool:
	return EQUIPMENT.has(kind) and (EQUIPMENT[kind].unlock == "" or EQUIPMENT[kind].unlock in unlocked)

func can_place(kind: String, cell: Vector2i) -> bool:
	return (kind == "desk" or EQUIPMENT.has(kind)) and placement_error(kind, cell) == ""

func place_experiment(kind: String, cell: Vector2i) -> bool:
	if kind == "desk": return place_desk(cell)
	if not can_place(kind, cell): return false
	funds -= EQUIPMENT[kind].cost
	experiments.append({"id": next_experiment_id, "kind": kind, "x": cell.x, "y": cell.y, "level": 1, "condition": 100.0})
	next_experiment_id += 1
	rebuild_navigation()
	announce("Installed %s. Staff can now work at this experiment." % EQUIPMENT[kind].name)
	updated.emit()
	return true

func upgrade_cost(experiment: Dictionary) -> float:
	return EQUIPMENT[experiment.kind].cost * 0.65 * experiment.level

func upgrade_experiment(id: int) -> bool:
	var experiment = experiment_by_id(id)
	if experiment.is_empty() or experiment.level >= 3 or funds < upgrade_cost(experiment): return false
	funds -= upgrade_cost(experiment)
	experiment.level += 1
	experiment.condition = 100.0
	announce("%s upgraded to level %d." % [EQUIPMENT[experiment.kind].name, experiment.level])
	updated.emit()
	return true

func service_experiment(id: int) -> bool:
	var experiment = experiment_by_id(id)
	if experiment.is_empty() or experiment.condition >= 99.9 or funds < 250: return false
	funds -= 250
	experiment.condition = 100.0
	updated.emit()
	return true

func remove_experiment(id: int) -> bool:
	var experiment = experiment_by_id(id)
	if experiment.is_empty(): return false
	funds += EQUIPMENT[experiment.kind].cost * 0.35
	experiments.erase(experiment)
	for person in staff:
		if person.experiment == id: person.experiment = -1
	rebuild_navigation()
	announce("Experiment decommissioned. Assigned staff returned to automatic selection.")
	updated.emit()
	return true

func hire(role: String) -> bool:
	if not ROLES.has(role) or funds < ROLES[role].cost or staff.size() >= 18: return false
	funds -= ROLES[role].cost
	var person = candidates[role].duplicate(true)
	person.id = next_staff_id
	next_staff_id += 1
	staff.append(person)
	candidates[role] = make_person(next_staff_id + 2, role)
	announce("%s joined. %s specialist, %s." % [person.name, FIELDS[person.specialty].name, Catalog.TRAITS[person.trait].name])
	updated.emit()
	return true

func dismiss(id: int) -> bool:
	for person in staff:
		if person.id == id:
			staff.erase(person)
			announce(person.name + " left the lab.")
			updated.emit()
			return true
	return false

func add_idea(field: String, kind: String = "letter") -> Dictionary:
	var idea = {"id": next_idea_id, "field": field, "kind": kind, "title": Catalog.TITLES[field][(next_idea_id - 1) % 4], "secondary": ""}
	if "mixed_mode" in unlocked and kind != "letter":
		for spec in EQUIPMENT.values():
			if spec.field == field: idea.secondary = spec.secondary
	next_idea_id += 1
	ideas.append(idea)
	return idea

func installed_fields() -> Array:
	var fields: Array = []
	for experiment in experiments:
		for field in output_mix(experiment):
			if not field in fields: fields.append(field)
	if fields.is_empty(): fields.append("optics")
	return fields

func think_idea() -> bool:
	if study_points < 8 or ideas.size() >= 6: return false
	study_points -= 8
	var fields = installed_fields()
	var field = fields[rng.randi_range(0, fields.size() - 1)]
	var tier = roll_tier()
	var idea = add_idea(field, tier)
	announce("%s idea discovered: %s" % [rarity(tier).name, idea.title])
	idea_discovered.emit(idea)
	ideas_changed.emit()
	updated.emit()
	return true

func refresh_ideas() -> bool:
	if "journal_club" not in unlocked or study_points < 12: return false
	study_points -= 12
	ideas.clear()
	for field in installed_fields():
		if ideas.size() < 6: add_idea(field, "letter")
	while ideas.size() < 6:
		var field = FIELDS.keys()[rng.randi_range(0, 3)]
		add_idea(field, roll_tier())
	announce("Journal club refreshed the idea board. The active paper is unchanged.")
	ideas_changed.emit()
	updated.emit()
	return true

func discard_idea(id: int) -> void:
	for idea in ideas:
		if idea.id == id:
			ideas.erase(idea)
			ideas_changed.emit()
			updated.emit()
			return

func idea_by_id(id: int) -> Dictionary:
	for idea in ideas:
		if idea.id == id: return idea
	return {}

func dataset_cost(idea: Dictionary, commitment: float = 1.0) -> Dictionary:
	var amount = ceilf(JOURNALS[idea.kind].data * clampf(commitment, 1.0, 2.0))
	if idea.secondary != "": return {idea.field: ceilf(amount * 0.75), idea.secondary: ceilf(amount * 0.25)}
	return {idea.field: amount}

func acceptance_chance(idea: Dictionary, commitment: float) -> float:
	return minf(0.97, JOURNALS[idea.kind].chance + (clampf(commitment, 1.0, 2.0) - 1.0) * 0.32 + (0.08 if "review_support" in unlocked else 0.0))

func can_start_paper(id: int, commitment: float = 1.0) -> bool:
	return paper_block_reason(id, commitment) == ""

func start_paper(id: int, commitment: float = 1.0) -> bool:
	if not can_start_paper(id, commitment): return false
	var idea = idea_by_id(id)
	var spec = JOURNALS[idea.kind]
	var committed = dataset_cost(idea, commitment)
	for field in committed: analyzed_by_field[field] -= committed[field]
	active_paper = idea.duplicate(true)
	active_paper.merge({"stage": "writing", "progress": 0.0, "work": spec.work * (1.0 + (clampf(commitment, 1.0, 2.0) - 1.0) * 0.2), "committed": committed, "chance": acceptance_chance(idea, commitment), "review_left": spec.review, "review_roll": rng.randf(), "started": day})
	ideas.erase(idea)
	announce("Started '%s'. %.0f%% acceptance estimate." % [active_paper.title, active_paper.chance * 100])
	ideas_changed.emit()
	updated.emit()
	return true

func resolve_review() -> void:
	if active_paper.is_empty(): return
	var accepted = active_paper.review_roll < active_paper.chance
	var spec = JOURNALS[active_paper.kind]
	pending_result = {"title": active_paper.title, "field": active_paper.field, "kind": active_paper.kind, "accepted": accepted, "chance": active_paper.chance, "day": day, "impact": spec.impact if accepted else 0, "grant": spec.grant if accepted else 0, "feedback": "The referees found the evidence convincing and the method reproducible." if accepted else "The referees requested a stronger dataset. 75% of each committed data type has been returned. The idea is available to try again."}
	if accepted:
		funds += spec.grant
		total_grants += spec.grant
		prestige += spec.impact
		lifetime_impact += spec.impact
		published += 1
	else:
		for field in active_paper.committed: analyzed_by_field[field] += active_paper.committed[field] * 0.75
		if ideas.size() >= 6: ideas.pop_back()
		ideas.push_front({"id": active_paper.id, "field": active_paper.field, "kind": active_paper.kind, "title": active_paper.title, "secondary": active_paper.secondary})
	history.push_front(pending_result.duplicate(true))
	if history.size() > 40: history.resize(40)
	active_paper = {}
	paused = true
	accumulated_time = 0.0
	announce(("Published: " if accepted else "Review decision: ") + pending_result.title)
	ideas_changed.emit()
	paper_resolved.emit(pending_result)

func acknowledge_result() -> void:
	pending_result = {}
	paused = true
	updated.emit()

func cancel_paper() -> void:
	if active_paper.is_empty() or active_paper.stage == "review": return
	for field in active_paper.committed: analyzed_by_field[field] += active_paper.committed[field]
	if ideas.size() >= 6: ideas.pop_back()
	ideas.push_front({"id": active_paper.id, "field": active_paper.field, "kind": active_paper.kind, "title": active_paper.title, "secondary": active_paper.secondary})
	active_paper = {}
	announce("Manuscript shelved. Dataset and idea returned; writing progress lost.")
	ideas_changed.emit()
	updated.emit()

func unlock_upgrade(key: String) -> bool:
	if not UPGRADES.has(key) or key in unlocked or prestige < UPGRADES[key].cost: return false
	if UPGRADES[key].requires != "" and UPGRADES[key].requires not in unlocked: return false
	prestige -= UPGRADES[key].cost
	unlocked.append(key)
	announce("Unlocked %s. This development is permanent." % UPGRADES[key].name)
	updated.emit()
	return true

func bottleneck() -> String:
	if not pending_result.is_empty(): return "A referee decision is waiting. Read it before resuming."
	if not active_paper.is_empty(): return "Peer review in progress. Students can prepare the next dataset." if active_paper.stage == "review" else "A manuscript is being written. Assign activity time to writing."
	if writing_power() <= 0: return "Assign activity hours to Auto or Write so somebody can write a paper."
	for idea in ideas:
		if can_start_paper(idea.id): return "An idea has enough evidence. Choose a data commitment in Papers."
	if study_points >= 8 and ideas.size() < 6: return "Study points are ready. Think of a new idea in Papers."
	if experiments.is_empty(): return "Build an experiment and assign collection hours."
	return "Collect and analyze matching data. The first optics letter needs 18 optics evidence."

func announce(message: String) -> void:
	log_entries.push_front({"day": day, "hour": hour, "message": message})
	if log_entries.size() > 80: log_entries.resize(80)
	announcement.emit(message)

func snapshot() -> Dictionary:
	var result = {"version": 3, "rng_state": str(rng.state), "rng_seed": str(rng.seed), "flavor_state": str(flavor_rng.state), "flavor_seed": str(flavor_rng.seed), "saved_at": Time.get_datetime_string_from_system()}
	for key in ["funds", "raw_by_field", "analyzed_by_field", "prestige", "lifetime_impact", "published", "day", "hour", "experiments", "staff", "candidates", "active_paper", "pending_result", "ideas", "unlocked", "history", "log_entries", "next_staff_id", "next_experiment_id", "next_idea_id", "total_grants", "rescue_count", "study_points", "desks", "next_desk_id", "lab_name", "resource_history", "recent_flavor", "next_flavor_hour", "discoveries_without_legendary"]:
		var value = get(key)
		result[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	return result

func save_lab(notify_user: bool = true, path: String = SAVE_PATH) -> bool:
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		if notify_user: announce("Could not save the lab.")
		return false
	file.store_string(JSON.stringify(snapshot(), "\t", true, true))
	file.close()
	var error = DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))
	if notify_user: announce("Lab saved." if error == OK else "Could not replace the save file.")
	return error == OK

func load_lab(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path): return false
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null: return false
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		announce("Unreadable save. Your current lab is unchanged.")
		return false
	var data = parser.data
	if data is Dictionary and data.get("version") == 1: data = migrate_v1(data)
	elif data is Dictionary and data.get("version") == 2: data = migrate_v2(data)
	if not valid_save(data):
		announce("Invalid save. Your current lab is unchanged.")
		return false
	for key in snapshot():
		if key not in ["version", "rng_state", "rng_seed", "flavor_state", "flavor_seed", "saved_at"]: set(key, data[key])
	for key in ["prestige", "lifetime_impact", "published", "day", "hour", "next_staff_id", "next_experiment_id", "next_idea_id", "rescue_count", "next_desk_id", "next_flavor_hour", "discoveries_without_legendary"]:
		set(key, int(get(key)))
	for person in staff + candidates.values():
		for key in ["id", "rest", "acquire", "analyze", "experiment", "desk"]: person[key] = int(person[key])
	for desk in desks:
		for key in ["id", "x", "y"]: desk[key] = int(desk[key])
	for experiment in experiments:
		for key in ["id", "x", "y", "level"]: experiment[key] = int(experiment[key])
	rng.seed = int(data.rng_seed)
	rng.state = int(data.rng_state)
	flavor_rng.seed = int(data.flavor_seed)
	flavor_rng.state = int(data.flavor_state)
	paused = true
	accumulated_time = 0
	autosave_days = 0
	last_produced = 0
	last_analyzed = 0
	last_written = 0
	rebuild_navigation()
	announce("Lab restored. Time is paused.")
	ideas_changed.emit()
	updated.emit()
	return true

func migrate_v1(old: Dictionary) -> Dictionary:
	# Build in a separate simulation so a malformed legacy file cannot alter this lab.
	for key in ["funds", "raw_data", "analyzed_data", "prestige", "day", "published"]:
		if not numeric(old.get(key)): return {}
	if not old.get("staff") is Array or not old.get("experiments") is Array: return {}
	var temporary = LabSimulation.new()
	temporary.new_lab()
	var migrated = temporary.snapshot()
	temporary.free()
	for key in ["funds", "prestige", "published", "day", "experiments", "next_staff_id", "next_experiment_id", "total_grants", "rescue_count"]:
		if old.has(key): migrated[key] = old[key]
	migrated.lifetime_impact = old.prestige
	migrated.raw_by_field.optics = old.raw_data
	migrated.analyzed_by_field.optics = old.analyzed_data
	migrated.staff = []
	for old_person in old.staff:
		if not old_person is Dictionary or not ROLES.has(old_person.get("role", "")) or not numeric(old_person.get("id")) or not old_person.get("name") is String: return {}
		var generator = LabSimulation.new()
		var person = generator.make_person(old_person.id, old_person.role)
		generator.free()
		person.name = old_person.name
		if old_person.role == "phd":
			person.acquire = clampi(roundi(float(old_person.get("allocation", 0.55)) * 16), 0, 16)
			person.analyze = 16 - person.acquire
		migrated.staff.append(person)
	for experiment in old.experiments:
		if experiment is Dictionary and EQUIPMENT.has(experiment.get("kind", "")):
			var key = EQUIPMENT[experiment.kind].unlock
			if key != "" and key not in migrated.unlocked: migrated.unlocked.append(key)
	# Old manuscripts had no review or data type. Return the original committed dataset.
	var old_paper = old.get("active_paper", {})
	if old_paper is Dictionary and JOURNALS.has(old_paper.get("kind", "")):
		migrated.analyzed_by_field.optics += {"letter": 24, "article": 80, "breakthrough": 200}[old_paper.kind]
	return migrate_v2(migrated)

func numeric(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value >= 0

func valid_save(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 3: return false
	for key in ["funds", "prestige", "lifetime_impact", "published", "day", "hour", "next_staff_id", "next_experiment_id", "next_idea_id", "total_grants", "rescue_count", "study_points", "next_desk_id", "next_flavor_hour", "discoveries_without_legendary"]:
		if not numeric(data.get(key)): return false
	if data.hour >= 24 or data.day < 1 or data.prestige > data.lifetime_impact: return false
	if not data.get("rng_state") is String or not data.rng_state.is_valid_int(): return false
	if not data.get("rng_seed") is String or not data.rng_seed.is_valid_int(): return false
	for key in ["raw_by_field", "analyzed_by_field"]:
		if not data.get(key) is Dictionary: return false
		for field in FIELDS:
			if not numeric(data[key].get(field)): return false
	for key in ["experiments", "staff", "ideas", "unlocked", "history", "log_entries", "desks", "resource_history", "recent_flavor"]:
		if not data.get(key) is Array: return false
	if data.staff.size() > 18 or data.ideas.size() > 6: return false
	for key in ["active_paper", "pending_result", "candidates"]:
		if not data.get(key) is Dictionary: return false
	if not data.get("lab_name") is String: return false
	for key in ["flavor_state", "flavor_seed"]:
		if not data.get(key) is String or not data[key].is_valid_int(): return false
	for point in data.resource_history:
		if not point is Dictionary or not numeric(point.get("day")) or not numeric(point.get("funds")) or not numeric(point.get("grants")) or not numeric(point.get("grant_income", 0)): return false
		for pool in ["raw", "analyzed"]:
			if not point.get(pool) is Dictionary: return false
			for field in FIELDS:
				if not numeric(point[pool].get(field)): return false
	var occupied = {}
	var desk_ids = []
	for desk in data.desks:
		if not desk is Dictionary or desk.get("kind") != "desk": return false
		for key in ["id", "x", "y"]:
			if not numeric(desk.get(key)): return false
		if desk.id in desk_ids or not Layout.room_allows("desk", Vector2i(desk.x, desk.y)): return false
		desk_ids.append(desk.id)
		for cell in Layout.cells("desk", Vector2i(desk.x, desk.y)):
			if occupied.has(cell): return false
			occupied[cell] = true
	var experiment_ids = []
	for experiment in data.experiments:
		if not experiment is Dictionary or not EQUIPMENT.has(experiment.get("kind", "")): return false
		for key in ["id", "x", "y", "level", "condition"]:
			if not numeric(experiment.get(key)): return false
		var cell = Vector2i(experiment.x, experiment.y)
		if experiment.id in experiment_ids or not Layout.room_allows(experiment.kind, cell) or experiment.level < 1 or experiment.level > 3 or experiment.condition < 35 or experiment.condition > 100: return false
		for footprint_cell in Layout.cells(experiment.kind, cell):
			if occupied.has(footprint_cell): return false
			occupied[footprint_cell] = true
		experiment_ids.append(experiment.id)
	for desk in data.desks:
		if occupied.has(Layout.chair(desk)): return false
	var saved_grid = AStarGrid2D.new()
	saved_grid.region = Rect2i(Vector2i.ZERO, Layout.SIZE)
	saved_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	saved_grid.update()
	for x in range(Layout.SIZE.x):
		for y in range(Layout.SIZE.y):
			var cell = Vector2i(x, y)
			if Layout.wall(cell) or Layout.fixed_furniture(cell) or occupied.has(cell): saved_grid.set_point_solid(cell)
	for desk in data.desks:
		if saved_grid.get_point_path(Layout.ENTRANCE, Layout.chair(desk)).is_empty(): return false
	for experiment in data.experiments:
		var accessible = false
		for target in Layout.perimeter(experiment):
			if saved_grid.is_in_boundsv(target) and not saved_grid.is_point_solid(target) and not saved_grid.get_point_path(Layout.ENTRANCE, target).is_empty(): accessible = true; break
		if not accessible: return false
	var staff_ids = []
	for person in data.staff:
		if not valid_person(person) or person.id in staff_ids: return false
		if person.experiment != -1 and person.experiment not in experiment_ids: return false
		if person.desk != -1 and person.desk not in desk_ids: return false
		staff_ids.append(person.id)
	for role in ROLES:
		if not valid_person(data.candidates.get(role)) or data.candidates[role].role != role: return false
	for key in data.unlocked:
		if not UPGRADES.has(key): return false
	for idea in data.ideas:
		if not valid_idea(idea): return false
	if not data.active_paper.is_empty():
		var paper = data.active_paper
		if not valid_idea(paper) or paper.get("stage") not in ["writing", "review"]: return false
		for key in ["progress", "work", "chance", "review_left", "review_roll", "started"]:
			if not numeric(paper.get(key)): return false
		if paper.chance > 1 or paper.review_roll > 1 or paper.progress > paper.work or paper.work <= 0: return false
		if not paper.get("committed") is Dictionary or paper.committed.is_empty(): return false
		for field in paper.committed:
			if not FIELDS.has(field) or not numeric(paper.committed[field]): return false
	for result in data.history + ([data.pending_result] if not data.pending_result.is_empty() else []):
		if not result is Dictionary or not result.get("title") is String or not result.get("feedback") is String or not result.get("accepted") is bool or not FIELDS.has(result.get("field", "")) or not JOURNALS.has(result.get("kind", "")): return false
		for key in ["day", "chance", "impact", "grant"]:
			if not numeric(result.get(key)): return false
	for entry in data.log_entries:
		if not entry is Dictionary or not entry.get("message") is String or not numeric(entry.get("day")): return false
	return true

func valid_person(person: Variant) -> bool:
	if not person is Dictionary: return false
	if not person.get("name") is String or not ROLES.has(person.get("role", "")) or not FIELDS.has(person.get("specialty", "")) or not Catalog.TRAITS.has(person.get("trait", "")) or not Catalog.PERSONALITIES.has(person.get("personality", "")): return false
	for key in ["id", "rest", "acquire", "analyze", "energy", "x", "y"]:
		if not numeric(person.get(key)): return false
	if person.rest + person.acquire + person.analyze > 24 or person.energy > 100 or person.x > 18 or person.y > 12: return false
	if person.get("focus") != "any" and not FIELDS.has(person.get("focus", "")): return false
	if person.get("duty") not in ["auto", "write", "study", "maintain"]: return false
	if not person.get("experiment") is float and not person.get("experiment") is int: return false
	if not person.get("desk") is float and not person.get("desk") is int: return false
	for key in ["status", "task"]:
		if not person.get(key) is String: return false
	if not person.get("route") is Array or not person.get("destination") is Array: return false
	return true

func valid_idea(idea: Variant) -> bool:
	return idea is Dictionary and numeric(idea.get("id")) and FIELDS.has(idea.get("field", "")) and JOURNALS.has(idea.get("kind", "")) and idea.get("title") is String and (idea.get("secondary") == "" or FIELDS.has(idea.get("secondary", "")))

func rarity(kind: String) -> Dictionary:
	return {"letter": {"name": "Common", "color": "b5bfc5", "icon": "paper"}, "article": {"name": "Rare", "color": "89acc5", "icon": "rare"}, "breakthrough": {"name": "Legendary", "color": "d5b577", "icon": "legendary"}}[kind]

func roll_tier() -> String:
	var roll = rng.randf()
	if discoveries_without_legendary >= 7 or roll < 0.15:
		discoveries_without_legendary = 0
		return "breakthrough"
	discoveries_without_legendary += 1
	return "article" if roll < 0.45 else "letter"

func scheduled_to_write(person: Dictionary, at_hour: int) -> bool:
	var local_hour = posmod(at_hour - Catalog.PERSONALITIES[person.personality].shift, 24)
	return local_hour >= person.rest + person.acquire + person.analyze and person.duty in ["auto", "write"]

func writing_availability() -> Dictionary:
	var assigned = 0
	var now = 0
	var next = 99
	var names = PackedStringArray()
	var desk_count = 0
	for person in staff:
		if person.duty not in ["auto", "write"] or activity_hours(person) == 0: continue
		assigned += activity_hours(person)
		if choose_desk(person).is_empty(): continue
		desk_count += 1
		names.append(person.name + ": %dh/day" % activity_hours(person))
		if scheduled_to_write(person, hour): now += 1
		for offset in range(24):
			if scheduled_to_write(person, (hour + offset) % 24): next = mini(next, offset); break
	var summary = "No writing hours assigned" if assigned == 0 else "Writers need a reachable desk" if desk_count == 0 else "%d writer%s scheduled now" % [now, "" if now == 1 else "s"] if now > 0 else "Next writing shift in %dh" % next
	return {"hours": assigned, "now": now, "next": next, "desks": desk_count, "summary": summary, "detail": "\n".join(names)}

func paper_block_reason(id: int, commitment: float = 1.0) -> String:
	var idea = idea_by_id(id)
	if idea.is_empty(): return "This idea is no longer available."
	if not pending_result.is_empty(): return "Read the referee decision first."
	if not active_paper.is_empty(): return "A manuscript is already active."
	if lifetime_impact < JOURNALS[idea.kind].prestige: return "Requires %d lifetime impact." % JOURNALS[idea.kind].prestige
	var writing = writing_availability()
	if writing.hours == 0: return "No writing hours. Open People and assign Auto or Write activity."
	if writing.desks == 0: return "No reachable writing desk. Place or assign a desk in the office."
	for field in dataset_cost(idea, commitment):
		if analyzed_by_field[field] < dataset_cost(idea, commitment)[field]: return "Need %.0f more %s evidence." % [ceilf(dataset_cost(idea, commitment)[field] - analyzed_by_field[field]), FIELDS[field].name]
	return ""

func maybe_flavor_event(force: bool = false) -> void:
	var time = (day - 1) * 24 + hour
	if not force and time < next_flavor_hour: return
	next_flavor_hour = time + flavor_rng.randi_range(8, 17)
	var event = Events.choose(self, flavor_rng, recent_flavor)
	if event.is_empty(): return
	recent_flavor.append(event.key)
	if recent_flavor.size() > 24: recent_flavor.pop_front()
	announce(event.message)
	log_entries[0]["flavor"] = true
	log_entries[0]["category"] = event.category

func record_resources() -> void:
	var previous = resource_history.back().grants if not resource_history.is_empty() else 0.0
	resource_history.append({"day": day, "funds": funds, "raw": raw_by_field.duplicate(), "analyzed": analyzed_by_field.duplicate(), "grants": total_grants, "grant_income": total_grants - previous})
	if resource_history.size() > 720: resource_history.pop_front()

var save_prefix = "user://"

func slot_path(slot: int) -> String:
	return save_prefix + "fieldwork_slot_%d_v3.json" % slot

func save_slot(slot: int, title: String) -> bool:
	if slot < 1 or slot > 5: return false
	var previous = lab_name
	lab_name = title.strip_edges().left(60) if title.strip_edges() != "" else previous
	if not save_lab(true, slot_path(slot)):
		lab_name = previous
		return false
	return true

func save_entries() -> Array:
	var result: Array = []
	var paths = [SAVE_PATH]
	for slot in range(1, 6): paths.append(slot_path(slot))
	paths.append(V2_PATH)
	paths.append(LEGACY_PATH)
	for path in paths:
		if not FileAccess.file_exists(path): continue
		var parser = JSON.new()
		var file = FileAccess.open(path, FileAccess.READ)
		if file == null or parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
			result.append({"path": path, "name": "Unreadable save", "day": 0, "valid": false, "date": ""})
			continue
		var data = parser.data
		result.append({"path": path, "name": str(data.get("lab_name", "Previous laboratory")), "day": int(data.day) if numeric(data.get("day")) else 0, "valid": valid_save(data) if data.get("version") == 3 else data.get("version") in [1, 2], "date": str(data.get("saved_at", "")), "autosave": path == SAVE_PATH, "legacy": path in [V2_PATH, LEGACY_PATH], "slot": paths.find(path), "modified": FileAccess.get_modified_time(path)})
	result.sort_custom(func(a, b): return a.get("modified", 0) > b.get("modified", 0))
	return result

func migrate_v2(old: Dictionary) -> Dictionary:
	for key in ["funds", "prestige", "lifetime_impact", "published", "day", "hour", "next_staff_id", "next_experiment_id", "next_idea_id", "total_grants", "rescue_count", "study_points"]:
		if old.has(key) and not numeric(old[key]): return {}
	for key in ["raw_by_field", "analyzed_by_field", "candidates", "active_paper", "pending_result"]:
		if old.has(key) and not old[key] is Dictionary: return {}
	for key in ["staff", "experiments", "ideas", "unlocked", "history", "log_entries"]:
		if not old.get(key) is Array: return {}
	for person in old.staff + old.get("candidates", {}).values():
		if not person is Dictionary: return {}
		var normalized = person.duplicate(true)
		normalized.desk = -1
		if not valid_person(normalized): return {}
	for experiment in old.experiments:
		if not experiment is Dictionary or not EQUIPMENT.has(experiment.get("kind", "")): return {}
		for key in ["id", "x", "y", "level", "condition"]:
			if not numeric(experiment.get(key)): return {}
	var temporary = LabSimulation.new()
	temporary.new_lab()
	temporary.autosave_enabled = false
	for key in ["funds", "raw_by_field", "analyzed_by_field", "prestige", "lifetime_impact", "published", "day", "hour", "staff", "candidates", "active_paper", "pending_result", "ideas", "unlocked", "history", "log_entries", "next_staff_id", "next_experiment_id", "next_idea_id", "total_grants", "rescue_count", "study_points"]:
		if old.has(key): temporary.set(key, old[key].duplicate(true) if old[key] is Dictionary or old[key] is Array else old[key])
	temporary.experiments.clear()
	temporary.rebuild_navigation()
	var original_funds = temporary.funds
	for experiment in old.get("experiments", []):
		if not experiment is Dictionary or not EQUIPMENT.has(experiment.get("kind", "")): temporary.free(); return {}
		var placed = false
		for x in [2, 5, 12, 15, 1, 4, 13, 16]:
			for y in [1, 3]:
				temporary.funds = maxf(temporary.funds, 100000)
				if temporary.placement_error(experiment.kind, Vector2i(x, y)) == "":
					var remapped = experiment.duplicate(true)
					remapped.x = x
					remapped.y = y
					temporary.experiments.append(remapped)
					temporary.rebuild_navigation()
					placed = true
					break
			if placed: break
		if not placed:
			original_funds += EQUIPMENT[experiment.kind].cost
			for person in temporary.staff:
				if person.get("experiment") == experiment.id: person.experiment = -1
	temporary.funds = original_funds
	for index in range(temporary.staff.size()):
		var person = temporary.staff[index]
		person.desk = index % 3 + 1
		person.x = float(Layout.ENTRANCE.x)
		person.y = float(Layout.ENTRANCE.y)
		person.motion = []
		person.working = false
		person.last_field = ""
	for candidate in temporary.candidates.values():
		candidate.desk = -1
		candidate.x = float(Layout.ENTRANCE.x)
		candidate.y = float(Layout.ENTRANCE.y)
		candidate.motion = []
		candidate.working = false
		candidate.last_field = ""
	temporary.resource_history.clear()
	temporary.record_resources()
	temporary.next_flavor_hour = (int(temporary.day) - 1) * 24 + int(temporary.hour) + 12
	var data = temporary.snapshot()
	for key in ["rng_seed", "rng_state"]:
		if old.has(key): data[key] = old[key]
	temporary.free()
	return data
