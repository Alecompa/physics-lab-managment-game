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
	await capture("main-menu-v4")
	check(press(game.menu_layer, "New laboratory"), "Main menu offers new lab")
	await settle()
	game.modal_box.find_children("*", "LineEdit", true, false)[0].text = "Physics Laboratory"
	check(press(game.modal_box, "Open the laboratory"), "New laboratory starts from menu")
	await settle()
	check(game.session_active and game.sim.paused and game.sim.lab_name == "Physics Laboratory", "Named new lab starts paused")
	check(fits(game.sidebar_scroll) and fits(game.floor_view), "Lab and sidebar fit window")
	check(game.floor_view.size.x > 900, "Lab has most of the window width")
	check(game.data_labels.size() == 4, "All four fields have counters")
	check(game.clock_label.text.contains("08:00"), "Clock displays hour")
	await capture("prototype-v4")
	# Test visual signal lifecycles separately from window-system pointer position.
	var button_rect = game.pause_button.get_global_rect()
	game.pause_button.mouse_entered.emit()
	await create_timer(0.22).timeout
	check(game.pause_button.hover_amount > 0.9, "Hover signal animates the button glow")
	check(game.pause_button.get_global_rect() == button_rect, "Button animation preserves layout and hit area")
	game.pause_button.button_down.emit()
	await create_timer(0.15).timeout
	check(game.pause_button.press_amount > 0.9, "Press feedback animates while held")
	game.pause_button.button_up.emit()
	await create_timer(0.15).timeout
	check(game.pause_button.press_amount < 0.1, "Button release clears press feedback")
	game.pause_button.mouse_exited.emit()
	await create_timer(0.22).timeout
	check(game.pause_button.hover_amount < 0.1, "Hover glow settles after pointer exit")
	# Route the click through the viewport, not the action callback.
	var click_down = InputEventMouseButton.new()
	click_down.button_index = MOUSE_BUTTON_LEFT
	click_down.pressed = true
	click_down.position = button_rect.get_center()
	root.push_input(click_down)
	var click_up = click_down.duplicate()
	click_up.pressed = false
	root.push_input(click_up)
	check(not game.sim.paused, "Animated button receives clicks and resumes the lab")
	game.sim.paused = true
	game._refresh()
	# Exercise real frame interpolation along corridors, with production and study visible.
	game.sim.paused = false
	game.sim.speed = 4
	for i in range(24):
		game.sim.advance_hour()
		await create_timer(0.53).timeout
		for person in game.sim.staff:
			var position = game.floor_view.person_positions[person.id]
			check(not game.sim.navigation.is_point_solid(Vector2i(position.round())), "Rendered walking stays on navigable floor")
		if i == 5: await capture("lab-active-v4")
		if i == 20: await capture("lab-rest-v4")
	check(game.sim.raw_data + game.sim.analyzed_data > 0 and game.sim.study_points > 0, "Rendered activity produces data and study")
	game.sim.new_lab()
	game._enter_lab()
	game._set_page("People")
	await capture("people-v4")
	game.floor_view.person_clicked.emit(2)
	await settle()
	check(game.page == "People" and game.selected_person == 2, "Clicking person opens their detail")
	var inputs = game.sidebar.find_children("*", "SpinBox", true, false)
	check(inputs.size() == 3, "Selected person's three routine controls appear")
	inputs[0].value = 10
	check(game.sim.staff[1].rest == 10, "Hours control changes simulated routine")
	var choices = game.sidebar.find_children("*", "OptionButton", true, false)
	check(choices.size() == 5, "Activity, field, experiment, desk and bed can be assigned")
	choices[1].select(1)
	choices[1].item_selected.emit(1)
	check(game.sim.staff[1].focus == "nuclear", "Field selector changes actual focus")
	await capture("routine-v4")
	game._recruitment()
	await settle()
	check(modal_fits(), "Recruitment modal fits")
	await capture("recruitment-v4")
	var hire_buttons = game.modal_box.find_children("*", "Button", true, false)
	hire_buttons[1].pressed.emit()
	check(game.sim.staff.size() == 4, "Hiring from preview adds staff")
	game.sim.new_lab()
	game._enter_lab()
	game.sim.prestige = 20
	game.sim.lifetime_impact = 20
	game._development()
	await capture("development-v4")
	check(modal_fits(), "Development tree is a separate fitting window")
	game._close_modal()
	game._set_page("Build")
	game.build_kind = "desk"
	game._floor_clicked(Vector2i(5, 11))
	check(game.sim.desks.size() == 4 and game.selected_kind == "desk", "Desk placement creates inspectable physical desk")
	game.build_kind = "vacuum"
	game._floor_clicked(Vector2i(12, 1))
	check(game.sim.experiments.size() == 2, "Experiment placement uses laboratory room")
	await capture("equipment-v4")
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
	await capture("papers-v4")
	check(press(game.sidebar, "Start manuscript"), "Eligible paper can start")
	check(game.sim.active_paper.committed.optics == 36, "Starting spends chosen typed evidence")
	game.sim.active_paper.stage = "review"
	game.sim.active_paper.review_left = 1
	game.sim.active_paper.review_roll = 0
	game.sim.advance_hour()
	await settle()
	check(is_instance_valid(game.modal_layer) and game.sim.paused and modal_fits(), "Publication pauses and presents fitting modal")
	check(game.modal_title.text.contains("Published"), "Accepted review gets publication feedback")
	await capture("publication-result-v4")
	game._close_modal()
	check(game.sim.pending_result.is_empty() and game.sim.paused, "Closing decision acknowledges without resuming")
	var idea = game.sim.add_idea("quantum", "breakthrough")
	game._discovery(idea)
	for i in range(35): await process_frame
	check(modal_fits() and game.sim.paused, "Legendary reveal fits and pauses")
	await capture("legendary-v4")
	game._close_modal()
	for i in range(24 * 30): game.sim.advance_hour()
	game._statistics()
	await settle()
	check(game.chart.samples.size() >= 30 and modal_fits(), "Graph displays recorded daily resources")
	press(game.modal_box, "Evidence")
	game.chart.hovered = 10
	await capture("statistics-v4")
	game._close_modal()
	game._show_pause_menu()
	check(game.sim.paused and game.menu_mode == "pause", "Pause menu stops simulation")
	await capture("pause-menu-v4")
	check(press(game.menu_layer, "Save laboratory"), "Pause menu opens save chooser")
	await settle()
	check(modal_fits(), "Five-slot chooser fits")
	await capture("save-menu-v4")
	check(press(game.modal_box, "Save here"), "Save chooser writes chosen slot")
	check(FileAccess.file_exists(game.sim.slot_path(1)), "Manual save file exists")
	game._load_menu()
	await settle()
	check(modal_fits(), "Load menu fits")
	await capture("load-menu-v4")
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
	await capture("save-menu-full-v4")
	game._close_modal()
	game._load_menu()
	await settle()
	check(modal_fits(), "Full load chooser scrolls within window")
	game._close_modal()
	for slot in range(1, 6): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.sim.slot_path(slot)))
	# Browsing windows preserve running time and expose a stable clock toolbar.
	game.sim.paused = false
	var clock_position = game.pause_button.global_position
	game.sim.day = 999
	game.sim.hour = 23
	game._refresh()
	await settle()
	check(game.pause_button.global_position.is_equal_approx(clock_position), "Clock and day changes cannot shift time controls")
	game._notebook_history()
	await settle()
	check(not game.sim.paused and modal_fits(), "Notebook browsing keeps simulation running")
	await capture("notebook-v4")
	game._close_modal()
	game._statistics()
	check(not game.sim.paused, "Statistics does not auto-pause")
	game._close_modal()
	game._recruitment()
	check(not game.sim.paused, "Recruitment does not auto-pause")
	game._close_modal()
	game._development()
	check(not game.sim.paused, "Development does not auto-pause")
	game._close_modal()
	game.sim.choose_program("dark_matter")
	game._program_window()
	await settle()
	check(not game.sim.paused and modal_fits(), "Program has a separate fitting window without auto-pause")
	await capture("program-v4")
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = game.pause_button.get_global_rect().get_center()
	click.pressed = true
	root.push_input(click)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click)
	await settle()
	check(game.sim.paused, "Visible toolbar receives pause clicks above an open window")
	game.sim.paused = false
	game._close_modal()
	game._publication_archive()
	await settle()
	check(modal_fits(), "Publication archive fits")
	await capture("archive-v4")
	game._close_modal()
	game.sim.unlocked.append_array(["precision", "module_slots", "mixed_mode"])
	game.sim.funds = 50000
	game.sim.install_module(1, "accelerator")
	game.sim.install_module(1, "materials")
	game._set_page("Build")
	game._floor_clicked(Vector2i(2, 2))
	await capture("instrument-upgrade-v4")
	game._module_window(1)
	await settle()
	check(not game.sim.paused and modal_fits(), "Module installation window fits and preserves running time")
	await capture("modules-v4")
	game._close_modal()
	game.sim.paused = true
	game._statistics()
	game._close_modal()
	check(game.sim.paused, "Browsing preserves an existing manual pause")
	# A publication can interrupt a browsing window and queue one milestone window.
	game.sim.new_lab()
	game.sim.choose_program("dark_matter")
	game._enter_lab()
	game.sim.analyzed_by_field.optics = 100
	game.sim.start_paper(1)
	game.sim.active_paper.stage = "review"; game.sim.active_paper.review_left = 1; game.sim.active_paper.review_roll = 0
	game.sim.advance_hour()
	game._close_modal()
	var second = game.sim.add_idea("optics", "letter")
	game.sim.start_paper(second.id)
	game.sim.active_paper.stage = "review"; game.sim.active_paper.review_left = 1; game.sim.active_paper.review_roll = 0
	game._statistics()
	game.sim.advance_hour()
	await settle()
	check(game.modal_title.text == "Published" and game.sim.program_level == 1, "Publication interrupts browsing before milestone feedback")
	game._development()
	await settle()
	check(game.modal_title.text == "Program milestone", "Queued milestone follows acknowledged publication")
	check(game.get_children().filter(func(child): return child.has_meta("management_window")).size() == 1, "Feedback cannot leave orphaned overlapping windows")
	await capture("milestone-v4")
	game._resume_from_feedback()
	check(not game.sim.paused and game.sim.pending_milestone.is_empty(), "Continue resumes after acknowledging milestone")
	# Render the completed-program state using archive fixtures; model tests exercise the real review path.
	for i in range(8):
		var paper = game.sim.history[0].duplicate(true)
		paper.paper_id = 100 + i
		paper.field = "nuclear"; paper.secondary = "quantum"; paper.kind = "breakthrough"
		paper.program_goal = "dark_matter" if i == 7 else ""
		paper.title = "A coherent dark-matter signature across independent detectors"
		game.sim.history.append(paper)
	game.sim.update_program()
	game._milestone()
	await settle()
	check(modal_fits() and game.modal_title.text == "Major discovery", "Victory feedback fits and identifies the final discovery")
	await capture("victory-v4")
	game._resume_from_feedback()
	check(not game.sim.paused, "The laboratory can continue after winning")
	game._help()
	await settle()
	check(modal_fits(), "Help fits window")
	await capture("guide-v4")
	game._close_modal()
	# A furnished fixture renders all instrument families and attached modules.
	game.sim.new_lab()
	game.sim.funds = 90000
	game.sim.unlocked = game.sim.UPGRADES.keys()
	game.sim.choose_program("dark_matter")
	for item in [["vacuum", Vector2i(5, 2)], ["detector", Vector2i(13, 2)], ["quantum", Vector2i(16, 2)]]:
		check(game.sim.place_experiment(item[0], item[1]), "Equipment visual fixture has a valid physical footprint")
	game.sim.install_module(game.sim.experiments[0].id, "accelerator")
	game.sim.install_module(game.sim.experiments[0].id, "quantum")
	game.sim.lab_name = "Physics Laboratory"
	game._enter_lab()
	for i in range(game.sim.staff.size()):
		var member = game.sim.staff[i]
		member.x = 4 + i * 5; member.y = 6
		member.working = true; member.task = "acquire"
		member.target_id = game.sim.experiments[i].id
	game.floor_view.reset_positions()
	game.floor_view.animation_time = 1.5
	game._refresh()
	await capture("lab-neon-equipped")
	var full_size = root.size
	root.size = Vector2i(1200, 800)
	await settle()
	check(game.game_ui.get_global_rect().end.x <= root.get_visible_rect().end.x + 1, "HUD remains inside the scaled minimum window")
	await capture("lab-neon-small")
	root.size = full_size
	await settle()
	game._return_to_main()
	check(not game.session_active and game.menu_mode == "main", "Return to main menu leaves session")
	print("UI checks: %d passed, %d failed." % [checks - failures, failures])
	quit(1 if failures else 0)
