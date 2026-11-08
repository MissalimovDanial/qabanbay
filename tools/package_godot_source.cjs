/* A clean, separate Godot school project. The student's original project is untouched. */
const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');

const root = path.resolve(__dirname, '..');
const stageRoot = path.join(root, 'build', 'school-project');
const projectRoot = path.join(stageRoot, 'Qabanbay-School');
const outputZip = path.join(root, 'downloads', 'qabanbay-school-godot.zip');
const stageOnly = process.argv.includes('--stage');

function filesUnder(folder) {
  if (!fs.existsSync(folder)) return [];
  return fs.readdirSync(folder, {withFileTypes: true}).flatMap(entry => {
    const full = path.join(folder, entry.name);
    return entry.isDirectory() ? filesUnder(full) : [full];
  });
}

function cleanStage() {
  // Resolve and verify the one disposable packaging destination before deletion.
  const resolved = path.resolve(stageRoot);
  const expected = path.resolve(root, 'build', 'school-project');
  if (resolved !== expected || path.dirname(resolved) !== path.join(root, 'build')) {
    throw new Error(`Refusing to clean an unexpected destination: ${resolved}`);
  }
  fs.rmSync(resolved, {recursive: true, force: true});
  fs.mkdirSync(projectRoot, {recursive: true});
}

function stageProject() {
  cleanStage();
  const selected = [];
  for (const folder of ['scripts', 'scenes', 'art', 'tests']) {
    for (const file of filesUnder(path.join(root, folder))) {
      if (file.endsWith('.import')) continue;
      selected.push(file);
    }
  }
  for (const relative of [
    'project.godot', 'export_presets.cfg', 'LICENSE', 'README.md',
    'docs/РЕДАКТИРОВАНИЕ_В_GODOT.md',
    'tools/bake_frames.gd', 'tools/create_editable_levels.gd',
    'tools/package_godot_source.cjs',
  ]) {
    const file = path.join(root, relative);
    if (!fs.existsSync(file)) throw new Error(`Required source is not ready: ${relative}`);
    selected.push(file);
  }
  for (const source of [...new Set(selected)]) {
    const relative = path.relative(root, source);
    const destination = path.join(projectRoot, relative);
    fs.mkdirSync(path.dirname(destination), {recursive: true});
    fs.copyFileSync(source, destination);
  }
  fs.writeFileSync(path.join(projectRoot, '.gitignore'), '.godot/\n.runtime*/\nbuild/\ndownloads/\n', 'utf8');
  for (const scene of ['main', 'level_two', 'level_three', 'level_four', 'level_five', 'campaign_map']) {
    if (!fs.existsSync(path.join(projectRoot, 'scenes', scene + '.tscn'))) {
      throw new Error(`Missing school-project scene: ${scene}`);
    }
  }
  console.log(`Separate school project staged: ${projectRoot}`);
  console.log(`Project entry: ${path.join(projectRoot, 'project.godot')}`);
}

function zipProject() {
  const python = process.env.PYTHON_BIN || path.join(process.env.USERPROFILE || '', '.cache',
    'codex-runtimes', 'codex-primary-runtime', 'dependencies', 'python', 'python.exe');
  if (!fs.existsSync(python)) throw new Error('Set PYTHON_BIN to a Python 3 executable.');
  fs.mkdirSync(path.dirname(outputZip), {recursive: true});
  const zipCode = [
    'import pathlib,sys,zipfile',
    'stage=pathlib.Path(sys.argv[1]); out=pathlib.Path(sys.argv[2])',
    'with zipfile.ZipFile(out,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=6) as z:',
    ' for p in sorted(stage.rglob("*")):',
    '  rel=p.relative_to(stage)',
    '  if any(v==".godot" or v.startswith(".runtime") or v in ("build","downloads") for v in rel.parts): continue',
    '  if p.is_file(): z.write(p,rel.as_posix())',
    'with zipfile.ZipFile(out) as z:',
    ' bad=z.testzip()',
    ' assert bad is None,bad',
    ' names=set(z.namelist())',
    ' assert "Qabanbay-School/project.godot" in names',
    ' assert all("Qabanbay-School/scenes/"+v+".tscn" in names for v in ("main","level_two","level_three","level_four","level_five","campaign_map"))',
    ' assert all(not any(v==".godot" or v.startswith(".runtime") for v in pathlib.PurePosixPath(n).parts) for n in names)',
    ' print(str(out)+": "+str(len(names))+" files, "+str(out.stat().st_size)+" bytes")',
  ].join('\n');
  const result = cp.spawnSync(python, ['-c', zipCode, stageRoot, outputZip], {
    cwd: root, stdio: 'inherit', windowsHide: true,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) throw new Error(`ZIP packaging failed with exit code ${result.status}`);
}

stageProject();
if (!stageOnly) zipProject();
