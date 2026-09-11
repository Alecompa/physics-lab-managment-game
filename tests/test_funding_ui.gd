extends SceneTree
var game: Control
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + message)
func settle() -> void:
	for i in range(10): await process_frame
func press(parent: Node, text: String) -> bool:
	for button in parent.find_children("*", "Button", true, false):
		if button.text == text and not button.disabled: button.pressed.emit(); return true
	return false
func capture(name: String) -> void:
	await settle()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
		root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png")
func text_in(parent: Node, text: String) -> bool:
	for label in parent.find_children("*", "Label", true, false):
		if label.text.contains(text): return true
	return false
func run() -> void:
	root.size = Vector2i(1440, 960)
	game = load("res://scenes/main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.sim.set_process(false)
	await settle()
	game._enter_lab()
	game._set_page("Grants")
	await settle()
	check(game.tabs.has("Grants") and game.page == "Grants", "Fourth tab opens grants")
	check(game.budget_label.text.contains("$460") and game.budget_label.text.contains("88 days"), "Budget strip shows costs and conservative runway")
	check(game.impact_label.text == "0 / 0", "Available and lifetime impact visible separately")
	check(game.tutorial_row.visible and game.tutorial_label.text.contains("Space"), "Guide gives explicit first action")
	check(text_in(game.sidebar, "Submit your first paper"), "Introductory grant explains its prerequisite")
	await capture("funding-v5-start")
	game._set_page("Papers")
	check(not text_in(game.sidebar, "$2,600") and text_in(game.sidebar, "+2 impact"), "Paper cards no longer promise funding")
	game.selected_person = 1; game._set_page("People")
	var activities = game.sidebar.find_children("*", "OptionButton", true, false)[0]
	var has_proposal = false
	for i in range(activities.item_count): has_proposal = has_proposal or activities.get_item_metadata(i) == "proposal"
	check(not has_proposal, "PhD activity selector has no proposal option")
	game.selected_person = 3; game._rebuild_sidebar()
	activities = game.sidebar.find_children("*", "OptionButton", true, false)[0]
	has_proposal = false
	for i in range(activities.item_count): has_proposal = has_proposal or activities.get_item_metadata(i) == "proposal"
	check(has_proposal, "Researcher can choose proposal activity")
	game.sim.first_submission_day = 1
	game._set_page("Grants")
	check(press(game.sidebar, "Start proposal"), "Intro draft starts from grant tab")
	await settle()
	var priority = game.sidebar.find_children("*", "OptionButton", true, false)[0]
	priority.item_selected.emit(1)
	check(game.sim.staff[2].duty == "proposal", "Grant tab assigns researcher priority")
	var proposal = game.sim.proposal_for("intro")
	proposal.progress = proposal.work; proposal.stage = "ready"
	game._rebuild_sidebar()
	check(press(game.sidebar, "Submit proposal"), "Ready proposal submits through UI")
	await settle()
	check(text_in(game.sidebar, "Review:"), "Review countdown is displayed")
	await capture("funding-v5-review")
	proposal.review_left = 1
	game.sim.advance_hour()
	await settle()
	check(game.modal_title.text == "Grant awarded" and game.pause_button.disabled, "Grant decision opens feedback and blocks resume")
	await capture("funding-v5-award")
	check(press(game.modal_box, "Review grants"), "Grant feedback can return to management")
	await settle()
	check(game.sim.grant_results.is_empty() and game.sim.paused and game.page == "Grants", "Acknowledgement stays paused and clears pending award")
	game._grant_history()
	check(text_in(game.modal_box, "Startup grant") and text_in(game.modal_box, "Introductory grant"), "History separates startup and proposal funding")
	game._close_modal()
	game._tutorial_window()
	check(text_in(game.modal_box, "Keep publishing"), "Tutorial recognizes completed grant")
	check(press(game.modal_box, "Hide guide"), "Guide can be hidden")
	check(not game.sim.tutorial_enabled and not game.tutorial_row.visible, "Guide preference applies immediately")
	game._close_modal()
	check(game._purchase_preview(1800, 200).contains("$200/day"), "Purchase preview includes future operating costs")
	game.sim.program_level = 1
	game.sim.day = 41
	game.sim.start_proposal("standard")
	proposal = game.sim.proposal_for("standard")
	proposal.progress = proposal.work; proposal.stage = "ready"
	game.sim.submit_proposal("standard")
	proposal.review_left = 1; proposal.review_roll = 1
	game.sim.advance_hour()
	await settle()
	check(game.modal_title.text == "Grant decision" and text_in(game.modal_box, "50% work retained"), "Rejection explains retained work")
	game._close_modal(); await settle()
	game._set_page("Grants")
	check(text_in(game.sidebar, "Revision credit: 96"), "Rejected proposal shows revision credit")
	await capture("funding-v5-revision")
	# Simultaneous paper and grant results: paper feedback must stay first.
	game.sim.new_lab(); game.sim.first_submission_day = 1
	game.sim.analyzed_by_field.optics = 100
	game.sim.start_paper(game.sim.ideas[0].id)
	game.sim.active_paper.stage = "review"; game.sim.active_paper.review_left = 1; game.sim.active_paper.review_roll = 0
	game.sim.start_proposal("intro")
	proposal = game.sim.proposal_for("intro")
	proposal.progress = proposal.work; proposal.stage = "ready"
	game.sim.submit_proposal("intro"); proposal.review_left = 1
	game.sim.advance_hour(); await settle()
	check(game.modal_title.text == "Published" and game.sim.grant_results.size() == 1, "Paper decision has priority over simultaneous grant")
	press(game.modal_box, "Close"); await settle()
	check(game.modal_title.text == "Grant awarded", "Queued grant feedback follows paper acknowledgement")
	press(game.modal_box, "Resume simulation"); await settle()
	check(not game.sim.feedback_blocked() and not game.sim.paused, "All feedback can be acknowledged without deadlock")
	game.sim.paused = true
	# Display scale and window size matrix; overflow must remain scrollable.
	for resolution in [Vector2i(1280, 800), Vector2i(1440, 960), Vector2i(1920, 1080)]:
		root.size = resolution
		for scale_value in [1.0, 1.15, 1.3]:
			game._set_ui_scale(scale_value)
			game._set_page("Grants")
			await settle()
			check(is_equal_approx(root.content_scale_factor, scale_value), "UI scale applies at %s / %s" % [resolution, scale_value])
			check(game.game_ui.get_child(0) is ScrollContainer, "Zoomed game retains scroll access")
			if game.get_viewport_rect().size.x < 1250:
				check(game.compact_toolbar.visible and not game.layout_left.visible, "Narrow zoom presents management without cropping its right edge")
				check(game.side_panel.get_global_rect().end.x <= game.get_viewport_rect().size.x + 1, "Compact management fits the logical viewport")
			game._display_settings(); await settle()
			check(press(game.modal_box, "Reset to 100%"), "Display reset stays reachable")
			await settle(); game._close_modal()
			game._set_ui_scale(scale_value)
			await capture("funding-v5-%dx%d-%d" % [resolution.x, resolution.y, roundi(scale_value * 100)])
	root.size = Vector2i(1440, 960)
	game._set_ui_scale(1.0)
	game._display_settings(); await settle()
	await capture("funding-v5-display")
	game._close_modal()
	if DisplayServer.get_name() != "headless":
		var original = root.mode
		game._toggle_fullscreen(); await settle()
		check(root.mode == Window.MODE_FULLSCREEN, "Fullscreen can be enabled")
		game._toggle_fullscreen(); await settle()
		check(root.mode == Window.MODE_WINDOWED, "Fullscreen can return to windowed")
		root.mode = original
	game.display_settings_path = "res://tests/.display_test.cfg"
	game.test_mode = false
	game._set_ui_scale(1.15)
	root.content_scale_factor = 1.0; game.ui_scale = 1.0
	game._load_display_settings()
	check(is_equal_approx(game.ui_scale, 1.15) and is_equal_approx(root.content_scale_factor, 1.15), "Display scale survives a preferences reload")
	game.test_mode = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.display_settings_path))
	game._set_ui_scale(1.0)
	game.sim.funds = 1
	game.sim.advance_hour(); await settle()
	check(game.modal_title.text == "Laboratory insolvent" and game.pause_button.disabled, "Insolvency UI explains stopped simulation")
	await capture("funding-v5-insolvency")
	print("Funding UI checks: %d passed, %d failed." % [checks - failures, failures])
	quit(1 if failures else 0)
