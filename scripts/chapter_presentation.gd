@tool
extends Control
## Illustrated chapter cover. Scenes retain their own gameplay and Layout nodes.
signal start_requested
signal map_requested

const STORY_ART = preload("res://art/source/05-menus-story.png")
const OPENING_ART=preload("res://art/animation/steppe-opening.png")
const CAMPAIGN_ART = preload("res://art/animation/campaign-story.png")
const ROMAN := ["I", "II", "III", "IV", "V"]
const COVERS := [Rect2(5,481,502,256),Rect2(1028,481,502,256),Rect2(1028,754,502,260),Rect2(517,481,502,256),Rect2(517,754,502,260)]
const PALETTES := [Color("5b9277"),Color("b47b55"),Color("6b8397"),Color("b28a63"),Color("7b809b")]
const TAGLINES := ["БЕРЕГ ЗАЙСАНА","БАТА ПЕРЕД ПОХОДОМ","ВЫЗОВ НА КОНЯХ","ПЕШИЙ СТРОЙ","ПРИКРЫТЬ ОТХОД"]
var chapter := 1
var stage: Dictionary = {}
var is_completed := false
var best_time_text := ""
var title_label: Label
var place_label: Label
var chapter_label: Label
var hook_label: Label
var status_label: Label
var picture_caption: Label
var difficulty_label: Label
var start_button: Button
var map_button: Button
var _built := false
var scene_art=preload("res://scripts/level_art.gd").new()
var hero_frames=preload("res://scripts/character_frames.gd").new()

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 if not _built:
  _build_ui()
 _refresh()

func configure(number: int, chapter_stage: Dictionary, completed: bool, best_time: String) -> void:
 chapter = clampi(number,1,5)
 stage = chapter_stage.duplicate()
 is_completed = completed
 best_time_text = best_time
 if _built:
  _refresh()
 queue_redraw()

func _text(text_value: String, font_size: int, color_value: Color, at: Vector2, extent: Vector2, node_name: String) -> Label:
 var label := Label.new()
 label.name = node_name
 label.text = text_value
 label.position = at
 label.size = extent
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",color_value)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(label)
 return label

func _style(fill: Color, border: Color, width: int = 2) -> StyleBoxFlat:
 var result := StyleBoxFlat.new()
 result.bg_color = fill
 result.border_color = border
 result.set_border_width_all(width)
 result.set_corner_radius_all(5)
 result.content_margin_left = 18
 result.content_margin_right = 18
 result.content_margin_top = 10
 result.content_margin_bottom = 10
 return result

func _build_ui() -> void:
 _built = true
 _text("ҚАБАНБАЙ",36,Color("f3d18d"),Vector2(68,45),Vector2(500,52),"SeriesTitle")
 _text("П У Т Ь   Б А Т Ы Р А",13,Color("8eaea8"),Vector2(71,99),Vector2(400,24),"SeriesSubtitle")
 chapter_label = _text("",16,Color("d3b97f"),Vector2(71,167),Vector2(455,28),"ChapterLabel")
 place_label = _text("",18,Color("99d4c1"),Vector2(71,220),Vector2(452,34),"PlaceLabel")
 title_label = _text("",43,Color("fff0cf"),Vector2(68,260),Vector2(456,112),"ChapterTitle")
 title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 hook_label = _text("",22,Color("c6d1c9"),Vector2(71,394),Vector2(431,105),"ChapterHook")
 hook_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 picture_caption = _text("",13,Color("edd39c"),Vector2(567,510),Vector2(627,30),"PictureCaption")
 picture_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 difficulty_label = _text("",15,Color("d6caa8"),Vector2(554,558),Vector2(500,28),"DifficultyLabel")
 status_label = _text("",15,Color("99c6ad"),Vector2(72,526),Vector2(455,30),"CompletionStatus")
 start_button = Button.new()
 start_button.name = "StartButton"
 start_button.position = Vector2(71,582)
 start_button.size = Vector2(435,64)
 start_button.text = "Начать испытание   →"
 start_button.add_theme_font_size_override("font_size",23)
 start_button.add_theme_color_override("font_color",Color("152d30"))
 start_button.add_theme_color_override("font_hover_color",Color("102529"))
 start_button.add_theme_color_override("font_pressed_color",Color("102529"))
 start_button.add_theme_stylebox_override("normal",_style(Color("d4b26e"),Color("f4d99e")))
 start_button.add_theme_stylebox_override("hover",_style(Color("f0d493"),Color("fff0be")))
 start_button.add_theme_stylebox_override("pressed",_style(Color("bba064"),Color("e7cd93")))
 start_button.add_theme_stylebox_override("focus",_style(Color(0,0,0,0),Color("fff4d0")))
 start_button.pressed.connect(func(): start_requested.emit())
 add_child(start_button)
 map_button = Button.new()
 map_button.name = "MapButton"
 map_button.position = Vector2(553,601)
 map_button.size = Vector2(235,45)
 map_button.text = "←   Карта путешествия"
 map_button.add_theme_font_size_override("font_size",18)
 map_button.add_theme_color_override("font_color",Color("cad7cb"))
 map_button.add_theme_color_override("font_hover_color",Color("fff0c7"))
 for state_name in ["normal","hover","pressed","focus"]:
  map_button.add_theme_stylebox_override(state_name,StyleBoxEmpty.new())
 map_button.pressed.connect(func(): map_requested.emit())
 add_child(map_button)
 _text("КАЗАХСКАЯ СТЕПЬ  ·  НАЧАЛО XVIII ВЕКА",11,Color("698c86"),Vector2(72,671),Vector2(1000,23),"Footer")

func _refresh() -> void:
 var index := chapter-1
 chapter_label.text = "ГЛАВА %s   /   ПЯТЬ ИСПЫТАНИЙ" % ROMAN[index]
 place_label.text = str(stage.get("place","Зайсан")).to_upper()
 title_label.text = str(stage.get("title","Первое испытание")).to_upper()
 hook_label.text = stage.get("hook","Защити табун.")
 picture_caption.text = TAGLINES[index]
 difficulty_label.text = "СЛОЖНОСТЬ   " + "◆ ".repeat(chapter) + "◇ ".repeat(5-chapter)
 status_label.text = "ПРОЙДЕНО  ·  ЛУЧШЕЕ ВРЕМЯ %s" % best_time_text if is_completed else "НОВОЕ ИСПЫТАНИЕ  ·  ГЛАВА %s" % ROMAN[index]
 start_button.text = "Пройти ещё раз   →" if is_completed else "Начать испытание   →"
 queue_redraw()

func _draw() -> void:
 var accent: Color = PALETTES[chapter-1]
 draw_rect(Rect2(0,0,1280,720),Color("09252c"))
 for row in range(36):
  var color_value := Color("163b40").lerp(Color("081d24"),float(row)/35)
  draw_rect(Rect2(0,row*20,1280,20),color_value)
 # Quiet stepped ornament and edge light frame the image without competing with it.
 draw_rect(Rect2(27,27,1226,666),Color("8b9b77"),false,1)
 draw_line(Vector2(551,95),Vector2(1217,95),Color("466760"),1)
 draw_line(Vector2(71,143),Vector2(506,143),Color("506958"),1)
 for corner in [Vector2(27,27),Vector2(1253,27),Vector2(27,693),Vector2(1253,693)]:
  var direction := Vector2(1 if corner.x<640 else -1,1 if corner.y<360 else -1)
  draw_polyline(PackedVector2Array([corner+Vector2(0,direction.y*25),corner,corner+Vector2(direction.x*25,0)]),Color("d9b979"),3)
  var inset: Vector2 = corner+direction*Vector2(9,9)
  draw_colored_polygon(PackedVector2Array([inset,inset+Vector2(direction.x*11,0),inset+Vector2(0,direction.y*11)]),Color("967a49"))
 var illustration := Rect2(553,150,663,344)
 draw_rect(Rect2(illustration.position-Vector2(7,7),illustration.size+Vector2(14,14)),Color("031820"))
 draw_texture_rect(preload("res://art/animation/sand-steppe.png"),illustration,false)
 scene_art.prop(self,"yurt",Vector2(1040,494),Vector2(225,172))
 hero_frames.hero_age=chapter
 hero_frames.pose(self,"hero","idle",0,Vector2(790,494))
 draw_rect(illustration,Color("c3a46b"),false,2)
 draw_line(Vector2(553,497),Vector2(1216,497),accent,3)
 # Chapter seal is a native, readable overlay rather than text painted into art.
 draw_circle(Vector2(1161,171),32,Color("102f37"))
 draw_arc(Vector2(1161,171),32,0,TAU,40,Color("d6b779"),2)
 draw_circle(Vector2(1161,171),27,Color("254747"))
 var seal_text: String = ROMAN[chapter-1]
 var font := ThemeDB.fallback_font
 var text_size := font.get_string_size(seal_text,HORIZONTAL_ALIGNMENT_LEFT,-1,22)
 draw_string(font,Vector2(1161-text_size.x/2,179),seal_text,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("ffe3a0"))
 for i in range(5):
  var p := Vector2(1178-i*14,572)
  draw_colored_polygon(PackedVector2Array([p+Vector2(0,-4),p+Vector2(4,0),p+Vector2(0,4),p+Vector2(-4,0)]),Color("d4b77e") if i<chapter else Color("3b5556"))

static func story_region(index:int) -> Rect2:
 var cell:=CAMPAIGN_ART.get_size()/Vector2(2,3)
 return Rect2(Vector2(index%2,floori(index/2.0))*cell+Vector2(3,3),cell-Vector2(6,6))

func draw_story(node:Node2D,index:int,time:float,first:bool) -> void:
 node.draw_rect(Rect2(0,0,1280,720),Color("182b2b"))
 node.draw_set_transform(Vector2.ZERO)
 node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 scene_art.background(node,time*10,Vector2(1280,720),chapter)
 scene_art.ground(node,0,1280,550,[],[])
 scene_art.prop(node,"yurt",Vector2(995,550),Vector2(310,230))
 hero_frames.hero_age=chapter
 hero_frames.pose(node,"hero","idle",int(time*4)%6,Vector2(720,550))
 for i in range(20):
  node.draw_rect(Rect2(0,398+i*14,1280,14),Color(0.04,0.08,0.10,i/22.0))
