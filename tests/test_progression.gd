extends SceneTree
const Simulation = preload("res://scripts/simulation.gd")
var sim: LabSimulation
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + message)
func reset() -> void:
	sim.new_lab()
	sim.set_process(false)
	sim.autosave_enabled = false
	sim.rng.seed = 123
func finish_paper(field: String, kind: String, secondary: String = "", goal: String = "", accepted: bool = true) -> void:
	sim.acknowledge_result()
	sim.acknowledge_milestone()
	sim.ideas.clear()
	var idea = sim.add_idea(field, kind)
	idea.secondary = secondary
	idea.program_goal = goal
	for key in sim.FIELDS: sim.analyzed_by_field[key] = 1000
	if kind != "letter": sim.lifetime_impact = maxi(7, sim.lifetime_impact)
	check(sim.start_paper(idea.id, 1.5), "Program paper can start: " + field + " " + kind)
	if sim.active_paper.is_empty(): return
	sim.active_paper.stage = "review"
	sim.active_paper.review_roll = 0 if accepted else 1
	sim.active_paper.review_left = 1
	sim.advance_hour()
	check(sim.pending_result.get("accepted", false) == accepted, "Referee decision has expected outcome")
func run() -> void:
	sim = Simulation.new()
	root.add_child(sim)
	reset()
	check(sim.valid_save(sim.snapshot()), "Fresh v5 state validates")
	var older = sim.snapshot()
	older.version = 3
	check(not sim.valid_save(older), "Prior save version rejected for fresh iteration")
	for person in sim.staff:
		check(not sim.reachable_bed(person).is_empty(), "Every founding person has a reachable bed")
	var person = sim.staff[0]
	sim.set_assignment(person.id, "bed", sim.staff[1].bed)
	check(person.bed == 1, "Two people cannot own the same bed")
	person.rest = 24; person.acquire = 0; person.analyze = 0
	person.energy = 20; person.x = 13; person.y = 11
	sim.advance_hour()
	check(is_equal_approx(person.energy, 27), "Assigned bed restores seven energy per stationary hour")
	sim.set_assignment(person.id, "bed", -1)
	person.energy = 20
	var seat = sim.Layout.REST_SEATS[int(person.id) % sim.Layout.REST_SEATS.size()]
	person.x = seat.x; person.y = seat.y; person.destination = []; person.route = []
	sim.advance_hour()
	check(is_equal_approx(person.energy, 22.8) and person.status.contains("40%"), "Bedless resting restores only 40% and explains it")
	check(sim.place_bed(Vector2i(14, 9)), "Another bed can be physically placed")
	check(person.bed == 4, "New bed goes to a person without one")
	check(not sim.place_bed(Vector2i(15, 10)), "Invalid sleeping-area placement rejected")
	sim.remove_bed(4)
	check(person.bed == -1, "Removing a bed clears its owner")
	reset()
	sim.prestige = 100; sim.lifetime_impact = 100; sim.funds = 100000
	check(not sim.upgrade_experiment(1), "Instrument level 2 gated by technology")
	check(not sim.unlock_upgrade("advanced_instruments"), "Cannot skip instrumentation prerequisites")
	check(sim.unlock_upgrade("precision") and sim.upgrade_experiment(1), "Precision technology permits purchased level 2")
	check(not sim.upgrade_experiment(1), "Level 3 has its own technology gate")
	check(sim.unlock_upgrade("module_slots"), "Module slots unlock after precision")
	var bench = sim.experiments[0]
	var before = sim.capacity_for(bench)
	check(sim.install_module(1, "accelerator") and is_equal_approx(sim.capacity_for(bench), before * 1.25), "Accelerator raises actual capacity by 25%")
	check(not sim.install_module(1, "accelerator"), "Duplicate modules cannot be installed")
	check(not sim.install_module(1, "nuclear"), "Data channel modules require mixed-mode technology")
	check(sim.unlock_upgrade("mixed_mode") and sim.install_module(1, "nuclear"), "Additional field module installs after unlock")
	check(sim.output_mix(bench) == {"optics": 0.75, "quantum": 0.25, "nuclear": 0.2}, "Module adds yield without removing native data")
	check(sim.module_reason(1, "materials").contains("occupied"), "Only two module slots available")
	for i in range(8): sim.advance_hour()
	check(sim.raw_by_field.nuclear > 0 and is_equal_approx(sim.raw_by_field.nuclear / sim.raw_by_field.optics, 0.2 / 0.75), "Actual acquisition produces the extra channel")
	check(sim.remove_module(1, "nuclear") and not sim.output_mix(bench).has("nuclear"), "Removing module removes its output effect")
	check(sim.unlock_upgrade("advanced_instruments") and sim.upgrade_experiment(1), "Advanced technology permits purchased level 3")
	check(not sim.upgrade_desk(1), "Desk upgrade gated by technology")
	check(sim.unlock_upgrade("desk_systems") and sim.upgrade_desk(1), "Workstation technology permits desk level 2")
	check(sim.unlock_upgrade("compute") and sim.upgrade_desk(1), "Analysis cluster permits desk level 3")
	# Compare actual work at level 1 and 3 without changes in traits or energy.
	person = sim.staff[0]
	person.rest = 0; person.acquire = 0; person.analyze = 24; person.personality = "early"
	person.x = 2; person.y = 10; person.energy = 100; person.destination = []; person.route = []
	for other in sim.staff.slice(1): other.rest = 24; other.acquire = 0; other.analyze = 0
	sim.raw_by_field.optics = 100; sim.analyzed_by_field.optics = 0; sim.hour = 8
	sim.desks[0].level = 1
	sim.advance_hour()
	var analysis = sim.analyzed_by_field.optics
	person.energy = 100; sim.hour = 8; sim.analyzed_by_field.optics = 0; sim.desks[0].level = 3
	sim.advance_hour()
	check(is_equal_approx(sim.analyzed_by_field.optics, analysis * 1.3), "Level 3 desk provides 30% actual productivity")
	for program in sim.Programs.PROGRAMS:
		reset()
		check(sim.choose_program(program) and not sim.choose_program("logical_qubit"), "One permanent program per run")
		var spec = sim.Programs.PROGRAMS[program]
		check(not sim.develop_discovery(), "Final discovery locked before milestones")
		finish_paper("optics", "letter")
		finish_paper("optics", "letter")
		check(sim.program_level == 1 and not sim.pending_milestone.is_empty(), "Foundations reached with starter papers")
		var hour = sim.hour
		sim.acknowledge_result(); sim.paused = false; sim._process(10); sim.advance_hour()
		check(sim.hour == hour, "Pending milestone stops direct and frame-driven time")
		finish_paper(spec.field, "article")
		finish_paper(spec.field, "article")
		finish_paper("optics", "letter")
		check(sim.program_level == 2, "Focused studies counts earlier publications cumulatively")
		finish_paper(spec.field, "article", spec.secondary)
		finish_paper(spec.field, "article", spec.secondary)
		finish_paper(spec.field, "breakthrough")
		check(sim.program_level == 3, "Mixed-field and legendary evidence completes third stage")
		check(sim.history[1].secondary == spec.secondary, "Publication archive retains secondary field")
		sim.acknowledge_result(); sim.acknowledge_milestone(); sim.ideas.clear(); sim.study_points = 12
		check(sim.develop_discovery(), "Final manuscript obtained without a random roll")
		var final_idea = sim.ideas.back()
		check(final_idea.program_goal == program and final_idea.secondary == spec.secondary and sim.study_points == 0, "Final manuscript carries exact program and mixed-field requirements")
		for field in sim.FIELDS: sim.analyzed_by_field[field] = 1000
		check(sim.start_paper(final_idea.id), "Final discovery manuscript can start")
		sim.cancel_paper()
		check(sim.ideas.back().program_goal == program, "Shelving keeps final manuscript identity")
		finish_paper(spec.field, "breakthrough", spec.secondary, program, false)
		check(sim.program_level == 3 and sim.ideas.back().program_goal == program, "Rejected final paper grants no progress and retains retry identity")
		finish_paper("optics", "letter")
		finish_paper(spec.field, "breakthrough", spec.secondary, program)
		check(sim.program_level == 4 and sim.pending_milestone.victory, "Program reaches its final discovery through accepted publications")
		check(sim.valid_save(sim.snapshot()), "Completed program and pending victory form a valid save")
		var path = "res://tests/.test_program.json"
		check(sim.save_lab(false, path), "Completed program saves")
		sim.new_lab()
		check(sim.load_lab(path) and sim.program_level == 4 and sim.pending_milestone.victory and sim.research_program == program, "Save restores program, evidence and unacknowledged victory")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		sim.acknowledge_result(); sim.acknowledge_milestone()
		sim.advance_hour()
		check(sim.pending_milestone.is_empty(), "Completed milestone does not repeat")
	reset()
	for i in range(45): finish_paper("optics", "letter")
	check(sim.history.size() == 45, "Publication archive retains more than forty papers")
	print("Progression checks: %d passed, %d failed." % [checks - failures, failures])
	quit(1 if failures else 0)
