extends Control
const Simulation = preload("res://scripts/simulation.gd")
const FloorView = preload("res://scripts/lab_floor.gd")
const Portrait = preload("res://scripts/portrait.gd")
const Schedule = preload("res://scripts/schedule_view.gd")
const Chart = preload("res://scripts/resource_chart.gd")
const Notebook = preload("res://scripts/notebook_view.gd")
const TechTree = preload("res://scripts/tech_tree_view.gd")
const U = preload("res://scripts/ui_kit.gd")
var sim: LabSimulation
var test_mode = false
var session_active = false
var game_ui: Control
var floor_view: LabFloor
var menu_layer: Control
var modal_layer: Control
var modal_box: VBoxContainer
var modal_return: Callable
var sidebar: VBoxContainer
var sidebar_scroll: ScrollContainer
var side_panel: Control
var page = "Build"
var selected_id = -1
var selected_kind = ""
var selected_person = -1
var build_kind = ""
var refreshers: Array[Callable] = []
var data_labels: Dictionary = {}
var tabs: Dictionary = {}
var clock_label: Label
var cash_label: Label
var impact_label: Label
var state_label: Label
var pause_button: Button
var hint_label: Label
var event_label: RichTextLabel
var headline_label: Label
var chart: Control
var paper_commitments: Dictionary = {}
var deferred_rebuild = false
var modal_title: Label
var menu_mode = "main"
var modal_refreshers: Array[Callable] = []
var archive_field = "any"
var archive_tier = "any"

func _ready() -> void:
	theme = U.theme()
	sim = Simulation.new()
	add_child(sim)
	sim.new_lab()
	sim.autosave_enabled = not test_mode
	_build_game()
	sim.updated.connect(_refresh)
	sim.announcement.connect(func(_text): _refresh())
	sim.ideas_changed.connect(_queue_rebuild)
	sim.paper_resolved.connect(_publication_result)
	sim.idea_discovered.connect(_discovery)
	get_tree().auto_accept_quit = false
	_show_main_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if sim != null and session_active and not test_mode:
			if not sim.save_lab(false): _info("Save failed", "The lab could not be saved. Use Save to choose a slot before quitting."); return
		get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE:
		if is_instance_valid(modal_layer): _close_modal(); _refresh(); return
		if is_instance_valid(menu_layer):
			if menu_mode == "pause": _resume_from_menu()
		elif build_kind != "": _cancel_build()
		elif session_active: _show_pause_menu()
		return
	if is_instance_valid(modal_layer) and event.keycode == KEY_SPACE and not get_viewport().gui_get_focus_owner() is LineEdit:
			_toggle_pause()
			return
	if is_instance_valid(menu_layer) or is_instance_valid(modal_layer) or not session_active: return
	match event.keycode:
		KEY_SPACE: _toggle_pause()
		KEY_1: sim.speed = 1; _refresh()
		KEY_2: sim.speed = 2; _refresh()
		KEY_3: sim.speed = 4; _refresh()
		KEY_H: _help()
		KEY_S:
			if event.ctrl_pressed or event.meta_pressed: _save_menu()

func _build_game() -> void:
	var background = ColorRect.new()
	background.color = U.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 18)
	add_child(margin)
	game_ui = margin
	var root = U.column(12)
	margin.add_child(root)
	var header = U.row(12)
	root.add_child(header)
	header.add_child(U.image("nuclear", U.ACCENT, 31))
	header.add_child(U.label("FIELDWORK", 23))
	U.space(header)
	header.add_child(U.image("coin", U.ACCENT, 21))
	cash_label = U.label("", 19)
	cash_label.custom_minimum_size.x = 108
	cash_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(cash_label)
	header.add_child(U.image("legendary", U.GOLD, 19))
	impact_label = U.label("", 17, U.GOLD)
	impact_label.custom_minimum_size.x = 45
	impact_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(impact_label)
	U.space(header)
	clock_label = U.label("", 15)
	clock_label.custom_minimum_size.x = 165
	clock_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(clock_label)
	pause_button = U.button("Resume", _toggle_pause, "play", "Pause or resume / Space")
	pause_button.custom_minimum_size.x = 112
	header.add_child(pause_button)
	for speed in [1, 2, 4]:
		var control = U.button("%dx" % speed, func(): sim.speed = speed; _refresh())
		control.set_meta("speed", speed)
		header.add_child(control)
	header.add_child(U.button("", _program_window, "program", "Research program and publication archive"))
	header.add_child(U.button("", _development, "tree", "Development tree"))
	header.add_child(U.button("", _statistics, "chart", "Resource history"))
	header.add_child(U.button("", _help, "info", "How to play / H"))
	header.add_child(U.button("", _show_pause_menu, "menu", "Pause menu / Esc"))
	var resources = U.row(10)
	root.add_child(resources)
	for field in Simulation.FIELDS:
		var card = U.panel(resources, U.PANEL, U.LINE, 10)
		card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var line = U.row(12)
		card.add_child(line)
		line.add_child(U.image(field, Color(Simulation.FIELDS[field].color), 30))
		var text = U.column(1)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		text.add_child(U.label(Simulation.FIELDS[field].name.to_upper(), 10, U.MUTED))
		var counts = U.label("", 17)
		text.add_child(counts)
		card.get_parent().tooltip_text = "Raw data needs analysis. Analyzed evidence can be committed to a paper in this field."
		data_labels[field] = counts
	var content = U.row(12)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)
	var left = U.column(10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(left)
	var floor_card = U.panel(left, U.PANEL, U.LINE, 10)
	floor_card.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	var floor_head = U.row()
	floor_card.add_child(floor_head)
	headline_label = U.label("The laboratory", 17)
	headline_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	headline_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	floor_head.add_child(headline_label)
	U.space(floor_head)
	state_label = U.label("PAUSED", 10, U.MUTED)
	floor_head.add_child(state_label)
	floor_head.add_child(U.button("", func(): side_panel.visible = not side_panel.visible, "people", "Show or hide management to expand the map"))
	floor_view = FloorView.new()
	floor_view.simulation = sim
	floor_view.cell_clicked.connect(_floor_clicked)
	floor_view.person_clicked.connect(func(id): selected_person = id; _set_page("People"))
	floor_view.placement_cancelled.connect(_cancel_build)
	floor_card.add_child(floor_view)
	hint_label = U.label("Click a person or workstation to inspect it.", 11, U.MUTED)
	floor_card.add_child(hint_label)
	var notebook_frame = Notebook.new()
	left.add_child(notebook_frame)
	var notebook = U.column(6)
	notebook_frame.add_child(notebook)
	var notebook_head = U.row()
	notebook.add_child(notebook_head)
	notebook_head.add_child(U.image("study", Notebook.INK, 15))
	notebook_head.add_child(U.label("LAB NOTEBOOK", 10, Notebook.INK))
	U.space(notebook_head)
	notebook_head.add_child(U.button("History", _notebook_history, "load"))
	event_label = RichTextLabel.new()
	event_label.bbcode_enabled = false
	event_label.add_theme_color_override("default_color", Notebook.INK)
	event_label.custom_minimum_size.y = 55
	event_label.add_theme_font_size_override("normal_font_size", 12)
	event_label.scroll_active = false
	notebook.add_child(event_label)
	var panel = U.panel(content, U.PANEL, U.LINE, 10)
	side_panel = panel.get_parent()
	side_panel.custom_minimum_size.x = 370
	var tab_row = U.row(4)
	panel.add_child(tab_row)
	for item in [["Build", "build"], ["People", "people"], ["Papers", "paper"]]:
		var tab = U.button(item[0], func(): _set_page(item[0]), item[1])
		tab.add_theme_font_size_override("font_size", 11)
		tab.add_theme_constant_override("icon_max_width", 15)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_row.add_child(tab)
		tabs[item[0]] = tab
	sidebar_scroll = ScrollContainer.new()
	sidebar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sidebar_scroll)
	sidebar = U.column(10)
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar_scroll.add_child(sidebar)
	_rebuild_sidebar()

func _money(value: float) -> String:
	return "$%s" % _commas(roundi(value))
func _commas(value: int) -> String:
	var digits = str(value)
	var result = ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0: result += ","
		result += digits[index]
	return result

func _set_page(value: String) -> void:
	page = value
	side_panel.visible = true
	sidebar_scroll.scroll_vertical = 0
	_rebuild_sidebar()

func _rebuild_sidebar() -> void:
	refreshers.clear()
	for child in sidebar.get_children(): sidebar.remove_child(child); child.queue_free()
	match page:
		"Build": _build_page()
		"People": _people_page()
		"Papers": _papers_page()
	for key in tabs: tabs[key].add_theme_stylebox_override("normal", U.box(Color("46534d") if page == key else U.CARD, U.ACCENT if page == key else U.LINE, 8))
	_refresh()

func _build_page() -> void:
	var object = sim.bed_by_id(selected_id) if selected_kind == "bed" else sim.desk_by_id(selected_id) if selected_kind == "desk" else sim.experiment_by_id(selected_id)
	if not object.is_empty():
		var inspector = U.panel(sidebar, U.CARD)
		if object.kind == "bed":
			inspector.add_child(U.label("Bed #%d" % object.id, 18))
			var owner = "Unassigned"
			for person in sim.staff:
				if person.bed == object.id: owner = person.name
			inspector.add_child(U.label(owner, 14, U.ACCENT))
			inspector.add_child(U.label("Full recovery for its assigned owner. Set ownership in People.", 12, U.MUTED, true))
			inspector.add_child(U.button("Remove / +$157", func(): _confirm("Remove bed?", "Its owner will rest at 40% efficiency until assigned another bed.", func(): sim.remove_bed(object.id); selected_id = -1; _rebuild_sidebar()), "close"))
		elif object.kind == "desk":
			inspector.add_child(U.label("Desk #%d / Level %d" % [object.id, object.get("level", 1)], 18))
			var status = U.label("", 12, U.MUTED, true)
			inspector.add_child(status)
			var upgrade = U.button("", func(): sim.upgrade_desk(object.id); _rebuild_sidebar(), "upgrade")
			inspector.add_child(upgrade)
			refreshers.append(func():
				var level = object.get("level", 1)
				status.text = "+%d%% analysis, writing and study.\n" % ((level - 1) * 15)
				if level < 3: status.text += "Next level: +%d%% productivity / %s" % [level * 15, _money(level * 700)]
				var reason = sim.desk_upgrade_reason(object)
				upgrade.text = reason if reason != "" else "Upgrade / " + _money(level * 700)
				upgrade.disabled = reason != ""
			)
			inspector.add_child(U.button("Remove / +$210", func(): _confirm("Remove desk?", "Assigned people will look for a shared desk.", func(): sim.remove_desk(object.id); selected_id = -1; _rebuild_sidebar()), "close"))
		else:
			inspector.add_child(U.label(sim.EQUIPMENT[object.kind].name, 18))
			var status = U.label("", 12, U.MUTED, true)
			inspector.add_child(status)
			var next = U.label("", 12, U.ACCENT, true)
			inspector.add_child(next)
			var upgrade = U.button("", func(): sim.upgrade_experiment(object.id); _rebuild_sidebar(), "upgrade")
			inspector.add_child(upgrade)
			var service = U.button("Service / $250", func(): sim.service_experiment(object.id), "build")
			inspector.add_child(service)
			refreshers.append(func():
				status.text = "Level %d / %.0f%% condition\nCapacity: %.2f base data/hour\n%s" % [object.level, object.condition, sim.capacity_for(object) / 24, _mix_text(object)]
				if object.level < 3:
					var upgraded = object.duplicate(true)
					upgraded.level += 1
					upgraded.condition = 100
					next.text = "Next level: %.2f → %.2f base data/hour\nUpkeep: %s → %s/day\nCondition restored to 100%%\n%s" % [sim.capacity_for(object) / 24, sim.capacity_for(upgraded) / 24, _money(sim.EQUIPMENT[object.kind].upkeep * (1 + 0.25 * (object.level - 1))), _money(sim.EQUIPMENT[object.kind].upkeep * (1 + 0.25 * object.level)), _mix_text(upgraded)]
				else: next.text = "Maximum instrument level"
				var reason = sim.upgrade_block_reason(object)
				upgrade.text = reason if reason != "" else "Upgrade / " + _money(sim.upgrade_cost(object))
				upgrade.disabled = reason != ""
				service.disabled = object.condition >= 99.9 or sim.funds < 250
			)
			inspector.add_child(U.label("MODULES / %d OF 2" % object.get("modules", []).size(), 11, U.MUTED))
			for key in object.get("modules", []):
				inspector.add_child(U.label(sim.Catalog.MODULES[key].name, 13, U.ACCENT))
				inspector.add_child(U.label(sim.Catalog.MODULES[key].description, 11, U.MUTED, true))
				inspector.add_child(U.button("Remove / recover 35%", func(): sim.remove_module(object.id, key); _rebuild_sidebar(), "close"))
			inspector.add_child(U.button("Install module", func(): _module_window(object.id), "plus"))
			inspector.add_child(U.button("Decommission", func(): _confirm("Decommission experiment?", "Recover 35% of the instrument's base purchase price. Installed modules are lost; remove them first to recover their value.", func(): sim.remove_experiment(object.id); selected_id = -1; _rebuild_sidebar()), "close"))
	var heading = U.row()
	sidebar.add_child(heading)
	heading.add_child(U.label("PLACE IN THE LAB", 10, U.MUTED))
	U.space(heading)
	heading.add_child(U.button("", func(): _info("Building", "Experiments occupy 2×2 tiles in either upper laboratory. Desks occupy 2×1 office tiles and need a free chair below. Beds occupy 1×2 tiles along the sleeping area's upper wall, with access at their foot. Routes must stay clear."), "info"))
	for kind in ["bed", "desk", "optics", "vacuum", "detector", "quantum"]:
		var spec = {"name": "Bed", "cost": 450, "field": "", "description": "An individually assigned bed. Full recovery for its owner."} if kind == "bed" else {"name": "Research desk", "cost": 600, "field": "", "description": "Analysis, writing and study. One person can use it at a time."} if kind == "desk" else sim.EQUIPMENT[kind]
		var card = U.panel(sidebar, U.CARD)
		var line = U.row(10)
		card.add_child(line)
		line.add_child(U.image(kind if kind in ["bed", "desk"] else spec.field, U.TEXT if kind in ["bed", "desk"] else Color(sim.FIELDS[spec.field].color), 28))
		var title = U.column(2)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(title)
		title.add_child(U.label(spec.name, 15))
		title.add_child(U.label(_money(spec.cost) + (" / 1×2" if kind == "bed" else " / 2×1" if kind == "desk" else " / 2×2"), 12, U.MUTED))
		var choose = U.button("", func(): build_kind = kind; floor_view.build_kind = kind; _refresh(), "plus", spec.description)
		line.add_child(choose)
		card.get_parent().tooltip_text = spec.description
		refreshers.append(func(): choose.disabled = sim.funds < spec.cost or kind not in ["desk", "bed"] and not sim.equipment_unlocked(kind); choose.icon = U.icon("check" if build_kind == kind else "plus"))
	if build_kind != "": sidebar.add_child(U.button("Cancel placement", _cancel_build, "close"))

func _mix_text(experiment: Dictionary) -> String:
	var pieces = PackedStringArray()
	for field in sim.output_mix(experiment): pieces.append("%.2f %s" % [sim.output_mix(experiment)[field], sim.FIELDS[field].name])
	return "Per base data: " + " + ".join(pieces)

func _module_window(id: int) -> void:
	var content = _open_modal("Instrument modules", 750)
	var list = _scroll_body(content, 690, 490)
	for key in sim.Catalog.MODULES:
		var spec = sim.Catalog.MODULES[key]
		var card = U.panel(list, U.CARD)
		card.add_child(U.label(spec.name + " / " + _money(spec.cost), 16))
		card.add_child(U.label(spec.description, 13, U.MUTED, true))
		var action = U.button("Install", func(): sim.install_module(id, key); _rebuild_sidebar(); _module_window(id), "plus")
		card.add_child(action)
		modal_refreshers.append(func():
			var reason = sim.module_reason(id, key)
			action.text = reason if reason != "" else "Install / " + _money(spec.cost)
			action.disabled = reason != ""
		)
	_refresh()

func _portrait(person: Dictionary, dimension: int = 64) -> Control:
	var portrait = Portrait.new()
	portrait.person = person
	portrait.custom_minimum_size = Vector2(dimension, dimension * 1.18)
	return portrait

func _people_page() -> void:
	var head = U.row()
	sidebar.add_child(head)
	head.add_child(U.label("TEAM / %d OF 18" % sim.staff.size(), 10, U.MUTED))
	U.space(head)
	head.add_child(U.button("Recruit", _recruitment, "plus"))
	var person = {}
	for member in sim.staff:
		if member.id == selected_person: person = member
	if person.is_empty():
		for member in sim.staff:
			var card = U.panel(sidebar, U.CARD)
			var line = U.row(10)
			card.add_child(line)
			line.add_child(_portrait(member, 48))
			var info = U.column(3)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(info)
			info.add_child(U.label(member.name, 16))
			info.add_child(U.label(sim.ROLES[member.role].name, 11, U.MUTED))
			var state = U.label("", 11, U.ACCENT, true)
			info.add_child(state)
			line.add_child(U.button("", func(): selected_person = member.id; floor_view.selected_person = member.id; _rebuild_sidebar(), "arrow", "Routine and assignments"))
			refreshers.append(func(): state.text = member.status)
		return
	sidebar.add_child(U.button("All staff", func(): selected_person = -1; _rebuild_sidebar(), "back"))
	var identity = U.row(12)
	sidebar.add_child(identity)
	identity.add_child(_portrait(person, 76))
	var bio = U.column(4)
	bio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(bio)
	bio.add_child(U.label(person.name, 20))
	bio.add_child(U.label(sim.ROLES[person.role].name, 12, U.MUTED))
	var field = U.row(6)
	bio.add_child(field)
	field.add_child(U.image(person.specialty, Color(sim.FIELDS[person.specialty].color), 18))
	field.add_child(U.label(sim.FIELDS[person.specialty].name, 12))
	var traits = U.label(sim.Catalog.TRAITS[person.trait].name + " / " + sim.Catalog.PERSONALITIES[person.personality].name, 11, U.MUTED, true)
	traits.tooltip_text = sim.Catalog.TRAITS[person.trait].description + "\n" + sim.Catalog.PERSONALITIES[person.personality].description + "\nSpecialty: +25% relevant work"
	bio.add_child(traits)
	var status = U.label("", 12, U.ACCENT, true)
	sidebar.add_child(status)
	var energy = ProgressBar.new()
	energy.show_percentage = false
	energy.custom_minimum_size.y = 7
	energy.tooltip_text = "An assigned reachable bed restores full energy. Bedless rest is 40% as effective."
	sidebar.add_child(energy)
	var routine = U.panel(sidebar, U.CARD)
	var routine_head = U.row()
	routine.add_child(routine_head)
	routine_head.add_child(U.label("DAILY ROUTINE", 10, U.MUTED))
	U.space(routine_head)
	routine_head.add_child(U.button("", func(): _info("Daily routine", "Drag the three white boundaries or change the hours below. The blocks are Rest, Collection, Analysis, then Activity. The total is always 24 hours. Night owls shift this entire routine eight hours later. Gold hours run the Activity you choose."), "info"))
	var timeline = Schedule.new()
	timeline.person = person
	timeline.boundary_changed.connect(func(block, hours): sim.set_schedule(person.id, block, hours))
	routine.add_child(timeline)
	var hours_row = U.row(6)
	routine.add_child(hours_row)
	for block in ["rest", "acquire", "analyze"]:
		var group = U.column(2)
		hours_row.add_child(group)
		group.add_child(U.label({"rest": "Rest", "acquire": "Collect", "analyze": "Analyze"}[block], 10, U.MUTED))
		var hours = SpinBox.new()
		hours.max_value = 24
		hours.value = person[block]
		hours.custom_minimum_size.x = 88
		hours.set_meta("block", block)
		hours.value_changed.connect(func(value): sim.set_schedule(person.id, block, int(value)))
		group.add_child(hours)
		refreshers.append(func(): hours.set_value_no_signal(person[block]))
	var remaining = U.label("", 12, U.GOLD)
	routine.add_child(remaining)
	_choice(sidebar, "Activity", {"auto": "Auto: write or study", "write": "Write", "study": "Study", "maintain": "Maintain"}, person.duty, func(value): sim.set_assignment(person.id, "duty", value))
	var fields = {"any": "Any / specialty first"}
	for key in sim.FIELDS: fields[key] = sim.FIELDS[key].name
	_choice(sidebar, "Data focus", fields, person.focus, func(value): sim.set_assignment(person.id, "focus", value))
	var stations = {-1: "Nearest matching experiment"}
	for station in sim.experiments: stations[int(station.id)] = sim.EQUIPMENT[station.kind].name + " #%d" % station.id
	_choice(sidebar, "Experiment", stations, int(person.experiment), func(value): sim.set_assignment(person.id, "experiment", value))
	var desks = {-1: "Any free desk"}
	for desk in sim.desks: desks[int(desk.id)] = "Desk #%d" % desk.id
	_choice(sidebar, "Desk", desks, int(person.desk), func(value): sim.set_assignment(person.id, "desk", value))
	var beds = {-1: "No bed / 40% recovery"}
	for bed in sim.beds:
		if sim.bed_owner(bed.id) in [-1, int(person.id)]: beds[int(bed.id)] = "Bed #%d" % bed.id
	_choice(sidebar, "Bed", beds, int(person.bed), func(value): sim.set_assignment(person.id, "bed", value))
	if person.bed == -1: sidebar.add_child(U.label("No assigned bed. Rest restores only 40% energy.", 12, U.GOLD, true))
	var budget = U.row()
	sidebar.add_child(budget)
	budget.add_child(U.label(_money(sim.ROLES[person.role].salary) + "/day", 11, U.MUTED))
	U.space(budget)
	budget.add_child(U.button("Release", func(): _confirm("Release " + person.name + "?", "Their salary and contribution will be removed.", func(): sim.dismiss(person.id); selected_person = -1; _rebuild_sidebar()), "close"))
	refreshers.append(func():
		status.text = person.status + " / %.0f%% energy" % person.energy
		energy.value = person.energy
		timeline.current_hour = sim.hour
		timeline.queue_redraw()
		remaining.text = "%dh activity / day" % sim.activity_hours(person)
	)

func _choice(parent: Node, caption: String, options: Dictionary, selected: Variant, action: Callable) -> void:
	var line = U.row(8)
	parent.add_child(line)
	var text = U.label(caption, 11, U.MUTED)
	text.custom_minimum_size.x = 80
	line.add_child(text)
	var control = OptionButton.new()
	control.fit_to_longest_item = false
	control.custom_minimum_size.x = 190
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for key in options:
		control.add_item(options[key])
		control.set_item_metadata(control.item_count - 1, key)
		if selected == key: control.select(control.item_count - 1)
	control.item_selected.connect(func(index): action.call(control.get_item_metadata(index)))
	line.add_child(control)

func _papers_page() -> void:
	var writing = U.panel(sidebar, U.CARD)
	var line = U.row()
	writing.add_child(line)
	line.add_child(U.image("write", U.GOLD, 18))
	var availability = U.label("", 12, U.GOLD, true)
	line.add_child(availability)
	U.space(line)
	line.add_child(U.button("Fix", func(): selected_person = -1; _set_page("People"), "people", "Change activity hours or assign a desk"))
	refreshers.append(func(): var value = sim.writing_availability(); availability.text = value.summary; availability.tooltip_text = value.detail)
	if not sim.active_paper.is_empty():
		var paper = sim.active_paper
		var active = U.panel(sidebar, Color("343833"))
		active.add_child(U.label(paper.title, 15, U.TEXT, true))
		var progress = ProgressBar.new()
		progress.custom_minimum_size.y = 7
		progress.show_percentage = false
		active.add_child(progress)
		var status = U.label("", 12, U.MUTED, true)
		active.add_child(status)
		if paper.stage == "writing": active.add_child(U.button("Shelve", func(): sim.cancel_paper(), "back", "Return evidence and idea; discard writing progress"))
		refreshers.append(func():
			if sim.active_paper.is_empty(): return
			progress.value = paper.progress / paper.work * 100 if paper.stage == "writing" else 100 * (1.0 - float(paper.review_left) / sim.JOURNALS[paper.kind].review)
			status.text = "Writing %.1f / %.1f" % [paper.progress, paper.work] if paper.stage == "writing" else "Peer review / %dh left" % paper.review_left
		)
	var ideas_head = U.row()
	sidebar.add_child(ideas_head)
	var study = U.label("", 12, U.MUTED)
	ideas_head.add_child(study)
	U.space(ideas_head)
	var think = U.button("Discover", func(): sim.think_idea(), "study", "Spend 8 study points. 55% common, 30% rare, 15% legendary. A legendary is guaranteed by the eighth discovery without one.")
	ideas_head.add_child(think)
	refreshers.append(func(): study.text = "%.1f study / %d of 6 ideas" % [sim.study_points, sim.ideas.size()]; think.disabled = sim.study_points < 8 or sim.ideas.size() >= 6)
	var refresh = U.button("Journal club", _journal_club, "people", "Refresh the board for 12 study points. Requires the Journal club development.")
	sidebar.add_child(refresh)
	refreshers.append(func(): refresh.disabled = sim.study_points < 12 or "journal_club" not in sim.unlocked)
	var sorted = sim.ideas.duplicate()
	var installed = sim.installed_fields()
	sorted.sort_custom(func(a, b):
		var a_locked = sim.lifetime_impact < sim.JOURNALS[a.kind].prestige
		var b_locked = sim.lifetime_impact < sim.JOURNALS[b.kind].prestige
		if a_locked != b_locked: return not a_locked
		var a_supported = a.field in installed and (a.secondary == "" or a.secondary in installed)
		var b_supported = b.field in installed and (b.secondary == "" or b.secondary in installed)
		if a_supported != b_supported: return a_supported
		if a.kind != b.kind: return sim.JOURNALS[a.kind].impact > sim.JOURNALS[b.kind].impact
		return a.id < b.id
	)
	for idea in sorted:
		var tier = sim.rarity(idea.kind)
		var color = Color(tier.color)
		var card = U.panel(sidebar, Color("36332d") if idea.kind == "breakthrough" else U.CARD, color.darkened(0.4), 12)
		var identity = U.row(7)
		card.add_child(identity)
		identity.add_child(U.image(tier.icon, color, 19))
		identity.add_child(U.label(tier.name.to_upper(), 10, color))
		U.space(identity)
		identity.add_child(U.image(idea.field, Color(sim.FIELDS[idea.field].color), 19))
		identity.add_child(U.label(sim.FIELDS[idea.field].name, 11))
		card.add_child(U.label(idea.title, 16, U.TEXT, true))
		var spec = sim.JOURNALS[idea.kind]
		if spec.prestige == 0: card.add_child(U.label("No impact required", 11, U.ACCENT))
		var rewards = U.label("On publication: %s / +%d impact" % [_money(spec.grant), spec.impact], 12, color, true)
		rewards.tooltip_text = spec.name + " / %dh peer review\n" % spec.review + "Rewards are paid only if accepted."
		card.add_child(rewards)
		var evidence = U.label("", 12, U.MUTED, true)
		card.add_child(evidence)
		var slider = HSlider.new()
		slider.min_value = 100
		slider.max_value = 200
		slider.step = 10
		slider.value = paper_commitments.get(int(idea.id), 100)
		slider.custom_minimum_size.y = 22
		slider.set_meta("idea_id", idea.id)
		slider.tooltip_text = "Commit 100% to 200% of the minimum evidence. More evidence improves acceptance odds and needs slightly more writing."
		slider.value_changed.connect(func(value): paper_commitments[int(idea.id)] = value; _refresh())
		card.add_child(slider)
		var odds = U.label("", 12, color)
		card.add_child(odds)
		var reason = U.label("", 11, U.MUTED, true)
		card.add_child(reason)
		var actions = U.row()
		card.add_child(actions)
		var start = U.button("Start manuscript", func(): sim.start_paper(idea.id, slider.value / 100), "write")
		start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(start)
		actions.add_child(U.button("", func(): sim.discard_idea(idea.id), "close", "Discard this idea to free a slot"))
		refreshers.append(func():
			var ratio = slider.value / 100
			var pieces = PackedStringArray()
			for field in sim.dataset_cost(idea, ratio): pieces.append("%.0f %s" % [sim.dataset_cost(idea, ratio)[field], sim.FIELDS[field].name])
			evidence.text = " + ".join(pieces) + " evidence / %d%%" % slider.value
			odds.text = "%.0f%% acceptance / %.1f writing" % [sim.acceptance_chance(idea, ratio) * 100, spec.work * (1 + (ratio - 1) * 0.2)]
			reason.text = sim.paper_block_reason(idea.id, ratio)
			reason.visible = reason.text != ""
			start.disabled = reason.text != ""
		)

func _drop_menu() -> void:
	if is_instance_valid(menu_layer): menu_layer.queue_free(); remove_child(menu_layer)
	menu_layer = null

func _show_main_menu() -> void:
	_close_modal()
	_drop_menu()
	sim.paused = true
	game_ui.visible = false
	menu_mode = "main"
	menu_layer = Control.new()
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_layer)
	var backdrop = ColorRect.new()
	backdrop.color = U.BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(backdrop)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(center)
	var columns = U.row(45)
	center.add_child(columns)
	var hero = U.column(10)
	hero.custom_minimum_size.x = 780
	columns.add_child(hero)
	var logo = U.row(14)
	hero.add_child(logo)
	logo.add_child(U.image("nuclear", U.ACCENT, 45))
	logo.add_child(U.label("FIELDWORK", 48))
	hero.add_child(U.label("PHYSICS LABORATORY MANAGEMENT", 11, U.MUTED))
	var preview = FloorView.new()
	preview.simulation = sim
	preview.custom_minimum_size = Vector2(780, 545)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(preview)
	var fields = U.row(24)
	hero.add_child(fields)
	for field in sim.FIELDS:
		fields.add_child(U.image(field, Color(sim.FIELDS[field].color), 22))
		fields.add_child(U.label(sim.FIELDS[field].name, 12, U.MUTED))
	var card = U.panel(columns, U.PANEL, U.LINE, 24)
	card.get_parent().custom_minimum_size.x = 325
	card.get_parent().size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.add_child(U.label("Welcome to the lab", 24))

	var saves = sim.save_entries().filter(func(entry): return entry.valid) if not test_mode else []
	if not saves.is_empty(): card.add_child(U.button("Continue", func(): _load_path(saves[0].path), "play"))
	card.add_child(U.button("New laboratory", _new_game_menu, "plus"))
	card.add_child(U.button("Load laboratory", _load_menu, "load"))
	card.add_child(U.button("How to play", _help, "info"))
	card.add_child(U.button("Quit", func(): get_tree().quit(), "close"))

func _new_game_menu() -> void:
	var content = _open_modal("New laboratory", 760)
	content.add_child(U.label("Laboratory name", 12, U.MUTED))
	var name_edit = LineEdit.new()
	name_edit.text = "My laboratory"
	name_edit.max_length = 60
	content.add_child(name_edit)
	content.add_child(U.label("Research program", 13, U.MUTED))
	var program_choice = OptionButton.new()
	for key in sim.Programs.PROGRAMS:
		program_choice.add_item(sim.Programs.PROGRAMS[key].name)
		program_choice.set_item_metadata(program_choice.item_count - 1, key)
	content.add_child(program_choice)
	var objective = U.label("", 14, U.TEXT, true)
	content.add_child(objective)
	var explain = func():
		var spec = sim.Programs.PROGRAMS[program_choice.get_item_metadata(program_choice.selected)]
		objective.text = spec.description + "\n\nFinal discovery: " + spec.discovery
	program_choice.item_selected.connect(func(_index): explain.call())
	explain.call()
	content.add_child(U.label("Four cumulative milestones. Every qualifying publication counts throughout the run. You can keep playing after the final discovery.", 12, U.MUTED, true))
	content.add_child(U.button("Open the laboratory", func():
		var title = name_edit.text.strip_edges()
		sim.new_lab()
		sim.autosave_enabled = not test_mode
		sim.lab_name = title if title != "" else "My laboratory"
		sim.choose_program(program_choice.get_item_metadata(program_choice.selected))
		_enter_lab()
	, "play"))

func _enter_lab() -> void:
	_close_modal()
	_drop_menu()
	session_active = true
	game_ui.visible = true
	sim.paused = true
	selected_id = -1
	selected_kind = ""
	selected_person = -1
	build_kind = ""
	floor_view.build_kind = ""
	floor_view.selected_id = -1
	floor_view.selected_person = -1
	floor_view.reset_positions()
	paper_commitments.clear()
	_set_page("Build")
	if not sim.pending_result.is_empty(): _publication_result(sim.pending_result)
	elif not sim.pending_milestone.is_empty(): _milestone()

func _show_pause_menu() -> void:
	if not session_active or is_instance_valid(modal_layer): return
	sim.paused = true
	_refresh()
	_drop_menu()
	menu_mode = "pause"
	menu_layer = Control.new()
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_layer)
	var shade = ColorRect.new()
	shade.color = Color(0.05, 0.07, 0.08, 0.84)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(center)
	var card = U.panel(center, U.PANEL, U.LINE, 24)
	card.get_parent().custom_minimum_size.x = 380
	card.add_child(U.label("Laboratory paused", 25))
	card.add_child(U.label(sim.lab_name, 13, U.MUTED, true))
	card.add_child(U.button("Resume", _resume_from_menu, "play"))
	card.add_child(U.button("Save laboratory", _save_menu, "save"))
	card.add_child(U.button("Load laboratory", _load_menu, "load"))
	card.add_child(U.button("Research program", _program_window, "program"))
	card.add_child(U.button("Development tree", _development, "tree"))
	card.add_child(U.button("Resource history", _statistics, "chart"))
	card.add_child(U.button("Return to main menu", _return_to_main, "back"))
	card.add_child(U.button("Save and quit", _quit_game, "close"))

func _resume_from_menu() -> void:
	_drop_menu()
	if not sim.pending_result.is_empty(): _publication_result(sim.pending_result)
	elif not sim.pending_milestone.is_empty(): _milestone()
	else: sim.paused = false
	_refresh()

func _return_to_main() -> void:
	if not test_mode and not sim.save_lab(false): _info("Save failed", "Could not write the autosave. Your lab is still open."); return
	session_active = false
	_show_main_menu()

func _quit_game() -> void:
	if not test_mode and not sim.save_lab(false): _info("Save failed", "Could not save. Your lab is still open."); return
	get_tree().quit()

func _open_modal(title: String, width: int = 640, on_close: Callable = Callable()) -> VBoxContainer:
	_close_modal()
	modal_return = on_close
	modal_layer = Control.new()
	modal_layer.set_meta("management_window", true)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal_layer)
	var shade = ColorRect.new()
	shade.color = Color(0.03, 0.04, 0.05, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.offset_top = 72 if session_active else 0
	modal_layer.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 72 if session_active else 0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_layer.add_child(center)
	var frame = U.panel(center, U.PANEL, U.LINE, 22)
	frame.get_parent().custom_minimum_size.x = width
	var head = U.row()
	frame.add_child(head)
	modal_title = U.label(title, 23, U.TEXT, true)
	head.add_child(modal_title)
	U.space(head)
	head.add_child(U.button("", _close_modal, "close", "Close / Esc"))
	modal_box = U.column(14)
	frame.add_child(modal_box)
	_refresh()
	return modal_box

func _close_modal() -> void:
	if not is_instance_valid(modal_layer): return
	modal_layer.queue_free()
	remove_child(modal_layer)
	modal_layer = null
	modal_refreshers.clear()
	var action = modal_return
	modal_return = Callable()
	if action.is_valid(): action.call()

func _info(title: String, message: String) -> void:
	var content = _open_modal(title)
	content.add_child(U.label(message, 15, U.TEXT, true))
	content.add_child(U.button("Back", _close_modal, "back"))

func _confirm(title: String, message: String, action: Callable) -> void:
	var content = _open_modal(title, 550)
	content.add_child(U.label(message, 14, U.MUTED, true))
	var line = U.row()
	content.add_child(line)
	line.add_child(U.button("Cancel", _close_modal, "back"))
	U.space(line)
	line.add_child(U.button("Confirm", func(): _close_modal(); action.call(), "check"))

func _save_menu() -> void:
	if not session_active: return
	var content = _open_modal("Save laboratory", 630)
	var title = LineEdit.new()
	title.text = sim.lab_name
	title.max_length = 60
	content.add_child(title)
	for slot in range(1, 6):
		var card = U.panel(content, U.CARD)
		var line = U.row()
		card.add_child(line)
		var entry = {}
		for save in sim.save_entries():
			if save.path == sim.slot_path(slot): entry = save
		var text = U.column(2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		text.add_child(U.label("Slot %d / %s" % [slot, entry.get("name", "Empty")], 15, U.TEXT, true))
		if not entry.is_empty(): text.add_child(U.label("Day %d / %s" % [entry.day, entry.date.replace("T", " ")], 11, U.MUTED))
		line.add_child(U.button("Save here", func():
			var requested_name = title.text
			var action = func():
				if sim.save_slot(slot, requested_name): _close_modal(); _refresh()
				else: _info("Save failed", "This slot could not be written.")
			if FileAccess.file_exists(sim.slot_path(slot)): _confirm("Replace slot %d?" % slot, "The save in this slot will be replaced with the current lab.", action)
			else: action.call()
		, "save"))
	content.add_child(U.label("Autosave is separate. Returning to the main menu also writes it.", 11, U.MUTED, true))

func _load_menu() -> void:
	var content = _open_modal("Load laboratory", 690)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 450)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list = U.column(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var entries = sim.save_entries()
	if entries.is_empty(): list.add_child(U.label("No saved laboratories yet.", 15, U.MUTED))
	for entry in entries:
		var card = U.panel(list, U.CARD)
		var line = U.row()
		card.add_child(line)
		var text = U.column(2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		var tag = "Autosave" if entry.get("autosave", false) else "Slot %d" % entry.get("slot", 0)
		text.add_child(U.label(entry.name, 16, U.TEXT, true))
		text.add_child(U.label("%s / Day %d" % [tag, entry.day], 11, U.MUTED))
		var load_button = U.button("Load", func():
			if session_active: _confirm("Load this laboratory?", "Save to a slot first if you want to keep the current lab.", func(): _load_path(entry.path))
			else: _load_path(entry.path)
		, "load")
		load_button.disabled = not entry.valid
		line.add_child(load_button)

func _load_path(path: String) -> void:
	if sim.load_lab(path): _enter_lab()
	else: _info("Could not load", "This save is not readable. Your current lab is unchanged.")

func _recruitment() -> void:
	var content = _open_modal("Recruitment", 690)
	for role in sim.ROLES:
		var candidate = sim.candidates[role]
		var card = U.panel(content, U.CARD)
		var line = U.row(14)
		card.add_child(line)
		line.add_child(_portrait(candidate, 60))
		var bio = U.column(3)
		bio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(bio)
		bio.add_child(U.label(candidate.name, 18))
		bio.add_child(U.label(sim.ROLES[role].name + " / " + sim.FIELDS[candidate.specialty].name, 12, U.MUTED))
		var traits = U.label(sim.Catalog.TRAITS[candidate.trait].name + " / " + sim.Catalog.PERSONALITIES[candidate.personality].name, 12, U.ACCENT)
		traits.tooltip_text = sim.Catalog.TRAITS[candidate.trait].description + "\n" + sim.Catalog.PERSONALITIES[candidate.personality].description
		bio.add_child(traits)
		bio.add_child(U.label(_money(sim.ROLES[role].salary) + "/day", 11, U.MUTED))
		bio.add_child(U.label("A free bed is available" if sim.free_bed_id() != -1 else "No spare bed / rest at 40% recovery", 11, U.GOLD, true))
		var hire = U.button("Hire " + _money(sim.ROLES[role].cost), func():
			if sim.hire(role): _close_modal(); selected_person = sim.staff.back().id; _set_page("People")
		, "plus")
		hire.disabled = sim.funds < sim.ROLES[role].cost or sim.staff.size() >= 18
		line.add_child(hire)

func _statistics() -> void:
	var content = _open_modal("Resource history", 900)
	chart = Chart.new()
	chart.samples = sim.resource_history
	var controls = U.row(8)
	content.add_child(controls)
	for item in [["Funds", "funds"], ["Raw data", "raw"], ["Evidence", "analyzed"], ["Paper income", "grants"]]:
		controls.add_child(U.button(item[0], func(): chart.metric = item[1]; chart.queue_redraw()))
	U.space(controls)
	var span = OptionButton.new()
	for days in [30, 90, 720]: span.add_item("%d days" % days)
	span.item_selected.connect(func(index): chart.horizon = [30, 90, 720][index]; chart.queue_redraw())
	controls.add_child(span)
	content.add_child(chart)
	modal_refreshers.append(func(): chart.queue_redraw())
	var legend = U.row(14)
	content.add_child(legend)
	for field in sim.FIELDS:
		legend.add_child(U.image(field, Color(sim.FIELDS[field].color), 18))
		legend.add_child(U.label(sim.FIELDS[field].name, 12, U.MUTED))
	content.add_child(U.label("Daily snapshots. Hover over the graph for values. Paper income counts accepted grants that day.", 11, U.MUTED, true))

func _publication_result(result: Dictionary) -> void:
	var content = _open_modal("Published" if result.accepted else "Referee decision", 720, _after_review)
	var color = U.ACCENT if result.accepted else U.GOLD
	var identity = U.row()
	content.add_child(identity)
	identity.add_child(U.image(sim.rarity(result.kind).icon, Color(sim.rarity(result.kind).color), 28))
	identity.add_child(U.label(sim.rarity(result.kind).name.to_upper(), 11, Color(sim.rarity(result.kind).color)))
	U.space(identity)
	identity.add_child(U.image(result.field, Color(sim.FIELDS[result.field].color), 24))
	identity.add_child(U.label(sim.FIELDS[result.field].name, 13))
	content.add_child(U.label(result.title, 25, color, true))
	content.add_child(U.label(result.feedback, 15, U.TEXT, true))
	content.add_child(U.label("+%s / +%d impact" % [_money(result.grant), result.impact] if result.accepted else "75% of evidence returned; idea restored.", 19, color, true))
	content.add_child(U.label("Acceptance estimate: %.0f%%. Time is paused." % (result.chance * 100), 12, U.MUTED))
	content.add_child(U.button("Close / remain paused", _close_modal, "back"))
	content.add_child(U.button("Resume simulation", _resume_from_feedback, "play"))

func _journal_club() -> void:
	if not sim.refresh_ideas(): return
	var best = sim.ideas[0]
	for idea in sim.ideas:
		if sim.JOURNALS[idea.kind].impact > sim.JOURNALS[best.kind].impact: best = idea
	_discovery(best)
	modal_title.text = "Journal club / six new ideas"

func _discovery(idea: Dictionary) -> void:
	var tier = sim.rarity(idea.kind)
	var color = Color(tier.color)
	var content = _open_modal("A new research idea", 630)
	var badge = U.row(14)
	content.add_child(badge)
	badge.add_child(U.image(tier.icon, color, 62))
	var title = U.column()
	badge.add_child(title)
	title.add_child(U.label(tier.name.to_upper(), 26, color))
	title.add_child(U.label(sim.JOURNALS[idea.kind].name, 13, U.MUTED))
	content.add_child(U.label(idea.title, 24, U.TEXT, true))
	var field = U.row()
	content.add_child(field)
	field.add_child(U.image(idea.field, Color(sim.FIELDS[idea.field].color), 25))
	field.add_child(U.label(sim.FIELDS[idea.field].name, 16))
	content.add_child(U.label("On publication: %s / +%d impact" % [_money(sim.JOURNALS[idea.kind].grant), sim.JOURNALS[idea.kind].impact], 16, color))
	content.add_child(U.button("View paper ideas", func(): _close_modal(); _set_page("Papers"), "paper"))
	# A short reveal uses opacity only; it doesn't hide costs or block input.
	content.modulate.a = 0
	create_tween().tween_property(content, "modulate:a", 1.0, 0.35)

func _notebook_history() -> void:
	var content = _open_modal("Lab notebook", 920)
	var book = Notebook.new()
	content.add_child(book)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(800, 540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	book.add_child(scroll)
	var entries = U.column(16)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries)
	for event in sim.log_entries:
		var entry = U.column(6)
		entries.add_child(entry)
		entry.add_child(U.label("DAY %d  /  %02d:00" % [event.day, event.get("hour", 0)], 11, Notebook.FAINT))
		entry.add_child(U.label(event.message, 15, Notebook.INK, true))

func _help() -> void:
	_info("Running the laboratory", "Space pauses or resumes; Esc closes a window or opens the pause menu. A day lasts 48 seconds at 1x. Browsing windows keeps time running. Referee decisions and program milestones pause with an explicit Resume button.\n\nPlace experiments in the upper labs, desks in the office, and beds along the sleeping area's upper wall. Assign each person a bed; bedless rest restores only 40% as much energy.\n\nIn People, assign daily rest, collection and analysis. Remaining gold hours run Activity. Auto writes when a manuscript needs work and studies otherwise.\n\nCommon papers need no impact. Commit matching evidence, then assign writing hours and a desk. More evidence improves acceptance odds.\n\nThe target icon opens your research program and all published papers. Its milestones use cumulative credit. The tree icon opens Development; impact unlocks technologies, then funds buy equipment upgrades and modules. Every upgrade shows its effect before purchase.")

func _floor_clicked(cell: Vector2i) -> void:
	if build_kind != "":
		if sim.place_experiment(build_kind, cell):
			var object = sim.object_at(cell)
			selected_id = object.id
			selected_kind = object.kind
			_cancel_build()
		else: hint_label.text = sim.placement_error(build_kind, cell)
		return
	var object = sim.object_at(cell)
	selected_id = object.get("id", -1)
	selected_kind = object.get("kind", "")
	floor_view.selected_id = selected_id
	floor_view.selected_kind = selected_kind
	if selected_id >= 0: _set_page("Build")

func _cancel_build() -> void:
	build_kind = ""
	floor_view.build_kind = ""
	floor_view.selected_id = selected_id
	floor_view.selected_kind = selected_kind
	_rebuild_sidebar()

func _toggle_pause() -> void:
	if not session_active: return
	if not sim.pending_result.is_empty() or not sim.pending_milestone.is_empty(): return
	sim.paused = not sim.paused
	_refresh()

func _queue_rebuild() -> void:
	if deferred_rebuild: return
	deferred_rebuild = true
	call_deferred("_finish_rebuild")
func _finish_rebuild() -> void:
	deferred_rebuild = false
	if page == "Papers": _rebuild_sidebar()

func _refresh() -> void:
	if not is_instance_valid(clock_label): return
	clock_label.text = "DAY %03d / %02d:00" % [sim.day, sim.hour]
	cash_label.text = _money(sim.funds)
	cash_label.tooltip_text = "University support: %s/day\nCosts: %s/day\nNet: %s/day" % [_money(sim.income()), _money(sim.expenses()), _money(sim.income() - sim.expenses())]
	impact_label.text = str(sim.prestige)
	impact_label.tooltip_text = "%d available impact\n%d lifetime impact\n%d published papers" % [sim.prestige, sim.lifetime_impact, sim.published]
	headline_label.text = sim.lab_name
	pause_button.icon = U.icon("play" if sim.paused else "pause")
	pause_button.text = "PAUSED" if sim.paused else "Pause"
	pause_button.disabled = not sim.pending_result.is_empty() or not sim.pending_milestone.is_empty()
	pause_button.add_theme_stylebox_override("normal", U.box(Color("66513a") if sim.paused else U.CARD, U.GOLD if sim.paused else U.LINE, 8))
	pause_button.add_theme_stylebox_override("disabled", U.box(Color("66513a"), U.GOLD, 8))
	state_label.text = "PAUSED / SPACE TO RESUME" if sim.paused else "%d× / RUNNING" % sim.speed
	state_label.add_theme_color_override("font_color", U.GOLD if sim.paused else U.MUTED)
	for control in pause_button.get_parent().get_children():
		if control.has_meta("speed"): control.add_theme_stylebox_override("normal", U.box(Color("46534d") if control.get_meta("speed") == sim.speed else U.CARD, U.LINE, 9))
	for field in data_labels: data_labels[field].text = "%.1f raw / %.1f evidence" % [sim.raw_by_field[field], sim.analyzed_by_field[field]]
	var messages = PackedStringArray()
	for event in sim.log_entries.slice(0, 3): messages.append("D%d / %02d:00   %s" % [event.day, event.get("hour", 0), event.message])
	event_label.text = "\n".join(messages)
	hint_label.text = "Placing %s / click to build / Esc to cancel" % ("a bed" if build_kind == "bed" else "a desk" if build_kind == "desk" else sim.EQUIPMENT[build_kind].name) if build_kind != "" else "Click a person or workstation to inspect it."
	for refresh in refreshers: refresh.call()
	for refresh in modal_refreshers.duplicate(): if refresh.is_valid(): refresh.call()
	floor_view.queue_redraw()

func _scroll_body(parent: Control, width: int, height: int) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(width, height)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var body = U.column(12)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	return body

func _development() -> void:
	var content = _open_modal("Development", 1120)
	var balance = U.label("", 13, U.GOLD)
	content.add_child(balance)
	modal_refreshers.append(func(): balance.text = "%d impact available / technologies unlock purchases; funds pay for equipment" % sim.prestige)
	var body = _scroll_body(content, 1060, 580)
	var tree = TechTree.new()
	tree.simulation = sim
	body.add_child(tree)
	_refresh()

func _program_window() -> void:
	var content = _open_modal("Research program", 1000)
	if sim.research_program == "":
		content.add_child(U.label("Choose the final goal for this run. This choice is permanent; qualifying publications count cumulatively.", 14, U.MUTED, true))
		for key in sim.Programs.PROGRAMS:
			var spec = sim.Programs.PROGRAMS[key]
			content.add_child(U.label(spec.description, 13, U.MUTED, true))
			content.add_child(U.button(spec.name, func(): sim.choose_program(key); _program_window(), spec.field))
		return
	var spec = sim.Programs.PROGRAMS[sim.research_program]
	var head = U.row()
	content.add_child(head)
	head.add_child(U.image(spec.field, Color(sim.FIELDS[spec.field].color), 30))
	head.add_child(U.label(spec.name, 24))
	U.space(head)
	head.add_child(U.button("Published papers", _publication_archive, "paper"))
	content.add_child(U.label("Final discovery: " + spec.discovery, 14, U.GOLD))
	content.add_child(U.label("Cumulative credit. Papers are never spent. Higher tiers count toward lower-tier requirements; mixed papers count in both fields.", 12, U.MUTED, true))
	var body = _scroll_body(content, 940, 450)
	var index = 0
	for stage in sim.Programs.stages(sim.research_program):
		var number = index
		var card = U.panel(body, Color("303c36") if number < sim.program_level else U.CARD)
		card.add_child(U.label("%d. %s%s" % [number + 1, stage.name, " / COMPLETE" if number < sim.program_level else " / CURRENT" if number == sim.program_level else ""], 17, U.ACCENT if number < sim.program_level else U.TEXT))
		card.add_child(U.label(stage.description, 12, U.MUTED, true))
		for requirement in stage.requirements:
			var line = U.row()
			card.add_child(line)
			var count = sim.Programs.count(sim.history, requirement)
			line.add_child(U.image("check" if count >= requirement.count else "paper", U.ACCENT if count >= requirement.count else U.MUTED, 17))
			line.add_child(U.label(sim.Programs.requirement_text(requirement), 13, U.TEXT, true))
			U.space(line)
			line.add_child(U.label("%d / %d" % [count, requirement.count], 13, U.ACCENT))
		index += 1
	var discovery = U.button("Develop final manuscript / 12 study", func(): sim.develop_discovery(), "legendary")
	content.add_child(discovery)
	modal_refreshers.append(func():
		var reason = sim.discovery_reason()
		discovery.disabled = reason != ""
		discovery.text = reason if reason != "" else "Develop final manuscript / 12 study"
	)
	_refresh()

func _publication_archive() -> void:
	var content = _open_modal("Published papers", 1000)
	var filters = U.row(10)
	content.add_child(filters)
	filters.add_child(U.button("Program progress", _program_window, "back"))
	U.space(filters)
	var fields = {"any": "All fields"}
	for field in sim.FIELDS: fields[field] = sim.FIELDS[field].name
	_choice(filters, "", fields, archive_field, func(value): archive_field = value; _publication_archive())
	_choice(filters, "", {"any": "All tiers", "letter": "Common", "article": "Rare", "breakthrough": "Legendary"}, archive_tier, func(value): archive_tier = value; _publication_archive())
	var body = _scroll_body(content, 940, 530)
	var shown = 0
	for paper in sim.history:
		if not paper.accepted: continue
		if archive_field != "any" and archive_field not in [paper.field, paper.get("secondary", "")]: continue
		if archive_tier != "any" and paper.kind != archive_tier: continue
		shown += 1
		var tier = sim.rarity(paper.kind)
		var card = U.panel(body, U.CARD, Color(tier.color).darkened(0.4))
		var line = U.row()
		card.add_child(line)
		line.add_child(U.image(tier.icon, Color(tier.color), 22))
		line.add_child(U.label(tier.name + " / Day %d" % paper.day, 12, Color(tier.color)))
		U.space(line)
		for field in [paper.field, paper.get("secondary", "")]:
			if field == "": continue
			line.add_child(U.image(field, Color(sim.FIELDS[field].color), 20))
			line.add_child(U.label(sim.FIELDS[field].name, 12))
		card.add_child(U.label(paper.title, 18, U.TEXT, true))
		card.add_child(U.label("Awarded %s / +%d impact" % [_money(paper.grant), paper.impact], 12, U.MUTED))
		var contributions = PackedStringArray()
		var level = 1
		for stage in sim.Programs.stages(sim.research_program):
			for requirement in stage.requirements:
				if sim.Programs.matches(paper, requirement): contributions.append(str(level)); break
			level += 1
		card.add_child(U.label("Counts toward program stages " + ", ".join(contributions), 12, U.ACCENT, true))
	if shown == 0: body.add_child(U.label("No published papers match these filters.", 15, U.MUTED))

func _after_review() -> void:
	sim.acknowledge_result()
	if not sim.pending_milestone.is_empty(): call_deferred("_show_pending_milestone")

func _show_pending_milestone() -> void:
	if session_active and not sim.pending_milestone.is_empty(): _milestone()

func _resume_from_feedback() -> void:
	_close_modal()
	if sim.pending_result.is_empty() and sim.pending_milestone.is_empty(): sim.paused = false
	_refresh()

func _milestone() -> void:
	var milestone = sim.pending_milestone.duplicate(true)
	if milestone.is_empty(): return
	var victory = milestone.victory
	var spec = sim.Programs.PROGRAMS[sim.research_program]
	var content = _open_modal("Major discovery" if victory else "Program milestone", 800, sim.acknowledge_milestone)
	content.add_child(U.image("legendary" if victory else "program", U.GOLD, 60))
	content.add_child(U.label(spec.discovery if victory else sim.Programs.stages(sim.research_program)[int(milestone.to) - 1].name + " complete", 25, U.GOLD, true))
	content.add_child(U.label("Your research program is complete. The laboratory can continue publishing and developing." if victory else "Stage %d of 4 completed. Earlier publications continue to count toward the next milestone." % milestone.to, 15, U.TEXT, true))
	content.add_child(U.button("Review program / remain paused", func(): _close_modal(); _program_window(), "program"))
	content.add_child(U.button("Continue simulation", _resume_from_feedback, "play"))
