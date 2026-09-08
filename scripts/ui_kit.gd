class_name LabUI
extends RefCounted
const BG = Color("080f17")
const PANEL = Color("111f2a")
const CARD = Color("182c38")
const LINE = Color("304f60")
const TEXT = Color("eaf4fa")
const MUTED = Color("93aebf")
const ACCENT = Color("67e6e0")
const GOLD = Color("f2c16e")
const NeonButton = preload("res://scripts/neon_button.gd")
static var icons: Dictionary = {}

static func icon(key: String) -> Texture2D:
	if not icons.has(key): icons[key] = load("res://assets/icons/" + key + ".svg")
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

static func theme() -> Theme:
	var result = Theme.new()
	result.default_font_size = 14
	for type in ["Label", "Button", "OptionButton", "LineEdit", "SpinBox"]: result.set_color("font_color", type, TEXT)
	result.set_stylebox("normal", "Button", box(CARD))
	result.set_stylebox("hover", "Button", box(Color("234650"), ACCENT))
	result.set_stylebox("pressed", "Button", box(Color("245660"), ACCENT))
	result.set_stylebox("disabled", "Button", box(Color("14232e"), Color("2a414e")))
	result.set_color("font_disabled_color", "Button", Color("728998"))
	result.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), ACCENT, 1))
	for control in ["OptionButton"]:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			result.set_stylebox(state, control, result.get_stylebox(state, "Button"))
		result.set_color("font_disabled_color", control, Color("728998"))
	result.set_stylebox("normal", "LineEdit", box(BG))
	result.set_stylebox("focus", "LineEdit", box(BG, ACCENT))
	result.set_stylebox("hover", "PopupMenu", box(CARD, ACCENT, 8))
	result.set_color("font_color", "PopupMenu", TEXT)
	result.set_color("font_hover_color", "PopupMenu", TEXT)
	for control in ["HScrollBar", "VScrollBar"]:
		result.set_stylebox("scroll", control, box(BG, BG, 3, 3))
		result.set_stylebox("grabber", control, box(LINE, LINE, 3, 3))
		result.set_stylebox("grabber_highlight", control, box(ACCENT.darkened(0.4), ACCENT, 3, 3))
		result.set_stylebox("grabber_pressed", control, box(ACCENT, ACCENT, 3, 3))
	result.set_stylebox("panel", "AcceptDialog", box(PANEL, LINE, 20))
	result.set_stylebox("panel", "PopupMenu", box(PANEL, LINE, 8))
	result.set_stylebox("panel", "TooltipPanel", box(Color("09151e"), LINE, 10))
	result.set_color("font_color", "TooltipLabel", TEXT)
	result.set_font_size("font_size", "TooltipLabel", 13)
	result.set_stylebox("slider", "HSlider", box(BG, LINE, 2, 3))
	result.set_stylebox("grabber_area", "HSlider", box(ACCENT.darkened(0.4), ACCENT.darkened(0.4), 2, 3))
	result.set_stylebox("grabber_area_highlight", "HSlider", box(ACCENT, ACCENT, 2, 3))
	result.set_icon("grabber", "HSlider", load("res://assets/icons/slider_handle.svg"))
	result.set_icon("grabber_highlight", "HSlider", load("res://assets/icons/slider_handle.svg"))
	result.set_stylebox("background", "ProgressBar", box(BG, BG, 0, 3))
	result.set_stylebox("fill", "ProgressBar", box(ACCENT, ACCENT, 0, 3))
	return result

static func label(text: String, size: int = 14, color: Color = TEXT, wrap: bool = false) -> Label:
	var result = Label.new()
	result.text = text
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
	frame.add_theme_stylebox_override("panel", box(color, border, padding))
	parent.add_child(frame)
	var contents = column()
	frame.add_child(contents)
	return contents

static func reveal(control: Control) -> void:
	control.modulate.a = 0.0
	control.create_tween().tween_property(control, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE)
