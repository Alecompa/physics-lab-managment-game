extends SceneTree
var game: Control
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run_tests")
func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures += 1; printerr("FAIL: " + message)
func settle() -> void:
	for i in range(8): await process_frame
func press(parent: Node, caption: String) -> bool:
	for button in parent.find_children("*", "Button", true, false):
		if button.text == caption and not button.disabled: button.pressed.emit(); return true
	return false
func capture(name: String) -> void:
	await settle()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
		root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png")
func fits(control: Control) -> bool:
	var rect = control.get_global_rect()
	return rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= 1441 and rect.end.y <= 961
func modal_fits() -> bool:
	return fits(game.modal_box.get_parent().get_parent())
func run_tests() -> void:
	root.size = Vector2i(1440, 960)
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.sim.set_process(false)
	game.sim.save_prefix = "res://tests/.ui_test_"
	await settle()
	check(not game.session_active and game.menu_layer.visible and not game.game_ui.visible, "Game opens at main menu")
	await capture("main-menu-v3")
	check(press(game.menu_layer, "New laboratory"), "Main menu offers new lab")
	await settle()
	game.modal_box.find_children("*", "LineEdit", true, false)[0].text = "The Test Annex"
	check(press(game.modal_box, "Open the laboratory"), "New laboratory starts from menu")
	await settle()
	check(game.session_active and game.sim.paused and game.sim.lab_name == "The Test Annex", "Named new lab starts paused")
	check(fits(game.sidebar_scroll) and fits(game.floor_view), "Lab and sidebar fit window")
	check(game.floor_view.size.x > 900, "Lab has most of the window width")
	check(game.data_labels.size() == 4, "All four fields have counters")
	check(game.clock_label.text.contains("08:00"), "Clock displays hour")
	await capture("prototype-v3")
	# Exercise real frame interpolation along corridors, with production and study visible.
	game.sim.paused = false
	game.sim.speed = 4
	for i in range(24):
		game.sim.advance_hour()
		await create_timer(0.53).timeout
		for person in game.sim.staff:
			var position = game.floor_view.person_positions[person.id]
			check(not game.sim.navigation.is_point_solid(Vector2i(position.round())), "Rendered walking stays on navigable floor")
		if i == 5: await capture("lab-active-v3")
		if i == 20: await capture("lab-rest-v3")
	check(game.sim.raw_data + game.sim.analyzed_data > 0 and game.sim.study_points > 0, "Rendered activity produces data and study")
	game.sim.new_lab()
	game._enter_lab()
	game._set_page("People")
	await capture("people-v3")
	game.floor_view.person_clicked.emit(2)
	await settle()
	check(game.page == "People" and game.selected_person == 2, "Clicking person opens their detail")
	var inputs = game.sidebar.find_children("*", "SpinBox", true, false)
	check(inputs.size() == 3, "Selected person's three routine controls appear")
	inputs[0].value = 10
	check(game.sim.staff[1].rest == 10, "Hours control changes simulated routine")
	var choices = game.sidebar.find_children("*", "OptionButton", true, false)
	check(choices.size() == 4, "Activity, field, experiment and physical desk can be assigned")
	choices[1].select(1)
	choices[1].item_selected.emit(1)
	check(game.sim.staff[1].focus == "nuclear", "Field selector changes actual focus")
	await capture("routine-v3")
	game._recruitment()
	await settle()
	check(modal_fits(), "Recruitment modal fits")
	await capture("recruitment-v3")
	var hire_buttons = game.modal_box.find_children("*", "Button", true, false)
	hire_buttons[1].pressed.emit()
	check(game.sim.staff.size() == 4, "Hiring from preview adds staff")
	game.sim.new_lab()
	game._enter_lab()
	game.sim.prestige = 20
	game.sim.lifetime_impact = 20
	game._set_page("Develop")
	await capture("development-v3")
	game._set_page("Build")
	game.build_kind = "desk"
	game._floor_clicked(Vector2i(5, 11))
	check(game.sim.desks.size() == 4 and game.selected_kind == "desk", "Desk placement creates inspectable physical desk")
	game.build_kind = "vacuum"
	game._floor_clicked(Vector2i(12, 1))
	check(game.sim.experiments.size() == 2, "Experiment placement uses laboratory room")
	await capture("equipment-v3")
	game.sim.new_lab()
	game._enter_lab()
	game._set_page("Papers")
	game.sim.analyzed_by_field.optics = 100
	game._refresh()
	await settle()
	var sliders = game.sidebar.find_children("*", "HSlider", true, false)
	check(sliders.size() == 5, "Each idea provides evidence commitment")
	check(int(sliders[0].get_meta("idea_id")) == 1, "Unlocked starter optics letter appears before locked rare paper")
	var paper_labels = game.sidebar.find_children("*", "Label", true, false)
	check(paper_labels.filter(func(label): return label.text == "No impact required").size() == 4, "Every common starter clearly states no impact requirement")
	check(paper_labels.filter(func(label): return label.text.begins_with("On publication:") and label.text.contains("+2 impact")).size() == 4, "Common impact rewards are explicitly labeled as publication rewards")
	for slider in sliders:
		if int(slider.get_meta("idea_id")) == 1: slider.value = 200
	check(game.paper_commitments[1] == 200, "Commitment choice persists")
	await capture("papers-v3")
	check(press(game.sidebar, "Start manuscript"), "Eligible paper can start")
	check(game.sim.active_paper.committed.optics == 36, "Starting spends chosen typed evidence")
	game.sim.active_paper.stage = "review"
	game.sim.active_paper.review_left = 1
	game.sim.active_paper.review_roll = 0
	game.sim.advance_hour()
	await settle()
	check(is_instance_valid(game.modal_layer) and game.sim.paused and modal_fits(), "Publication pauses and presents fitting modal")
	check(game.modal_title.text.contains("Published"), "Accepted review gets publication feedback")
	await capture("publication-result-v3")
	game._close_modal()
	check(game.sim.pending_result.is_empty() and game.sim.paused, "Closing decision acknowledges without resuming")
	var idea = game.sim.add_idea("quantum", "breakthrough")
	game._discovery(idea)
	for i in range(35): await process_frame
	check(modal_fits() and game.sim.paused, "Legendary reveal fits and pauses")
	await capture("legendary-v3")
	game._close_modal()
	for i in range(24 * 30): game.sim.advance_hour()
	game._statistics()
	await settle()
	check(game.chart.samples.size() >= 30 and modal_fits(), "Graph displays recorded daily resources")
	press(game.modal_box, "Evidence")
	game.chart.hovered = 10
	await capture("statistics-v3")
	game._close_modal()
	game._show_pause_menu()
	check(game.sim.paused and game.menu_mode == "pause", "Pause menu stops simulation")
	await capture("pause-menu-v3")
	check(press(game.menu_layer, "Save laboratory"), "Pause menu opens save chooser")
	await settle()
	check(modal_fits(), "Five-slot chooser fits")
	await capture("save-menu-v3")
	check(press(game.modal_box, "Save here"), "Save chooser writes chosen slot")
	check(FileAccess.file_exists(game.sim.slot_path(1)), "Manual save file exists")
	game._load_menu()
	await settle()
	check(modal_fits(), "Load menu fits")
	await capture("load-menu-v3")
	game._load_path(game.sim.slot_path(1))
	await settle()
	check(game.sim.day >= 30 and game.session_active and game.sim.paused, "Load restores gameplay and starts paused")
	# Test full slots and long laboratory names without touching player files.
	for slot in range(1, 6): game.sim.save_slot(slot, "The Laboratory for Unreasonably Long and Complicated Names")
	game._refresh()
	await settle()
	check(fits(game.floor_view) and fits(game.sidebar_scroll), "Long lab name keeps gameplay in bounds")
	game._save_menu()
	await settle()
	check(modal_fits(), "Full named save chooser fits")
	await capture("save-menu-full-v3")
	game._close_modal()
	game._load_menu()
	await settle()
	check(modal_fits(), "Full load chooser scrolls within window")
	game._close_modal()
	for slot in range(1, 6): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.sim.slot_path(slot)))
	game._help()
	await settle()
	check(modal_fits(), "Help fits window")
	await capture("guide-v3")
	game._close_modal()
	game._return_to_main()
	check(not game.session_active and game.menu_mode == "main", "Return to main menu leaves session")
	print("UI checks: %d passed, %d failed." % [checks - failures, failures])
	quit(1 if failures else 0)
