class_name LabCatalog
extends RefCounted

const FIELDS = {
	"nuclear": {"name": "Nuclear", "color": "c8ab79"},
	"quantum": {"name": "Quantum", "color": "b0a5c8"},
	"materials": {"name": "Materials", "color": "94acbc"},
	"optics": {"name": "Optics", "color": "91b8ad"}
}
const EQUIPMENT = {
	"optics": {"name": "Optical bench", "short": "OPT", "cost": 2400.0, "capacity": 18.0, "upkeep": 12.0, "prestige": 0, "unlock": "", "field": "optics", "secondary": "quantum", "color": "91b8ad", "description": "Interference measurements. Upgraded benches can also collect quantum data."},
	"vacuum": {"name": "Materials chamber", "short": "MAT", "cost": 4800.0, "capacity": 24.0, "upkeep": 20.0, "prestige": 0, "unlock": "", "field": "materials", "secondary": "optics", "color": "94acbc", "description": "Thin films and surface measurements. Adds optics data after mixed-mode upgrades."},
	"detector": {"name": "Particle detector", "short": "NUC", "cost": 8200.0, "capacity": 33.0, "upkeep": 30.0, "prestige": 0, "unlock": "nuclear_lab", "field": "nuclear", "secondary": "materials", "color": "c8ab79", "description": "Rare-event detection. Spend impact in Development to unlock construction."},
	"quantum": {"name": "Quantum rig", "short": "QNT", "cost": 14500.0, "capacity": 45.0, "upkeep": 44.0, "prestige": 0, "unlock": "quantum_lab", "field": "quantum", "secondary": "nuclear", "color": "b0a5c8", "description": "Coherence measurements. Upgraded rigs can also probe nuclear spin."}
}
const ROLES = {
	"phd": {"name": "PhD student", "cost": 900.0, "salary": 18.0, "description": "Collects and analyzes data; can also write or study."},
	"researcher": {"name": "Researcher", "cost": 1800.0, "salary": 32.0, "description": "Writes papers and studies new ideas; can collect or analyze too."},
	"technician": {"name": "Technician", "cost": 1200.0, "salary": 22.0, "description": "Services individual experiments; can help with data work."}
}
const JOURNALS = {
	"letter": {"name": "Research letter", "tag": "FOCUSED RESULT", "data": 18.0, "work": 10.0, "grant": 2600.0, "impact": 2, "prestige": 0, "chance": 0.62, "review": 24},
	"article": {"name": "Full article", "tag": "SUBSTANTIAL STUDY", "data": 48.0, "work": 26.0, "grant": 8200.0, "impact": 5, "prestige": 2, "chance": 0.48, "review": 48},
	"breakthrough": {"name": "High-impact paper", "tag": "FLAGSHIP PAPER", "data": 110.0, "work": 55.0, "grant": 22000.0, "impact": 12, "prestige": 7, "chance": 0.35, "review": 72}
}
const UPGRADES = {
	"precision": {"name": "Precision instrumentation", "cost": 2, "requires": "", "branch": "instrumentation", "description": "Unlock level 2 experiments: +50% base capacity. Purchase each upgrade with funds."},
	"module_slots": {"name": "Modular instruments", "cost": 3, "requires": "precision", "branch": "instrumentation", "description": "Unlock two module slots per experiment and the acquisition accelerator."},
	"mixed_mode": {"name": "Mixed-mode acquisition", "cost": 3, "requires": "module_slots", "branch": "instrumentation", "description": "Unlock extra data-channel modules and mixed-field paper ideas. Existing level 2/3 instruments also gain their native secondary channel."},
	"advanced_instruments": {"name": "Advanced instrumentation", "cost": 6, "requires": "mixed_mode", "branch": "instrumentation", "description": "Unlock level 3 experiments: double base capacity. Purchase each upgrade with funds."},
	"nuclear_lab": {"name": "Nuclear instrumentation", "cost": 3, "requires": "precision", "branch": "instrumentation", "description": "Unlock particle detectors. Primary data: Nuclear. Construction costs $8,200."},
	"quantum_lab": {"name": "Quantum instrumentation", "cost": 6, "requires": "mixed_mode", "branch": "instrumentation", "description": "Unlock quantum rigs. Primary data: Quantum. Construction costs $14,500."},
	"desk_systems": {"name": "Workstation systems", "cost": 2, "requires": "", "branch": "computation", "description": "Unlock level 2 desks: +15% analysis, writing and study for their seated user. $700 per desk."},
	"compute": {"name": "Analysis cluster", "cost": 4, "requires": "desk_systems", "branch": "computation", "description": "+25% analysis at every desk. Also unlock level 3 desks: +30% desk productivity. $1,400 per desk."},
	"journal_club": {"name": "Journal club", "cost": 2, "requires": "desk_systems", "branch": "computation", "description": "Refresh all six paper ideas for 12 study points. Individual discoveries still cost 8 points."},
	"review_support": {"name": "Internal peer review", "cost": 5, "requires": "journal_club", "branch": "computation", "description": "+8 acceptance percentage points for new manuscripts, capped at 97%."},
	"lounge": {"name": "Rest facilities", "cost": 3, "requires": "compute", "branch": "computation", "description": "Assigned beds restore 10 energy/hour instead of 7. Bedless rest remains 40% as effective."}
}
const MODULES = {
	"accelerator": {"name": "Acquisition accelerator", "cost": 1400, "unlock": "module_slots", "field": "", "description": "+25% experiment capacity and operator acquisition speed."},
	"nuclear": {"name": "Nuclear channel", "cost": 1800, "unlock": "mixed_mode", "field": "nuclear", "description": "Add Nuclear data equal to 20% of the experiment's base output. Existing channels retain their yield."},
	"quantum": {"name": "Quantum channel", "cost": 1800, "unlock": "mixed_mode", "field": "quantum", "description": "Add Quantum data equal to 20% of the experiment's base output. Existing channels retain their yield."},
	"materials": {"name": "Materials channel", "cost": 1800, "unlock": "mixed_mode", "field": "materials", "description": "Add Materials data equal to 20% of the experiment's base output. Existing channels retain their yield."},
	"optics": {"name": "Optics channel", "cost": 1800, "unlock": "mixed_mode", "field": "optics", "description": "Add Optics data equal to 20% of the experiment's base output. Existing channels retain their yield."}
}
const TRAITS = {
	"meticulous": {"name": "Meticulous", "description": "+20% analysis, -20% collection", "analyze": 1.2, "acquire": 0.8},
	"inventive": {"name": "Inventive", "description": "+35% study, -15% writing", "study": 1.35, "write": 0.85},
	"practical": {"name": "Practical", "description": "+20% collection, -15% analysis", "acquire": 1.2, "analyze": 0.85},
	"diligent": {"name": "Diligent", "description": "+20% writing, -20% study", "write": 1.2, "study": 0.8}
}
const PERSONALITIES = {
	"early": {"name": "Early bird", "description": "+10% work before noon", "shift": 0},
	"night": {"name": "Night owl", "description": "Routine starts 8h later; +10% work after 16:00", "shift": 8},
	"social": {"name": "Sociable", "description": "+10% work with a colleague within 1.5 tiles", "shift": 0},
	"quiet": {"name": "Solitary", "description": "+10% work alone, -10% near a colleague", "shift": 0}
}
const TITLES = {
	"optics": ["A quieter light: tracing noise in an interferometer", "Light around the corner: resolving a hidden fringe", "When beams agree: a study of phase stability", "The missing fringe in a cold optical cavity"],
	"materials": ["Small cracks, large consequences in thin films", "A surface remembers: defects after thermal cycling", "Order from disorder in a layered crystal", "The quiet life of a grain boundary"],
	"quantum": ["One more moment of coherence", "Entanglement at the edge of a noisy world", "Reading a qubit without losing the story", "A fragile agreement between two quantum states"],
	"nuclear": ["Listening for a rare decay", "A faint signature beneath the background", "Counting the events that almost never happen", "Unexpected structure in a nuclear spin spectrum"]
}
const NAMES = ["Alex Chen", "Sam Okafor", "Maya Patel", "Leo Rossi", "Noor Hassan", "Eva Novak", "Jules Martin", "Iris Park", "Owen Clarke", "Ada Silva", "Robin Kim", "Nico Costa"]
