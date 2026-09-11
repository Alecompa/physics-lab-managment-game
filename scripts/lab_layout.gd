class_name LabLayout
extends RefCounted

# The maximum region is stable; purchased wings open additional floor cells.
const SIZE = Vector2i(40, 24)
const ENTRANCE = Vector2i(9, 7)
const REST_SEATS = [Vector2i(13, 12), Vector2i(15, 12), Vector2i(17, 12)]
const BED_STARTS = [Vector2i(13, 9), Vector2i(16, 9), Vector2i(18, 9)]
const DESK_STARTS = [Vector2i(2, 9), Vector2i(5, 9), Vector2i(2, 11)]

static func dimensions(level: int = 0) -> Vector2i:
	return [Vector2i(28, 20), Vector2i(34, 24), SIZE][clampi(level, 0, 2)]

static func inside(cell: Vector2i, level: int = 0) -> bool:
	var bounds = dimensions(level)
	return cell.x >= 0 and cell.y >= 0 and cell.x < bounds.x and cell.y < bounds.y

# Three rooms, a connecting hall and wide doorways. Old saves keep their open plan.
static func wall(cell: Vector2i, level: int = 0, style: String = "rooms") -> bool:
	var bounds = dimensions(level)
	if not inside(cell, level) or cell.x == 0 or cell.y == 0 or cell.x == bounds.x - 1 or cell.y == bounds.y - 1: return true
	if style == "open": return false
	if cell.y == 6 and cell.x < 27: return cell.x not in [8, 9, 20, 21]
	if cell.y == 8 and cell.x < 27: return cell.x not in [4, 5, 15, 16, 22, 23]
	if cell.x == 11 and cell.y >= 9 and cell.y < 19: return cell.y not in [14, 15]
	return false

static func room(cell: Vector2i, level: int = 0, style: String = "rooms") -> String:
	if wall(cell, level, style): return "wall"
	if style == "rooms":
		if cell.x >= 27 or cell.y >= 19: return "measurements"
		if cell.y in [6, 7, 8] or cell.x == 11 and cell.y in [14, 15]: return "corridor"
		if cell.y < 6: return "optics"
		return "office" if cell.x < 11 else "common"
	if cell.y < 8: return "optics" if cell.x < 12 else "measurements"
	return "office" if cell.x < 12 else "common"

static func decorations(style: String = "rooms") -> Dictionary:
	if style == "open": return {}
	return {
		Vector2i(1, 1): "plant", Vector2i(26, 1): "plant",
		Vector2i(1, 18): "plant", Vector2i(26, 18): "plant", Vector2i(12, 18): "plant",
		Vector2i(5, 1): "shelf", Vector2i(6, 1): "shelf", Vector2i(7, 1): "shelf",
		Vector2i(2, 17): "shelf", Vector2i(3, 17): "shelf",
		Vector2i(22, 9): "counter", Vector2i(23, 9): "sink", Vector2i(24, 9): "counter", Vector2i(25, 9): "plant",
	}

static func fixed_furniture(cell: Vector2i, style: String = "rooms") -> bool:
	return cell == Vector2i(12, 12) or decorations(style).has(cell)

static func footprint(kind: String) -> Vector2i:
	return Vector2i(1, 2) if kind == "bed" else Vector2i(2, 1) if kind == "desk" else Vector2i(2, 2)

static func cells(kind: String, origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var dimensions = footprint(kind)
	for x in range(dimensions.x):
		for y in range(dimensions.y): result.append(origin + Vector2i(x, y))
	return result

static func room_allows(kind: String, origin: Vector2i, level: int = 0, style: String = "rooms") -> bool:
	for cell in cells(kind, origin):
		if wall(cell, level, style) or fixed_furniture(cell, style) or cell == ENTRANCE or cell in REST_SEATS: return false
	if kind == "desk" and wall(origin + Vector2i.DOWN, level, style): return false
	if kind == "bed" and wall(origin + Vector2i(0, 2), level, style): return false
	return true

static func chair(desk: Dictionary) -> Vector2i:
	return Vector2i(desk.x, desk.y + 1)

static func perimeter(experiment: Dictionary) -> Array[Vector2i]:
	var origin = Vector2i(experiment.x, experiment.y)
	return [origin + Vector2i(0, 2), origin + Vector2i(1, 2), origin + Vector2i(-1, 0), origin + Vector2i(-1, 1), origin + Vector2i(2, 0), origin + Vector2i(2, 1), origin + Vector2i(0, -1), origin + Vector2i(1, -1)]

static func bed_access(bed: Dictionary) -> Vector2i:
	return Vector2i(bed.x, bed.y + 2)
