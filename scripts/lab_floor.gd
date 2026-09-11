class_name LabFloor
extends Control
signal cell_clicked(cell: Vector2i)
signal placement_cancelled
signal person_clicked(id: int)
var simulation: LabSimulation
var build_kind = ""
var moving_id = -1
var zoom = 1.0
var pan = Vector2.ZERO
var dragging_map = false
var placement_reason = ""
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
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(620, 360)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	font = ThemeDB.fallback_font
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	mouse_exited.connect(func(): hovered = Vector2i(-1, -1); queue_redraw())

func reset_positions() -> void:
	person_positions.clear()
	trails.clear()
	last_stamp = -1
	reset_camera()

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
	return center(person_positions.get(person.id, Vector2(person.x, person.y))) + Vector2((int(person.id) % 3 - 1) * 8, (int(person.id) % 2) * 3)

func cell_at(point: Vector2) -> Vector2i:
	return Vector2i(((point - floor_origin) / tile).floor())

func reset_camera() -> void:
	zoom = 1.0
	pan = Vector2.ZERO
	queue_redraw()

func update_camera() -> void:
	var dimensions = Vector2(Layout.dimensions(simulation.expansion_level))
	tile = minf((size.x - 22) / dimensions.x, (size.y - 35) / dimensions.y) * zoom
	var map_size = dimensions * tile
	pan = pan.clamp(-map_size * 0.5, map_size * 0.5)
	floor_origin = (size - map_size) * 0.5 + pan

func zoom_at(factor: float, anchor: Vector2) -> void:
	if simulation == null: return
	update_camera()
	var world = (anchor - floor_origin) / tile
	zoom = clampf(zoom * factor, 0.7, 3.5)
	update_camera()
	pan += anchor - (floor_origin + world * tile)
	update_camera()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		dragging_map = event.pressed
		mouse_default_cursor_shape = Control.CURSOR_DRAG if dragging_map else Control.CURSOR_ARROW
		grab_focus()
		accept_event()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		zoom_at(1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15, event.position)
		accept_event()
		return
	if event is InputEventPanGesture:
		pan -= event.delta * 24.0
		update_camera()
		queue_redraw()
		accept_event()
		return
	if event is InputEventMagnifyGesture:
		zoom_at(event.factor, event.position)
		accept_event()
		return
	if event is InputEventKey and event.pressed:
		var direction = {KEY_LEFT: Vector2.RIGHT, KEY_RIGHT: Vector2.LEFT, KEY_UP: Vector2.DOWN, KEY_DOWN: Vector2.UP}.get(event.keycode, Vector2.ZERO)
		if direction != Vector2.ZERO:
			pan += direction * 40
			update_camera()
			queue_redraw()
			accept_event()
			return
	if event is InputEventMouseMotion:
		if dragging_map:
			pan += event.relative
			update_camera()
			queue_redraw()
			accept_event()
			return
		hovered = cell_at(event.position)
		mouse_default_cursor_shape = Control.CURSOR_CROSS if build_kind != "" else Control.CURSOR_ARROW
		tooltip_text = ""
		if build_kind != "":
			placement_reason = simulation.relocation_error(build_kind, moving_id, hovered) if moving_id >= 0 else simulation.placement_error(build_kind, hovered)
			tooltip_text = placement_reason
		else:
			var object = simulation.object_at(hovered)
			if not object.is_empty():
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				tooltip_text = "%s #%d" % [object.kind.capitalize(), object.id] if object.kind in ["bed", "desk"] else "%s / L%d / %.0f%% condition" % [simulation.EQUIPMENT[object.kind].name, object.level, object.condition]
			for person in simulation.staff:
				if person_screen_position(person).distance_to(event.position) < 15:
					mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
					tooltip_text = "%s\n%s\nEnergy %.0f%%" % [person.name, person.status, person.energy]
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT: placement_cancelled.emit()
		if event.button_index == MOUSE_BUTTON_LEFT:
			grab_focus()
			if build_kind == "":
				for person in simulation.staff:
					if person_screen_position(person).distance_to(event.position) < 14:
						selected_person = person.id
						person_clicked.emit(person.id)
						return
			var cell = cell_at(event.position)
			if Layout.inside(cell, simulation.expansion_level): cell_clicked.emit(cell)

func text_at(point: Vector2, text: String, color: Color, text_size: int = 12) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size, color)

func _draw() -> void:
	if simulation == null or font == null: return
	update_camera()
	var dimensions = Layout.dimensions(simulation.expansion_level)
	var map_rect = Rect2(floor_origin, Vector2(dimensions) * tile)
	draw_style_box(LabUI.box(Color("0f1215"), Color("304959"), 1, 6), map_rect.grow(3))
	for x in range(dimensions.x):
		for y in range(dimensions.y):
			var cell = Vector2i(x, y)
			var position = floor_origin + Vector2(cell) * tile
			var room = Layout.room(cell, simulation.expansion_level, simulation.layout_style)
			var color = Color("c8ddd7") if room in ["optics", "measurements"] else Color("e4cba3") if room == "office" else Color("e2dfc8")
			if room == "corridor": color = Color("81aaa8")
			if room == "wall": color = Color("f0e3c3")
			elif (x + y) % 2: color = color.darkened(0.025)
			draw_rect(Rect2(position, Vector2.ONE * tile), color)
			draw_rect(Rect2(position, Vector2.ONE * tile), Color(0.15, 0.25, 0.3, 0.07), false)
			if room == "office":
				draw_line(position + Vector2(0, tile * 0.5), position + Vector2(tile, tile * 0.5), Color(0.35, 0.26, 0.16, 0.12), 1)
			if room == "wall":
				draw_rect(Rect2(position + Vector2(0, tile * 0.65), Vector2(tile, tile * 0.35)), Color("688c90"))
				draw_line(position, position + Vector2(tile, 0), Color("fff2d7"), 2)
				if y == 0 and x % 4 in [1, 2]: draw_rect(Rect2(position + Vector2(1, tile * 0.3), Vector2(tile - 2, tile * 0.25)), Color("83d5ec"))
	if simulation.layout_style == "rooms":
		# Rugs sit below furniture and do not obstruct circulation.
		var rug = Rect2(floor_origin + Vector2(12.65, 11.55) * tile, Vector2(5.25, 1.85) * tile)
		draw_style_box(LabUI.box(Color("83958a"), Color("c9c6a9"), 0, 3), rug)
		for row in range(5):
			draw_line(rug.position + Vector2(tile * 0.12, tile * (0.2 + row * 0.32)), rug.position + Vector2(rug.size.x - tile * 0.12, tile * (0.2 + row * 0.32)), Color(0.85, 0.84, 0.72, 0.18), 1)
		# Mounted on walls, these details never claim a walkable cell.
		for cell in [Vector2(13, 0.65), Vector2(2, 8.65)]: draw_wall_detail(cell, "board")
		draw_wall_detail(Vector2(17, 0.65), "monitor")
		for cell in Layout.decorations(simulation.layout_style): draw_decoration(cell, Layout.decorations(simulation.layout_style)[cell])
		# Hall runner and threshold strips make the doors legible at Fit zoom.
		draw_rect(Rect2(floor_origin + Vector2(1.2, 7.2) * tile, Vector2(25.6, 0.6) * tile), Color("597b80"))
		for cell in [Vector2(8, 6), Vector2(20, 6), Vector2(4, 8), Vector2(15, 8), Vector2(22, 8)]:
			var p = floor_origin + cell * tile
			draw_line(p + Vector2(0, tile * 0.5), p + Vector2(tile * 2, tile * 0.5), Color("c8b998"), 2)
	for seat in Layout.REST_SEATS:
		draw_furniture("armchair", Rect2(center(Vector2(seat)) - Vector2.ONE * tile * 0.44, Vector2.ONE * tile * 0.88))
	draw_furniture("table", Rect2(center(Vector2(12, 12)) - Vector2.ONE * tile * 0.46, Vector2.ONE * tile * 0.92))
	for bed in simulation.beds: draw_bed(bed)

	for desk in simulation.desks: draw_desk(desk)
	for experiment in simulation.experiments: draw_experiment(experiment)
	if build_kind != "" and Layout.inside(hovered, simulation.expansion_level):
		var color = LabUI.ACCENT if placement_reason == "" else Color("c97f73")
		var rect = Rect2(floor_origin + Vector2(hovered) * tile, Vector2(Layout.footprint(build_kind)) * tile)
		draw_rect(rect, Color(color, 0.25))
		draw_rect(rect, color, false, 2)
		if build_kind == "desk": draw_circle(center(Vector2(hovered + Vector2i.DOWN)), tile * 0.22, color)
	if build_kind == "" and Layout.inside(hovered, simulation.expansion_level):
		var object = simulation.object_at(hovered)
		if not object.is_empty(): draw_selection(Rect2(floor_origin + Vector2(object.x, object.y) * tile, Vector2(Layout.footprint(object.kind)) * tile))
	for person in simulation.staff: draw_person(person)

func glow(p: Vector2, radius: float, color: Color, opacity: float = 0.12) -> void:
	for ring in range(5, 0, -1):
		draw_circle(p, radius * ring / 5.0, Color(color, opacity * (1.0 - ring / 6.0)))

func draw_wall_detail(cell: Vector2, kind: String) -> void:
	var p = floor_origin + cell * tile + Vector2(0, -tile * 0.15)
	var r = Rect2(p, Vector2(tile * 1.7, tile * 0.45))
	draw_style_box(LabUI.box(Color("172c39"), Color("496773"), 0, 2), r)
	if kind == "board":
		draw_rect(r.grow(-3), Color("cfdbd6"))
		var points = PackedVector2Array()
		for i in range(18): points.append(p + Vector2(5 + i * (r.size.x - 10) / 17, r.size.y * (0.5 + sin(i * 0.9) * 0.22)))
		draw_polyline(points, Color("578a94"), 1, true)
	else:
		for i in range(3):
			var q = p + Vector2(4 + i * tile * 0.54, 3)
			draw_rect(Rect2(q, Vector2(tile * 0.45, tile * 0.29)), Color("7b939d"))
			draw_rect(Rect2(q + Vector2(2, 2), Vector2(tile * 0.22, tile * 0.15)), Color("173445"))
			draw_circle(q + Vector2(tile * 0.35, tile * 0.17), 1.4, LabUI.ACCENT)

var furniture_textures: Dictionary = {}

func furniture_texture(key: String) -> Texture2D:
	if not furniture_textures.has(key): furniture_textures[key] = load("res://assets/kenney/furniture/" + key + ".png")
	return furniture_textures[key]

func draw_furniture(key: String, rect: Rect2) -> void:
	var texture = furniture_texture(key)
	var dimensions = texture.get_size()
	var scale_value = minf(rect.size.x / dimensions.x, rect.size.y / dimensions.y)
	var extent = dimensions * scale_value
	var origin = rect.position + (rect.size - extent) * 0.5
	# All baked sprites fit their existing footprint; collision geometry is unchanged.
	draw_set_transform(rect.get_center() + Vector2(0, rect.size.y * 0.32), 0, Vector2(1, 0.32))
	draw_circle(Vector2.ZERO, rect.size.x * 0.42, Color(0.14, 0.23, 0.24, 0.18))
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(texture, Rect2(origin, extent), false)

func draw_decoration(cell: Vector2i, kind: String) -> void:
	draw_furniture(kind, Rect2(floor_origin + Vector2(cell) * tile + Vector2.ONE * tile * 0.03, Vector2.ONE * tile * 0.94))

func draw_desk(desk: Dictionary) -> void:
	var p = floor_origin + Vector2(desk.x, desk.y) * tile
	draw_furniture("desk", Rect2(p, Vector2(tile * 2, tile * 1.12)))
	var chair = center(Vector2(Layout.chair(desk)))
	draw_furniture("chair", Rect2(chair - Vector2.ONE * tile * 0.4, Vector2.ONE * tile * 0.8))
	var active = simulation.staff.any(func(person): return person.get("working", false) and person.task in ["study", "analyze", "write", "proposal", "supervise"] and Vector2(person.x, person.y).distance_to(Vector2(Layout.chair(desk))) < 0.6)
	if active: glow(p + Vector2(tile * 0.8, tile * 0.22), tile * 0.28, LabUI.ACCENT, 0.12)
	if desk.get("level", 1) > 1:
		for i in range(desk.level - 1): draw_circle(p + Vector2(tile * (1.65 + i * 0.12), tile * 0.85), tile * 0.04, LabUI.GOLD)
	if desk.id == selected_id and selected_kind == "desk": draw_selection(Rect2(p, Vector2(tile * 2, tile)))

func draw_experiment(experiment: Dictionary) -> void:
	var p = floor_origin + Vector2(experiment.x, experiment.y) * tile
	var color = Color(simulation.EQUIPMENT[experiment.kind].color)
	var active = false
	for person in simulation.staff:
		if person.target_id == experiment.id and person.get("working", false) and person.task == "acquire": active = true
	draw_set_transform(p, 0, Vector2.ONE * tile / 40.0)
	draw_style_box(LabUI.box(Color(0.01, 0.05, 0.08, 0.35), Color(0, 0, 0, 0), 0, 5), Rect2(5, 12, 72, 66))
	for q in [Vector2(9, 62), Vector2(64, 62)]: draw_rect(Rect2(q, Vector2(6, 12)), Color("142a35"))
	draw_style_box(LabUI.box(Color("96b9b2"), Color("456e70"), 0, 4), Rect2(3, 4, 74, 65))
	draw_line(Vector2(6, 6), Vector2(73, 6), Color("f6ebcf"), 1)
	draw_line(Vector2(5, 65), Vector2(75, 65), Color("1e3644"), 3)
	match experiment.kind:
		"optics":
			for x in range(9):
				for y in range(7): draw_circle(Vector2(9 + x * 7.5, 10 + y * 8), 0.9, Color("263e4b"))
			var beam = PackedVector2Array([Vector2(14, 48), Vector2(33, 23), Vector2(52, 47), Vector2(66, 22)])
			for q in beam:
				draw_circle(q + Vector2(0, 3), 6, Color("1b2d38"))
				draw_circle(q, 4, Color("94abb0"))
				draw_rect(Rect2(q - Vector2(2, 6), Vector2(4, 11)), Color("263e49"))
				draw_line(q - Vector2(1, 5), q + Vector2(1, 3), Color("a8e6de"), 1)
			draw_polyline(beam, Color(color, 0.10 if not active else 0.20), 6, true)
			draw_polyline(beam, Color(color, 0.45 if not active else 0.95), 1.3, true)
			if active:
				var t = fmod(animation_time * 1.5, 3.0)
				var q = beam[int(t)].lerp(beam[int(t) + 1], fmod(t, 1.0))
				glow(q, 8, color, 0.15)
				draw_circle(q, 1.5, Color.WHITE)
		"vacuum":
			for x in [12, 59]:
				draw_style_box(LabUI.box(Color("738d97"), Color("2c4452"), 0, 3), Rect2(x, 16, 10, 37))
				draw_line(Vector2(x + 3, 19), Vector2(x + 3, 48), Color("a7bec5"), 2)
			draw_circle(Vector2(40, 33), 23, Color("283f4d"))
			draw_circle(Vector2(40, 31), 21, Color("a4b5b8"))
			draw_circle(Vector2(40, 31), 16, Color("506d7c"))
			draw_circle(Vector2(40, 31), 12, Color("152f40"))
			for i in range(8): draw_circle(Vector2(40, 31) + Vector2.from_angle(i * TAU / 8) * 18, 1.5, Color("374d59"))
			draw_arc(Vector2(40, 31), 9, animation_time if active else 0, (animation_time if active else 0) + PI * 1.5, 30, color, 2, true)
			if active: glow(Vector2(40, 31), 14, color, 0.08)
		"detector":
			draw_style_box(LabUI.box(Color("1b3444"), Color("6e8287"), 0, 6), Rect2(11, 14, 58, 42))
			for i in range(6):
				var x = 16 + i * 8
				draw_style_box(LabUI.box(Color("d9c8a2"), Color("314856"), 0, 3), Rect2(x, 11, 6, 46))
				draw_rect(Rect2(x + 2, 16, 2, 34), color.darkened(0.4))
			if active:
				var y = 20 + fmod(animation_time * 13, 28)
				draw_line(Vector2(10, y), Vector2(70, y - 5), Color(color, 0.18), 6, true)
				draw_line(Vector2(10, y), Vector2(70, y - 5), color, 1.5, true)
		"quantum":
			draw_circle(Vector2(40, 33), 27, Color("142b3a"))
			for radius in [25, 19, 12]:
				draw_circle(Vector2(40, 33), radius, Color("d8c49b"), false, 3, true)
				draw_arc(Vector2(40, 33), radius, 0.3, 2.3, 30, color, 1, true)
			for i in range(4):
				var q = Vector2(40, 33) + Vector2.from_angle(i * PI / 2) * 24
				draw_circle(q, 4, Color("bdd0d5"))
				draw_circle(q, 2, Color("4b5975"))
			glow(Vector2(40, 33), 11, color, 0.06 if not active else 0.18)
			draw_circle(Vector2(40, 33), 4 + (sin(animation_time * 2) if active else 0), color)
	# Status strip, readout and module attachments remain visible at normal zoom.
	draw_style_box(LabUI.box(Color("102735"), Color("55717d"), 0, 1), Rect2(9, 56, 22, 8))
	for i in range(4): draw_line(Vector2(12 + i * 4, 62), Vector2(12 + i * 4, 60 - (sin(animation_time * 2 + i) * 2 if active else 0)), color, 1)
	draw_circle(Vector2(68, 60), 2.5, color if active else Color("657d87"))
	if active: glow(Vector2(68, 60), 7, color, 0.10)
	for i in range(experiment.level): draw_rect(Rect2(36 + i * 5, 59, 3, 2), color)
	if experiment.condition < 55: draw_texture_rect(LabUI.icon("warning"), Rect2(5, 6, 14, 14), false, LabUI.GOLD)
	for index in range(experiment.get("modules", []).size()):
		var key = experiment.modules[index]
		var q = Vector2(index * 21 + 4, 66)
		draw_style_box(LabUI.box(Color("193847"), LabUI.ACCENT, 0, 2), Rect2(q, Vector2(18, 12)))
		draw_texture_rect(LabUI.icon("clock" if key == "accelerator" else key), Rect2(q + Vector2(3, 1), Vector2(10, 10)), false, LabUI.ACCENT if key == "accelerator" else Color(simulation.FIELDS[key].color))
	draw_set_transform(Vector2.ZERO)
	if experiment.id == selected_id and selected_kind not in ["desk", "bed"]: draw_selection(Rect2(p, Vector2.ONE * tile * 2))

func draw_selection(rect: Rect2) -> void:
	draw_rect(rect, Color(LabUI.ACCENT, 0.06))
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var direction = (rect.get_center() - corner).sign()
		draw_line(corner, corner + Vector2(direction.x * 10, 0), LabUI.ACCENT, 2)
		draw_line(corner, corner + Vector2(0, direction.y * 10), LabUI.ACCENT, 2)

func draw_person(person: Dictionary) -> void:
	var p = person_screen_position(person)
	var walking = trails.has(person.id) and not trails[person.id].is_empty()
	var phase = animation_time * 5 + person.id
	var size_value = clampf(tile / 34, 0.85, 1.3)
	var look = StaffAppearance.of(person)
	var skin = look.skin
	var sleeping = person.task == "rest" and person.get("working", false) and person.get("bed", -1) != -1 and not walking
	if sleeping:
		draw_circle(p, 4.5 * size_value, skin)
		if look.style != 4: draw_arc(p - Vector2(0, 1), 4.5 * size_value, PI, TAU, 10, look.hair, 2)
		draw_texture_rect(LabUI.icon("rest"), Rect2(p + Vector2(8, -12 + sin(animation_time) * 2), Vector2(13, 13)), false, Color("4d655a"))
		return
	if person.id == selected_person: draw_arc(p, 12 * size_value, 0, TAU, 24, LabUI.ACCENT, 1.5)
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
	draw_furniture("bed", Rect2(p, Vector2(tile, tile * 2)))
	if bed.id == selected_id and selected_kind == "bed": draw_selection(Rect2(p, Vector2(tile, tile * 2)))
