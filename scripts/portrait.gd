extends Control
var person: Dictionary = {}
func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO: custom_minimum_size = Vector2(64, 76)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	if person.is_empty(): return
	var look = StaffAppearance.of(person)
	var s = size.x / 64.0
	var c = size * Vector2(0.5, 0.4)
	draw_style_box(LabUI.box(look.shirt.darkened(0.48), LabUI.LINE, 0, 7), Rect2(Vector2.ZERO, size))
	var width = 27 if look.wide else 23
	draw_circle(c + Vector2(0, 34) * s, width * s, look.shirt)
	if person.role == "researcher":
		for side in [-1, 1]: draw_colored_polygon(PackedVector2Array([c + Vector2(side * 6, 20) * s, c + Vector2(side * width, 31) * s, c + Vector2(side * width, 60) * s, c + Vector2(side * 8, 60) * s]), Color("d6dcd5"))
	if look.style == 2: draw_style_box(LabUI.box(look.hair, look.hair, 0, 6), Rect2(c + Vector2(-18, -10) * s, Vector2(36, 44) * s))
	if look.style == 3: draw_circle(c + Vector2(14, -10) * s, 9 * s, look.hair)
	draw_rect(Rect2(c + Vector2(-5, 12) * s, Vector2(10, 14) * s), look.skin.darkened(0.1))
	var face_width = 15 if look.wide else 13
	draw_circle(c + Vector2(0, 2) * s, face_width * s, look.skin)
	if look.style != 4:
		draw_arc(c + Vector2(0, -3) * s, 14 * s, PI, TAU, 20, look.hair, (8 if look.style == 0 else 5) * s)
		if look.style == 1:
			for i in range(6): draw_circle(c + Vector2(-13 + i * 5, -10 - (i % 2) * 3) * s, 5 * s, look.hair)
	if look.beard: draw_arc(c + Vector2(0, 4) * s, 10 * s, 0, PI, 16, look.hair, 4 * s)
	for x in [-6, 6]:
		draw_circle(c + Vector2(x, 2) * s, 1.3 * s, Color("303538"))
		if look.glasses: draw_circle(c + Vector2(x, 2) * s, 5 * s, Color("343c40"), false, 1.2 * s, true)
	if look.glasses: draw_line(c + Vector2(-1, 2) * s, c + Vector2(1, 2) * s, Color("343c40"), 1.2 * s)
	draw_line(c + Vector2(-3, 11) * s, c + Vector2(4, 11) * s, look.skin.darkened(0.35), 1.4 * s)
	draw_rect(Rect2(c + Vector2(10, 32) * s, Vector2(7, 10) * s), Color(LabCatalog.FIELDS[person.specialty].color))
