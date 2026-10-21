## The on-screen radio dial shown while tuning: a warm glowing strip with
## tick marks, station-free numbers and a red needle.
extends Control

var freq := 99.0
var signal_strength := 0.0

const MIN_FREQ := 87.5
const MAX_FREQ := 108.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.16, 0.1, 0.07, 0.92))
	var inner := r.grow(-8)
	draw_rect(inner, Color(0.85, 0.72, 0.45))
	var font := get_theme_default_font()
	var ink := Color(0.25, 0.16, 0.1)
	draw_line(Vector2(inner.position.x, inner.position.y + 28), Vector2(inner.end.x, inner.position.y + 28), ink.lerp(Color(0.85, 0.72, 0.45), 0.6), 1.0)
	var f := 88.0
	while f <= 108.0:
		var x := inner.position.x + (f - MIN_FREQ) / (MAX_FREQ - MIN_FREQ) * inner.size.x
		var major := int(f) % 4 == 0
		draw_line(Vector2(x, inner.end.y - (18 if major else 9)), Vector2(x, inner.end.y), ink, 2.0)
		if major:
			draw_string(font, Vector2(minf(x - 20, inner.end.x - 44), inner.end.y - 22), str(int(f)), HORIZONTAL_ALIGNMENT_CENTER, 40, 14, ink)
		f += 1.0
	var nx := inner.position.x + (freq - MIN_FREQ) / (MAX_FREQ - MIN_FREQ) * inner.size.x
	draw_line(Vector2(nx, inner.position.y + 2), Vector2(nx, inner.end.y), Color(0.75, 0.12, 0.08), 3.0)
	# Little signal lamp: brighter the closer you are to something.
	var lamp := Color(0.3, 0.25, 0.15).lerp(Color(1.0, 0.85, 0.3), signal_strength)
	draw_circle(Vector2(inner.end.x - 16, inner.position.y + 14), 7, lamp)
	draw_string(font, Vector2(inner.position.x + 8, inner.position.y + 20), "FM %.1f MHz" % freq, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ink)
