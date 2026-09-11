extends Control
## Low-contrast architectural grid and orbital motif, shared by menu and HUD.
var phase = 0.0
var tick = 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _process(delta: float) -> void:
	phase += delta * 0.08
	tick += delta
	if tick > 0.05:
		tick = 0.0
		queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("182e36"))
	var c = size * Vector2(0.3, 0.45)
	for i in range(16, 0, -1):
		draw_circle(c, i * 42.0, Color(0.06, 0.25, 0.3, 0.025))
	for x in range(24, int(size.x), 48):
		for y in range(24, int(size.y), 48):
			draw_circle(Vector2(x, y), 0.8, Color(0.3, 0.8, 0.85, 0.11))
	for i in range(3):
		var radius = 280.0 + i * 100
		draw_arc(c, radius, phase + i, phase + i + PI * 1.5, 100, Color(0.2, 0.7, 0.75, 0.07), 1, true)
		var p = c + Vector2.from_angle(phase + i) * radius
		draw_circle(p, 2.5, Color(0.3, 0.9, 0.9, 0.35))
