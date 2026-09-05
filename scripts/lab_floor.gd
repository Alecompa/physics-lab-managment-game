class_name LabFloor
extends Control
signal cell_clicked(cell: Vector2i)
signal placement_cancelled
signal person_clicked(id: int)
var simulation: LabSimulation
var build_kind = ""
var selected_id = -1
var selected_kind = ""
var selected_person = -1
var hovered = Vector2i(-1, -1)
var animation_time = 0.0
var person_positions: Dictionary = {}
var trails: Dictionary = {}
var last_stamp = -1
var floor_origin = Vector2.ZERO
var tile = 40.0
var font: Font
const Layout = preload("res://scripts/lab_layout.gd")

func _ready() -> void:
	custom_minimum_size = Vector2(620, 480)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	font = ThemeDB.fallback_font
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_exited.connect(func(): hovered = Vector2i(-1, -1); queue_redraw())

func reset_positions() -> void:
	person_positions.clear()
	trails.clear()
	last_stamp = -1

func _process(delta: float) -> void:
	if simulation == null: return
	var stamp = simulation.day * 24 + simulation.hour
	if not simulation.paused: animation_time += delta * simulation.speed
	for person in simulation.staff:
		if not person_positions.has(person.id): person_positions[person.id] = Vector2(person.x, person.y)
		if stamp != last_stamp:
			var route = simulation.navigation.get_point_path(Vector2i(person_positions[person.id].round()), Vector2i(roundi(person.x), roundi(person.y)))
			trails[person.id] = Array(route)
		if not simulation.paused and trails.has(person.id):
			var budget = delta * simulation.speed * simulation.WALK_SPEED / simulation.HOUR_SECONDS
			while budget > 0 and not trails[person.id].is_empty():
				var target: Vector2 = trails[person.id][0]
				var distance = person_positions[person.id].distance_to(target)
				var used = minf(budget, distance)
				person_positions[person.id] = person_positions[person.id].move_toward(target, used)
				budget -= used
				if used >= distance - 0.0001: trails[person.id].pop_front()
	last_stamp = stamp
	queue_redraw()

func center(cell: Vector2) -> Vector2:
	return floor_origin + (cell + Vector2(0.5, 0.5)) * tile

func person_screen_position(person: Dictionary) -> Vector2:
	if person.get("working", false) and person.task == "rest" and trails.get(person.id, []).is_empty():
		var bed = simulation.bed_by_id(person.get("bed", -1))
		if not bed.is_empty(): return center(Vector2(bed.x, bed.y)) + Vector2(0, tile * 0.1)
	return center(person_positions.get(person.id, Vector2(person.x, person.y))) + Vector2(3 if int(person.id) % 2 else -3, 0)

func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(((point - floor_origin) / tile).floor())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hovered = cell_at(event.position)
		tooltip_text = ""
		if build_kind != "": tooltip_text = simulation.placement_error(build_kind, hovered)
		else:
			var object = simulation.object_at(hovered)
			if not object.is_empty(): tooltip_text = "%s #%d" % [object.kind.capitalize(), object.id] if object.kind in ["bed", "desk"] else "%s / L%d / %.0f%% condition" % [simulation.EQUIPMENT[object.kind].name, object.level, object.condition]
			for person in simulation.staff:
				if person_screen_position(person).distance_to(event.position) < 15: tooltip_text = "%s\n%s\nEnergy %.0f%%" % [person.name, person.status, person.energy]
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT: placement_cancelled.emit()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if build_kind == "":
				for person in simulation.staff:
					if person_screen_position(person).distance_to(event.position) < 14:
						selected_person = person.id
						person_clicked.emit(person.id)
						return
			var cell = cell_at(event.position)
			if Layout.inside(cell): cell_clicked.emit(cell)

func text_at(point: Vector2, text: String, color: Color, text_size: int = 12) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, color)

func _draw() -> void:
	if simulation == null or font == null: return
	tile = minf((size.x - 22) / 20.0, (size.y - 35) / 14.0)
	floor_origin = (size - Vector2(20, 14) * tile) * 0.5
	var map_rect = Rect2(floor_origin, Vector2(20, 14) * tile)
	draw_style_box(LabUI.box(Color("0f1215"), Color("0f1215"), 0, 10), Rect2(map_rect.position + Vector2(0, 8), map_rect.size))
	for x in range(20):
		for y in range(14):
			var cell = Vector2i(x, y)
			var position = floor_origin + Vector2(cell) * tile
			var room = Layout.room(cell)
			var color = Color("cbd0c6") if room in ["optics", "measurements"] else Color("c8c6bb") if room == "office" else Color("c7cdbe") if room == "common" else Color("aab8b5")
			if room == "wall": color = Color("4a535a")
			elif (x + y) % 2 == 1: color = color.darkened(0.024)
			draw_rect(Rect2(position, Vector2.ONE * tile), color)
			if room != "wall": draw_rect(Rect2(position, Vector2.ONE * tile), Color(0.2, 0.3, 0.3, 0.045), false)
			else:
				draw_line(position + Vector2(1, 1), position + Vector2(tile - 1, 1), Color("798389"), 2)
				if y in [0, 13] and x in [2, 3, 5, 6, 13, 14, 16, 17]:
					draw_rect(Rect2(position + Vector2(1, tile * 0.35), Vector2(tile - 2, tile * 0.25)), Color("aabfc3"))
	# Door frames occupy the walls, while their openings remain walkable.
	for y in [5, 8]:
		for x in [4, 15]:
			var p = floor_origin + Vector2(x, y) * tile
			draw_line(p, p + Vector2(0, tile), Color("f3efe0"), 3)
			draw_line(p + Vector2(tile, 0), p + Vector2(tile, tile), Color("f3efe0"), 3)
			draw_arc(p, tile * 0.8, 0, PI * 0.5, 12, Color("7d928b"), 1)
	# Coffee table and seats remain available for less effective bedless rest.
	var coffee = center(Vector2(12, 12))
	draw_rect(Rect2(coffee - Vector2.ONE * tile * 0.3, Vector2.ONE * tile * 0.6), Color("87765d"))
	draw_circle(coffee, tile * 0.12, Color("e4dfd2"))
	for seat in Layout.REST_SEATS: draw_circle(center(Vector2(seat)), tile * 0.22, Color("788c7d"))
	for bed in simulation.beds: draw_bed(bed)
	for cell in [Vector2(1, 6), Vector2(18, 7), Vector2(18, 12)]:
		var p = center(cell)
		draw_circle(p, tile * 0.18, Color("817364"))
		for angle in range(5): draw_circle(p + Vector2.from_angle(angle * 1.25) * tile * 0.11, tile * 0.12, Color("667e66"))
	var label_color = Color("64736f")
	for item in [[Vector2(1, 0), "OPTICS LAB"], [Vector2(12, 0), "MEASUREMENT LAB"], [Vector2(1, 13), "OFFICE"], [Vector2(12, 13), "SLEEPING AREA"]]:
		var label_position = center(item[0]) + Vector2(0, 4)
		var label_width = font.get_string_size(item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_rect(Rect2(label_position - Vector2(4, 12), Vector2(label_width + 8, 16)), Color("4a535a"))
		text_at(label_position, item[1], Color("dce0d7"), 10)

	for desk in simulation.desks: draw_desk(desk)
	for experiment in simulation.experiments: draw_experiment(experiment)
	if build_kind != "" and Layout.inside(hovered):
		var color = LabUI.ACCENT if simulation.can_place(build_kind, hovered) else Color("c97f73")
		var rect = Rect2(floor_origin + Vector2(hovered) * tile, Vector2(Layout.footprint(build_kind)) * tile)
		draw_rect(rect, Color(color, 0.25))
		draw_rect(rect, color, false, 2)
		if build_kind == "desk": draw_circle(center(Vector2(hovered + Vector2i.DOWN)), tile * 0.22, color)
	for person in simulation.staff: draw_person(person)

func draw_desk(desk: Dictionary) -> void:
	var p = floor_origin + Vector2(desk.x, desk.y) * tile
	var rect = Rect2(p + Vector2(3, 4), Vector2(tile * 2 - 6, tile - 8))
	draw_rect(Rect2(rect.position + Vector2(0, 4), rect.size), Color(0.1, 0.15, 0.15, 0.3))
	draw_style_box(LabUI.box(Color("9c8c73"), Color("7c715f"), 0, 3), rect)
	var active = false
	for person in simulation.staff:
		if person.get("working", false) and person.task in ["study", "analyze", "write"] and Vector2(person.x, person.y).distance_to(Vector2(Layout.chair(desk))) < 0.6: active = true
	draw_rect(Rect2(p + Vector2(7, 7), Vector2(tile * 0.65, tile * 0.45)), Color("354449"))
	draw_rect(Rect2(p + Vector2(10, 10), Vector2(tile * 0.5, tile * 0.28)), Color("9cb7b4") if active else Color("617879"))
	if active:
		for line in range(3): draw_line(p + Vector2(12, 12 + line * 4), p + Vector2(18 + sin(animation_time + line) * 5, 12 + line * 4), Color("dce7db"), 1)
	draw_rect(Rect2(p + Vector2(tile * 1.1, 9), Vector2(tile * 0.55, tile * 0.5)), Color("e7e5d5"))
	draw_circle(center(Vector2(Layout.chair(desk))), tile * 0.21, Color("697577"))
	if desk.id == selected_id and selected_kind == "desk": draw_rect(Rect2(p, Vector2(tile * 2, tile)), Color("d6b45f"), false, 2)

func draw_experiment(experiment: Dictionary) -> void:
	var p = floor_origin + Vector2(experiment.x, experiment.y) * tile
	var rect = Rect2(p + Vector2(5, 5), Vector2.ONE * (tile * 2 - 10))
	var color = Color(simulation.EQUIPMENT[experiment.kind].color)
	var active = false
	for person in simulation.staff:
		if person.target_id == experiment.id and person.get("working", false) and person.task == "acquire": active = true
	draw_rect(Rect2(rect.position + Vector2(3, 6), rect.size), Color(0.1, 0.15, 0.15, 0.25))
	draw_style_box(LabUI.box(Color("647379"), Color("4b5a60"), 0, 4), rect)
	var c = rect.get_center()
	match experiment.kind:
		"optics":
			for x in range(5):
				for y in range(5): draw_circle(rect.position + Vector2(8 + x * rect.size.x / 5.6, 8 + y * rect.size.y / 5.6), 1, Color("9ba7a5"))
			for offset in [-0.3, 0.0, 0.3]:
				var q = c + Vector2(rect.size.x * offset, rect.size.y * offset * -0.5)
				draw_rect(Rect2(q - Vector2(4, 8), Vector2(8, 16)), Color("c7cec4"))
			draw_line(c + Vector2(-rect.size.x * 0.35, rect.size.y * 0.17), c + Vector2(rect.size.x * 0.35, -rect.size.y * 0.17), color, 2 if active else 1)
		"vacuum":
			draw_circle(c, tile * 0.62, Color("a2b0af"))
			draw_circle(c, tile * 0.43, Color("334d58"))
			draw_arc(c, tile * 0.28, animation_time if active else 0, (animation_time if active else 0) + PI * 1.5, 20, color, 2)
		"detector":
			for i in range(5): draw_rect(Rect2(c + Vector2(-tile * 0.63 + i * tile * 0.28, -tile * 0.65), Vector2(tile * 0.17, tile * 1.3)), color.darkened(0.2))
			if active: draw_line(c - Vector2(tile * 0.7, 0), c + Vector2(tile * 0.7, 0), Color("eee2c5"), 2)
		"quantum":
			for radius in [0.25, 0.45, 0.65]: draw_arc(c, tile * radius, 0, TAU, 32, color, 3)
	if active:
		var pulse = fmod(animation_time * 0.4, 1.0)
		draw_circle(c + Vector2(sin(animation_time * 2) * tile * 0.25, -tile * 0.8 - pulse * 12), 2.5, Color(color, 1 - pulse))
	draw_circle(rect.end - Vector2(7, 7), 3, color if active else Color("404e51"))
	if experiment.condition < 55: draw_texture_rect(LabUI.icon("warning"), Rect2(rect.position + Vector2(2, 2), Vector2(15, 15)), false, Color("d5ae73"))
	for index in range(experiment.get("modules", []).size()):
		var key = experiment.modules[index]
		var q = rect.position + Vector2(index * 21 + 4, rect.size.y - 19)
		draw_style_box(LabUI.box(Color("283d45"), LabUI.ACCENT, 0, 2), Rect2(q, Vector2(18, 15)))
		draw_texture_rect(LabUI.icon("clock" if key == "accelerator" else key), Rect2(q + Vector2(2, 1), Vector2(13, 13)), false, LabUI.ACCENT if key == "accelerator" else Color(simulation.FIELDS[key].color))
	if experiment.id == selected_id and selected_kind not in ["desk", "bed"]: draw_rect(Rect2(p, Vector2.ONE * tile * 2), Color("d6b45f"), false, 2)

func draw_person(person: Dictionary) -> void:
	var p = person_screen_position(person)
	var walking = trails.has(person.id) and not trails[person.id].is_empty()
	var phase = animation_time * 5 + person.id
	var size_value = clampf(tile / 44, 0.7, 1.1)
	var look = StaffAppearance.of(person)
	var skin = look.skin
	var sleeping = person.task == "rest" and person.get("working", false) and person.get("bed", -1) != -1 and not walking
	if sleeping:
		draw_circle(p, 4.5 * size_value, skin)
		if look.style != 4: draw_arc(p - Vector2(0, 1), 4.5 * size_value, PI, TAU, 10, look.hair, 2)
		draw_texture_rect(LabUI.icon("rest"), Rect2(p + Vector2(8, -12 + sin(animation_time) * 2), Vector2(13, 13)), false, Color("4d655a"))
		return
	if person.id == selected_person: draw_arc(p, 12 * size_value, 0, TAU, 24, Color("5b7568"), 1.5)
	draw_circle(p + Vector2(1, 6), 7 * size_value, Color(0.1, 0.15, 0.15, 0.25))
	var step = sin(phase) * 3 if walking and not simulation.paused else 0.0
	draw_line(p + Vector2(-3, 2), p + Vector2(-3, 9 + step) * size_value, Color("48545a"), 3 * size_value)
	draw_line(p + Vector2(3, 2), p + Vector2(3, 9 - step) * size_value, Color("48545a"), 3 * size_value)
	draw_circle(p, (6.5 if look.wide else 5.5) * size_value, Color("e4e7de") if person.role == "researcher" else look.shirt)
	draw_circle(p - Vector2(0, 6) * size_value, 4.2 * size_value, skin)
	if look.style != 4: draw_arc(p - Vector2(0, 7) * size_value, 4 * size_value, PI, TAU, 10, look.hair, 3 if look.style == 1 else 2)
	if look.style in [2, 3]: draw_circle(p + Vector2(4, -6) * size_value, 3 * size_value, look.hair)
	if look.glasses: draw_line(p + Vector2(-3, -5) * size_value, p + Vector2(3, -5) * size_value, Color("36414b"), 1.4)
	if look.beard: draw_arc(p - Vector2(0, 5) * size_value, 3 * size_value, 0, PI, 8, look.hair, 1.5)
	draw_circle(p + Vector2(4, 1), 1.8, Color(simulation.FIELDS[person.specialty].color))
	if person.get("working", false) and not walking:
		var symbol = "rest" if person.task == "rest" else "study" if person.task == "study" else "write" if person.task == "write" else ""
		if symbol != "":
			var offset = sin(animation_time * 1.5 + person.id) * 1.5
			draw_texture_rect(LabUI.icon(symbol), Rect2(p + Vector2(7, -21 + offset), Vector2(12, 12)), false, Color("4d655a"))
	if person.energy < 25: draw_circle(p + Vector2(8, -7), 3, Color("c08472"))

func draw_bed(bed: Dictionary) -> void:
	var p = floor_origin + Vector2(bed.x, bed.y) * tile
	var rect = Rect2(p + Vector2(3, 3), Vector2(tile - 6, tile * 2 - 6))
	draw_style_box(LabUI.box(Color("ede6d3"), Color("8b877c"), 0, 4), rect)
	var blanket = Color("82999b")
	for person in simulation.staff:
		if person.get("bed", -1) == bed.id: blanket = StaffAppearance.of(person).shirt
	draw_rect(Rect2(p + Vector2(5, tile * 0.7), Vector2(tile - 10, tile * 1.1)), blanket)
	draw_style_box(LabUI.box(Color("f6efdd"), Color("c9c1ad"), 0, 3), Rect2(p + Vector2(7, 8), Vector2(tile - 14, tile * 0.45)))
	text_at(p + Vector2(5, tile * 2 - 8), str(int(bed.id)), Color("e6e6d9"), 10)
	if bed.id == selected_id and selected_kind == "bed": draw_rect(Rect2(p, Vector2(tile, tile * 2)), LabUI.GOLD, false, 2)
