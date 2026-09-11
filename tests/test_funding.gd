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
	sim.new_lab()
	sim.set_process(false)
	sim.autosave_enabled = false
	sim.rng.seed = seed_value
	sim.grant_rng.seed = seed_value
func ready(kind: String, extra: float = 0.0) -> Dictionary:
	check(sim.start_proposal(kind, extra), "Draft opens for " + kind)
	var proposal = sim.proposal_for(kind)
	proposal.progress = proposal.work
	proposal.stage = "ready"
	return proposal
func drain_feedback() -> void:
	if not sim.pending_result.is_empty(): sim.acknowledge_result()
	if not sim.pending_milestone.is_empty(): sim.acknowledge_milestone()
	while not sim.grant_results.is_empty(): sim.acknowledge_grant()

func run() -> void:
	sim = Simulation.new()
	root.add_child(sim)
	reset()
	check(sim.funds == 30000 and sim.total_grants == 30000, "Startup grant is credited once and included in the funding ledger")
	check(sim.expenses() == 460 and sim.income() == 120, "Starting gross costs 460, university 120")
	check(is_equal_approx(sim.runway(), 30000.0 / 340), "Runway excludes speculative grants")
	var cash = sim.funds
	sim.advance_hour()
	check(is_equal_approx(sim.funds, cash - 340.0 / 24), "Support and expenses accrue each hour")
	check(is_equal_approx(sim.runway(1800, 200), (sim.funds - 1800) / 540), "Recruitment preview includes salary and purchase cost")
	sim.lifetime_impact = 30
	sim.prestige = 30
	check(sim.income() == 240, "University bonus is capped")
	sim.day = 31
	check(sim.income() == 240, "No decay in first 30 days")
	sim.day = 46
	check(sim.income() == 195, "Publication bonus decays gradually")
	sim.day = 61
	check(sim.income() == 150, "Base remains funded when publication bonus reaches its floor")
	sim.unlock_upgrade("precision")
	check(sim.income() == 150, "Spending impact does not cut university support")
	var idea = sim.ideas[0]
	sim.analyzed_by_field.optics = 100
	sim.start_paper(idea.id)
	sim.active_paper.review_roll = 0
	cash = sim.funds
	var grants = sim.total_grants
	sim.resolve_review()
	check(sim.funds == cash and sim.total_grants == grants and not sim.pending_result.has("grant"), "Accepted papers award no money and carry no funding column")
	check(sim.last_publication_day == sim.day and sim.income() == 240, "Accepted paper resets publication decay")
	reset()
	check(not sim.start_proposal("intro"), "Intro cannot start before first submission")
	check(not sim.start_proposal("small") and not sim.start_proposal("standard") and not sim.start_proposal("large"), "Grant gates cannot be skipped")
	sim.first_submission_day = 1
	check(sim.start_proposal("intro"), "Submission alone qualifies for introductory grant")
	sim.set_assignment(1, "duty", "proposal")
	check(sim.staff[0].duty != "proposal", "PhD cannot be assigned proposal activity")
	sim.set_assignment(3, "duty", "proposal")
	var study = sim.study_points
	for i in range(8): sim.advance_hour()
	check(sim.proposal_for("intro").progress > 0 and sim.total_proposal_hours > 0, "Researcher writes proposal in real Activity hours")
	check(sim.study_points == study, "Proposal time does not also generate study")
	var progress = sim.proposal_for("intro").progress
	for desk in sim.desks.duplicate(): sim.remove_desk(desk.id)
	sim.advance_hour()
	check(sim.proposal_for("intro").progress == progress, "Proposal writing requires a physical desk")
	reset()
	sim.first_submission_day = 1
	var proposal = ready("intro")
	check(sim.submit_proposal("intro"), "Completed introductory proposal can be submitted")
	check(not sim.submit_proposal("intro"), "Double submission cannot consume or duplicate a grant")
	check(sim.next_grant_day("small") == 1, "Intro does not consume ordinary small eligibility")
	check(sim.valid_save(sim.snapshot()), "Submitted proposal forms a valid save")
	proposal.review_left = 1
	proposal.review_roll = 1
	sim.advance_hour()
	check(sim.intro_grant_completed and sim.total_grants == 42000, "Intro guaranteed even when random draw would fail")
	check(sim.proposal_for("intro").is_empty() and sim.grant_results.size() == 1, "Award removes proposal and queues feedback")
	var now = [sim.day, sim.hour, sim.funds]
	sim.paused = false
	sim._process(100)
	sim.advance_hour()
	check([sim.day, sim.hour, sim.funds] == now, "Unacknowledged funding result hard-stops time")
	drain_feedback()
	check(not sim.start_proposal("intro"), "Intro cannot be farmed again")
	proposal = ready("small", 0.5)
	sim.grant_next_days.small = 21
	check(not sim.submit_proposal("small"), "A previously used ordinary call still enforces its next date")
	sim.day = 21
	var paper_rng = sim.rng.state
	check(sim.submit_proposal("small"), "Small can submit at next call")
	check(sim.rng.state == paper_rng, "Grant draws do not change paper randomness")
	check(is_equal_approx(proposal.chance, 0.7), "Full preparation reaches 70% small chance at zero impact")
	proposal.review_roll = 1
	proposal.review_left = 1
	cash = sim.total_grants
	sim.advance_hour()
	check(sim.total_grants == cash and proposal.stage == "rejected" and proposal.credit == 48, "Rejection pays nothing and retains half of last proposal hours")
	drain_feedback()
	check(sim.start_proposal("small", 0.5), "Rejected proposal can be revised")
	proposal = sim.proposal_for("small")
	check(proposal.progress == 48 and proposal.revision, "Revision starts with retained work")
	check(is_equal_approx(sim.grant_estimate("small", 0.5, true).chance, 0.75), "Revision adds five points once")
	proposal.stage = "ready"; proposal.progress = proposal.work
	sim.day = 41
	sim.submit_proposal("small")
	proposal.review_roll = 1; proposal.review_left = 1
	sim.advance_hour(); drain_feedback()
	check(proposal.credit == 48, "Repeated rejection never compounds retained credit")
	check(sim.grant_estimate("large", 0.5, true).chance < sim.grant_estimate("small", 0.5, true).chance, "Size affects funding odds")
	sim.lifetime_impact = 500; sim.program_level = 4
	check(sim.grant_estimate("small", 0.5, true).chance == 0.85, "Success capped at 85%")
	sim.grant_next_days.small = 21
	check(sim.next_grant_day("small") == 21 and sim.grant_period("small") == 20, "Milestones never postpone small call eligibility")
	reset()
	sim.program_level = 2
	sim.intro_grant_completed = true
	proposal = ready("standard")
	sim.submit_proposal("standard")
	var large = ready("large")
	sim.submit_proposal("large")
	check(sim.proposals.size() == 2 and sim.writing_proposal().is_empty(), "Different grant sizes can review concurrently")
	proposal.review_roll = 0; proposal.review_left = 1
	large.review_roll = 0; large.review_left = 1
	sim.advance_hour()
	check(sim.grant_results.size() == 2 and sim.total_grants == 134000, "Same-hour decisions queue and pay exactly once")
	now = [sim.day, sim.hour, sim.total_grants]
	sim.advance_hour()
	check([sim.day, sim.hour, sim.total_grants] == now, "Queued results cannot be resolved twice")
	check(sim.valid_save(sim.snapshot()), "Pending simultaneous results can be saved")
	var path = "res://tests/.funding_save.json"
	check(sim.save_lab(false, path), "Funding state saves atomically")
	sim.new_lab()
	check(sim.load_lab(path) and sim.grant_results.size() == 2 and sim.total_grants == 134000, "Loading preserves pending grants and cash without repaying")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	drain_feedback()
	var corrupt = sim.snapshot()
	corrupt.grant_next_days.small = -1
	check(not sim.valid_save(corrupt), "Malformed calendar rejected")
	corrupt = sim.snapshot(); corrupt.grant_history[0].amount = 999999
	check(not sim.valid_save(corrupt), "Malformed award rejected")
	reset()
	sim.first_submission_day = 1
	proposal = ready("intro")
	sim.submit_proposal("intro")
	var draw = proposal.review_roll
	check(sim.save_lab(false, path), "Review saves")
	sim.new_lab()
	var loaded = sim.load_lab(path)
	check(loaded, "In-flight review reloads from JSON numeric fields")
	if loaded: check(sim.proposal_for("intro").review_roll == draw, "Review draw survives save/load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# Preserve the longer introductory reviews from the first v5 builds.
	reset(); sim.first_submission_day = 1
	proposal = ready("intro"); sim.submit_proposal("intro")
	proposal.erase("review_duration"); proposal.review_left = 96
	check(sim.save_lab(false, path) and sim.load_lab(path), "Legacy five-day introductory review stays loadable")
	check(sim.proposal_for("intro").review_duration == 120 and sim.proposal_for("intro").review_left == 96, "Legacy review keeps remaining time and correct progress denominator")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	reset()
	cash = sim.funds
	sim.remove_experiment(1); sim.remove_desk(1); sim.remove_bed(1)
	check(sim.funds == cash, "Dismantling starter furniture produces no third funding source")
	reset()
	sim.funds = 1
	sim.advance_hour()
	check(sim.bankrupt and sim.funds == 0 and sim.rescue_count == 0, "Insolvency stops with no bailout")
	now = [sim.day, sim.hour]
	sim.paused = false; sim._process(100); sim.advance_hour()
	check([sim.day, sim.hour] == now and sim.valid_save(sim.snapshot()), "Insolvency cannot be bypassed and remains saveable")
	var outcomes = []
	for seed_value in range(1, 13):
		outcomes.append(playtest(seed_value, false, false))
		outcomes.append(playtest(seed_value, false, true))
	var aggressive = playtest(42, true, true)
	check(aggressive.bankrupt, "Aggressive unfunded expansion can fail within the first hour")
	print("Prudent 75-day playtests: ", JSON.stringify(outcomes))
	print("Aggressive playtest: ", JSON.stringify(aggressive))
	print("Funding checks: %d passed, %d failed." % [checks - failures, failures])
	quit(1 if failures else 0)

func playtest(seed_value: int, aggressive: bool, force_rejections: bool) -> Dictionary:
	reset(seed_value)
	# Deterministic staff as well as decisions; new_lab intentionally randomizes candidates.
	for person in sim.staff:
		person.trait = ["meticulous", "practical", "diligent"][int(person.id) - 1]
		person.personality = "early"
	sim.choose_program("dark_matter")
	if aggressive:
		sim.hire("researcher"); sim.hire("phd"); sim.hire("phd")
		sim.place_experiment("vacuum", Vector2i(12, 1))
	else:
		sim.upgrade_desk(1) # Locked purchase must have no effect.
		sim.funds -= 3000 # Explicit capital reserve spent in this stress scenario.
	var intro_day = 0
	var minimum = sim.runway()
	var forced = 0
	for i in range(75 * 24):
		if sim.bankrupt or sim.day > 75: break
		drain_feedback()
		if sim.intro_grant_completed and intro_day == 0: intro_day = sim.day
		var drafting = sim.writing_proposal()
		if drafting.is_empty():
			for kind in ["intro", "standard", "small"]:
				if sim.grant_start_reason(kind) == "" and (kind == "intro" or sim.day >= sim.next_grant_day(kind) - 8):
					sim.start_proposal(kind, 0.5 if kind == "small" else 0.25 if kind == "standard" else 0.0)
					break
		for proposal in sim.proposals:
			if sim.grant_submit_reason(proposal.kind) == "":
				sim.submit_proposal(proposal.kind)
				if force_rejections and proposal.kind != "intro" and forced < 2:
					proposal.review_roll = 1
					forced += 1
		sim.set_assignment(3, "duty", "proposal" if not sim.writing_proposal().is_empty() else "auto")
		if sim.active_paper.is_empty():
			var commitment = 1.0 if sim.first_submission_day == 0 else 1.5
			var started = false
			for idea in sim.ideas:
				if idea.field == sim.Programs.PROGRAMS[sim.research_program].field and sim.can_start_paper(idea.id, commitment):
					sim.start_paper(idea.id, commitment); started = true; break
			if not started and sim.study_points >= 8:
				if sim.ideas.size() >= 6: sim.discard_idea(sim.ideas.back().id)
				sim.think_idea()
		sim.advance_hour()
		minimum = minf(minimum, sim.runway())
	if not aggressive:
		check(not sim.bankrupt and sim.day == 76, "Prudent seed %d survives day 75, forced declines %s" % [seed_value, force_rejections])
		check(intro_day > 0 and intro_day <= 22, "Introductory award arrives promptly for seed %d" % seed_value)
		check(sim.published > 0 and sim.total_proposal_hours > 0, "Science and funding both progress")
		check(sim.valid_save(sim.snapshot()), "Playtested economy remains saveable")
	return {"seed": seed_value, "forced": forced, "day": sim.day, "intro_day": intro_day, "papers": sim.published, "funds": roundi(sim.funds), "minimum_runway": snappedf(minimum, 0.1), "proposal_hours": roundi(sim.total_proposal_hours), "bankrupt": sim.bankrupt}
