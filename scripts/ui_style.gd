class_name UiStyle
extends RefCounted
## Shared look for menu and HUD widgets.

const PANEL_RADIUS := 8 # rounded corner size, px
const PANEL_PADDING := 12 # inner padding, px
const BUTTON_MIN_WIDTH := 320 # menu button width, px
const BAR_HEIGHT := 14 # progress bar thickness, px


static func label(text: String, size: int = GameConfig.FONT_MEDIUM, color: Color = GameConfig.COLOR_UI) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", maxi(2, size / 8))
	return l


static func panel_box(color: Color = GameConfig.COLOR_PANEL) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(PANEL_RADIUS)
	s.set_content_margin_all(PANEL_PADDING)
	return s


static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_box())
	return p


static func button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.x = BUTTON_MIN_WIDTH
	b.add_theme_font_size_override("font_size", GameConfig.FONT_MEDIUM)
	b.add_theme_stylebox_override("normal", panel_box(GameConfig.COLOR_PANEL))
	b.add_theme_stylebox_override("hover", panel_box(GameConfig.COLOR_PANEL.lightened(0.15)))
	b.add_theme_stylebox_override("pressed", panel_box(GameConfig.COLOR_PANEL.lightened(0.3)))
	b.add_theme_stylebox_override("focus", panel_box(GameConfig.COLOR_PANEL.lightened(0.2)))
	b.add_theme_color_override("font_color", GameConfig.COLOR_UI)
	b.add_theme_color_override("font_hover_color", GameConfig.COLOR_WARN)
	b.add_theme_color_override("font_focus_color", GameConfig.COLOR_WARN)
	return b


static func bar(color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	var bg := panel_box(Color(0, 0, 0, 0.5))
	bg.set_content_margin_all(0)
	b.add_theme_stylebox_override("background", bg)
	var fill := panel_box(color)
	fill.set_content_margin_all(0)
	b.add_theme_stylebox_override("fill", fill)
	b.max_value = 1.0
	return b
