extends SceneTree

const Simulation = preload("res://scripts/simulation.gd")
var sim: LabSimulation
var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func reset_lab() -> void:
	sim.new_lab()
	sim.rng.seed = 42
	sim.autosave_enabled = false
	sim.set_process(false)
	for person in sim.staff:
		person.trait = "diligent"
		person.personality = "early"

func run_hours(count: int) -> void:
	for i in range(count): sim.advance_hour()

func run_to_result(limit: int = 1000) -> void:
	for i in range(limit):
		if not sim.pending_result.is_empty(): return
		sim.advance_hour()

func run_tests() -> void:
	sim = Simulation.new()
	root.add_child(sim)
	reset_lab()
	check(Simulation.DAY_SECONDS == 48, "A day takes 48 seconds")
	sim._process(24)
	check(sim.day == 1 and sim.hour == 8, "Paused clock consumes no time")
	sim.paused = false
	sim._process(1.0)
	check(sim.hour == 8, "Clock accumulates partial hours")
	sim._process(1.0)
	check(sim.hour == 9, "Two real seconds advance an hour at 1x")
	sim.speed = 4
	sim._process(1.0)
	check(sim.hour == 11, "4x changes the hourly simulation rate")
	reset_lab()
	check(sim.raw_by_field.size() == 4 and sim.analyzed_by_field.size() == 4, "Four independent data pools exist")
	var person = sim.staff[0]
	check(sim.scheduled_task(person, 0) == "rest" and sim.scheduled_task(person, 8) == "acquire" and sim.scheduled_task(person, 16) == "analyze", "Daily routine chooses the correct work blocks")
	person.personality = "night"
	check(sim.scheduled_task(person, 8) == "rest" and sim.scheduled_task(person, 16) == "acquire", "Night owl shifts the routine by eight hours")
	sim.set_schedule(person.id, "rest", 12)
	check(person.rest == 12 and sim.activity_hours(person) >= 0, "Changing a schedule keeps the daily budget valid")
	sim.set_schedule(person.id, "analyze", 24)
	check(person.analyze == 24 and person.rest == 0 and person.acquire == 0, "The edited schedule block gets priority without exceeding 24h")
	reset_lab()
	person = sim.staff[0]
	var start_position = Vector2(person.x, person.y)
	sim.advance_hour()
	check(Vector2(person.x, person.y) != start_position, "Staff move toward a workstation")
	check(person.target_id == 1, "Collector targets an installed experiment")
	check(not sim.navigation.is_point_solid(Vector2i(roundi(person.x), roundi(person.y))), "Agent remains outside solid equipment tiles")
	run_hours(7)
	check(sim.raw_by_field.optics > 0 and sim.raw_by_field.nuclear == 0, "Optical bench creates optics data only before mixed-mode upgrades")
	var before = sim.raw_data + sim.analyzed_data
	run_hours(8)
	check(is_equal_approx(sim.raw_data + sim.analyzed_data, before), "Analysis conserves evidence across typed pools")
	check(sim.analyzed_by_field.optics > 0, "Scheduled analysis turns raw optics into optics evidence")
	check(person.energy < 100, "Working consumes individual energy")
	var energy = person.energy
	run_hours(8)
	check(person.energy > energy, "Resting at the common area restores energy")
	person.energy = 1
	sim.advance_hour()
	check(person.task == "rest", "Exhausted staff choose emergency rest")
	# Specialty, trait bonus/malus and personalities affect actual efficiency.
	reset_lab()
	person = sim.staff[0]
	person.specialty = "optics"
	person.trait = "meticulous"
	var specialized = sim.performance(person, "analyze", "optics")
	var general = sim.performance(person, "analyze", "nuclear")
	check(is_equal_approx(specialized / general, 1.25), "Specialty gives a 25% field bonus")
	check(sim.performance(person, "analyze") > sim.performance(person, "acquire"), "Meticulous trait boosts analysis and penalizes collection")
	sim.hour = 18
	var evening = sim.performance(person, "write")
	sim.hour = 9
	check(sim.performance(person, "write") > evening, "Early bird gets a morning work bonus")
	# Explicit field/station assignments and blocked workstations.
	reset_lab()
	person = sim.staff[0]
	sim.set_assignment(person.id, "focus", "nuclear")
	sim.advance_hour()
	check(person.status == "No matching accessible experiment", "A nuclear-focused student cannot collect from an optics-only bench")
	sim.place_experiment("vacuum", Vector2i(12, 1))
	sim.set_assignment(person.id, "focus", "materials")
	sim.set_assignment(person.id, "experiment", 2)
	sim.advance_hour()
	check(person.target_id == 2, "Explicit assignment reaches the selected experiment")
	sim.remove_experiment(2)
	check(person.experiment == -1, "Removing an assigned experiment resets station selection")
	reset_lab()
	check(sim.desks.size() == 3 and sim.valid_save(sim.snapshot()), "Starting furniture forms a valid save")
	check(not sim.place_desk(Vector2i(4, 7)), "Corridor desk placement rejected")
	check(not sim.place_desk(Vector2i(2, 10)), "Desk cannot occupy an existing chair")
	check(sim.place_desk(Vector2i(5, 11)), "Desk can be physically placed in the office")
	check(sim.navigation.is_point_solid(Vector2i(5, 11)) and not sim.navigation.is_point_solid(Vector2i(5, 12)), "Desktop is solid and chair stays accessible")
	for desk in sim.desks:
		check(not sim.navigation.get_point_path(sim.Layout.ENTRANCE, sim.Layout.chair(desk)).is_empty(), "Every desk chair connects to corridor")
	for i in range(48):
		sim.advance_hour()
		for member in sim.staff:
			for point in member.motion:
				check(not sim.navigation.is_point_solid(Vector2i(roundi(point[0]), roundi(point[1]))), "Walking path avoids solid walls and furniture")
	sim.analyzed_by_field.optics = 100
	for member in sim.staff: member.duty = "study"
	check(sim.paper_block_reason(sim.ideas[0].id).contains("No writing hours"), "Publication explains missing writing time")
	sim.staff[2].duty = "auto"
	for desk in sim.desks.duplicate(): sim.remove_desk(desk.id)
	check(sim.paper_block_reason(sim.ideas[0].id).contains("desk"), "Publication explains missing physical desk")
	# Permanent unlock spending and mixed experiment output.
	reset_lab()
	var cash = sim.funds
	check(not sim.place_experiment("detector", Vector2i(4, 2)), "Locked experiments cannot be purchased")
	check(not sim.place_experiment("optics", Vector2i(2, 2)) and not sim.place_experiment("optics", Vector2i(-1, 0)), "Occupied and out-of-bounds placement is rejected")
	check(sim.funds == cash, "Rejected construction never charges money")
	sim.prestige = 20
	sim.lifetime_impact = 20
	var income = sim.income()
	check(not sim.unlock_upgrade("quantum_lab"), "Development prerequisites are enforced")
	sim.unlocked.append_array(["precision", "module_slots"])
	check(sim.unlock_upgrade("mixed_mode") and sim.prestige == 17, "Unlock spends exactly the listed impact")
	check(sim.lifetime_impact == 20 and sim.income() == income, "Spending impact leaves lifetime reputation and support unchanged")
	check(not sim.unlock_upgrade("mixed_mode"), "An unlock cannot be purchased twice")
	check(sim.output_mix(sim.experiments[0]).size() == 1, "Mixed-mode requires an equipment upgrade too")
	sim.upgrade_experiment(1)
	check(sim.output_mix(sim.experiments[0]) == {"optics": 0.75, "quantum": 0.25}, "Level 2 splits output 75/25")
	sim.unlocked.append("advanced_instruments")
	sim.upgrade_experiment(1)
	check(sim.output_mix(sim.experiments[0]) == {"optics": 0.6, "quantum": 0.4}, "Level 3 splits output 60/40")
	check(not sim.upgrade_experiment(1), "Level 3 remains the upgrade cap")
	run_hours(8)
	check(sim.raw_by_field.quantum > 0 and is_equal_approx(sim.raw_by_field.quantum / sim.raw_data, 0.4), "Upgraded collection produces both types in the actual simulation")
	# Study, idea generation and paid board refresh.
	reset_lab()
	run_hours(8)
	check(sim.study_points > 0, "Idle Auto researchers study at a desk")
	check(not sim.think_idea(), "Ideas require earned study resources")
	sim.study_points = 30
	var idea_count = sim.ideas.size()
	check(sim.think_idea() and sim.ideas.size() == idea_count + 1 and sim.study_points == 22, "Thinking costs 8 points and adds one idea")
	check(sim.ideas.back().field == "optics", "New ideas favor installed research fields")
	check(not sim.think_idea(), "Full board blocks further idea creation")
	check(not sim.refresh_ideas(), "Board refresh is locked before journal club")
	sim.prestige = 2
	sim.lifetime_impact = 2
	sim.unlocked.append("desk_systems")
	sim.unlock_upgrade("journal_club")
	check(sim.refresh_ideas() and sim.study_points == 10 and sim.ideas.size() == 6, "Journal club refresh consumes 12 study and replaces the board")
	sim.discard_idea(sim.ideas[0].id)
	check(sim.ideas.size() == 5, "Discard frees an idea slot")
	# Candidate preview is the person hired, with persistent traits.
	reset_lab()
	var candidate = sim.candidates.researcher.duplicate(true)
	check(sim.hire("researcher"), "Researcher hire succeeds")
	check(sim.staff.back().name == candidate.name and sim.staff.back().specialty == candidate.specialty and sim.staff.back().trait == candidate.trait and sim.staff.back().personality == candidate.personality, "Hired staff exactly match the previewed candidate")
	sim.funds = 0
	check(not sim.hire("phd"), "Unaffordable hire is rejected")
	# Common papers start at zero impact; rewards are not entry requirements.
	reset_lab()
	for starter in sim.ideas:
		if starter.kind == "letter":
			sim.analyzed_by_field[starter.field] = 18
			check(sim.can_start_paper(starter.id), "Common %s paper is accessible at zero lifetime impact" % starter.field)
		else:
			check(sim.paper_block_reason(starter.id) == "Requires 2 lifetime impact.", "Only the rare starter article needs two lifetime impact")
	check(sim.start_paper(sim.ideas[0].id) and sim.prestige == 0 and sim.lifetime_impact == 0, "Starting a common paper does not charge impact")
	# Evidence commitment, writing, review and hard pause on a decision.
	reset_lab()
	var idea = sim.ideas[0]
	sim.analyzed_by_field.nuclear = 100
	check(not sim.can_start_paper(idea.id), "Wrong-field evidence cannot fund an optics paper")
	sim.analyzed_by_field.optics = 100
	check(sim.acceptance_chance(idea, 2) > sim.acceptance_chance(idea, 1), "Extra evidence increases acceptance chance")
	check(sim.dataset_cost(idea, 2).optics == 36, "Double commitment spends twice the typed dataset")
	check(sim.start_paper(idea.id, 2), "Idea with enough evidence starts writing")
	check(sim.analyzed_by_field.optics == 64 and sim.active_paper.work == 12, "Extra evidence is debited and increases writing work")
	check(not sim.start_paper(sim.ideas[0].id), "Only one active manuscript is allowed")
	sim.active_paper.review_roll = 0.0
	sim.paused = false
	run_to_result()
	check(sim.published == 1 and sim.pending_result.accepted, "Successful peer review publishes the paper")
	check(sim.pending_result.title == idea.title and sim.pending_result.feedback != "", "Publication result includes a flavor title and referee feedback")
	check(sim.paused and sim.prestige == 2 and sim.lifetime_impact == 2, "Publication pauses and awards available and lifetime impact")
	check(sim.total_grants == 2600, "Publication grants are paid exactly once")
	var stopped_hour = sim.hour
	var stopped_day = sim.day
	sim.paused = false
	sim._process(100)
	sim.advance_hour()
	check(sim.hour == stopped_hour and sim.day == stopped_day, "An unacknowledged result blocks time even if resume is requested")
	sim.acknowledge_result()
	check(sim.paused and sim.pending_result.is_empty(), "Acknowledging feedback keeps the lab paused")
	# Rejection keeps a recovery route and doesn't invent rewards.
	reset_lab()
	idea = sim.ideas[0]
	sim.analyzed_by_field.optics = 36
	sim.start_paper(idea.id, 2)
	sim.active_paper.review_roll = 1.0
	sim.active_paper.stage = "review"
	sim.active_paper.review_left = 1
	for member in sim.staff: member.rest = 24; member.acquire = 0; member.analyze = 0
	sim.advance_hour()
	check(not sim.pending_result.accepted and sim.published == 0 and sim.total_grants == 0, "Rejected paper earns no publication rewards")
	check(sim.analyzed_by_field.optics == 27 and not sim.idea_by_id(idea.id).is_empty(), "Rejection returns 75% of typed evidence and the original idea")
	# Multi-field manuscript and exact cancellation refund.
	reset_lab()
	sim.unlocked.append("mixed_mode")
	sim.lifetime_impact = 7
	sim.prestige = 7
	sim.ideas.clear()
	idea = sim.add_idea("optics", "article")
	check(idea.secondary == "quantum", "Advanced ideas may span two fields")
	sim.analyzed_by_field.optics = 100
	check(not sim.can_start_paper(idea.id), "Cross-field paper requires both data types")
	sim.analyzed_by_field.quantum = 100
	sim.start_paper(idea.id, 1.5)
	check(sim.analyzed_by_field.optics == 46 and sim.analyzed_by_field.quantum == 82, "Cross-field commitment spends the displayed 75/25 dataset")
	sim.cancel_paper()
	check(sim.analyzed_by_field.optics == 100 and sim.analyzed_by_field.quantum == 100, "Shelving refunds the exact committed data in both fields")
	# Save fidelity, deterministic review and fresh-save validation.
	reset_lab()
	sim.analyzed_by_field.optics = 50
	sim.start_paper(sim.ideas[0].id, 1.5)
	run_hours(3)
	var saved = sim.snapshot()
	var path = "res://tests/.test_save.json"
	check(sim.save_lab(false, path), "Version 4 save writes atomically")
	sim.funds = 0
	check(sim.load_lab(path), "Version 4 save loads")
	check(sim.funds == saved.funds and sim.hour == saved.hour and sim.staff[0].trait == saved.staff[0].trait and sim.staff[0].energy == saved.staff[0].energy, "Save preserves finances, clock, traits and individual energy")
	check(sim.active_paper.review_roll == saved.active_paper.review_roll and sim.active_paper.committed == saved.active_paper.committed, "Save preserves fixed review roll and exact commitment")
	sim.active_paper.stage = "review"
	sim.active_paper.review_left = 1
	sim.active_paper.review_roll = 0
	sim.advance_hour()
	sim.save_lab(false, path)
	sim.acknowledge_result()
	check(sim.load_lab(path) and not sim.pending_result.is_empty() and sim.paused, "Unacknowledged publication survives reload and remains paused")
	var invalid = sim.snapshot()
	invalid.staff[0].energy = "bad"
	check(not sim.valid_save(invalid), "Malformed staff state is rejected")
	invalid = sim.snapshot()
	invalid.analyzed_by_field.optics = -1
	check(not sim.valid_save(invalid), "Negative typed evidence is rejected")
	invalid = sim.snapshot()
	invalid.ideas[0].field = "unknown"
	check(not sim.valid_save(invalid), "Unknown research fields are rejected")
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	cash = sim.funds
	check(not sim.load_lab(path) and sim.funds == cash, "Corrupt save leaves the current lab unchanged")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# Named slots preserve furniture, graphs, flavor state and rarity protection.
	reset_lab()
	sim.save_prefix = "res://tests/.test_"
	sim.place_desk(Vector2i(5, 11))
	run_hours(48)
	sim.discoveries_without_legendary = 5
	check(sim.save_slot(2, "Test Annex"), "Named slot saves")
	var desk_count = sim.desks.size()
	var sample_count = sim.resource_history.size()
	sim.new_lab()
	check(sim.load_lab(sim.slot_path(2)), "Named slot loads")
	check(sim.lab_name == "Test Annex" and sim.desks.size() == desk_count and sim.resource_history.size() == sample_count and sim.discoveries_without_legendary == 5, "Slot preserves name, furniture, history and loot state")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(sim.slot_path(2)))
	reset_lab()
	var longest_drought = 0
	var drought = 0
	var legendary_count = 0
	for i in range(1000):
		if sim.roll_tier() == "breakthrough": legendary_count += 1; drought = 0
		else: drought += 1; longest_drought = maxi(longest_drought, drought)
	check(longest_drought <= 7 and legendary_count > 150 and legendary_count < 300, "Legendary discovery is forgiving and protects against long droughts")
	reset_lab()
	run_hours(5)
	var economy = [sim.funds, sim.raw_data, sim.analyzed_data, sim.prestige, sim.rng.state]
	var last_key = ""
	for i in range(12):
		sim.maybe_flavor_event(true)
		if not sim.recent_flavor.is_empty():
			check(sim.recent_flavor.back() != last_key, "Flavor does not repeat its previous template")
			last_key = sim.recent_flavor.back()
	check([sim.funds, sim.raw_data, sim.analyzed_data, sim.prestige, sim.rng.state] == economy, "Flavor cannot change economy or publication randomness")
	reset_lab()
	var crowded = sim.snapshot()
	crowded.desks.append({"id": 4, "kind": "desk", "x": 2, "y": 10})
	check(not sim.valid_save(crowded), "Save cannot place a desktop over another desk chair")
	for member in sim.staff:
		member.rest = 0
		member.acquire = 0
		member.analyze = 24
		member.desk = 1
		member.x = 2.0
		member.y = 10.0
	sim.raw_by_field.optics = 100
	sim.advance_hour()
	var desk_workers = sim.staff.filter(func(member): return member.working)
	check(desk_workers.size() == 1, "One person per physical desk during a work hour")
	check(sim.staff.filter(func(member): return member.status.contains("no free")).size() == 2, "Other people report shared desk contention")
	# A normal starting team can collect its first dataset without injected evidence.
	reset_lab()
	var elapsed = 0
	while not sim.can_start_paper(sim.ideas[0].id) and elapsed < 24 * 20:
		sim.advance_hour()
		elapsed += 1
	check(elapsed < 24 * 20, "Founding team reaches its first optics manuscript through normal routines")
	sim.start_paper(sim.ideas[0].id, 1)
	sim.active_paper.review_roll = 0
	run_to_result()
	check(sim.published == 1 and sim.rescue_count == 0, "Normal collection, analysis, writing and review completes without rescue")
	print("First manuscript ready after %d lab hours; first decision on day %d at %02d:00." % [elapsed, sim.day, sim.hour])
	# A decision during a large frame must stop the remaining clock catch-up.
	reset_lab()
	sim.analyzed_by_field.optics = 36
	sim.start_paper(1, 2)
	sim.active_paper.stage = "review"
	sim.active_paper.review_left = 1
	sim.active_paper.review_roll = 0
	sim.paused = false
	sim.speed = 4
	sim._process(50)
	check(sim.day == 1 and sim.hour == 9 and sim.paused, "Publication stops a large fast-forward frame after exactly one hour")
	# Every field and tier has a complete peer-review path.
	for field in Simulation.FIELDS:
		for kind in Simulation.JOURNALS:
			reset_lab()
			sim.ideas.clear()
			sim.lifetime_impact = 20
			sim.prestige = 20
			idea = sim.add_idea(field, kind)
			sim.analyzed_by_field[field] = 300
			check(sim.start_paper(idea.id, 2), "%s %s accepts matching evidence" % [field, kind])
			sim.active_paper.review_roll = 0
			run_to_result(1200)
			check(sim.published == 1 and sim.pending_result.field == field and sim.pending_result.kind == kind, "%s %s completes writing and review" % [field, kind])
	# Maintenance is performed at one reachable experiment, not across the whole lab.
	reset_lab()
	sim.hire("technician")
	var technician = sim.staff.back()
	technician.personality = "early"
	technician.experiment = 1
	sim.experiments[0].condition = 50
	run_hours(5)
	check(sim.experiments[0].condition > 50 and technician.target_id == 1, "Technician travels to and services assigned equipment")
	# Compute and lounge developments produce their advertised effects.
	reset_lab()
	person = sim.staff[0]
	person.rest = 0
	person.acquire = 0
	person.analyze = 24
	person.x = 2
	person.y = 10
	sim.raw_by_field.optics = 100
	for other in sim.staff.slice(1): other.rest = 24; other.acquire = 0; other.analyze = 0
	sim.advance_hour()
	var base_analysis = sim.analyzed_by_field.optics
	person.energy = 100
	sim.hour = 8
	sim.analyzed_by_field.optics = 0
	sim.unlocked.append("compute")
	sim.advance_hour()
	check(is_equal_approx(sim.analyzed_by_field.optics, base_analysis * 1.25), "Analysis cluster raises actual analysis by 25%")
	person.rest = 24
	person.analyze = 0
	person.x = 13
	person.y = 11
	person.energy = 20
	person.destination = []
	sim.unlocked.append("lounge")
	sim.advance_hour()
	check(person.energy == 30, "Common room restores ten energy per stationary rest hour")
	# Long-run strategy: publish, acknowledge reviews, and buy new ideas with study.
	reset_lab()
	var decisions = 0
	for i in range(24 * 160):
		if not sim.pending_result.is_empty(): sim.acknowledge_result(); decisions += 1
		if sim.active_paper.is_empty():
			var started = false
			for paper_idea in sim.ideas:
				if paper_idea.field == "optics" and sim.can_start_paper(paper_idea.id, 1.5):
					sim.start_paper(paper_idea.id, 1.5)
					started = true
					break
			if not started and sim.study_points >= 8:
				if sim.ideas.size() >= 6: sim.discard_idea(sim.ideas.back().id)
				sim.think_idea()
		sim.advance_hour()
	check(sim.published >= 5 and sim.rescue_count == 0, "A 160-day idea-and-review strategy remains playable without bailouts")
	print("160-day playtest: %d papers, %d review decisions, %d lifetime impact, $%.0f funds." % [sim.published, decisions, sim.lifetime_impact, sim.funds])
	print("Simulation checks: %d passed, %d failed." % [checks - failures, failures])
	quit(1 if failures else 0)
