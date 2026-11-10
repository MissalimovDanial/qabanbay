from pathlib import Path
import shutil
from zipfile import ZipFile, ZIP_DEFLATED

source=Path(__file__).resolve().parents[1]
workspace=source.parent
destination=workspace/'Qabanbay-Levels'
names=['main','level_two','level_three','level_four','level_five']
files=[p for p in source.rglob('*') if p.is_file() and not any(v in {'.godot','.git','__pycache__'} for v in p.relative_to(source).parts)]
for number in range(1,7):
    label=f'Level{number}' if number<6 else 'LevelMax'
    target=destination/label
    target.mkdir(parents=True,exist_ok=True)
    for item in files:
        relative=item.relative_to(source)
        if relative.parts[0] in {'tests','tools'} and relative.as_posix() != 'tools/web_loading.html':continue
        if relative.parts[0]=='scenes' and number<6 and item.stem!=names[number-1]:continue
        result=target/relative
        result.parent.mkdir(parents=True,exist_ok=True)
        if not result.exists() or item.stat().st_mtime_ns!=result.stat().st_mtime_ns or item.stat().st_size!=result.stat().st_size:
            shutil.copy2(item,result)
    project=(source/'project.godot').read_text(encoding='utf-8')
    project=project.replace('Кабанбай — учебный проект',f'Кабанбай — {label}')
    if number<6:project=project.replace('scenes/campaign_map.tscn',f'scenes/{names[number-1]}.tscn')
    (target/'project.godot').write_text(project,encoding='utf-8')
    downloads=workspace/'Qabanbay-Downloads'
    downloads.mkdir(exist_ok=True)
    with ZipFile(downloads/(label+'.zip'),'w',ZIP_DEFLATED,compresslevel=1) as pack:
        for part in target.rglob('*'):
            relative=part.relative_to(target)
            if not part.is_file() or '.godot' in relative.parts or 'screenshots' in relative.parts:continue
            pack.write(part,Path(label)/relative)
    print(label,'ready')
destination.joinpath('README.md').write_text('Открой project.godot нужной папки через Импорт в Godot 4.7.2.\nLevel1–Level5 запускают отдельные уровни, LevelMax — карту и кампанию.\nРедактируй сцену в scenes, затем F6 для проверки. Подробности в README каждой копии.\nИзменения между копиями не синхронизируются автоматически.\n',encoding='utf-8')
archive=workspace/'Qabanbay-Journey.zip'
with ZipFile(archive,'w',ZIP_DEFLATED,compresslevel=1) as out:
    for item in files:out.write(item,Path('Qabanbay-School')/item.relative_to(source))
with ZipFile(archive) as check:assert check.testzip() is None
print('Source archive CRC checked',archive.stat().st_size)
