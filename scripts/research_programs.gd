class_name ResearchPrograms
extends RefCounted

const PROGRAMS = {
	"dark_matter": {"starter": "detector", "opening": "The detector is quiet. That is the point: measure every background before claiming an event nobody can explain.", "stages": ["Counting the background", "The rare-event window", "A signal across detectors", "Beyond the known particles"], "flavour": ["Map radioactive backgrounds and detector stability. A convincing null result is still useful physics.", "Calibrate recoil candidates and blind your selection cuts before opening the signal window.", "Use independent channels to distinguish a real signal from a detector artifact.", "The excess survives independent detectors. Now make the case that known backgrounds cannot explain it."],"name": "Dark matter searches", "field": "nuclear", "secondary": "quantum", "description": "Separate rare signals from detector backgrounds, then test them with quantum measurements.", "discovery": "A reproducible dark-matter candidate signal", "paper": "A coherent dark-matter signature across independent detectors"},
	"logical_qubit": {"starter": "quantum", "opening": "One physical qubit forgets quickly. Your task is to arrange many imperfect measurements into one reliable logical memory.", "stages": ["Learning the noise", "Closing the correction loop", "Logical versus physical", "A memory that outlasts its parts"], "flavour": ["Characterize coherence, readout errors and drift with the introductory quantum rig.", "Measure syndrome extraction and show when correction helps instead of adding noise.", "Compare encoded and unencoded memories, with optical readout as an independent check.", "Demonstrate reproducible logical error suppression beyond the lifetime of the physical qubits."],"name": "Fault-tolerant quantum computing", "field": "quantum", "secondary": "optics", "description": "Control optical noise and quantum coherence to demonstrate a stable logical qubit.", "discovery": "A stable logical qubit", "paper": "A logical qubit sustained beyond its physical coherence limit"},
	"superconductivity": {"starter": "vacuum", "opening": "A thin film drops its resistance. A bad contact can do that too. Start with the controls and earn the extraordinary claim.", "stages": ["Trusting the sample", "Mapping the transition", "Independent probes", "A phase that reproduces"], "flavour": ["Measure sample uniformity and contact stability before interpreting a resistance drop.", "Map reproducible transitions across preparations, temperatures and magnetic fields.", "Combine transport and quantum measurements to test whether the phase is truly superconducting.", "Independent samples and probes agree on a new superconducting phase. Publish the full reproducibility protocol."],"name": "Unconventional superconductivity", "field": "materials", "secondary": "quantum", "description": "Connect material structure to quantum behavior and reproduce a new superconducting phase.", "discovery": "A reproducible superconducting phase", "paper": "Independent confirmation of an unconventional superconducting phase"}
}
const TIERS = {"letter": 0, "article": 1, "breakthrough": 2}

static func stages(program: String) -> Array:
	if not PROGRAMS.has(program): return []
	var p = PROGRAMS[program]
	return [
		{"name": "Foundations", "subtitle": p.stages[0], "description": p.flavour[0], "requirements": [{"count": 2}, {"count": 1, "field": p.field}]},
		{"name": "Focused studies", "subtitle": p.stages[1], "description": p.flavour[1], "requirements": [{"count": 5}, {"count": 2, "field": p.field}, {"count": 1, "field": p.field, "tier": 1}]},
		{"name": "Independent evidence", "subtitle": p.stages[2], "description": p.flavour[2], "requirements": [{"count": 8}, {"count": 2, "field": p.field, "mixed": true}, {"count": 1, "field": p.field, "tier": 2}]},
		{"name": "Major discovery", "subtitle": p.stages[3], "description": p.flavour[3], "requirements": [{"count": 10}, {"count": 2, "field": p.field, "tier": 2}, {"count": 1, "goal": program}]}
	]

static func matches(paper: Dictionary, requirement: Dictionary) -> bool:
	if not paper.get("accepted", false): return false
	if TIERS.get(paper.get("kind", ""), -1) < requirement.get("tier", 0): return false
	var fields = [paper.get("field", ""), paper.get("secondary", "")]
	if requirement.has("field") and requirement.field not in fields: return false
	if requirement.get("mixed", false) and paper.get("secondary", "") == "": return false
	if requirement.has("goal") and paper.get("program_goal", "") != requirement.goal: return false
	return true

static func count(history: Array, requirement: Dictionary) -> int:
	var amount = 0
	for paper in history:
		if matches(paper, requirement): amount += 1
	return amount

static func requirement_text(requirement: Dictionary) -> String:
	if requirement.has("goal"): return "Publish the program's final discovery manuscript"
	var parts = PackedStringArray()
	if requirement.get("tier", 0) == 2: parts.append("legendary")
	elif requirement.get("tier", 0) == 1: parts.append("rare or legendary")
	if requirement.get("mixed", false): parts.append("mixed-field")
	if requirement.has("field"): parts.append(LabCatalog.FIELDS[requirement.field].name)
	parts.append("paper" if requirement.count == 1 else "papers")
	return "%d %s" % [requirement.count, " ".join(parts)]

static func level(program: String, history: Array) -> int:
	var completed = 0
	for stage in stages(program):
		for requirement in stage.requirements:
			if count(history, requirement) < requirement.count: return completed
		completed += 1
	return completed
