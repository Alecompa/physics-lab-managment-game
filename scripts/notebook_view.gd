class_name NotebookView
extends PanelContainer
const PAPER = Color("17232b")
const INK = Color("d2e6ec")
const FAINT = Color("8fa7b5")
func _ready() -> void:
	var style = LabUI.box(PAPER, Color("62716c"), 12, 5)
	style.content_margin_left = 50
	add_theme_stylebox_override("panel", style)
	resized.connect(queue_redraw)
func _draw() -> void:
	draw_rect(Rect2(0, 0, 35, size.y), Color("0b161e"))
	for y in range(39, int(size.y) - 5, 24): draw_line(Vector2(43, y), Vector2(size.x - 12, y), Color(0.45, 0.65, 0.7, 0.12), 1)
	draw_line(Vector2(40, 5), Vector2(40, size.y - 5), Color("967c56"), 1)
	for y in range(19, int(size.y) - 7, 28):
		draw_circle(Vector2(22, y), 3, Color("071017"))
		draw_arc(Vector2(14, y), 8, PI * 0.9, TAU + 0.3, 16, Color("74959f"), 2, true)
