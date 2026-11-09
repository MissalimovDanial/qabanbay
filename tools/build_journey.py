"""Author editable scenes; runtime never regenerates the student's layout."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
NAMES=['main','level_two','level_three','level_four','level_five']
LENGTHS=[72000,82000,80000,72000,72000]
ARENAS=[70000,80000,68000,70000,70000]
COUNTS=[[],[3]*10,[2]*4,[4]*5,[4]*8]
for chapter,(name,length,arena) in enumerate(zip(NAMES,LENGTHS,ARENAS),1):
    lines=['[gd_scene load_steps=4 format=3]',
      f'[ext_resource type="Script" path="res://scripts/{"level_two"}.gd" id="1"]',
      '[ext_resource type="Script" path="res://scripts/editor/level_layout.gd" id="2"]',
      '[ext_resource type="Script" path="res://scripts/editor/level_item.gd" id="3"]',
      f'[node name="Level{chapter}" type="Node2D"]','script = ExtResource("1")',f'chapter_number = {chapter}',
      '[node name="Layout" type="Node2D" parent="."]','script = ExtResource("2")',f'chapter_number = {chapter}',
      f'world_length = {length}.0',f'arena_start = {arena}.0',f'exit_x = {length-450}.0']
    for group in ['Rocks','Gaps','Platforms','Spikes','Guards','Charms','Scenery','Checkpoints']:
        lines.append(f'[node name="{group}" type="Node2D" parent="Layout"]')
    count={}; gaps=[]; platforms=[]
    def item(kind,x,y=550,w=80,h=50,group=None,**props):
        group=group or {'rock':'Rocks','gap':'Gaps','platform':'Platforms','spikes':'Spikes','camp':'Guards','guard':'Guards','charm':'Charms','decor':'Scenery','checkpoint':'Checkpoints'}.get(kind,'')
        count[kind]=count.get(kind,0)+1
        parent='Layout'+('/'+group if group else '')
        lines.extend([f'[node name="{kind.title()}{count[kind]:03}" type="Marker2D" parent="{parent}"]',f'position = Vector2({x}, {y})','script = ExtResource("3")',f'kind = "{kind}"',f'dimensions = Vector2({w}, {h})'])
        lines.extend(f'{key} = {value}' for key,value in props.items())
    def gap(a,b,depth=0):
        depth=depth or (95 if b-a<200 else 165)
        gaps.append((a,b,depth)); item('gap',(a+b)/2,w=b-a,h=depth or 380,ravine_depth=float(depth))
    def platform(x,y,w):
        platforms.append((x,y)); item('platform',x,y,w,22)
        item('charm',x,y-65,22,22)
    def clear(x,margin=100):
        return all(not a-margin<x<b+margin for a,b,_ in gaps)
    item('hero_spawn',180); item('elder',390)
    item('boss_spawn',arena+650)
    # Landmark rhythm: short jumps, stepping stones, gullies and open grasslands.
    for index,x in enumerate(range(3600,arena-2400,2800)):
        if chapter in (1,2,4) and x+600>=41800 and x<=43250:continue
        if chapter in (1,3,5) and x+600>=25000 and x<=26400:continue
        if index%4==0:
            gap(x,x+1100)
        elif index%4==1:
            item('spikes',x,w=70 if chapter==1 else 100,h=25)
        elif index%4==2:
            gap(x,x+1300)
        else:
            item('decor',x,w=280,h=210,prop_name='"yurt"')
    # Place a long ravine between the repeating clusters.
    bridge_x=17100 if chapter!=3 else 23300
    # Remove overlap with regular hazards by placing between the repeating clusters.
    if clear(bridge_x,800):
        gap(bridge_x,bridge_x+1400)
    # A playable gully with a real floor, enemies and steps back up.
    if chapter in (4,5):
        gx=30000
        gap(gx,gx+1000,175)
        item('rock',gx+180,725,90,48)
    if chapter in (1,3,5):
        pit=25000
        gap(pit,pit+1400,175)
        item('secret',pit+340,725,110,140,group='Scenery')
    if chapter in (1,2,4):
        lake=41800
        gaps.append((lake,lake+1450,0))
        item('lake',lake+725,w=1450,h=400,group='Gaps')
        for j in range(5):
            platform(lake+150+j*285,490 if j%2==0 else 460,269)
    if chapter in (2,4,5):
        item('passage',12600,550,420,295,group='Scenery')
    for a,b,depth in list(gaps):
        if depth>0 and b-a>=400:
            platform(a+(b-a)*0.28,495,470)
            platform(a+(b-a)*0.72,485,470)
    camps=COUNTS[chapter-1]
    for idx,quota in enumerate(camps):
        x=2600+idx*(arena-6200)/max(1,len(camps)-1)
        if chapter==4 and idx==2 or chapter==5 and idx==3:x=30500
        else:
            while not clear(x,650): x+=370
        item('camp' if idx%2==0 and x!=30500 else 'guard',round(x),w=120,h=145,enemy_count=quota)
    if chapter in (4,5):
        # Move one authored encounter into the gully rather than adding a new quota.
        # The unique marker remains editable and owns its finite group.
        pass
    for x in range(2400,arena-1000,1500):
        if clear(x,140):
            item('decor',x,w=50,h=32,prop_name='"grass_tuft"')
            item('rock',x+110,w=85+(x%3)*10,h=45)
            if x%4500==2400:
                item('decor',x-250,w=160,h=235,prop_name='"dead_tree"')
            for dx in (0,38,76):item('charm',x+dx,490,w=22,h=22)
    for x in ([1050,1600,2400] if chapter==1 else [])+list(range(9000,arena,9000)):
        while not clear(x,200): x+=400
        item('checkpoint',x)
        item('decor',1900 if chapter==1 and x==1600 else x-150,w=240,h=185,prop_name='"yurt"')
    item('decor',390,w=300,h=230,prop_name='"yurt"')
    # Authored finish clearing; never teleport to the map after the last kill.
    item('decor',length-380,w=310,h=235,prop_name='"yurt"')
    text='\n\n'.join(lines)+'\n'
    import re
    def remove_hazard(match):
        block=match.group(0)
        if 'kind = "spikes"' not in block: return block
        pos=re.search(r'position = Vector2\(([^,]+),',block)
        size=re.search(r'dimensions = Vector2\(([^,]+),',block)
        x=float(pos[1]); half=float(size[1])/2
        return '' if any(x+half>a and x-half<b for a,b,_ in gaps) else block
    text=re.sub(r'\[node[^\n]*\][\s\S]*?(?=\[node|$)',remove_hazard,text)
    (ROOT/'scenes'/f'{name}.tscn').write_text(text,encoding='utf-8')
    print(chapter,length,len(gaps),len(platforms),sum(camps))

# Apply deliberate spacing and optional underground routes to regenerated scenes.
import subprocess, sys
subprocess.run([sys.executable,str(ROOT/"tools/polish_placement.py")],check=True)
