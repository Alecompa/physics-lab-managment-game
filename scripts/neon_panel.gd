extends PanelContainer
## A faint glass highlight; decoration never participates in input or layout.
var emblem = ""
var tint = Color("67e6e0")
func _ready() -> void:
	resized.connect(queue_redraw)
func _draw() -> void:
	for i in range(18):
		var alpha = 0.018 * (1.0 - i / 18.0)
		draw_line(Vector2(8, 2 + i), Vector2(size.x - 8, 2 + i), Color(tint, alpha), 1)
	draw_line(Vector2(12, 1), Vector2(size.x - 12, 1), Color(tint, 0.12), 1)
	if emblem != "":
		draw_texture_rect(LabUI.icon(emblem), Rect2(Vector2(size.x - 65, 6), Vector2(58, 58)), false, Color(tint, 0.055))
