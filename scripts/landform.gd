@tool
extends RefCounted
static func surface(x:float,ravines:Array,base:float=550.0)->float:
 for r in ravines:
  var a:float=r.span.x
  var b:float=r.span.y
  if r.depth<=0:
   if x>a and x<b:return 100000.0
   continue
  var rim:=minf(210,(b-a)*0.23)
  if x>a and x<b:
   var t:=clampf(minf(x-a,b-x)/rim,0,1)
   return base+r.depth*(t*t*(3-2*t))+sin((x-a)*0.019)*4*t*t
  if x>=a-100 and x<=a:
   return base-12*sin((x-a+100)/100*PI)
  if x>=b and x<=b+100:
   return base-12*sin((x-b)/100*PI)
 return base
