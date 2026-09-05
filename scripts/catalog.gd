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
	"journal_club": {"name": "Journal club", "cost": 2, "requires": "", "description": "Spend 12 study points to refresh the entire idea board. Normal study still creates individual ideas for 8 points."},
	"nuclear_lab": {"name": "Nuclear instrumentation", "cost": 3, "requires": "", "description": "Permanently unlock particle detector construction."},
	"mixed_mode": {"name": "Mixed-mode acquisition", "cost": 3, "requires": "", "description": "Level 2 experiments produce 75% primary and 25% secondary data. Level 3 uses a 60/40 split. Enables cross-field ideas."},
	"compute": {"name": "Analysis cluster", "cost": 4, "requires": "", "description": "All analysis work is 25% faster, for every field."},
	"quantum_lab": {"name": "Quantum instrumentation", "cost": 6, "requires": "mixed_mode", "description": "Permanently unlock quantum rig construction. Requires mixed-mode acquisition."},
	"lounge": {"name": "Staff common room", "cost": 3, "requires": "", "description": "Rest restores 10 energy per hour instead of 7."},
	"review_support": {"name": "Internal peer review", "cost": 5, "requires": "journal_club", "description": "Adds 8 percentage points to acceptance chances of newly started papers, up to 97%."}
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
