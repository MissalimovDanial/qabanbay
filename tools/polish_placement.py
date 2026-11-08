from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
for scene in (root/'scenes').glob('*.tscn'):
    if scene.stem=='campaign_map':continue
    source=scene.read_text(encoding='utf-8')
    prefix=source[:source.index('[node ')]
    blocks=re.findall(r'(?ms)^\[node .*?(?=^\[node |\Z)',source)
    entries=[]
    for index,block in enumerate(blocks):
        kind=re.search(r'^kind = "([^"]+)"',block,re.M)
        pos=re.search(r'position = Vector2\(([^,]+), ([^)]+)\)',block)
        size=re.search(r'dimensions = Vector2\(([^,]+), ([^)]+)\)',block)
        prop=re.search(r'prop_name = "([^"]+)"',block)
        if kind and pos and size:
            entries.append(dict(i=index,kind=kind[1],x=float(pos[1]),w=float(size[1]),prop=prop[1] if prop else ''))
    danger=[(v['x']-v['w']/2-45,v['x']+v['w']/2+45) for v in entries if v['kind']=='spikes']
    scenery=[v for v in entries if v['kind']=='rock' or v['kind']=='decor' and v['prop'] in ('yurt','dead_tree','tree')]
    scenery.sort(key=lambda v:0 if v['prop']=='yurt' else 1 if v['prop'] in ('tree','dead_tree') else 2)
    placed=[dict(x=v['x']+230,w=290,prop='yurt') for v in entries if v['kind']=='camp']; remove=set()
    for v in scenery:
        half=v['w']*.48
        if any(v['x']+half>a and v['x']-half<b for a,b in danger) or any(abs(v['x']-q['x'])<half+q['w']*.48+28 for q in placed):
            remove.add(v['i'])
        else:placed.append(v)
    blocks=[b for i,b in enumerate(blocks) if i not in remove]
    if 'name="CavePassageExtra"' not in source:
        blocks.append('[node name="CavePassageExtra" type="Marker2D" parent="Layout/Scenery"]\nposition = Vector2(54340, 715)\nscript = ExtResource("3")\nkind = "secret"\ndimensions = Vector2(110, 140)\nexit_offset = 1020.0\n')
    if 'name="SteppeDetailRock' not in source:
        obstacles=[(v['x']-v['w']/2-70,v['x']+v['w']/2+70) for v in entries if v['kind'] not in ('charm','platform')]
        obstacles.extend((q['x']-q['w']/2-60,q['x']+q['w']/2+60) for q in placed)
        detail=0
        for base in range(2200,66000,1700):
            x=base+(base//1700*37)%150
            if any(x+65>a and x-65<b for a,b in obstacles):continue
            detail+=1
            blocks.append(f'[node name="SteppeDetailRock{detail:02}" type="Marker2D" parent="Layout/Rocks"]\nposition = Vector2({x}, 550)\nscript = ExtResource("3")\nkind = "rock"\ndimensions = Vector2(46, 24)\n')
            blocks.append(f'[node name="SteppeDetailGrass{detail:02}" type="Marker2D" parent="Layout/Scenery"]\nposition = Vector2({x-40}, 550)\nscript = ExtResource("3")\nkind = "decor"\ndimensions = Vector2(32, 21)\nprop_name = "grass_tuft"\n')
            if detail>=12:break
    scene.write_text(prefix+'\n'.join(blocks),encoding='utf-8')
    print(scene.stem,'overlaps removed',len(remove),'extra cave passage added')

