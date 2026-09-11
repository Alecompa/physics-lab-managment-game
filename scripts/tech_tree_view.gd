extends Control
var simulation: LabSimulation
var controls: Dictionary = {}
const POSITIONS = {
	"campus_planning": Vector2(250, 815), "precision": Vector2(10, 45), "module_slots": Vector2(10, 235), "mixed_mode": Vector2(10, 425), "advanced_instruments": Vector2(10, 615),
	"nuclear_lab": Vector2(250, 235), "quantum_lab": Vector2(250, 615),
	"desk_systems": Vector2(540, 45), "compute": Vector2(540, 235), "journal_club": Vector2(780, 235), "review_support": Vector2(780, 425), "lounge": Vector2(540, 425)
}
func _ready() -> void:
	custom_minimum_size = Vector2(1020, 1000)
	for key in simulation.UPGRADES:
		var spec = simulation.UPGRADES[key]
		var body = LabUI.panel(self, LabUI.CARD, LabUI.LINE, 10)
		var panel = body.get_parent()
		panel.position = POSITIONS[key]
		panel.custom_minimum_size = Vector2(220, 163)
		panel.size.x = 220
		body.add_child(LabUI.label(spec.name, 14, LabUI.TEXT, true))
		panel.tooltip_text = spec.description
		var summaries = {"precision": "Level 2 instruments · +50% capacity", "module_slots": "Two module slots per instrument", "mixed_mode": "Secondary data channels", "advanced_instruments": "Level 3 instruments · 2× capacity", "nuclear_lab": "Build particle detectors", "quantum_lab": "Build quantum rigs", "desk_systems": "Level 2 desks · +15% productivity", "compute": "+25% analysis · level 3 desks", "journal_club": "Refresh ideas for 12 study", "review_support": "+8 acceptance points", "lounge": "Beds restore 10 energy/hour", "campus_planning": "Purchase additional lab wings"}
		body.add_child(LabUI.label(summaries[key], 11, LabUI.MUTED, true))
		var action = LabUI.button("", func(): simulation.unlock_upgrade(key); refresh(), "upgrade")
		action.add_theme_stylebox_override("normal", LabUI.skin(Color("547d89"), 7))
		action.add_theme_font_size_override("font_size", 11)
		body.add_child(action)
		controls[key] = {"panel": panel, "button": action}
	simulation.updated.connect(refresh)
	refresh()
func refresh() -> void:
	for key in controls:
		var spec = simulation.UPGRADES[key]
		var owned = key in simulation.unlocked
		var blocked = spec.requires != "" and spec.requires not in simulation.unlocked or key == "campus_planning" and simulation.program_level < 3
		var button = controls[key].button
		button.disabled = owned or blocked or simulation.prestige < spec.cost
		button.tooltip_text = "Requires milestone 3 and Advanced instrumentation" if key == "campus_planning" and blocked else "Requires " + simulation.UPGRADES[spec.requires].name if blocked else ""
		button.text = "Unlocked" if owned else "Locked / %d impact" % spec.cost if blocked else "%d impact" % spec.cost
		controls[key].panel.add_theme_stylebox_override("panel", LabUI.skin(Color("447869") if owned else LabUI.CARD.lightened(0.07), 10, "frame"))
	queue_redraw()
func _draw() -> void:
	var font = ThemeDB.fallback_font
	draw_string(font, Vector2(12, 22), "INSTRUMENTATION", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, LabUI.ACCENT)
	draw_string(font, Vector2(542, 22), "COMPUTATION & RESEARCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, LabUI.ACCENT)
	for key in POSITIONS:
		var parent = simulation.UPGRADES[key].requires
		if parent == "": continue
		var start = POSITIONS[parent] + Vector2(110, 166)
		var end = POSITIONS[key] + Vector2(110, -3)
		var mid = start.y + 12
		draw_polyline(PackedVector2Array([start, Vector2(start.x, mid), Vector2(end.x, mid), end]), LabUI.ACCENT if parent in simulation.unlocked else LabUI.LINE, 2, true)
		draw_colored_polygon(PackedVector2Array([end + Vector2(-4, -5), end + Vector2(4, -5), end + Vector2(0, 1)]), LabUI.ACCENT if parent in simulation.unlocked else LabUI.LINE)
