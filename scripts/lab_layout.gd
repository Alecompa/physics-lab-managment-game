class_name LabLayout
extends RefCounted

const SIZE = Vector2i(20, 14)
const ENTRANCE = Vector2i(9, 7)
const REST_SEATS = [Vector2i(13, 12), Vector2i(15, 12), Vector2i(17, 12)]
const BED_STARTS = [Vector2i(13, 9), Vector2i(16, 9), Vector2i(18, 9)]
const DESK_STARTS = [Vector2i(2, 9), Vector2i(5, 9), Vector2i(2, 11)]

static func inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE.x and cell.y < SIZE.y

static func wall(cell: Vector2i) -> bool:
	if not inside(cell): return true
	if cell.x == 0 or cell.x == 19 or cell.y == 0 or cell.y == 13: return true
	if cell.y in [5, 8] and cell.x not in [4, 9, 10, 15]: return true
	if cell.x in [8, 11] and cell.y not in [3, 6, 7, 10]: return true
	return false

static func room(cell: Vector2i) -> String:
	if wall(cell): return "wall"
	if cell.y < 5 and cell.x < 8: return "optics"
	if cell.y < 5 and cell.x > 11: return "measurements"
	if cell.y > 8 and cell.x < 8: return "office"
	if cell.y > 8 and cell.x > 11: return "common"
	return "corridor"

static func fixed_furniture(cell: Vector2i) -> bool:
	return cell == Vector2i(12, 12)

static func footprint(kind: String) -> Vector2i:
	return Vector2i(1, 2) if kind == "bed" else Vector2i(2, 1) if kind == "desk" else Vector2i(2, 2)

static func cells(kind: String, origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var dimensions = footprint(kind)
	for x in range(dimensions.x):
		for y in range(dimensions.y): result.append(origin + Vector2i(x, y))
	return result

static func room_allows(kind: String, origin: Vector2i) -> bool:
	for cell in cells(kind, origin):
		if kind == "desk" and room(cell) != "office": return false
		if kind == "bed" and (room(cell) != "common" or origin.y != 9): return false
		if kind not in ["desk", "bed"] and room(cell) not in ["optics", "measurements"]: return false
	if kind == "desk" and room(origin + Vector2i.DOWN) != "office": return false
	return true

static func chair(desk: Dictionary) -> Vector2i:
	return Vector2i(desk.x, desk.y + 1)

static func perimeter(experiment: Dictionary) -> Array[Vector2i]:
	var origin = Vector2i(experiment.x, experiment.y)
	return [origin + Vector2i(0, 2), origin + Vector2i(1, 2), origin + Vector2i(-1, 0), origin + Vector2i(-1, 1), origin + Vector2i(2, 0), origin + Vector2i(2, 1), origin + Vector2i(0, -1), origin + Vector2i(1, -1)]

static func bed_access(bed: Dictionary) -> Vector2i:
	return Vector2i(bed.x, bed.y + 2)
