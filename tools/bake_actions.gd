extends SceneTree
## Six sprite frames for each action, aligned to a single ground pivot.
## Small changes of compression and lean bridge the original key poses.
const Frames = preload("res://scripts/character_frames.gd")
const HERO_SHEETS := {
 "hero": "hero-young",
 "hero-adult": "hero-adult-armored",
 "hero-veteran": "hero-veteran-armored"
}
func _initialize() -> void:
 var source = Frames.new()
 DirAccess.make_dir_recursive_absolute("res://art/animation/actions")
 var kinds:Array=Frames.CLIPS.keys()
 kinds.append_array(["hero-adult","hero-veteran"])
 if OS.get_cmdline_user_args().has("--hero-only"):
  kinds = HERO_SHEETS.keys()
 for kind in kinds:
  var model:String="hero" if str(kind).begins_with("hero") else str(kind)
  var bank: Dictionary=source._bank(model)
  var actions:=SpriteFrames.new()
  actions.remove_animation("default")
  for clip in Frames.CLIPS[model]:
   actions.add_animation(clip)
   actions.set_animation_speed(clip,12.0)
   actions.set_animation_loop(clip,clip in ["run","idle","talk","point","bless","gallop"])
   var span: Array=Frames.CLIPS[model][clip]
   for step in range(6):
    var t:=step/5.0
    var frame: Dictionary=bank.frames[span[0]+roundi((span[1]-1)*t)]
    var img: Image=frame.texture.get_image()
    var anchor:float=frame.anchor_x-frame.bounds.position.x
    var hero_source_scale := 1.0
    if model=="hero":
     var sheet_name: String = HERO_SHEETS[kind]
     var row: int = {"kick":0,"idle":0,"run":1,"jump":2,"attack":3,"hurt":4,"super":5,"land":2,"dodge":1}[clip]
     var rows := 6
     var opacity_cut := 0.74 if kind == "hero-veteran" else 0.55
     if clip in ["run", "kick"]:
      sheet_name = "hero-run-cycle" if clip == "run" else "hero-down-kick-armored"
      rows = 3
      row = HERO_SHEETS.keys().find(kind)
      opacity_cut = 0.92 if clip == "run" else 0.55
     var atlas: Image = load("res://art/animation/" + sheet_name + ".png").get_image()
     var cell := Vector2i(atlas.get_width() / 6, atlas.get_height() / rows)
     var left := atlas.get_width() * step / 6
     var right := atlas.get_width() * (step + 1) / 6
     img = atlas.get_region(Rect2i(left, row * cell.y, right - left, cell.y))
     hero_source_scale = 209.0 / cell.y
     img.convert(Image.FORMAT_RGBA8)
     for y in range(img.get_height()):
      for x in range(img.get_width()):
       var pixel := img.get_pixel(x, y)
       if pixel.a < opacity_cut or (pixel.r > 0.78 and pixel.g < 0.22 and pixel.b < 0.24):
        img.set_pixel(x, y, Color.TRANSPARENT)
       else:
        pixel.a = 1.0
        img.set_pixel(x, y, pixel)
     var bounds:=img.get_used_rect()
     for y in range(bounds.end.y-1,bounds.position.y-1,-1):
      var solid:=0
      for x in range(bounds.position.x,bounds.end.x):
       if img.get_pixel(x,y).a>0.8:solid+=1
      if solid>=5:
       bounds.size.y=y-bounds.position.y+1
       break
     anchor=cell.x*(0.48 if clip != "run" else 0.51)-bounds.position.x
     img=img.get_region(bounds)
    if model=="elder":
     var atlas:Image=load("res://art/animation/elder-staff.png").get_image()
     var cell:=Vector2i(atlas.get_width()/6,atlas.get_height()/3)
     var row:int={"idle":0,"talk":1,"point":2,"bless":2}[clip]
     img=atlas.get_region(Rect2i(Vector2i(step,row)*cell,cell))
     img.convert(Image.FORMAT_RGBA8)
     for y in range(img.get_height()):
      for x in range(img.get_width()):
       if img.get_pixel(x,y).a<0.55:img.set_pixel(x,y,Color.TRANSPARENT)
     var bounds:=img.get_used_rect()
     anchor=cell.x*.45-bounds.position.x
     img=img.get_region(bounds)
    if img.is_compressed():
     img.decompress()
    img.convert(Image.FORMAT_RGBA8)
    if kind=="enemy":
     var pixels:=img.get_data()
     for at in range(0,pixels.size(),4):
      var red:=float(pixels[at])
      if pixels[at+3]>0 and red>48 and pixels[at+1]<red*0.46 and pixels[at+2]<red*0.50:
       pixels[at]=int(red*0.70)
       pixels[at+1]=int(red*0.46)
       pixels[at+2]=int(red*0.31)
     img.set_data(img.get_width(),img.get_height(),false,Image.FORMAT_RGBA8,pixels)
    var lean:=0.0
    var scale_x: float=bank.scale
    if model=="hero":
     scale_x=0.66 if kind=="hero" else 0.84 if kind=="hero-adult" else 0.88
    elif model=="elder":
     scale_x=125.0/(load("res://art/animation/elder-staff.png").get_height()/3.0)
    elif clip in ["idle","talk","point","bless"]:
     scale_x=Frames.HEIGHTS[model]/img.get_height()
    if model=="hero":scale_x *= hero_source_scale
    var scale_y: float=scale_x
    img.resize(maxi(1,roundi(img.get_width()*scale_x)),maxi(1,roundi(img.get_height()*scale_y)),Image.INTERPOLATE_NEAREST)
    var sheet:=Image.create_empty(430,195,false,Image.FORMAT_RGBA8)
    var x:int=195-roundi(anchor*scale_x)
    for row in range(img.get_height()):
     var shift:=roundi(lean*(1.0-float(row)/img.get_height()))
     sheet.blit_rect(img,Rect2i(0,row,img.get_width(),1),Vector2i(x+shift,185-img.get_height()+row))
    actions.add_frame(clip,ImageTexture.create_from_image(sheet))
  var err:=ResourceSaver.save(actions,"res://art/animation/actions/"+kind+".res",ResourceSaver.FLAG_COMPRESS)
  if err!=OK:
   push_error("Cannot save "+kind)
   quit(1)
   return
 print("Baked six-frame action banks: ", ", ".join(kinds))
 quit()
