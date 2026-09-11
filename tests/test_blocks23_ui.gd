extends SceneTree
var game: Control
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + message)
func settle() -> void:
	for i in range(8): await process_frame
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
func run() -> void:
	root.size = Vector2i(1440, 960)
	game = load("res://scenes/main.tscn").instantiate(); game.test_mode = true
	root.add_child(game); game.sim.set_process(false)
	game.sim.choose_program("dark_matter"); game._enter_lab()
	await settle()
	var floor_view = game.floor_view
	check(floor_view.clip_contents, "Map cannot draw over the management panel")
	var anchor = floor_view.size * 0.5
	floor_view.update_camera()
	var before = (anchor - floor_view.floor_origin) / floor_view.tile
	floor_view.zoom_at(1.8, anchor)
	check(((anchor - floor_view.floor_origin) / floor_view.tile).distance_to(before) < 0.01, "Zoom preserves the cell under the cursor")
	floor_view.pan += Vector2(60, 30); floor_view.update_camera()
	var point = floor_view.center(Vector2(5, 5))
	check(floor_view.cell_at(point) == Vector2i(5, 5), "Picking remains correct after zoom and pan")
	floor_view.reset_camera(); floor_view.update_camera()
	check(floor_view.zoom == 1 and floor_view.pan == Vector2.ZERO, "Fit restores the camera")
	game.selected_id = 1; game.selected_kind = "detector"; game._set_page("Build")
	check(press(game.sidebar, "Move / free"), "Inspector exposes relocation")
	var count = game.sim.experiments.size()
	game._floor_clicked(Vector2i(22, 15))
	check(game.sim.experiments.size() == count and game.sim.experiments[0].x == 22 and game.moving_id == -1, "Placement click moves rather than duplicating the instrument")
	check(game.sim.funds == 30000, "UI relocation is free")
	await capture("blocks23-flexible-map")
	game.selected_person = 1; game._set_page("People")
	var choices = game.sidebar.find_children("*", "OptionButton", true, false)
	var mentor = choices.back()
	check(mentor.item_count == 2 and mentor.get_item_metadata(mentor.selected) == 3, "PhD inspector exposes assigned mentor")
	mentor.item_selected.emit(0)
	await settle()
	check(game.sim.staff[0].supervisor == -1, "Supervisor selection changes the model")
	await capture("blocks23-supervision")
	game.sim.program_level = 3; game.sim.prestige = 100; game.sim.lifetime_impact = 100; game.sim.funds = 200000
	for key in ["precision", "module_slots", "mixed_mode", "advanced_instruments", "campus_planning"]: game.sim.unlock_upgrade(key)
	game._set_page("Build")
	check(press(game.sidebar, "Open wing / $45,000"), "First wing is purchasable from Build")
	check(game.sim.expansion_level == 1, "Wing purchase updates the model")
	game.sim.program_level = 4; game.sim.expand_lab(); game.floor_view.reset_camera()
	game.sim.place_experiment("optics", Vector2i(36, 18)); game._rebuild_sidebar()
	await capture("blocks23-expanded-map")
	game._program_window(); await capture("blocks23-program")
	game._close_modal()
	for resolution in [Vector2i(1280, 800), Vector2i(1920, 1080)]:
		root.size = resolution
		for scale_value in [1.0, 1.3]:
			game._set_ui_scale(scale_value); game._set_page("People")
			await settle()
			check(game.side_panel.get_global_rect().end.x <= root.get_visible_rect().size.x + 1, "Management panel fits at %s / %s" % [resolution, scale_value])
			await capture("blocks23-%dx%d-%d" % [resolution.x, resolution.y, scale_value * 100])
	root.size = Vector2i(1280, 800); game._set_ui_scale(1.3)
	game._new_game_menu(); await capture("blocks23-new-program")
	check(game.modal_title.text == "New laboratory", "Program selection still opens with detailed flavour")
	print("Blocks 2/3 UI checks: %d passed, %d failed." % [checks - failures, failures])
	quit(1 if failures else 0)
