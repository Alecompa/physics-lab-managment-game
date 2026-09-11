extends SceneTree
const Simulation = preload("res://scripts/simulation.gd")
var sim: LabSimulation
var failures = 0
var checks = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + message)
func setup(seed_value: int) -> void:
	sim.new_lab(); sim.autosave_enabled = false; sim.set_process(false)
	sim.rng.seed = seed_value; sim.grant_rng.seed = seed_value
	for person in sim.staff:
		person.trait = ["meticulous", "practical", "diligent"][int(person.id) - 1]; person.personality = "early"
func opening(program: String, seed_value: int) -> Dictionary:
	setup(seed_value); sim.choose_program(program)
	var first_publication = 0
	var first_standard = 0
	var first_milestone = 0
	var first_intro = 0
	var field = sim.Programs.PROGRAMS[program].field
	for i in range(90 * 24):
		if sim.bankrupt or sim.day > 90 or first_standard > 0: break
		if sim.published > 0 and first_publication == 0: first_publication = sim.day
		if sim.program_level > 0 and first_milestone == 0: first_milestone = sim.day
		if sim.intro_grant_completed and first_intro == 0: first_intro = sim.day
		if not sim.pending_result.is_empty(): sim.acknowledge_result()
		if not sim.pending_milestone.is_empty(): sim.acknowledge_milestone()
		while not sim.grant_results.is_empty():
			if sim.grant_results[0].kind == "standard": first_standard = sim.day
			sim.acknowledge_grant()
		if sim.writing_proposal().is_empty():
			for kind in ["intro", "standard", "small"]:
				if sim.grant_start_reason(kind) == "" and sim.day >= sim.next_grant_day(kind) - 8:
					sim.start_proposal(kind); break
		for proposal in sim.proposals:
			if sim.grant_submit_reason(proposal.kind) == "": sim.submit_proposal(proposal.kind)
		sim.set_assignment(3, "duty", "proposal" if not sim.writing_proposal().is_empty() else "auto")
		if sim.active_paper.is_empty():
			var started = false
			for idea in sim.ideas:
				if idea.field == field and sim.can_start_paper(idea.id): sim.start_paper(idea.id); started = true; break
			if not started and sim.study_points >= 8:
				if sim.ideas.size() == 6: sim.discard_idea(sim.ideas.back().id)
				sim.think_idea()
		if sim.experiments[0].condition < 65 and sim.funds > 1000: sim.service_experiment(1)
		sim.advance_hour()
	check(not sim.bankrupt and first_publication > 0 and first_milestone > 0 and first_standard > 0, "Science and first standard review reachable: %s seed %d" % [program, seed_value])
	return {"program": program, "seed": seed_value, "first_publication": first_publication, "milestone_1": first_milestone, "intro_award": first_intro, "first_standard_decision": first_standard, "bankrupt": sim.bankrupt, "funds": roundi(sim.funds)}
func team_benchmark(phds: int, researchers: int) -> Dictionary:
	setup(42)
	sim.staff.clear()
	for i in range(phds + researchers):
		var person = sim.make_person(i + 1, "phd" if i < phds else "researcher")
		person.specialty = "optics"; person.personality = "early"; person.trait = "diligent"
		if phds == 0: person.acquire = 6; person.analyze = 6
		sim.staff.append(person)
	sim.desks.clear(); sim.beds.clear(); sim.experiments.clear(); sim.funds = 100000
	for i in range(phds + researchers):
		sim.desks.append({"id": i + 1, "kind": "desk", "x": 1 + i * 3, "y": 9})
		sim.beds.append({"id": i + 1, "kind": "bed", "x": 1 + i * 3, "y": 14})
		sim.staff[i].desk = i + 1; sim.staff[i].bed = i + 1
	for i in range(4): sim.experiments.append({"id": i + 1, "kind": "optics", "x": 2 + i * 5, "y": 2, "level": 1, "condition": 100.0})
	sim.rebuild_navigation()
	for i in range(phds):
		for mentor in sim.staff:
			if mentor.role == "researcher" and sim.assign_supervisor(i + 1, mentor.id): break
	for i in range(30 * 24): sim.advance_hour()
	var wear = 0.0
	for instrument in sim.experiments: wear += 100 - instrument.condition
	return {"phds": phds, "researchers": researchers, "salary_per_day": phds * 100 + researchers * 200, "evidence": snappedf(sim.analyzed_data, 0.1), "study_points": snappedf(sim.study_points, 0.1), "wear_total": snappedf(wear, 0.1), "scope": "30 days, equal salaries, four benches, no papers or grants; researchers collect/analyze when no PhDs are present"}
func run() -> void:
	sim = Simulation.new(); root.add_child(sim)
	var reports = []
	for program in sim.Programs.PROGRAMS:
		for seed_value in range(1, 7): reports.append(opening(program, seed_value))
	for seed_index in range(6):
		for field in ["first_publication", "milestone_1", "intro_award", "first_standard_decision"]:
			check(reports[seed_index][field] == reports[seed_index + 6][field] and reports[seed_index][field] == reports[seed_index + 12][field], "Equivalent branch timing: " + field)
	var teams = [team_benchmark(6, 1), team_benchmark(4, 2), team_benchmark(0, 4)]
	var file = FileAccess.open("res://docs/playtest-blocks23-programs.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope": "Controlled opening and equal-salary production benchmarks, not human or endgame validation", "openings": reports, "teams": teams}, "\t")); file.close()
	print("Program and team checks: %d passed, %d failed." % [checks - failures, failures])
	print("Team benchmarks: ", JSON.stringify(teams))
	quit(1 if failures else 0)
