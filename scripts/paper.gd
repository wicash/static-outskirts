## A sheet of paper drawn over the game: used for the journal (J) and the
## backpack (Tab). main.gd fills it with a title, text and optional buttons.
extends Control

const PAPER := Color(0.93, 0.89, 0.78)
const INK := Color(0.24, 0.17, 0.12)

var _title: Label
var _body: RichTextLabel
var _buttons: VBoxContainer
var _footer: Label


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
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
	sheet.custom_minimum_size = Vector2(620, 500)
	sheet.position = Vector2(-310, -250)
	sheet.rotation = deg_to_rad(-0.8)
	add_child(sheet)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	sheet.add_child(col)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", INK)
	col.add_child(_title)
	var rule := ColorRect.new()
	rule.color = Color(0.75, 0.3, 0.25, 0.6)
	rule.custom_minimum_size = Vector2(0, 2)
	col.add_child(rule)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = false
	_body.scroll_active = true
	_body.custom_minimum_size = Vector2(560, 300)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_color_override("default_color", INK)
	_body.add_theme_font_size_override("normal_font_size", 17)
	_body.add_theme_font_size_override("bold_font_size", 17)
	col.add_child(_body)
	_buttons = VBoxContainer.new()
	col.add_child(_buttons)
	_footer = Label.new()
	_footer.add_theme_font_size_override("font_size", 14)
	_footer.add_theme_color_override("font_color", INK.lightened(0.35))
	col.add_child(_footer)


func open(title: String, text: String, footer: String, scroll_to_end := false) -> void:
	_title.text = title
	_body.text = text
	_footer.text = footer
	for b in _buttons.get_children():
		b.queue_free()
	visible = true
	_body.scroll_following = scroll_to_end
	_body.scroll_to_line(_body.get_line_count() if scroll_to_end else 0)


func add_button(label: String, action: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 16)
	b.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed"]:
		var st := StyleBoxFlat.new()
		st.bg_color = PAPER.darkened(0.12 if state == "normal" else 0.22)
		st.border_color = INK.lightened(0.4)
		st.border_width_bottom = 2
		st.set_content_margin_all(6)
		b.add_theme_stylebox_override(state, st)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.pressed.connect(action)
	_buttons.add_child(b)


func close() -> void:
	visible = false
