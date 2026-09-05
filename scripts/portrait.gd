extends Control
var person: Dictionary = {}
func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO: custom_minimum_size = Vector2(64, 76)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	if person.is_empty(): return
	var seed_value = absi((person.name + person.specialty).hash())
	var skin = [Color("d7b8a0"), Color("b78c6b"), Color("8b6550"), Color("e0c9b5")][seed_value % 4]
	var hair = [Color("343232"), Color("654d3b"), Color("8d8477"), Color("b6a078")][seed_value % 4]
	var center = size * Vector2(0.5, 0.40)
	var scale_value = size.x / 64.0
	draw_style_box(LabUI.box(Color("3f494a"), LabUI.LINE, 0, 7), Rect2(Vector2.ZERO, size))
	draw_circle(center + Vector2(0, 31) * scale_value, 25 * scale_value, Color("c5cbc5"))
	draw_rect(Rect2(center + Vector2(-6, 12) * scale_value, Vector2(12, 15) * scale_value), skin.darkened(0.08))
	draw_circle(center + Vector2(0, -1) * scale_value, 18 * scale_value, hair)
	draw_circle(center + Vector2(0, 3) * scale_value, 14 * scale_value, skin)
	draw_arc(center + Vector2(0, -3) * scale_value, 15 * scale_value, PI, TAU, 20, hair, 8 * scale_value)
	if seed_value % 3 == 0:
		draw_rect(Rect2(center + Vector2(-13, 0) * scale_value, Vector2(10, 7) * scale_value), Color("343c40"), false, 1.5)
		draw_rect(Rect2(center + Vector2(3, 0) * scale_value, Vector2(10, 7) * scale_value), Color("343c40"), false, 1.5)
		draw_line(center + Vector2(-3, 3) * scale_value, center + Vector2(3, 3) * scale_value, Color("343c40"), 1)
	for x in [-6, 6]: draw_circle(center + Vector2(x, 3) * scale_value, 1.2 * scale_value, Color("303538"))
	draw_line(center + Vector2(-4, 11) * scale_value, center + Vector2(4, 11) * scale_value, skin.darkened(0.3), 1.5)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-12, 23) * scale_value, center + Vector2(0, 32) * scale_value, center + Vector2(12, 23) * scale_value]), Color(LabCatalog.FIELDS[person.specialty].color))
