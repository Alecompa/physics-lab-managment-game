extends Control
signal boundary_changed(block: String, hours: int)
var person: Dictionary = {}
var current_hour = 8
var dragging = -1
const COLORS = [Color("7785ac"), Color("70c9b7"), Color("68aed1"), Color("dfb466")]
func _ready() -> void:
	custom_minimum_size = Vector2(300, 76)
	mouse_default_cursor_shape = Control.CURSOR_HSIZE
	tooltip_text = "Drag a boundary to change rest, collection or analysis hours. Gold is remaining activity time. The marker shows the current lab hour."
func boundaries() -> Array:
	return [person.rest, person.rest + person.acquire, person.rest + person.acquire + person.analyze]
func _gui_input(event: InputEvent) -> void:
	if person.is_empty(): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var distances = []
			for value in boundaries(): distances.append(absf(event.position.x - value * size.x / 24))
			dragging = distances.find(distances.min())
		else: dragging = -1
	if event is InputEventMouseMotion and dragging >= 0:
		var hour = clampi(roundi(event.position.x / size.x * 24), 0, 24)
		var offset = 0 if dragging == 0 else person.rest if dragging == 1 else person.rest + person.acquire
		boundary_changed.emit(["rest", "acquire", "analyze"][dragging], maxi(0, hour - offset))
		queue_redraw()
func _draw() -> void:
	if person.is_empty(): return
	var limits = boundaries()
	for hour in range(24):
		var segment = 0 if hour < limits[0] else 1 if hour < limits[1] else 2 if hour < limits[2] else 3
		draw_style_box(LabUI.box(COLORS[segment], COLORS[segment], 0, 2), Rect2(hour * size.x / 24 + 1, 21, size.x / 24 - 2, 27))
	var font = ThemeDB.fallback_font
	for hour in [0, 6, 12, 18, 24]:
		draw_string(font, Vector2(clampf(hour * size.x / 24 - 5, 0, size.x - 16), 13), "%02d" % hour, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LabUI.MUTED)
	for boundary in limits:
		var x = clampf(boundary * size.x / 24, 2, size.x - 2)
		draw_line(Vector2(x, 19), Vector2(x, 51), LabUI.TEXT, 2)
	var local_hour = posmod(current_hour - LabCatalog.PERSONALITIES[person.personality].shift, 24)
	var x = (local_hour + 0.5) * size.x / 24
	draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 58), Vector2(x + 4, 58), Vector2(x, 51)]), LabUI.TEXT)
	var names = ["Rest", "Collect", "Analyze", "Activity"]
	for i in range(4):
		draw_circle(Vector2(i * size.x / 4 + 3, 69), 3, COLORS[i])
		draw_string(font, Vector2(i * size.x / 4 + 11, 73), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, LabUI.MUTED)
