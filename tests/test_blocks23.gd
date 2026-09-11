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
	sim.new_lab(); sim.autosave_enabled = false; sim.set_process(false)
	for person in sim.staff:
		person.personality = "early"; person.trait = "diligent"
func idle() -> void:
	for person in sim.staff:
		person.rest = 24; person.acquire = 0; person.analyze = 0
func roundtrip() -> Dictionary:
	return JSON.parse_string(JSON.stringify(sim.snapshot()))
func run() -> void:
	sim = Simulation.new(); root.add_child(sim); reset()
	check(sim.supervisees(3).size() == 2 and sim.research_hours(sim.staff[2]) == 12, "Two founding PhDs reserve four Activity hours")
	check(is_equal_approx(sim.phd_productivity(sim.staff[0]), 1), "Founders have opening mentoring coverage")
	check(not sim.assign_supervisor(3, 1) and not sim.assign_supervisor(1, 2), "Only researchers mentor PhDs")
	check(sim.hire("phd"), "Third PhD can be hired")
	check(not sim.assign_supervisor(sim.staff.back().id, 3), "A researcher cannot supervise more than two PhDs")
	check(is_equal_approx(sim.phd_productivity(sim.staff.back()), 0.6), "New unsupervised student receives the productivity penalty")
	check(sim.assign_supervisor(1, -1) and sim.assign_supervisor(4, 3), "Mentor slots can be reassigned")
	check(is_equal_approx(sim.phd_productivity(sim.staff.back()), 0.6), "Assignment alone cannot create mentoring credit")
	reset()
	sim.start_proposal("intro") # Still locked; mentoring must work without a proposal.
	sim.hour = 8
	for i in range(6): sim.advance_hour()
	check(is_equal_approx(sim.staff[0].supervision_today, 2) and is_equal_approx(sim.staff[1].supervision_today, 2), "Mentor spends actual desk time delivering two hours per student")
	check(sim.supervision_remaining(3) == 0 and sim.staff[2].task == "study", "Mentor resumes selected Activity after teaching")
	idle()
	for i in range(34): sim.advance_hour()
	check(is_equal_approx(sim.phd_productivity(sim.staff[0]), 0.6), "Coverage expires after a day with no mentoring")
	reset()
	var person = sim.staff[0]
	var supervised = sim.performance(person, "analyze", "optics")
	sim.assign_supervisor(1, -1)
	check(is_equal_approx(sim.performance(person, "analyze", "optics"), supervised * 0.6), "Supervision affects real work multipliers")
	sim.dismiss(3)
	check(sim.staff[1].supervisor == -1 and sim.phd_productivity(sim.staff[1]) == 0.6, "Dismissal clears mentoring references immediately")
	reset(); idle()
	var instrument = sim.experiments[0]
	instrument.condition = 90
	for i in range(24): sim.advance_hour()
	check(instrument.condition == 90, "Idle instruments do not decay at midnight")
	person = sim.staff[0]
	person.rest = 0; person.acquire = 24; person.x = 2; person.y = 4
	sim.hour = 8
	sim.advance_hour()
	check(instrument.operating_hours > 0 and is_equal_approx(90 - instrument.condition, instrument.operating_hours * 0.1), "PhD wear follows productive operating time, including capacity limits")
	var condition = instrument.condition
	person.focus = "quantum"
	sim.advance_hour()
	check(instrument.condition == condition, "No matching work produces no wear")
	person.focus = "any"; person.role = "researcher"; person.supervisor = -1
	var old_hours = instrument.operating_hours
	sim.advance_hour()
	check(is_equal_approx(condition - instrument.condition, (instrument.operating_hours - old_hours) * 0.04), "Researcher wear is lower per operating hour")
	var repairs = []
	for role in ["researcher", "technician"]:
		reset(); idle(); person = sim.staff[2]
		person.role = role; person.rest = 0; person.duty = "maintain"; person.x = 2; person.y = 4
		for student in sim.staff.slice(0, 2): student.supervisor = -1
		sim.experiments[0].condition = 50
		sim.advance_hour(); repairs.append(sim.experiments[0].condition - 50)
	check(is_equal_approx(repairs[1] / repairs[0], 1.2 / 0.45), "Technician maintenance has a distinct productive advantage")
	check(sim.service_cost({"condition": 40}) > sim.service_cost({"condition": 90}), "Repair cost scales with actual damage")
	reset()
	check(sim.Layout.dimensions() == Vector2i(28, 20), "Starting map has 28 by 20 cells")
	check(sim.can_place("desk", Vector2i(20, 3)) and sim.can_place("bed", Vector2i(22, 3)) and sim.can_place("optics", Vector2i(22, 15)), "Furniture and experiments can cross former room boundaries")
	check(not sim.can_place("desk", sim.Layout.ENTRANCE), "Entrance cannot be blocked")
	check(not sim.can_place("bed", Vector2i(14, 17)), "Bed must leave a walkable foot inside the perimeter")
	sim.experiments[0].condition = 73; sim.experiments[0].modules = ["accelerator"]
	var cash = sim.funds
	check(sim.relocate_object("optics", 1, Vector2i(22, 15)), "Instrument relocation succeeds")
	check(sim.funds == cash and sim.experiments[0].condition == 73 and sim.experiments[0].modules == ["accelerator"], "Relocation preserves money, condition and modules")
	check(not sim.relocate_object("optics", 1, Vector2i(2, 9)) and sim.experiments[0].x == 22, "Rejected relocation is atomic")
	sim.funds = 0
	check(sim.relocate_object("desk", 1, Vector2i(20, 3)) and sim.staff[0].desk == 1, "Moving is free and retains ownership")
	check(sim.valid_save(roundtrip()), "Relocated open-plan layout survives JSON validation")
	reset(); person = sim.staff[0]
	var time_left = sim.travel(person, Vector2i(20, 7))
	check(time_left > 0.5 and person.x == 20 and person.travel_hours < 0.5, "Eleven tiles take less than half an hour; remaining time is usable")
	var programs_report = []
	for program in sim.Programs.PROGRAMS:
		reset(); sim.choose_program(program)
		var spec = sim.Programs.PROGRAMS[program]
		check(sim.experiments[0].kind == spec.starter and sim.experiments[0].introductory, "Program receives its introductory instrument: " + program)
		check(sim.expenses() == 460 and sim.capacity() == 18 and sim.funds == 30000, "Opening economy is equivalent: " + program)
		check(sim.staff.all(func(member): return member.specialty == spec.field) and sim.ideas[0].field == spec.field, "Staff and ideas follow the program: " + program)
		check(sim.Programs.stages(program)[0].requirements[1].field == spec.field, "Foundations requires the selected science, not optics universally")
		check(sim.Programs.stages(program)[0].description != sim.Programs.stages(program)[1].description, "Stage-specific scientific flavour is present")
		if spec.starter in ["detector", "quantum"]:
			check(not sim.equipment_unlocked(spec.starter), "Starter does not unlock advanced construction")
		var first_evidence = 0
		for i in range(15 * 24):
			if sim.analyzed_by_field[spec.field] >= 18: first_evidence = sim.day; break
			sim.advance_hour()
		check(first_evidence > 0 and first_evidence < 12, "All branches reach first-letter evidence promptly")
		programs_report.append({"program": program, "first_evidence_day": first_evidence, "walking_hours": sim.staff[0].travel_hours})
	reset(); sim.prestige = 100; sim.lifetime_impact = 100; sim.funds = 200000
	for key in ["precision", "module_slots", "mixed_mode", "advanced_instruments"]: sim.unlock_upgrade(key)
	check(not sim.unlock_upgrade("campus_planning") and not sim.expand_lab(), "Early labs cannot buy endgame land")
	sim.program_level = 3
	check(sim.unlock_upgrade("campus_planning"), "Third milestone unlocks campus technology")
	cash = sim.funds
	check(sim.expand_lab() and sim.expansion_level == 1 and sim.funds == cash - 45000, "First wing purchased exactly once")
	check(sim.Layout.dimensions(1) == Vector2i(34, 24) and sim.can_place("optics", Vector2i(29, 19)), "Purchased wing contains usable floor")
	check(not sim.expand_lab(), "Second wing requires major discovery")
	sim.program_level = 4
	check(sim.expand_lab() and not sim.expand_lab(), "Second wing unlocks and cannot be repurchased")
	check(sim.place_experiment("optics", Vector2i(36, 18)), "Second wing supports equipment placement")
	check(sim.valid_save(roundtrip()), "Expanded save validates after JSON roundtrip")
	var path = "res://tests/.test_blocks23.json"
	check(sim.save_lab(false, path), "Expanded game saves")
	reset()
	check(sim.load_lab(path) and sim.expansion_level == 2 and sim.experiments.back().x == 36, "Expanded floor and furniture reload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var corrupt = roundtrip(); corrupt.expansion_level = 0
	check(not sim.valid_save(corrupt), "Saves cannot hide furniture inside an unpurchased wing")
	reset()
	var legacy = roundtrip(); legacy.version = 5; legacy.erase("expansion_level"); legacy.erase("layout_style")
	for member in legacy.staff + legacy.candidates.values():
		for key in ["supervisor", "supervision_coverage", "supervision_today", "travel_hours", "work_hours", "wait_hours"]: member.erase(key)
	var file = FileAccess.open(path, FileAccess.WRITE); file.store_string(JSON.stringify(legacy)); file.close()
	check(sim.load_lab(path) and sim.expansion_level == 0 and sim.supervisees(3).size() == 2, "Legacy v5 loads and receives sensible initial supervision")
	check(sim.tutorial_step().text.contains("Space"), "Migrated untouched save still has an actionable introduction")
	sim.raw_by_field.optics = 1
	check(sim.tutorial_step().text.contains("Optics"), "Legacy optical lab guide follows its available data source")
	check(sim.save_lab(false, path) and FileAccess.file_exists(path + ".v5-backup"), "First upgraded write keeps the old v5 file as a backup")
	check(JSON.parse_string(FileAccess.get_file_as_string(path + ".v5-backup")).version == 5, "Backup preserves the original schema")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".v5-backup"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	corrupt = roundtrip(); corrupt.staff[0].supervisor = 999
	check(not sim.valid_save(corrupt), "Dangling mentor references rejected")
	corrupt = roundtrip(); corrupt.staff[0].supervision_today = 20
	check(not sim.valid_save(corrupt), "Unlimited mentoring credit rejected")
	print("Program openings: ", JSON.stringify(programs_report))
	print("Blocks 2/3 checks: %d passed, %d failed." % [checks - failures, failures])
	quit(1 if failures else 0)
