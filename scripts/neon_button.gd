extends Button
## Animate paint only: containers retain fixed hit boxes throughout interaction.
var glow_color = Color("67e6e0")
var hover_amount = 0.0
var press_amount = 0.0
var hover_tween: Tween
var press_tween: Tween

func _ready() -> void:
	var tree = get_tree()
	pressed.connect(func(): tree.call_group("lab_audio", "play_effect", "click"))
	mouse_entered.connect(func(): _hover(1.0))
	mouse_exited.connect(func(): _hover(0.0))
	button_down.connect(func(): _press(1.0))
	button_up.connect(func(): _press(0.0))

func _hover(value: float) -> void:
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_method(func(v: float): hover_amount = v; queue_redraw(), hover_amount, value, 0.16)

func _press(value: float) -> void:
	if press_tween: press_tween.kill()
	press_tween = create_tween()
	press_tween.tween_method(func(v: float): press_amount = v; queue_redraw(), press_amount, value, 0.12)

func _draw() -> void:
	if disabled: return
	var color = glow_color
	if hover_amount > 0.01:
		var rim = StyleBoxFlat.new()
		rim.bg_color = Color(color, 0.035 * hover_amount)
		rim.border_color = Color(color, hover_amount * 0.7)
		rim.set_border_width_all(1)
		rim.set_corner_radius_all(8)
		rim.shadow_color = Color(color, hover_amount * 0.12)
		rim.shadow_size = 5
		draw_style_box(rim, Rect2(Vector2.ONE, size - Vector2.ONE * 2))
		draw_line(Vector2(10, size.y - 2), Vector2(size.x - 10, size.y - 2), Color(color, hover_amount * 0.6), 1)
	if press_amount > 0.01:
		draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color(color, press_amount * 0.12))
