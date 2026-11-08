extends SceneTree
func _initialize()->void:
 var heights:Array[float]=[]
 for kind in ["hero","hero-adult","hero-veteran"]:
  var actions:SpriteFrames=load("res://art/animation/actions/"+kind+".res")
  var lowest:=1000
  var highest:=0
  for clip in ["idle","run","jump","attack","super","hurt"]:
   assert(actions.get_frame_count(clip)==6,"Each hero action has six frames")
   for frame in range(6):
    var bounds:=actions.get_frame_texture(clip,frame).get_image().get_used_rect()
    assert(bounds.size.x>0 and bounds.size.y>0,"A hero frame cannot be empty")
    assert(bounds.end.y==185,"Feet remain anchored to the support plane")
    if clip=="idle":
     lowest=mini(lowest,bounds.size.y)
     highest=maxi(highest,bounds.size.y)
  assert(highest-lowest<10,"Idle must not alternate between tall and short bodies")
  heights.append((highest+lowest)*0.5)
 assert(heights[1]>heights[0]*1.15 and heights[2]>heights[1],"The adult is visibly taller than the youth")
 print("Hero animation checks passed: three age atlases, six frames per action, stable feet and idle height. Heights ",heights)
 quit()
