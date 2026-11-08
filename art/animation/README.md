# Оригинальные листы анимации

Созданы встроенным imagegen по дизайну проекта. PNG сохранены в этой папке;
их рабочие кадры подготовлены в baked/*.res инструментом tools/bake_frames.gd.
Полные тела заменяют прежнюю сборную анимацию ног. Исходные PNG не изменены.

- hero-v2.png — бег, покой, ранение, приземление, прыжок, рывок, копьё.
- elder-v2.png — покой, объяснение, указание дороги, приветствие.
- enemy-v3.png — покой, движение, меч, ранение, восстановление, поражение.
- boar-v2.png — покой, бросок, подготовка, отдых, ранение, поражение.
- horse-v2.png — покой, ходьба, галоп, испуг.
- terrain-v2.png — отдельные камни без забора, трава, камыш, деревья и опоры.
- eagle-v2.png — взмахи крыльев и планирование беркута.

Все персонажи оригинальные. Листы содержат позы с разным временем удержания;
144 позиции воспроизведения не означают 144 уникальных рисунка.

Промпты generation: stylized-concept, production pixel-art transparent atlas,
consistent complete body, character identity from art/source/02-characters-poses.png,
no pasted limb parts, no text/gridlines, shared grounded baseline and coherent size.
Hero32: eight run frames; four idle,two hurt,two landing; four jump,four dodge;
eight spear attack with anticipation/thrust/follow-through. Elder32: eight idle,
eight talking gesture,eight pointing,eight greeting. Boar32: eight idle,eight
charge,four windup,four recovery,four hurt,four down. Horse16: four idle,four
walk,four gallop,four startle. Clean enemy revision: roomy4columns8rows request,
no motion arcs/glow or disconnectedparts; fouridle,fourwalk,eight sword attack,
fourhurt,fourrecover,eightdefeat. Actual generatedclean sheet has28wholeposes;
32positions use intentionalkneel/downholds. Terrain8: lowgranite,mosscrag,grass,
reeds,willow,steppetree,wooddeck,grassyfloatingrock; no adjacentfence/wood inrocks.
Eagle8: upstroke/midup/level/downstroke/midrise/glide/bank, darkchestnut body,
goldenneck, actualtransparentalpha. Used built-in imagegen, not API/CLI fallback.

## Версия Аягоз

- riders.png — 6 колонок × 4 ряда, герой галоп / удар, враг галоп / удар.
- riders-bow.png — такой же формат, галоп с луком / выстрел для двух всадников.
- campaign-story.png — 2 × 3 сюжетные иллюстрации с бата, дуэлью, боем и отходом.
- steppe-horizons.png — три полосы степи для дневного, вечернего и грозового неба.
- actions/*.res — шестикадровые именованные действия персонажей. Сборка через
  tools/bake_actions.gd из прежних ключевых кадров с промежуточными наклонами
  и сжатием. Не все эти шесть кадров являются самостоятельными рисунками.

Старые банки baked сохраняются как исходники для пересборки actions.
У конных PNG действия расположены по строгой сетке и воспроизводятся прямо
из атласа. Их редакторский предпросмотр находится в Layout.

- archer.png — пеший лучник в общей бронзово-коричневой форме, 6 колонок × 4 ряда.
  Покой, бег, подготовка выстрела, выпуск стрелы. В каждой строке 6 поз.

- infantry.png — воин с саблей в той же форме, 6 колонок × 4 ряда.
  Покой, бег, подготовка, удар. Поражение обоих пеших типов сопровождается
  наклоном тела и затуханием в коде level_two.gd.
