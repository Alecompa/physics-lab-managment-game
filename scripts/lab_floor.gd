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
	custom_minimum_size = Vector2(620, 360)
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
	return center(person_positions.get(person.id, Vector2(person.x, person.y))) + Vector2((int(person.id) % 3 - 1) * 8, (int(person.id) % 2) * 3)

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
			var color = Color("b4c0c2") if room in ["optics", "measurements"] else Color("bdbaae") if room == "office" else Color("aebbb8") if room == "common" else Color("8fa8b3")
			if room != "wall":
				var sunlight = maxf(0, 1.0 - minf(y, 13 - y) / 5.0)
				color = color.lerp(Color("e0dfcb"), sunlight * 0.18)
			if room == "wall": color = Color("263d4c")
			elif (x + y) % 2 == 1: color = color.darkened(0.024)
			draw_rect(Rect2(position, Vector2.ONE * tile), color)
			if room != "wall": draw_rect(Rect2(position + Vector2.ONE, Vector2.ONE * (tile - 1)), Color(0.15, 0.25, 0.3, 0.10), false)
			else:
				draw_rect(Rect2(position, Vector2.ONE * tile), Color("304959"))
				if y == 0 or Layout.room(cell + Vector2i.UP) != "wall":
					draw_line(position + Vector2(0, 2), position + Vector2(tile, 2), Color("66818e"), 2)
				if x == 0 or Layout.room(cell + Vector2i.LEFT) != "wall":
					draw_line(position + Vector2(2, 0), position + Vector2(2, tile), Color("536f7e"), 2)
				if x == 19 or Layout.room(cell + Vector2i.RIGHT) != "wall":
					draw_line(position + Vector2(tile - 2, 0), position + Vector2(tile - 2, tile), Color("182f3e"), 3)
				if y < 13 and Layout.room(cell + Vector2i.DOWN) != "wall":
					draw_rect(Rect2(position + Vector2(0, tile - 5), Vector2(tile, 5)), Color("172a36"))
					draw_rect(Rect2(position + Vector2(0, tile), Vector2(tile, tile * 0.15)), Color(0.03, 0.1, 0.15, 0.16))
				if y in [0, 13] and x in [2, 3, 5, 6, 13, 14, 16, 17]:
					draw_rect(Rect2(position + Vector2(1, tile * 0.35), Vector2(tile - 2, tile * 0.25)), Color("83d5ec"))
	# Door frames occupy the walls, while their openings remain walkable.
	for y in [5, 8]:
		for x in [4, 15]:
			var p = floor_origin + Vector2(x, y) * tile
			draw_line(p + Vector2(1, 0), p + Vector2(1, tile), Color("0d202b"), 5)
			draw_line(p, p + Vector2(0, tile), Color("94e9ee"), 2)
			draw_line(p + Vector2(tile, 0), p + Vector2(tile, tile), Color("94e9ee"), 2)
			draw_line(p + Vector2(3, tile * 0.5), p + Vector2(tile - 3, tile * 0.5), Color(0.6, 0.9, 1, 0.2), 1)
			draw_rect(Rect2(p + Vector2(-4, 0), Vector2(8, tile)), Color(0.3, 0.9, 1, 0.07))
	# Wall-mounted details do not occupy or imply additional blocked floor cells.
	for item in [[Vector2(2, 1), "cabinet"], [Vector2(5, 1), "board"], [Vector2(13, 1), "board"], [Vector2(16, 1), "cabinet"]]:
		draw_wall_detail(item[0], item[1])
	for cell in [Vector2(8, 2), Vector2(11, 2), Vector2(8, 11), Vector2(11, 11)]:
		var lamp = center(cell)
		glow(lamp, tile * 0.6, Color("7de5ed"), 0.10)
		draw_style_box(LabUI.box(Color("d5faff"), Color("72a9b8"), 0, 2), Rect2(lamp - Vector2(2, 6), Vector2(4, 12)))
	# Coffee table and seats remain available for less effective bedless rest.
	var coffee = center(Vector2(12, 12))
	draw_rect(Rect2(coffee - Vector2.ONE * tile * 0.3, Vector2.ONE * tile * 0.6), Color("87765d"))
	draw_circle(coffee, tile * 0.12, Color("e4dfd2"))
	for seat in Layout.REST_SEATS:
		var q = center(Vector2(seat))
		draw_circle(q + Vector2(1, 3), tile * 0.23, Color(0.03, 0.09, 0.12, 0.2))
		draw_circle(q, tile * 0.22, Color("355568"))
		draw_arc(q, tile * 0.20, 0, PI, 16, Color("809ba5"), 2, true)
	for bed in simulation.beds: draw_bed(bed)
	for cell in [Vector2(1, 6), Vector2(18, 7), Vector2(18, 12)]:
		var p = center(cell)
		draw_circle(p + Vector2(2, 4), tile * 0.26, Color(0.05, 0.15, 0.15, 0.2))
		draw_circle(p, tile * 0.19, Color("344e58"))
		draw_circle(p, tile * 0.15, Color("697866"))
		for angle in range(7):
			var direction = Vector2.from_angle(angle * TAU / 7)
			var side = direction.orthogonal()
			var leaf = PackedVector2Array([p, p + direction * tile * 0.17 + side * tile * 0.09, p + direction * tile * 0.34, p + direction * tile * 0.17 - side * tile * 0.09])
			draw_colored_polygon(leaf, Color("628f76") if angle % 2 else Color("86aa82"))
			draw_line(p, p + direction * tile * 0.29, Color("b1c69a"), 0.6, true)
	for item in [[Vector2(1, 0), "OPTICS LAB"], [Vector2(12, 0), "MEASUREMENT LAB"], [Vector2(1, 13), "OFFICE"], [Vector2(12, 13), "SLEEPING AREA"]]:
		var label_position = center(item[0]) + Vector2(0, 4)
		var label_width = font.get_string_size(item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_rect(Rect2(label_position - Vector2(4, 12), Vector2(label_width + 8, 16)), Color("263d4c"))
		text_at(label_position, item[1], Color("d4edf5"), 10)

	for desk in simulation.desks: draw_desk(desk)
	for experiment in simulation.experiments: draw_experiment(experiment)
	if build_kind != "" and Layout.inside(hovered):
		var color = LabUI.ACCENT if simulation.can_place(build_kind, hovered) else Color("c97f73")
		var rect = Rect2(floor_origin + Vector2(hovered) * tile, Vector2(Layout.footprint(build_kind)) * tile)
		draw_rect(rect, Color(color, 0.25))
		draw_rect(rect, color, false, 2)
		if build_kind == "desk": draw_circle(center(Vector2(hovered + Vector2i.DOWN)), tile * 0.22, color)
	if build_kind == "" and Layout.inside(hovered):
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

func draw_desk(desk: Dictionary) -> void:
	var p = floor_origin + Vector2(desk.x, desk.y) * tile
	var active = false
	for person in simulation.staff:
		if person.get("working", false) and person.task in ["study", "analyze", "write"] and Vector2(person.x, person.y).distance_to(Vector2(Layout.chair(desk))) < 0.6: active = true
	var unit = tile / 40.0
	draw_set_transform(p, 0, Vector2.ONE * unit)
	draw_style_box(LabUI.box(Color(0, 0.04, 0.07, 0.3), Color(0, 0, 0, 0), 0, 4), Rect2(3, 9, 75, 32))
	for x in [5, 66]: draw_rect(Rect2(x, 25, 7, 12), Color("344954"))
	draw_style_box(LabUI.box(Color("899c9f"), Color("425c68"), 0, 3), Rect2(2, 3, 76, 29))
	draw_line(Vector2(5, 5), Vector2(75, 5), Color("c6d2ce"), 1)
	draw_rect(Rect2(22, 19, 4, 5), Color("233e4c"))
	draw_rect(Rect2(17, 24, 14, 2), Color("3b5360"))
	draw_style_box(LabUI.box(Color("102733"), Color("566e7b"), 0, 2), Rect2(10, 7, 29, 15))
	draw_rect(Rect2(13, 9, 23, 10), Color("245e73") if active else Color("27414f"))
	if active:
		glow(Vector2(24, 15), 22, LabUI.ACCENT, 0.04)
		for line in range(3): draw_line(Vector2(15, 11 + line * 3), Vector2(24 + sin(animation_time + line) * 7, 11 + line * 3), Color("81e8e7"), 1)
	draw_style_box(LabUI.box(Color("c0ccc8"), Color("687e82"), 0, 1), Rect2(13, 25, 24, 4))
	for i in range(7): draw_line(Vector2(15 + i * 3, 25), Vector2(15 + i * 3, 28), Color("7f939b"), 0.5)
	draw_rect(Rect2(49, 10, 16, 19), Color("e2dfce"))
	for i in range(4): draw_line(Vector2(52, 14 + i * 3), Vector2(61, 14 + i * 3), Color("9eaeb0"), 0.6)
	draw_circle(Vector2(69, 12), 3, Color("dce9e5"))
	draw_circle(Vector2(69, 12), 1.8, Color("695344"))
	if desk.get("level", 1) > 1:
		draw_rect(Rect2(41, 8, 5, 19), Color("2a424e"))
		for i in range(desk.level - 1): draw_circle(Vector2(43.5, 11 + i * 5), 1, LabUI.ACCENT)
	draw_set_transform(Vector2.ZERO)
	var chair = center(Vector2(Layout.chair(desk)))
	draw_circle(chair + Vector2(1, 3), tile * 0.22, Color(0.03, 0.09, 0.12, 0.25))
	draw_style_box(LabUI.box(Color("304b5c"), Color("1b303e"), 0, 4), Rect2(chair - Vector2.ONE * tile * 0.21, Vector2.ONE * tile * 0.42))
	draw_line(chair + Vector2(-tile * 0.18, tile * 0.16), chair + Vector2(tile * 0.18, tile * 0.16), Color("7896a4"), 2)
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
	draw_style_box(LabUI.box(Color("435e6b"), Color("182f3d"), 0, 4), Rect2(3, 4, 74, 65))
	draw_line(Vector2(6, 6), Vector2(73, 6), Color("93a8ae"), 1)
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
				draw_style_box(LabUI.box(Color("758b94"), Color("314856"), 0, 3), Rect2(x, 11, 6, 46))
				draw_rect(Rect2(x + 2, 16, 2, 34), color.darkened(0.4))
			if active:
				var y = 20 + fmod(animation_time * 13, 28)
				draw_line(Vector2(10, y), Vector2(70, y - 5), Color(color, 0.18), 6, true)
				draw_line(Vector2(10, y), Vector2(70, y - 5), color, 1.5, true)
		"quantum":
			draw_circle(Vector2(40, 33), 27, Color("142b3a"))
			for radius in [25, 19, 12]:
				draw_circle(Vector2(40, 33), radius, Color("728995"), false, 3, true)
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
	var blanket = Color("699caa")
	for person in simulation.staff:
		if person.get("bed", -1) == bed.id: blanket = StaffAppearance.of(person).shirt
	draw_set_transform(p, 0, Vector2.ONE * tile / 40.0)
	draw_style_box(LabUI.box(Color(0.04, 0.1, 0.13, 0.28), Color(0, 0, 0, 0), 0, 5), Rect2(5, 7, 33, 73))
	draw_style_box(LabUI.box(Color("546e79"), Color("2e4757"), 0, 5), Rect2(3, 2, 34, 76))
	draw_style_box(LabUI.box(Color("d8e2dd"), Color("9babac"), 0, 4), Rect2(5, 5, 30, 69))
	draw_style_box(LabUI.box(blanket.darkened(0.1), blanket.darkened(0.3), 0, 3), Rect2(7, 29, 26, 42))
	draw_rect(Rect2(7, 29, 26, 5), blanket.lightened(0.25))
	draw_line(Vector2(10, 36), Vector2(10, 66), Color(blanket.lightened(0.3), 0.4), 1)
	draw_style_box(LabUI.box(Color("f1eee2"), Color("becbc6"), 0, 4), Rect2(9, 9, 22, 15))
	draw_line(Vector2(12, 12), Vector2(28, 12), Color("ffffff"), 1)
	draw_set_transform(Vector2.ZERO)
	if bed.id == selected_id and selected_kind == "bed": draw_selection(Rect2(p, Vector2(tile, tile * 2)))
