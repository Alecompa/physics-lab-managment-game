class_name GrantRules
extends RefCounted

const SPECS = {
	"intro": {"name": "Introductory grant", "amount": 12000.0, "hours": 48.0, "review": 24, "milestone": 0, "base": 1.0, "period": 20},
	"small": {"name": "Small grant", "amount": 14000.0, "hours": 64.0, "review": 120, "milestone": 0, "base": 0.55, "period": 20},
	"standard": {"name": "Standard grant", "amount": 32000.0, "hours": 192.0, "review": 192, "milestone": 1, "base": 0.45, "period": 30},
	"large": {"name": "Large grant", "amount": 72000.0, "hours": 384.0, "review": 288, "milestone": 2, "base": 0.35, "period": 45}
}

static func estimate(kind: String, impact: int, milestones: int, extra: float, revision: bool = false) -> Dictionary:
	if kind == "intro": return {"base": 1.0, "impact": 0.0, "milestones": 0.0, "preparation": 0.0, "revision": 0.0, "chance": 1.0}
	var parts = {"base": SPECS[kind].base, "impact": minf(0.15, impact * 0.005), "milestones": minf(0.15, milestones * 0.05), "preparation": 0.15 * sqrt(clampf(extra / 0.5, 0, 1)), "revision": 0.05 if revision else 0.0}
	parts.chance = minf(0.85, parts.base + parts.impact + parts.milestones + parts.preparation + parts.revision)
	return parts
