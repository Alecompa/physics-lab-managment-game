extends Control
const Simulation = preload("res://scripts/simulation.gd")
const FloorView = preload("res://scripts/lab_floor.gd")
const Portrait = preload("res://scripts/portrait.gd")
const Schedule = preload("res://scripts/schedule_view.gd")
const Chart = preload("res://scripts/resource_chart.gd")
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
	var chapter = U.label("NORTH ANNEX", 10, U.MUTED)
	chapter.tooltip_text = "A fixed starting laboratory. Space expansion will come in a later iteration."
	header.add_child(chapter)
	U.space(header)
	header.add_child(U.image("coin", U.ACCENT, 21))
	cash_label = U.label("", 19)
	header.add_child(cash_label)
	header.add_child(U.image("legendary", U.GOLD, 19))
	impact_label = U.label("", 17, U.GOLD)
	header.add_child(impact_label)
	U.space(header)
	clock_label = U.label("", 15)
	header.add_child(clock_label)
	pause_button = U.button("", _toggle_pause, "play", "Pause or resume / Space")
	header.add_child(pause_button)
	for speed in [1, 2, 4]:
		var control = U.button("%dx" % speed, func(): sim.speed = speed; _refresh())
		control.set_meta("speed", speed)
		header.add_child(control)
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
	var notebook = U.panel(left, U.PANEL, U.LINE, 10)
	var notebook_head = U.row()
	notebook.add_child(notebook_head)
	notebook_head.add_child(U.image("study", U.MUTED, 15))
	notebook_head.add_child(U.label("LAB NOTEBOOK", 10, U.MUTED))
	U.space(notebook_head)
	notebook_head.add_child(U.button("History", _notebook_history, "load"))
	event_label = RichTextLabel.new()
	event_label.bbcode_enabled = false
	event_label.custom_minimum_size.y = 55
	event_label.add_theme_font_size_override("normal_font_size", 12)
	event_label.scroll_active = false
	notebook.add_child(event_label)
	var panel = U.panel(content, U.PANEL, U.LINE, 10)
	side_panel = panel.get_parent()
	side_panel.custom_minimum_size.x = 370
	var tab_row = U.row(4)
	panel.add_child(tab_row)
	for item in [["Build", "build"], ["People", "people"], ["Papers", "paper"], ["Develop", "upgrade"]]:
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
		"Develop": _develop_page()
	for key in tabs: tabs[key].add_theme_stylebox_override("normal", U.box(Color("46534d") if page == key else U.CARD, U.ACCENT if page == key else U.LINE, 8))
	_refresh()

func _build_page() -> void:
	var object = sim.desk_by_id(selected_id) if selected_kind == "desk" else sim.experiment_by_id(selected_id)
	if not object.is_empty():
		var inspector = U.panel(sidebar, U.CARD)
		if object.kind == "desk":
			inspector.add_child(U.label("Desk #%d" % object.id, 18))
			var owners = PackedStringArray()
			for person in sim.staff:
				if person.desk == object.id: owners.append(person.name)
			inspector.add_child(U.label(" / ".join(owners) if not owners.is_empty() else "Shared desk", 12, U.MUTED, true))
			inspector.add_child(U.button("Remove / +$210", func(): _confirm("Remove this desk?", "Assigned people will look for a shared desk.", func(): sim.remove_desk(object.id); selected_id = -1; _rebuild_sidebar()), "close"))
		else:
			inspector.add_child(U.label(sim.EQUIPMENT[object.kind].name, 18))
			var status = U.label("", 12, U.MUTED, true)
			inspector.add_child(status)
			var upgrade = U.button("Upgrade", func(): sim.upgrade_experiment(object.id); _rebuild_sidebar(), "upgrade")
			inspector.add_child(upgrade)
			inspector.add_child(U.button("Service / $250", func(): sim.service_experiment(object.id), "build"))
			inspector.add_child(U.button("Decommission", func(): _confirm("Decommission experiment?", "Recover 35% of its original price.", func(): sim.remove_experiment(object.id); selected_id = -1; _rebuild_sidebar()), "close"))
			refreshers.append(func():
				var mix = PackedStringArray()
				for field in sim.output_mix(object): mix.append("%d%% %s" % [sim.output_mix(object)[field] * 100, sim.FIELDS[field].name])
				status.text = "Level %d / %.0f%% condition\n%s" % [object.level, object.condition, " + ".join(mix)]
				upgrade.text = "Maximum level" if object.level >= 3 else "Upgrade / " + _money(sim.upgrade_cost(object))
				upgrade.disabled = object.level >= 3 or sim.funds < sim.upgrade_cost(object)
			)
	var heading = U.row()
	sidebar.add_child(heading)
	heading.add_child(U.label("PLACE IN THE LAB", 10, U.MUTED))
	U.space(heading)
	heading.add_child(U.button("", func(): _info("Building", "Experiments occupy 2×2 floor tiles in either laboratory. Desks occupy 2×1 tiles in the office and need a free chair tile below. Doorways, corridors and routes to workstations stay clear."), "info"))
	for kind in ["desk", "optics", "vacuum", "detector", "quantum"]:
		var spec = {"name": "Research desk", "cost": 600, "field": "", "description": "A physical desk for analysis, writing and study. One person can use it at a time."} if kind == "desk" else sim.EQUIPMENT[kind]
		var card = U.panel(sidebar, U.CARD)
		var line = U.row(10)
		card.add_child(line)
		line.add_child(U.image("desk" if kind == "desk" else spec.field, U.TEXT if kind == "desk" else Color(sim.FIELDS[spec.field].color), 28))
		var title = U.column(2)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(title)
		title.add_child(U.label(spec.name, 15))
		title.add_child(U.label(_money(spec.cost) + (" / 2×1" if kind == "desk" else " / 2×2"), 12, U.MUTED))
		var choose = U.button("", func(): build_kind = kind; floor_view.build_kind = kind; _refresh(), "plus", spec.description)
		line.add_child(choose)
		card.get_parent().tooltip_text = spec.description
		refreshers.append(func(): choose.disabled = sim.funds < spec.cost or kind != "desk" and not sim.equipment_unlocked(kind); choose.icon = U.icon("check" if build_kind == kind else "plus"))
	if build_kind != "": sidebar.add_child(U.button("Cancel placement", _cancel_build, "close"))

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
	energy.tooltip_text = "Rest restores energy. Low energy reduces productivity."
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

func _develop_page() -> void:
	sidebar.add_child(U.label("LAB DEVELOPMENT", 10, U.MUTED))
	sidebar.add_child(U.label("Existing upgrades. Research programs will come later.", 11, U.MUTED, true))
	for key in sim.UPGRADES:
		var spec = sim.UPGRADES[key]
		var card = U.panel(sidebar, U.CARD)
		var line = U.row()
		card.add_child(line)
		line.add_child(U.image("upgrade", U.ACCENT, 22))
		line.add_child(U.label(spec.name, 15, U.TEXT, true))
		card.get_parent().tooltip_text = spec.description
		var unlock = U.button("", func(): sim.unlock_upgrade(key), "legendary", spec.description)
		card.add_child(unlock)
		refreshers.append(func():
			var dependency = spec.requires != "" and spec.requires not in sim.unlocked
			unlock.text = "Unlocked" if key in sim.unlocked else "Requires " + sim.UPGRADES[spec.requires].name if dependency else "%d impact" % spec.cost
			unlock.disabled = key in sim.unlocked or sim.prestige < spec.cost or dependency
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
	card.add_child(U.label("NORTH ANNEX / ITERATION 03", 10, U.MUTED))
	var saves = sim.save_entries().filter(func(entry): return entry.valid) if not test_mode else []
	if not saves.is_empty(): card.add_child(U.button("Continue", func(): _load_path(saves[0].path), "play"))
	card.add_child(U.button("New laboratory", _new_game_menu, "plus"))
	card.add_child(U.button("Load laboratory", _load_menu, "load"))
	card.add_child(U.button("How to play", _help, "info"))
	card.add_child(U.button("Quit", func(): get_tree().quit(), "close"))

func _new_game_menu() -> void:
	var content = _open_modal("New laboratory", 520)
	content.add_child(U.label("Laboratory name", 12, U.MUTED))
	var name_edit = LineEdit.new()
	name_edit.text = "The North Annex"
	name_edit.max_length = 60
	content.add_child(name_edit)
	content.add_child(U.label("A fixed lab, three desks, two PhD students and a researcher. Days last 48 seconds at 1x.", 13, U.MUTED, true))
	content.add_child(U.button("Open the laboratory", func():
		var title = name_edit.text.strip_edges()
		sim.new_lab()
		sim.autosave_enabled = not test_mode
		sim.lab_name = title if title != "" else "The North Annex"
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
	card.add_child(U.button("Resource history", _statistics, "chart"))
	card.add_child(U.button("Return to main menu", _return_to_main, "back"))
	card.add_child(U.button("Save and quit", _quit_game, "close"))

func _resume_from_menu() -> void:
	_drop_menu()
	if not sim.pending_result.is_empty(): _publication_result(sim.pending_result)
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
	sim.paused = true
	modal_return = on_close
	modal_layer = Control.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal_layer)
	var shade = ColorRect.new()
	shade.color = Color(0.03, 0.04, 0.05, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(center)
	var frame = U.panel(center, U.PANEL, U.LINE, 22)
	frame.get_parent().custom_minimum_size.x = width
	var head = U.row()
	frame.add_child(head)
	modal_title = U.label(title, 23, U.TEXT, true)
	head.add_child(modal_title)
	U.space(head)
	head.add_child(U.button("", _close_modal, "close", "Close / keep time paused"))
	modal_box = U.column(14)
	frame.add_child(modal_box)
	_refresh()
	return modal_box

func _close_modal() -> void:
	if not is_instance_valid(modal_layer): return
	modal_layer.queue_free()
	remove_child(modal_layer)
	modal_layer = null
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
		var tag = "Autosave" if entry.get("autosave", false) else "Import previous version" if entry.get("legacy", false) else "Slot %d" % entry.get("slot", 0)
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
	var legend = U.row(14)
	content.add_child(legend)
	for field in sim.FIELDS:
		legend.add_child(U.image(field, Color(sim.FIELDS[field].color), 18))
		legend.add_child(U.label(sim.FIELDS[field].name, 12, U.MUTED))
	content.add_child(U.label("Daily snapshots. Hover over the graph for values. Paper income counts accepted grants that day.", 11, U.MUTED, true))

func _publication_result(result: Dictionary) -> void:
	var content = _open_modal("Published" if result.accepted else "Referee decision", 720, sim.acknowledge_result)
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
	content.add_child(U.button("Return to the lab", _close_modal, "back"))

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
	content.add_child(U.label("Potential award: %s / %d impact" % [_money(sim.JOURNALS[idea.kind].grant), sim.JOURNALS[idea.kind].impact], 16, color))
	content.add_child(U.button("View paper ideas", func(): _close_modal(); _set_page("Papers"), "paper"))
	# A short reveal uses opacity only; it doesn't hide costs or block input.
	content.modulate.a = 0
	create_tween().tween_property(content, "modulate:a", 1.0, 0.35)

func _notebook_history() -> void:
	var content = _open_modal("Lab notebook", 820)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 490)
	content.add_child(scroll)
	var entries = U.column(12)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries)
	for event in sim.log_entries:
		entries.add_child(U.label("Day %d / %02d:00" % [event.day, event.get("hour", 0)], 10, U.MUTED))
		entries.add_child(U.label(event.message, 14, U.TEXT, true))

func _help() -> void:
	_info("Life in the North Annex", "Space pauses. A day lasts 48 seconds at 1x. Esc opens the pause menu.\n\nBUILD: experiments go in the upper rooms. Desks go in the office and need a free chair space below. Walls and corridors stay fixed.\n\nPEOPLE: click a portrait or a person on the floor. Drag routine boundaries, assign activity and choose a desk. Gold hours are Activity. Auto writes when there is a manuscript and studies otherwise.\n\nPAPERS: analyzed evidence must match the field. More committed evidence raises review odds. The writing banner explains missing hours or desks. Study earns points for discovering ideas.\n\nSAVE: use the pause menu for five named slots. Autosave is separate. Statistics records resources each midnight. Hover over icons, traits and controls for details.")

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
	if not sim.pending_result.is_empty(): _publication_result(sim.pending_result); return
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
	state_label.text = "PAUSED" if sim.paused else "%d× / LIVE" % sim.speed
	for control in pause_button.get_parent().get_children():
		if control.has_meta("speed"): control.add_theme_stylebox_override("normal", U.box(Color("46534d") if control.get_meta("speed") == sim.speed else U.CARD, U.LINE, 9))
	for field in data_labels: data_labels[field].text = "%.1f raw / %.1f evidence" % [sim.raw_by_field[field], sim.analyzed_by_field[field]]
	var messages = PackedStringArray()
	for event in sim.log_entries.slice(0, 3): messages.append("D%d / %02d:00   %s" % [event.day, event.get("hour", 0), event.message])
	event_label.text = "\n".join(messages)
	hint_label.text = "Placing %s / click to build / Esc to cancel" % ("a desk" if build_kind == "desk" else sim.EQUIPMENT[build_kind].name) if build_kind != "" else "Click a person or workstation to inspect it."
	for refresh in refreshers: refresh.call()
	floor_view.queue_redraw()
