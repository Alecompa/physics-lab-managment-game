extends SceneTree
var checks = 0
var failures = 0
var game: Control
var sim: LabSimulation
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + message)
func settle() -> void:
	for i in range(10): await process_frame
func reset() -> void:
	sim.new_lab(); sim.set_process(false); sim.autosave_enabled = false
	for p in sim.staff:
		p.rest = 24; p.acquire = 0; p.analyze = 0; p.supervisor = -1
	var researcher = sim.staff[2]
	researcher.rest = 0; researcher.personality = "early"; researcher.energy = 100
	researcher.x = 2; researcher.y = 12
	sim.hour = 12; sim.first_submission_day = 1
func drafts() -> void:
	sim.analyzed_by_field.optics = 100
	check(sim.start_paper(sim.ideas[0].id), "Paper starts with the selected priority")
	check(sim.start_proposal("intro"), "Grant starts with the selected priority")
func capture(name: String) -> void:
	await settle()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
		root.get_texture().get_image().save_png("res://docs/screenshots/" + name + ".png")
func run() -> void:
	root.size = Vector2i(1440, 960)
	game = load("res://scenes/main.tscn").instantiate(); game.test_mode = true
	root.add_child(game); sim = game.sim
	reset(); drafts()
	var p = sim.staff[2]
	sim.advance_hour()
	check(sim.active_paper.progress > 0 and sim.proposal_for("intro").progress == 0, "Default researcher works on paper first")
	p.duty = "proposal"
	var paper_progress = sim.active_paper.progress
	sim.advance_hour()
	check(sim.proposal_for("intro").progress > 0 and sim.active_paper.progress == paper_progress, "Grant priority diverts real Activity hours")
	sim.proposal_for("intro").progress = sim.proposal_for("intro").work - 0.01
	sim.advance_hour()
	check(sim.proposal_for("intro").stage == "ready" and sim.active_paper.progress > paper_progress, "Unused grant-completion time immediately goes to paper")
	check(sim.proposal_for("intro").submitted == 0, "Finished draft still needs player submission")
	sim.active_paper.progress = sim.active_paper.work - 0.01
	var study = sim.study_points
	sim.advance_hour()
	check(sim.active_paper.stage == "review" and sim.study_points > study, "Unused paper-completion time goes to study")
	reset(); sim.start_proposal("intro"); sim.advance_hour()
	check(sim.proposal_for("intro").progress > 0, "Auto researcher works on grant when no paper exists")
	p = sim.staff[2]; p.duty = "study"
	var grant_progress = sim.proposal_for("intro").progress
	sim.advance_hour()
	check(sim.proposal_for("intro").progress == grant_progress and sim.study_points > 0, "Explicit study remains available")
	reset(); sim.start_proposal("intro"); sim.staff[2].rest = 24
	p = sim.staff[0]; p.rest = 0; p.duty = "auto"; p.x = 2; p.y = 10
	sim.advance_hour()
	check(sim.proposal_for("intro").progress == 0, "PhDs never write grants through fallback")
	reset(); sim.start_proposal("intro"); p = sim.staff[2]
	p.duty = "proposal"; sim.staff[0].supervisor = 3; sim.staff[0].supervision_today = 1.9
	sim.advance_hour()
	check(is_equal_approx(sim.staff[0].supervision_today, 2) and sim.proposal_for("intro").progress > 0, "Mentoring finishes before grant and leaves remaining Activity usable")
	reset(); sim.start_proposal("intro"); sim.desks.clear(); sim.rebuild_navigation(); sim.advance_hour()
	check(sim.proposal_for("intro").progress == 0, "Automatic grants still need a reachable desk")
	reset()
	for level in range(3):
		sim.expansion_level = level; sim.rebuild_navigation()
		for desk in sim.desks: check(not sim.navigation.get_point_path(sim.Layout.ENTRANCE, sim.Layout.chair(desk)).is_empty(), "Every desk is reachable through room doors")
		for bed in sim.beds: check(not sim.navigation.get_point_path(sim.Layout.ENTRANCE, sim.Layout.bed_access(bed)).is_empty(), "Every bed is reachable through room doors")
		check(sim.valid_save(JSON.parse_string(JSON.stringify(sim.snapshot()))), "Room plan roundtrips at each expansion")
	check(sim.Layout.wall(Vector2i(3, 6)) and not sim.Layout.wall(Vector2i(8, 6)), "Walls and doorway agree with navigation")
	check(not sim.can_place("optics", Vector2i(6, 5)), "Instruments cannot straddle a wall")
	check(not sim.can_place("desk", Vector2i(5, 1)), "Decorative shelves occupy their drawn cells")
	check(sim.can_place("optics", Vector2i(22, 15)), "Common room retains flexible free space")
	reset(); sim.layout_style = "open"; sim.rebuild_navigation()
	check(sim.relocate_object("optics", 1, Vector2i(6, 5)), "Legacy floor can contain an instrument across new wall coordinates")
	var legacy = JSON.parse_string(JSON.stringify(sim.snapshot())); legacy.version = 6; legacy.erase("layout_style")
	var path = "res://tests/.iteration7-save.json"
	var f = FileAccess.open(path, FileAccess.WRITE); f.store_string(JSON.stringify(legacy)); f.close()
	reset()
	check(sim.load_lab(path) and sim.layout_style == "open" and sim.experiments[0].x == 6, "Legacy save keeps floor and object positions")
	check(sim.save_lab(false, path) and FileAccess.file_exists(path + ".v6-backup"), "Original v6 receives a backup")
	check(sim.load_lab(path) and sim.layout_style == "open", "Converted legacy plan persists after reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path)); DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".v6-backup"))
	sim.new_lab(); sim.autosave_enabled = false; sim.choose_program("dark_matter"); game._enter_lab(); await settle()
	await capture("iteration7-map")
	game.selected_person = 3; game._set_page("People"); await settle()
	var choices = game.sidebar.find_children("*", "OptionButton", true, false)
	var priority = choices[0]
	check(priority.get_item_text(0) == "Papers first" and priority.tooltip_text.contains("switches automatically"), "Priority UI is concise and explains fallback on hover")
	priority.item_selected.emit(priority.item_count - 1)
	check(sim.staff[2].duty == "proposal", "People UI sets grant priority")
	await capture("iteration7-people")
	game.selected_person = 1; game._set_page("People")
	var trait_hint = false
	for label in game.sidebar.find_children("*", "Label", true, false):
		if label.tooltip_text.contains("Specialty:"): trait_hint = label.mouse_filter != Control.MOUSE_FILTER_IGNORE
	check(trait_hint, "PhD trait hover text can receive the mouse")
	game._set_page("Grants"); await capture("iteration7-grants")
	check(game.audio.music.stream.get_length() > 30 and game.audio.music.stream.loop, "Local soundtrack is imported and looping")
	for stream in game.audio.EFFECTS.values(): check(stream.get_length() > 0, "Each interaction/goal sound decodes")
	game._display_settings(); await settle()
	var music = game.modal_box.find_child("MusicVolume", true, false)
	var effects = game.modal_box.find_child("EffectsVolume", true, false)
	music.value = 0; effects.value = 70
	check(game.audio.music_volume == 0 and is_equal_approx(game.audio.effects_volume, 0.7), "Music and effects levels are independent; zero mutes")
	game.display_settings_path = "res://tests/.iteration7-settings.cfg"; game.test_mode = false
	game._save_display_settings(); game.audio.music_volume = 1; game.audio.effects_volume = 1; game._load_display_settings()
	check(game.audio.music_volume == 0 and is_equal_approx(game.audio.effects_volume, 0.7), "Audio preferences survive a reload")
	game.test_mode = true; DirAccess.remove_absolute(ProjectSettings.globalize_path(game.display_settings_path))
	await capture("iteration7-settings")
	game._close_modal()
	game.audio.silent = false; game.audio.music_volume = 0; game.audio.effects_volume = 0.001; game.audio.apply_levels()
	game.audio.play_effect("goal")
	check(game.audio.music.playing and game.audio.voices[0].playing, "Audio players start on a goal cue")
	game._show_pause_menu()
	check(game.audio.music.playing and game.audio.started, "Pause menu keeps the same music player active")
	game.audio.music.stop()
	for voice in game.audio.voices: voice.stop()
	game.audio.silent = true; game._drop_menu()
	for resolution in [Vector2i(1280, 800), Vector2i(1920, 1080)]:
		root.size = resolution; game._set_ui_scale(1.3); game._set_page("People"); await settle()
		check(game.side_panel.get_global_rect().end.x <= root.get_visible_rect().size.x + 1, "Shortened staff UI fits at 130%")
		await capture("iteration7-%dx%d" % [resolution.x, resolution.y])
	print("Iteration 7 checks: %d passed, %d failed." % [checks - failures, failures])
	quit(1 if failures else 0)
