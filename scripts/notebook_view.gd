class_name NotebookView
extends PanelContainer
const PAPER = Color("e5ddc8")
const INK = Color("39464a")
const FAINT = Color("6d766f")
func _ready() -> void:
	var style = LabUI.box(PAPER, Color("9d8f73"), 12, 5)
	style.content_margin_left = 50
	add_theme_stylebox_override("panel", style)
	resized.connect(queue_redraw)
func _draw() -> void:
	for y in range(39, int(size.y) - 5, 24): draw_line(Vector2(43, y), Vector2(size.x - 12, y), Color(0.45, 0.55, 0.58, 0.23), 1)
	draw_line(Vector2(40, 5), Vector2(40, size.y - 5), Color("b69588"), 1)
	for y in range(19, int(size.y) - 7, 28):
		draw_circle(Vector2(22, y), 3, Color("b5a78d"))
		draw_arc(Vector2(14, y), 8, PI * 0.9, TAU + 0.3, 16, Color("6e756f"), 2, true)
