class_name LabUI
extends RefCounted
const BG = Color("181b20")
const PANEL = Color("23272d")
const CARD = Color("2b3036")
const LINE = Color("3b4249")
const TEXT = Color("edf0e9")
const MUTED = Color("a0aaa9")
const ACCENT = Color("a6bdae")
const GOLD = Color("d5b577")
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
	result.set_stylebox("hover", "Button", box(Color("3b4448"), ACCENT))
	result.set_stylebox("pressed", "Button", box(Color("46554e"), ACCENT))
	result.set_stylebox("disabled", "Button", box(Color("252a30"), Color("31383e")))
	result.set_color("font_disabled_color", "Button", Color("788480"))
	result.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), ACCENT, 1))
	result.set_stylebox("normal", "LineEdit", box(BG))
	result.set_stylebox("panel", "AcceptDialog", box(PANEL, LINE, 20))
	result.set_stylebox("panel", "PopupMenu", box(PANEL, LINE, 8))
	result.set_stylebox("panel", "TooltipPanel", box(Color("111519"), LINE, 10))
	result.set_color("font_color", "TooltipLabel", TEXT)
	result.set_font_size("font_size", "TooltipLabel", 13)
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
	var result = Button.new()
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
	var frame = PanelContainer.new()
	frame.add_theme_stylebox_override("panel", box(color, border, padding))
	parent.add_child(frame)
	var contents = column()
	frame.add_child(contents)
	return contents
