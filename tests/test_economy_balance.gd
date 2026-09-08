extends SceneTree
const Simulation = preload("res://scripts/simulation.gd")
var sim: LabSimulation
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + message)
func reset(seed_value: int = 42) -> void:
	sim.new_lab(); sim.set_process(false); sim.autosave_enabled = false
	sim.rng.seed = seed_value; sim.grant_rng.seed = seed_value
	for person in sim.staff:
		person.trait = "diligent"; person.personality = "early"
	sim.choose_program("dark_matter")
func acknowledge() -> void:
	if not sim.pending_result.is_empty(): sim.acknowledge_result()
	if not sim.pending_milestone.is_empty(): sim.acknowledge_milestone()
	while not sim.grant_results.is_empty(): sim.acknowledge_grant()
func run() -> void:
	sim = Simulation.new(); root.add_child(sim)
	# Reproduce the reported day-59 save without reading or overwriting personal files.
	reset()
	sim.hire("researcher"); sim.place_experiment("vacuum", Vector2i(12, 1))
	sim.day = 59; sim.hour = 0; sim.funds = 3893.166666666
	sim.published = 2; sim.lifetime_impact = 4; sim.prestige = 4; sim.program_level = 1
	sim.first_submission_day = 16; sim.last_publication_day = 48; sim.intro_grant_completed = true
	sim.grant_history = [{"kind": "intro", "day": 41, "accepted": true, "amount": 12000.0, "chance": 1.0, "hours": 48.0, "revision": false}, {"kind": "startup", "day": 1, "accepted": true, "amount": 24000.0, "chance": 1.0, "hours": 0.0, "revision": false}]
	sim.total_grants = 36000
	sim.grant_next_days.small = 61
	sim.start_proposal("small")
	var proposal = sim.proposal_for("small")
	proposal.work = 96.0; proposal.stage = "ready"; proposal.progress = proposal.work
	var old_deadline = 81
	check(sim.runway() < old_deadline - sim.day, "Old milestone calendar would outlast the reported cash reserve")
	var path = "res://tests/.balance_legacy_v5.json"
	check(sim.save_lab(false, path), "Early v5 save can be retained")
	var original_cash = sim.funds
	sim.new_lab()
	check(sim.load_lab(path), "Early v5 saves still load after balance revision")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(sim.funds == original_cash and sim.total_grants == 36000, "Loading does not silently award the new startup difference")
	check(sim.next_grant_day("small") == 1 and sim.grant_submit_reason("small") == "", "Introductory call penalty removed from existing first small draft")
	check(sim.runway() > 5, "Reported reserve can cover the immediate small review")
	check(sim.submit_proposal("small"), "Reported proposal can be submitted immediately after loading")
	proposal = sim.proposal_for("small"); proposal.review_roll = 0
	for i in range(5 * 24): sim.advance_hour()
	check(not sim.bankrupt and sim.grant_results.size() == 1 and sim.grant_results[0].amount == 14000, "Successful second grant arrives before insolvency in reported scenario")
	print("Reported scenario replay: day %d, $%.0f funds, %.1f days runway." % [sim.day, sim.funds, sim.runway()])
	# An ordinary used call must retain its cooldown on load.
	acknowledge()
	check(sim.save_lab(false, path), "Used ordinary call saves")
	var next_day = sim.next_grant_day("small")
	sim.new_lab(); sim.load_lab(path)
	check(sim.next_grant_day("small") == next_day and next_day > sim.grant_history[0].day - 5, "Migration cannot reset a consumed ordinary call")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var reports = []
	for kind in ["optics", "vacuum"]:
		for seed_value in range(1, 13): reports.append(moderate_run(seed_value, kind, false))
	# Deliberately decline the first competitive grant: expansion must remain a risk.
	for seed_value in range(1, 7): reports.append(moderate_run(seed_value, "vacuum", true))
	var survived = reports.filter(func(report): return not report.bankrupt).size()
	print("Moderate expansion: %d/%d runs survived day 75." % [survived, reports.size()])
	print("Detailed moderate outcomes written to docs/playtest-block1.json")
	var report_file = FileAccess.open("res://docs/playtest-block1.json", FileAccess.WRITE)
	report_file.store_string(JSON.stringify({"engine": "Godot 4.7.2", "scope": "Automated 75-day scenarios, not full-program or human validation", "starting_grant": 30000, "small_award": 14000, "small_period": 20, "small_hours": 64, "recovery_policy": "Prioritize rejected small revisions; assign both researchers to proposals below 20 days runway", "expansion_day": 25, "intro_draft_not_before_day": 30, "survived": survived, "runs": reports}, "\t"))
	report_file.close()
	check(survived >= 24, "At least 80% of controlled moderate-expansion runs survive the first hour")
	print("Balance checks: %d passed, %d failed." % [checks - failures, failures])
	quit(1 if failures else 0)

func moderate_run(seed_value: int, kind: String, force_first_rejection: bool) -> Dictionary:
	reset(seed_value)
	var expanded = false
	var forced = false
	var first_award_day = 0
	var ordinary_decision_day = 0
	var minimum = sim.runway()
	var ready_wait_hours = 0
	var peak_wait = 0
	var milestone_days = []
	for i in range(75 * 24):
		if sim.bankrupt or sim.day > 75: break
		if not sim.pending_milestone.is_empty(): milestone_days.append({"stage": sim.program_level, "day": sim.day})
		if not sim.grant_results.is_empty():
			for result in sim.grant_results:
				if result.kind != "intro" and ordinary_decision_day == 0: ordinary_decision_day = sim.day
		acknowledge()
		if sim.intro_grant_completed and first_award_day == 0: first_award_day = sim.day
		if sim.day >= 25 and not expanded:
			check(sim.hire("researcher"), "Moderate researcher affordable")
			var researcher = sim.staff.back()
			researcher.specialty = "optics"; researcher.trait = "diligent"; researcher.personality = "early"
			check(sim.place_bed(Vector2i(14, 9)), "Moderate expansion includes a bed")
			check(sim.place_desk(Vector2i(5, 11)), "Moderate expansion includes a desk")
			sim.set_assignment(researcher.id, "desk", sim.desks.back().id)
			check(sim.place_experiment(kind, Vector2i(12, 1)), "Moderate instrument affordable")
			expanded = true
		if sim.writing_proposal().is_empty():
			var rejected_small = not sim.proposal_for("small").is_empty() and sim.proposal_for("small").stage == "rejected"
			var choices = ["intro"] if not sim.intro_grant_completed else ["small", "standard"] if ordinary_decision_day == 0 or rejected_small else ["standard", "small"]
			for choice in choices:
				if choice == "intro" and sim.day < 30: continue
				if sim.grant_start_reason(choice) == "" and sim.day >= sim.next_grant_day(choice) - 8:
					sim.start_proposal(choice, 0.25 if choice != "intro" else 0.0); break
		var waiting = false
		for proposal in sim.proposals:
			if proposal.stage == "ready" and sim.day < sim.next_grant_day(proposal.kind): waiting = true
			if sim.grant_submit_reason(proposal.kind) == "":
				sim.submit_proposal(proposal.kind)
				if proposal.kind != "intro" and force_first_rejection and not forced:
					proposal.review_roll = 1; forced = true
		ready_wait_hours = ready_wait_hours + 1 if waiting else 0
		peak_wait = maxi(peak_wait, ready_wait_hours)
		var duty = "proposal" if not sim.writing_proposal().is_empty() else "auto"
		if sim.staff[2].duty != duty: sim.set_assignment(3, "duty", duty)
		if expanded:
			var second_duty = duty if sim.runway() < 20 else "auto"
			if sim.staff[3].duty != second_duty: sim.set_assignment(sim.staff[3].id, "duty", second_duty)
		if sim.active_paper.is_empty():
			var started = false
			for idea in sim.ideas:
				if idea.field == "optics" and sim.can_start_paper(idea.id): sim.start_paper(idea.id); started = true; break
			if not started and sim.study_points >= 8:
				if sim.ideas.size() >= 6: sim.discard_idea(sim.ideas.back().id)
				sim.think_idea()
		sim.advance_hour()
		minimum = minf(minimum, sim.runway())
	check(ordinary_decision_day > 0, "Moderate expansion receives second grant decision before cash runs out")
	check(sim.valid_save(sim.snapshot()), "Moderate scenario save validates")
	return {"seed": seed_value, "instrument": kind, "forced_first_rejection": force_first_rejection, "bankrupt": sim.bankrupt, "day": sim.day, "funds": roundi(sim.funds), "minimum_runway": snappedf(minimum, 0.1), "intro_award_day": first_award_day, "first_ordinary_decision_day": ordinary_decision_day, "longest_ready_wait_hours": peak_wait, "papers": sim.published, "proposal_hours": roundi(sim.total_proposal_hours), "milestones": milestone_days, "grants": sim.grant_history.duplicate(true)}
