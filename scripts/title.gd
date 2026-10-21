## The title screen, drawn over your kitchen with the lamp on.
extends Control

signal chosen(choice: String)  # "continue", "new" or "quit"


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.03, 0.04, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	col.position = Vector2(90, -170)
	col.add_theme_constant_override("separation", 12)
	add_child(col)
	var title := Label.new()
	title.text = "STATIC OUTSKIRTS"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.62))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.04))
	title.add_theme_constant_override("outline_size", 10)
	col.add_child(title)
	var sub := Label.new()
	sub.text = "Ninety-one days after. Somebody is still on the radio."
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
	col.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	col.add_child(gap)
	if preload("res://scripts/save_game.gd").exists():
		col.add_child(_button("Continue", "continue"))
	col.add_child(_button("New game", "new"))
	col.add_child(_button("Quit", "quit"))
	var note := Label.new()
	note.text = "working title  ·  prototype"
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color(0.7, 0.68, 0.62, 0.8))
	note.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	note.position = Vector2(90, -40)
	add_child(note)


func _button(text: String, choice: String) -> Button:
	var b := Button.new()
	b.text = "  " + text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(260, 44)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color(0.9, 0.86, 0.78))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.5))
	for state in ["normal", "hover", "pressed", "focus"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.1, 0.07, 0.05, 0.0 if state == "normal" or state == "focus" else 0.5)
		st.border_color = Color(1.0, 0.8, 0.45, 0.0 if state == "normal" or state == "focus" else 0.8)
		st.border_width_left = 3
		b.add_theme_stylebox_override(state, st)
	b.pressed.connect(func(): chosen.emit(choice))
	return b
