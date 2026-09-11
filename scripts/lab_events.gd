class_name LabEvents
extends RefCounted
## Flavor uses its own RNG and cannot change resources or publication draws.

const LINES = {
	"supervise": ["{name} asks which control would make the result unconvincing. The student adds it to tomorrow's run.", "{name} and a PhD reconstruct yesterday's calibration from the lab notebook.", "A short discussion with {name} saves an afternoon of fitting the wrong model."],
	"acquire": ["{name} labels a cable 'do not unplug'. It was already unplugged.", "{name} asks the {bench} to behave. For once, it seems to listen.", "A very small measurement gets a very large sigh from {name}.", "{name} straightens the cables, then photographs them as evidence.", "{name} has named the {bench} 'Please'.", "The {bench} hums in B-flat. {name} insists that is useful information."],
	"analyze": ["{name} finds a beautiful trend. It was the row numbers.", "{name} gives a suspicious outlier a second chance.", "A spreadsheet called 'final_final_really' appears on {name}'s desk.", "{name} celebrates a clean fit with a very restrained fist pump.", "{name} discovers yesterday's mystery was a unit conversion.", "The error bars are getting smaller. {name}'s coffee is getting colder."],
	"write": ["{name} deletes 'clearly' from the manuscript. The sentence improves.", "{name} spends ten minutes negotiating with a figure caption.", "The paper now contains one fewer 'however', thanks to {name}.", "{name} calls a result 'interesting'. Everyone knows what that means.", "{name} finally gets all the references to use the same font."],
	"study": ["{name} follows a footnote into three more papers.", "{name} borrows a book and returns with a new question.", "The whiteboard says 'simple proof'. {name} has used the entire whiteboard.", "{name} discovers that a paper from 1978 already noticed the problem.", "{name} explains an idea to a plant. The plant is an excellent listener."],
	"rest": ["{name} has strong opinions about the common-room biscuits.", "{name} is winning an argument with the coffee machine.", "A quiet minute. Even {name}'s laptop seems relieved.", "{name} brings a mug marked 'control sample' to the common room.", "{name} starts a conversation about anything except physics. It lasts four minutes."],
	"maintain": ["{name} finds the missing screw. It was holding the spare screws.", "{name} fixes a rattle that everyone had started calling normal.", "The maintenance notebook gains a small, triumphant tick from {name}.", "{name} produces the exact adapter nobody knew the lab owned."]
}
const TIRED = ["{name} has read the same sentence three times. A rest block would help.", "{name} reaches for a cold, empty mug. Energy is running low.", "{name}'s notes are getting shorter. They need a proper break."]
const WORN = ["The {bench} has developed an unconvincing rattle. Its condition is below 55%.", "{name} leaves a service note on the {bench}. Its capacity is falling with wear.", "A calibration check on the {bench} ends with 'please service this'."]
const SPECIALIST = ["{name} recognizes the {field} signature before the plot finishes drawing.", "This is {name}'s kind of {field} problem. The notes suddenly get very precise.", "{name} spots a familiar {field} pattern and quietly saves everyone some time."]

static func choose(sim: Node, random: RandomNumberGenerator, recent: Array) -> Dictionary:
	var options: Array = []
	for person in sim.staff:
		var field = person.get("last_field", "")
		var experiment = sim.experiment_by_id(person.get("target_id", -1))
		var bench = sim.EQUIPMENT[experiment.kind].name.to_lower() if not experiment.is_empty() else "instrument"
		if person.energy < 30: append_lines(options, TIRED, "tired", person, bench, field)
		if not experiment.is_empty() and experiment.condition < 55: append_lines(options, WORN, "wear", person, bench, field)
		if person.get("working", false) and field == person.specialty and person.task in ["acquire", "analyze"]:
			append_lines(options, SPECIALIST, "specialist", person, bench, sim.FIELDS[field].name.to_lower())
		if person.get("working", false) and LINES.has(person.task): append_lines(options, LINES[person.task], person.task, person, bench, field)
	if sim.research_program != "":
		var spec = sim.Programs.PROGRAMS[sim.research_program]
		options.append({"key": "program_" + sim.research_program + str(sim.program_level), "message": spec.flavour[mini(sim.program_level, 3)], "category": "program"})
	var fresh: Array = []
	for option in options:
		if option.key not in recent: fresh.append(option)
	if fresh.is_empty():
		fresh = options.filter(func(option): return recent.is_empty() or option.key != recent.back())
	if fresh.is_empty(): return {}
	return fresh[random.randi_range(0, fresh.size() - 1)]

static func append_lines(options: Array, lines: Array, category: String, person: Dictionary, bench: String, field: String) -> void:
	for index in range(lines.size()):
		options.append({"key": category + str(index), "message": lines[index].replace("{name}", person.name.split(" ")[0]).replace("{bench}", bench).replace("{field}", field), "category": category})
