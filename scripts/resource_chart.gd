extends Control
var samples: Array = []
var metric = "funds"
var horizon = 30
var hovered = -1
func _ready() -> void:
	custom_minimum_size = Vector2(760, 330)
	mouse_exited.connect(func(): hovered = -1; queue_redraw())
func data() -> Array:
	return samples.slice(maxi(0, samples.size() - horizon)) if horizon > 0 else samples
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hovered = clampi(roundi((event.position.x - 65) / (size.x - 95) * (data().size() - 1)), 0, maxi(0, data().size() - 1))
		queue_redraw()
func value(sample: Dictionary, field: String) -> float:
	if metric in ["raw", "analyzed"]: return sample[metric][field]
	return sample.get("grant_income", 0) if metric == "grants" else sample.get(metric, 0)
func _draw() -> void:
	var history = data()
	var font = ThemeDB.fallback_font
	var plot = Rect2(65, 35, size.x - 95, size.y - 95)
	var fields = LabCatalog.FIELDS.keys() if metric in ["raw", "analyzed"] else ["funds"]
	var maximum = 1.0
	for sample in history:
		for field in fields: maximum = maxf(maximum, value(sample, field))
	maximum *= 1.1
	for index in range(5):
		var y = plot.position.y + plot.size.y * index / 4.0
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), LabUI.LINE, 1)
		draw_string(font, Vector2(3, y + 4), "%.0f" % (maximum * (1 - index / 4.0)), HORIZONTAL_ALIGNMENT_LEFT, 56, 11, LabUI.MUTED)
	if history.size() < 2:
		draw_string(font, plot.position + Vector2(30, 90), "History starts at the next midnight.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, LabUI.MUTED)
		return
	for field in fields:
		var color = Color(LabCatalog.FIELDS[field].color) if LabCatalog.FIELDS.has(field) else LabUI.ACCENT
		var points = PackedVector2Array()
		for index in range(history.size()): points.append(Vector2(plot.position.x + plot.size.x * index / (history.size() - 1), plot.end.y - plot.size.y * value(history[index], field) / maximum))
		draw_polyline(points, Color(color, 0.10), 6, true)
		draw_polyline(points, color, 2, true)
		if hovered >= 0 and hovered < history.size(): draw_circle(points[hovered], 4, color)
	for index in [0, history.size() - 1]:
		draw_string(font, Vector2(plot.position.x + (plot.size.x - 50) * index / (history.size() - 1), plot.end.y + 25), "Day %d" % history[index].day, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, LabUI.MUTED)
	if hovered >= 0 and hovered < history.size():
		var sample = history[hovered]
		var parts = PackedStringArray(["Day %d" % sample.day])
		for field in fields: parts.append("%s %.1f" % [LabCatalog.FIELDS[field].name if LabCatalog.FIELDS.has(field) else metric.capitalize(), value(sample, field)])
		draw_string(font, Vector2(65, size.y - 12), "  /  ".join(parts), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, LabUI.TEXT)
