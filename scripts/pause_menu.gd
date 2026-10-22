## The pause menu (Esc): resume, settings, back to the title, or quit.
## Settings are kept in user://settings.cfg and applied by main.gd
## (apply_settings). The game is paused underneath; this menu keeps running.
extends Control

signal settings_changed(settings: Dictionary)
signal closed

const PATH := "user://settings.cfg"
const PAPER := Color(0.93, 0.89, 0.78)
const INK := Color(0.24, 0.17, 0.12)

const DEFAULTS := {
	"volume": 0.8,        # everything
	"music": 0.7,         # the music, on top of that
	"sensitivity": 1.0,   # mouse look, times the normal speed
	"invert_y": false,
	"fov": 70.0,
	"pixels": 2,          # 1 fine, 2 crisp, 3 chunky
	"fullscreen": false,
	"hints": true,        # the controls line at the top left
}

var settings := DEFAULTS.duplicate()
var _col: VBoxContainer
var _title: Label


static func load_settings() -> Dictionary:
	var out := DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for key in DEFAULTS:
			out[key] = cfg.get_value("settings", key, DEFAULTS[key])
	return out


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in settings:
		cfg.set_value("settings", key, settings[key])
	cfg.save(PATH)


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	settings = load_settings()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var sheet := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = PAPER.darkened(0.25)
	style.set_border_width_all(3)
	style.set_content_margin_all(28)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 10
	sheet.add_theme_stylebox_override("panel", style)
	sheet.set_anchors_preset(Control.PRESET_CENTER)
	sheet.custom_minimum_size = Vector2(520, 0)
	sheet.position = Vector2(-260, -260)
	sheet.rotation = deg_to_rad(0.6)
	add_child(sheet)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 10)
	sheet.add_child(_col)


func open() -> void:
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_main_page()


func close() -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _title.text == "Settings":
			_main_page()
		else:
			close()


func _clear(title: String) -> void:
	for c in _col.get_children():
		c.queue_free()
	_title = Label.new()
	_title.text = title
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", INK)
	_col.add_child(_title)
	var rule := ColorRect.new()
	rule.color = Color(0.75, 0.3, 0.25, 0.6)
	rule.custom_minimum_size = Vector2(0, 2)
	_col.add_child(rule)


func _main_page() -> void:
	_clear("Paused")
	_button("Back to the outskirts", close)
	_button("Settings", _settings_page)
	_button("Quit to the title screen", _to_title)
	_note("The game saves when you go to bed. Anything since then is lost if you quit.")
	_button("Quit the game", func(): get_tree().quit())


func _to_title() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _settings_page() -> void:
	_clear("Settings")
	_slider("Volume", "volume", 0.0, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100))
	_slider("Music", "music", 0.0, 1.0, 0.05, func(v): return "%d%%" % roundi(v * 100))
	_slider("Mouse speed", "sensitivity", 0.3, 2.5, 0.1, func(v): return "%.1fx" % v)
	_slider("Field of view", "fov", 55.0, 95.0, 1.0, func(v): return "%d°" % roundi(v))
	_choice("Pixels", "pixels", [[1, "Fine"], [2, "Crisp"], [3, "Chunky"]])
	_toggle("Invert mouse up and down", "invert_y")
	_toggle("Show the controls at the top", "hints")
	_toggle("Full screen", "fullscreen")
	_button("Back", _main_page)


func _changed(key: String, value: Variant) -> void:
	settings[key] = value
	save_settings()
	settings_changed.emit(settings)


# --- Widgets, all in the same inky paper style -------------------------------------------

func _row(label: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(170, 0)
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", INK)
	row.add_child(l)
	_col.add_child(row)
	return row


func _slider(label: String, key: String, lo: float, hi: float, step: float, fmt: Callable) -> void:
	var row := _row(label)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = float(settings[key])
	s.custom_minimum_size = Vector2(200, 24)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_NONE
	row.add_child(s)
	var v := Label.new()
	v.text = fmt.call(s.value)
	v.add_theme_font_size_override("font_size", 16)
	v.add_theme_color_override("font_color", INK.lightened(0.2))
	row.add_child(v)
	s.value_changed.connect(func(x: float):
		v.text = fmt.call(x)
		_changed(key, x))


func _choice(label: String, key: String, options: Array) -> void:
	var row := _row(label)
	for o in options:
		var b := _small_button(o[1])
		b.toggle_mode = true
		b.button_pressed = int(settings[key]) == o[0]
		b.pressed.connect(func():
			_changed(key, o[0])
			for c in row.get_children():
				if c is Button:
					c.button_pressed = c == b)
		row.add_child(b)


func _toggle(label: String, key: String) -> void:
	var c := CheckBox.new()
	c.text = label
	c.button_pressed = bool(settings[key])
	c.focus_mode = Control.FOCUS_NONE
	c.add_theme_font_size_override("font_size", 17)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		c.add_theme_color_override(state, INK)
	c.toggled.connect(func(on: bool): _changed(key, on))
	_col.add_child(c)


func _note(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(460, 0)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", INK.lightened(0.35))
	_col.add_child(l)


func _small_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 16)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var st := StyleBoxFlat.new()
		st.bg_color = PAPER.darkened(0.3 if "pressed" in state else (0.2 if state == "hover" else 0.1))
		st.border_color = INK.lightened(0.4)
		st.border_width_bottom = 2
		st.set_content_margin_all(6)
		b.add_theme_stylebox_override(state, st)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, INK)
	return b


func _button(text: String, action: Callable) -> void:
	var b := _small_button(text)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(action)
	_col.add_child(b)
