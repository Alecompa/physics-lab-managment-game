class_name LabUI
extends RefCounted
const BG = Color("182e36")
const PANEL = Color("27424d")
const CARD = Color("345764")
const LINE = Color("648d94")
const TEXT = Color("fff8e9")
const MUTED = Color("b6cfcf")
const ACCENT = Color("9ee5c4")
const GOLD = Color("ffce80")
const NeonButton = preload("res://scripts/neon_button.gd")
static var icons: Dictionary = {}

static func icon(key: String) -> Texture2D:
	var replacements = {"back": "back", "arrow": "next", "play": "play", "close": "close"}
	if key in ["bed", "desk"]:
		if not icons.has(key): icons[key] = load("res://assets/kenney/furniture/" + key + ".png")
		return icons[key]
	if not icons.has(key): icons[key] = load("res://assets/kenney/ui/" + replacements[key] + ".png") if replacements.has(key) else load("res://assets/icons/" + key + ".svg")
	return icons[key]

static func box(color: Color = PANEL, border: Color = LINE, padding: int = 12, radius: int = 8) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border
	result.set_border_width_all(1)
	result.set_corner_radius_all(radius)
	result.border_blend = true
	result.shadow_color = Color(0, 0.015, 0.025, 0.2)
	result.shadow_size = 3
	result.shadow_offset = Vector2(0, 2)
	result.content_margin_left = padding
	result.content_margin_right = padding
	result.content_margin_top = padding
	result.content_margin_bottom = padding
	return result

static func skin(color: Color = CARD, padding: int = 12, asset: String = "button") -> StyleBoxTexture:
	var result = StyleBoxTexture.new()
	result.texture = load("res://assets/kenney/ui/" + asset + ".png")
	result.modulate_color = color
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		result.set_texture_margin(side, (14 if side == SIDE_BOTTOM else 10) if asset == "frame" else 8)
		result.set_content_margin(side, padding)
	if asset == "slider":
		var strip = AtlasTexture.new()
		strip.atlas = result.texture
		strip.region = Rect2(12, 4, 72, 8)
		result.texture = strip
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]: result.set_texture_margin(side, 1)
	return result

static func install_cursors() -> void:
	if DisplayServer.get_name() == "headless": return
	for entry in [[Input.CURSOR_ARROW, "arrow", Vector2(5, 4)], [Input.CURSOR_POINTING_HAND, "hand", Vector2(12, 3)], [Input.CURSOR_MOVE, "pan", Vector2(16, 16)], [Input.CURSOR_DRAG, "drag", Vector2(16, 16)], [Input.CURSOR_CROSS, "crosshair", Vector2(16, 16)]]:
		var original = load("res://assets/kenney/cursors/" + entry[1] + ".png").get_image()
		original.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(original), entry[0], entry[2])

static func theme() -> Theme:
	var result = Theme.new()
	result.default_font_size = 14
	for type in ["Label", "Button", "OptionButton", "LineEdit", "SpinBox"]: result.set_color("font_color", type, TEXT)
	result.set_stylebox("normal", "Button", skin(Color("547d89")))
	result.set_stylebox("hover", "Button", skin(Color("6caa9c")))
	result.set_stylebox("pressed", "Button", skin(Color("527f78"), 12, "pressed"))
	result.set_stylebox("disabled", "Button", skin(Color("364e58")))
	result.set_color("font_disabled_color", "Button", Color("a0b4b8"))
	result.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), ACCENT, 1))
	for control in ["OptionButton"]:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			result.set_stylebox(state, control, result.get_stylebox(state, "Button"))
		result.set_color("font_disabled_color", control, Color("a0b4b8"))
	result.set_stylebox("normal", "LineEdit", skin(Color("304956"), 12, "panel"))
	result.set_stylebox("focus", "LineEdit", skin(Color("42626b"), 12, "panel"))
	result.set_stylebox("hover", "PopupMenu", box(CARD, ACCENT, 8))
	result.set_color("font_color", "PopupMenu", TEXT)
	result.set_color("font_hover_color", "PopupMenu", TEXT)
	for control in ["HScrollBar", "VScrollBar"]:
		result.set_stylebox("scroll", control, box(BG, BG, 3, 3))
		result.set_stylebox("grabber", control, box(LINE, LINE, 3, 3))
		result.set_stylebox("grabber_highlight", control, box(ACCENT.darkened(0.4), ACCENT, 3, 3))
		result.set_stylebox("grabber_pressed", control, box(ACCENT, ACCENT, 3, 3))
	result.set_stylebox("panel", "AcceptDialog", skin(PANEL, 20, "frame"))
	result.set_stylebox("panel", "PopupMenu", skin(PANEL, 10, "frame"))
	result.set_stylebox("panel", "TooltipPanel", skin(Color("25414b"), 12, "frame"))
	result.set_color("font_color", "TooltipLabel", TEXT)
	result.set_font_size("font_size", "TooltipLabel", 13)
	result.set_stylebox("slider", "HSlider", box(BG, LINE, 2, 3))
	result.set_stylebox("grabber_area", "HSlider", box(ACCENT.darkened(0.4), ACCENT.darkened(0.4), 2, 3))
	result.set_stylebox("grabber_area_highlight", "HSlider", box(ACCENT, ACCENT, 2, 3))
	result.set_icon("grabber", "HSlider", load("res://assets/kenney/ui/handle.png"))
	result.set_icon("grabber_highlight", "HSlider", load("res://assets/kenney/ui/handle.png"))
	result.set_stylebox("background", "ProgressBar", skin(Color("567780"), 0, "slider"))
	result.set_stylebox("fill", "ProgressBar", skin(ACCENT, 0, "slider"))
	result.set_icon("arrow", "OptionButton", load("res://assets/kenney/ui/arrow.png"))
	result.set_icon("checked", "CheckBox", load("res://assets/kenney/ui/check.png"))
	result.set_icon("unchecked", "CheckBox", load("res://assets/kenney/ui/unchecked.png"))
	return result

static func label(text: String, size: int = 14, color: Color = TEXT, wrap: bool = false) -> Label:
	var result = Label.new()
	result.text = text
	if size >= 20: result.add_theme_font_override("font", load("res://assets/kenney/ui/heading.ttf"))
	result.mouse_filter = Control.MOUSE_FILTER_PASS
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	if wrap:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result

static func button(text: String, action: Callable, symbol: String = "", hint: String = "") -> Button:
	var result = NeonButton.new()
	result.custom_minimum_size.y = 40
	result.text = text
	result.focus_mode = Control.FOCUS_NONE
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.tooltip_text = hint
	result.pressed.connect(action)
	if symbol != "":
		result.icon = icon(symbol)
		result.add_theme_constant_override("icon_max_width", 19)
	return result

static func image(key: String, color: Color = TEXT, dimension: int = 24) -> TextureRect:
	var result = TextureRect.new()
	result.texture = icon(key)
	result.self_modulate = color
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.custom_minimum_size = Vector2(dimension, dimension)
	return result

static func row(gap: int = 8) -> HBoxContainer:
	var result = HBoxContainer.new()
	result.add_theme_constant_override("separation", gap)
	return result

static func column(gap: int = 8) -> VBoxContainer:
	var result = VBoxContainer.new()
	result.add_theme_constant_override("separation", gap)
	return result

static func space(parent: Node) -> void:
	var control = Control.new()
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(control)

static func panel(parent: Node, color: Color = PANEL, border: Color = LINE, padding: int = 12) -> VBoxContainer:
	var frame = load("res://scripts/neon_panel.gd").new()
	frame.tint = border.lightened(0.2)
	frame.add_theme_stylebox_override("panel", skin(color.lightened(0.07), padding, "frame"))
	parent.add_child(frame)
	var contents = column()
	frame.add_child(contents)
	return contents

static func reveal(control: Control) -> void:
	control.modulate.a = 0.0
	control.create_tween().tween_property(control, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE)
