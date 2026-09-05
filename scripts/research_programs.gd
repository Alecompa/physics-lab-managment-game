class_name ResearchPrograms
extends RefCounted

const PROGRAMS = {
	"dark_matter": {"name": "Dark matter searches", "field": "nuclear", "secondary": "quantum", "description": "Separate rare signals from detector backgrounds, then test them with quantum measurements.", "discovery": "A reproducible dark-matter candidate signal", "paper": "A coherent dark-matter signature across independent detectors"},
	"logical_qubit": {"name": "Fault-tolerant quantum computing", "field": "quantum", "secondary": "optics", "description": "Control optical noise and quantum coherence to demonstrate a stable logical qubit.", "discovery": "A stable logical qubit", "paper": "A logical qubit sustained beyond its physical coherence limit"},
	"superconductivity": {"name": "Unconventional superconductivity", "field": "materials", "secondary": "quantum", "description": "Connect material structure to quantum behavior and reproduce a new superconducting phase.", "discovery": "A reproducible superconducting phase", "paper": "Independent confirmation of an unconventional superconducting phase"}
}
const TIERS = {"letter": 0, "article": 1, "breakthrough": 2}

static func stages(program: String) -> Array:
	if not PROGRAMS.has(program): return []
	var p = PROGRAMS[program]
	return [
		{"name": "Foundations", "description": "Establish a publication record with the starting lab.", "requirements": [{"count": 2}, {"count": 1, "field": "optics"}]},
		{"name": "Focused studies", "description": "Build a body of work in the program's principal field.", "requirements": [{"count": 5}, {"count": 2, "field": p.field}, {"count": 1, "field": p.field, "tier": 1}]},
		{"name": "Independent evidence", "description": "Connect disciplines and establish a high-impact result.", "requirements": [{"count": 8}, {"count": 2, "field": p.field, "mixed": true}, {"count": 1, "field": p.field, "tier": 2}]},
		{"name": "Major discovery", "description": p.discovery, "requirements": [{"count": 10}, {"count": 2, "field": p.field, "tier": 2}, {"count": 1, "goal": program}]}
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
