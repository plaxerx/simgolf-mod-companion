# Companion QOL patches

Personal tweaks on top of SimGolf Remastered. They patch an **installed** game,
so they work without rebuilding the program from source.

## Start year 2021

`Apply-CompanionPatches.cmd` (or `Apply-CompanionPatches.ps1`) makes careers
start in 2021 instead of 2001 (the game's calendar opens in March). Close the
game first.

The game stores the year as an offset from the first year and only adds 2001
when it writes the date as text, so saves are unchanged and simply show the
new years. The script finds the 10 display sites by byte signature (8 x
`year + 2001`, 1 x `year + 2000` for "Last Year", 1 in the debug overlay),
keeps the original as `<exe>.companion-backup`, and checks its own work.

- Another year: `Apply-CompanionPatches.ps1 -StartYear 2031`
- Undo everything: `Apply-CompanionPatches.ps1 -StartYear 2001 -StartLand share -StaffRadius 100 -StaffNames off -NightTint vanilla -Celebrities vanilla -ProGolfers vanilla -PixelHdFix off -NewsHold 1 -EscapeAll off -KeepWeather off -LandmarkRadius 100 -WhiteFlowers off -Distances vanilla -Labels off -ProAim off -ScrollEdge off -NewsPopup off -GreenRoll off -ShotFix off -AllShots off -YearEvents yearly -CurveFix off -ClubCache off -RedFlowers off -DesignNames off -SnackPath needed -GolferNames vanilla -StaffMax 20 -StaffSpeed 100 -TourneyBuild open -TourneyWages paid -Calendar vanilla` (gives back the byte-identical program and the original data files)
- Preview: `Apply-CompanionPatches.ps1 -DryRun`
- Re-run after every game update, since an update replaces the program (and
  with it every fix below, the Pixel HD flicker fix included).
  `Apply-CompanionPatches.ps1 -DryRun` shows what is in place.

## Starting land: 2x the vanilla side

Each property has an acreage (rolled again for every new career). The land
generator turns it into a starting square of side `2k`, `k` the largest with
`4k^2 <= acres x 10` in vanilla. The remaster multiplies that by the map area
(the same *share* of a bigger map), so on Huge most properties start owning
nearly everything. This patch uses `acres x 40` on any map size instead:
twice the vanilla side, then year-end tracts up to 156 x 156 on Huge.

The shape depends on the property's coast type, as in vanilla:

| coast type | starting land | 40 acres (shown as 160) | 80 acres (shown as 320) |
|---|---|---|---|
| inland | centred square `2k x 2k` | 40 x 40 | 56 x 56 |
| coastal | band `2k` wide, from the shore to `k` past the centre | 40 x 98 | 56 x 106 |
| island | rounded island, about `2k + 24` across at the middle, water ring | about 64 across | about 80 across |

Measured in game (Huge map): inland Phoenix 80 acres = 56 x 56, coastal
San Diego 40 acres = 40 x 98, island Wales 40 acres = 64 across.
Vanilla 50 x 50 for comparison: inland 80 acres = 28 x 28, coastal 40 acres = 20 x 34.

**World-map acreage label.** The world map's "N acres" (list and hover text)
is multiplied by the same factor (x4 at `-StartLand 2`), so a property reads
as 4x vanilla, matching the 4x land. Like vanilla's label it describes the
`2k x 2k` core; the shore strip of coastal properties and the water ring of
islands come on top. Prices are unchanged.

- Other multiples: `-StartLand 1.5`, `2.5` or `3` (label x2.25, x6.25, x9); `-StartLand share` restores the remaster's rule and label.
- It applies to new courses only; existing saves keep the land they own.
- Source: `[map] start_land=` in `data/mods.ini` (`GEN_START_LAND`, `grid.c`, `golf.json`). The label scaling is in the patcher only (the world-map function needs a decompiler export to patch in source).

## Staff work radius: 1.5x

An employee works around the centre of its zone. On a Huge map the vanilla
reach is small, so `-StaffRadius 150` (the default; 100 to 200) scales all of
it by 50%:

| what | vanilla | 150% |
|---|---|---|
| zone ring drawn (pro, marshal, vendor) | 4 tiles | 6 tiles |
| zone ring drawn (groundskeeper / skilled) | 6 / 8 tiles | 9 / 12 tiles |
| golfers a pro, marshal or vendor walks to | 4 tiles from the centre | 6 tiles |
| mowing search (groundskeeper / skilled) | 12 / 16 tiles, box +-16 | 18 / 24 tiles, box +-24 |
| ball pickup | 5 tiles | 7.5 tiles |

Both ring draws (original and HD) and the staff AI (`FUN_00402a40`) are
patched. Two limits no longer fit their instruction, so they call small code
caves in the program's padding. Patcher only: the AI is generated code.

## Staff names

Every employee used to be "Randy Groundskeeper", "Sally Soda Vendor" and so
on, one name per job. With `-StaffNames on` (the default) each paid
employee gets a random first and last name (74 men's and 58 women's first
names; vendors get women's names, as in vanilla; 116 surnames). The name is
written into the employee's own name field the first time it is shown, so it is
saved with the game and stays. Names you type with Rename are never replaced.
If a fired employee's slot is reused for a different job, the new hire gets a
new name.

The code and name lists live in a small section (`.cmpn`) the patcher adds to
the program. `-StaffNames off` removes it again. Patcher only.

## Night light: brighter and bluer

The course has no lights, so night play needs more to see by.
`-NightTint twilight` (the default) changes two things:

- the clear-night colour the course is multiplied by: (102, 125, 176) becomes
  (115, 145, 224), a nautical-twilight blue (`environment.c`);
- the terrain's moonlit sky-light floor: 0.30 becomes 0.36 (`terrain_lighting.cpp`).

Measured in game at midnight, clear sky, the same view: average colour
(43, 56, 41) vanilla, (47, 64, 49) twilight. Daytime is unchanged, apart from
a little more sky light on terrain while the sun is very low.

Tune it with `-NightTint "r,g,b,floor"` (each 0.2 to 1, e.g.
`"0.5,0.62,0.95,0.40"` for a lighter night); `-NightTint vanilla` restores it.
Source: the same values are in `environment.c` and `terrain_lighting.cpp`.

## Celebrities: 2020s guests

`celebrities.dta` (next to the script) replaces the 2001 list in
`game\Themes\Standard\celebrities.dta`: 36 parody guests, three or four per
celebrity type (action star, pop star, politician, comedian, supermodel,
fitness, female comedian, leading man, movie star, rock star, athlete). The
mod's own 10 fictional guests are still added after them. The original file
is kept as `celebrities.dta.companion-backup`; `-Celebrities vanilla` puts it
back. It is read when the game starts.

## Pro golfers: the 2020s tour

`progolfers.dta` (next to the script) replaces the 57 parody pros of 2001 in
`game\Themes\Standard\progolfers.dta` with 2020s ones (Scotty Shuffler, Rory
McIlroyal, Nelly Accordion, Lydia K.O. and so on). Each takes the slot, skills
and tier note of an old pro, so tournaments are as hard as before. Tiger,
Phil, Ernie, Vijay, Retief and Bernhard stayed, moved down to the 55-65
group: they are on the Champions Tour now. The game's own amateurs and hackers
at the top of the file are unchanged, and the mod's touring pros are still
added after the list. The original is kept as
`progolfers.dta.companion-backup`; `-ProGolfers vanilla` puts it back. Checked
in game: the loaded pro table holds the new names. Saves keep the pros they
already copied.

## Labels: clearer names, typos, job titles, famous golfers

`-Labels on` (the default) rewrites 50 strings in `image\golf.bin` (the
original program the remaster loads; kept as `golf.bin.companion-backup`) and 7
in the remaster's program, each in its own slot:

- typos: "wbs" -> "waste bunkers" (the plural golfers use), "rhododedron" ->
  "azalea" ("rhododendron" does not fit), "aqua hybiscus", "Pot o'Gold",
  "stonehenge", "Ballwasher", "you will need expand", "increases your players
  speed of play", "Ranger/Marshall";
- the default name of the stream terrain, "ravine" / "ravines" -> "stream" /
  "streams". Each course theme sets its own singular (burn, stream, canyon), so
  the HUD already said Stream; now the plural matches;
- staff jobs (plain / skilled): Club Pro / Head Pro (was Celebrity), Ranger /
  Marshal, Greenkeeper / Agronomist (were Groundskeeper / Technician), Cart
  Server / Bartender (were Soda Vendor / Refresher). The remaster's weeds
  message now says "Hire a Greenkeeper";
- the famous-golfer name lists (real 2001 names: Tiger Woods, Jack Nicklaus,
  ...) -> the 2020s tour (Ludvig Iceberg, Zander Chauffeur, Scotty Shuffler,
  Lydia K.O., ...).

- landmarks: "radio antenna" -> "cell tower" ("a hideous cell tower"),
  "oriental house" -> "tea house" ("a traditional tea house");
- celebrity types "fitness guru" -> "influencer", "beauty" -> "icon"; the
  investors Don Trump, L.Probst and B.Gates -> E.Muskrat, J.Bezzos and M.Zuck;
  the fallback celebrity "Bill Clinton" -> "Bubba Klinton"; "Rocky Mtns." ->
  "Rocky Mountains"; the skill "Mental Toughness" -> "Composure";
- remaster tooltips: "Analyze golf shot" -> "Shot preview", "Upgrade (can be
  rotated, Tab)" -> "Upgrade (Tab rotates)", the Extras tray's "Home site" ->
  "Home lot".

Building and skill names go through the game's data tables instead: a small
mod, `mods\companion_labels` (next to the script), copied into the game's
`mods` folder and switched on with `companion_labels=1` under `[mods]` in
`mods.ini`:

- Snack Bar -> Snack Shack, Putting Green -> Practice Green, Cart Garage ->
  Cart Barn, Home Site -> Home Lot, Willow Tree -> Scenic Willow, TV Tower ->
  Camera Tower, TV Booth -> Broadcast Booth. "Halfway House" was the first
  pick, but each course theme copies the snack bar's name from an 11-letter
  slot when the course loads, so it has to fit 11;
- skills: Power, Driving Distance, Driving Accuracy, Iron Play, Putting, Draw
  (right to left), Fade (left to right), Spin Control, Scrambling, Luck,
  Confidence.

Checked in game: the loaded course shows "waste bunkers" and "streams", the new
job titles, building and skill names, landmarks and golfers, and plays normally.
`-Labels off` gives back the byte-identical program, `golf.bin` and `mods.ini`
and removes the mod.

**Bench and flower bed names (source only, not built yet).** The remaster's
placement card showed "Bench design 3" and "Flower bed design 7". In a build
from this source (`design_name` in `ui/ui_hud.c`) the tooltips and the hint
name them: Wooden park bench, Carved box bench, Red bench, Round wood bench,
Backless bench, Lovers' bench; and "Yellow flowers, square bed" ... "Red
flowers, stone-edged bed". A flower design is shape (design / 5: square,
curved, stone-edged) and colour (design % 5), and the colours follow the
course theme: yellow, orange, purple, white, red on standard courses; aqua,
orange, purple, blue, red on tropical; red, orange, purple, blue, pink on
desert. Read from the art loaders and the palette table, not yet seen in a
build. The same source carries the job titles, tooltips and weeds message
above.

## Pixel HD flicker fix (upstream bug)

With Pixel HD textures, the sharp filter and a UI scale that is not a whole
number (on a 1440p screen any UI scale above 2 becomes 2.4, a 1066 x 600
canvas), the course flickered while the game ran: one presented frame per game
frame showed the top-left quarter of the view at double size. Paused, no new
game frames arrive, so no flicker. The original 0.1.36 program does it too.

Cause (`hd_native.c`, `draw_layer_ref`): at a non-whole scale the sharp filter
keeps a whole-multiple copy of each layer and rebuilds it for every new game
frame by switching the render target to the copy and back.
`SDL_SetRenderTarget` resets the render scale, and Pixel HD was drawing the
course into its small picture at scale 1/2, so that frame came out at 2x.

`-PixelHdFix on` (the default) points those two `SDL_SetRenderTarget` calls at
two small helpers in the `.cmpn` section that save the scale before the switch
and put it back after (the section is now read/write/execute to hold the saved
scale). `-PixelHdFix off` restores the calls. The source fix is the same three
lines in `hd_native.c`. Measured with the game's frame dump at 2560 x 1440: 66
bad frames in 66 game frames before, 0 in 90 after.

Without the patch, UI scale 2 (a 1280 x 720 canvas), HD textures, or another
filter also avoid it.

## Scroll edge: no dark bar while scrolling (upstream bug)

With the weather on, scrolling the course up showed a dark bar along the
bottom of the view for a moment, and scrolling down showed one along the top.
The original 0.1.36 program does it too.

Cause (`environment_fx.cpp`): while the course slides to the new camera
position (smooth scrolling), the edge it uncovers still shows the previous
picture. The weather shader looks up each pixel in a material map that covers
only the new picture, and anything outside the map counted as "not the course",
so that strip missed the daylight lift and the wet-ground shading every course
pixel gets.

`-ScrollEdge on` (the default) changes two lines of the shader text inside the
program (the game compiles it at start) so a pixel past the map uses the
nearest map pixel instead. At rest the map covers the whole view, so nothing
else changes. `-ScrollEdge off` restores the text. Measured on the frame dump
at 2560 x 1440 while dragging the view: the strip was 13 to 15 brightness
levels darker than the course just inside it, and is 2 to 6 now, the same as
with the weather off.

## Membership roster on Shift+F9

F1 to F12 all have actions (F1-F10 reports and maps, F11 textures, F12
Options), so the roster moved to Shift+F9 and plain F9 does nothing in the
game. Set in `options.ini`:

```ini
[keys]
membership_roster=Shift+F9 | none
```

That is the format Options > Controls writes, and that page can change it
back (or delete the two lines).

## Money popups fade in and out (source only, not built yet)

The floating "+$" / "-$" amount (`FUN_0040c890` queues it, `drawMoneyLabels`
`FUN_0040c910` draws it once per course frame) used to show at full strength
for its 24 frames and then vanish. In a build from this source it fades up
over the first 4 frames and down over the last 8. `[ui] money_fade=0` in
`data/mods.ini` turns it off.

- `port/src/port/golf/money_labels.c`: an `@override` of `FUN_0040c910`, the
  original line for line (read from the port's compiled function), with the
  text drawn at an alpha taken from the popup's timer. It keeps
  `PORT_TRACE(0x0040c910)`, which the camera controls rely on, and calls the
  game's functions through `icall_lookup`, so it needs no Ghidra prototypes.
- The legacy-text layer gets an alpha channel: `gdi_text_alpha()` (`gdi.c`,
  declared in `legacy_text.h`) stamps each text record, `gdi_legacy_capture`
  copies it into the `LegacyRun`, and `legacy_text_native.c` draws the glyphs
  and underline with that alpha.
- Only the native (Windows) renderer shows the fade. The browser build and any
  text the capture does not pick up stay opaque, as before.
- Not compiled or tried in game: this machine has no compiler or decompiler
  export. Build it, then watch a sale or a purchase on the course.

## News messages stay up longer: 3x

Events, offers and golfer news vanished before they could be read. Not a
companion bug: the game shows each message for `length / 4 + 16` course ticks
(the vanilla timer), and the remaster's 2x to 4x speeds burn through that.
`-NewsHold 3` (the default; 1 to 8) multiplies the timer. While a message is
up, low-priority news that arrives is dropped, as in vanilla, so a longer hold
means a little less chatter. 1 restores the original. Checked in game. In a
build from this source the same is `[ui] news_hold=3` in `data/mods.ini`
(`hud_news_posted`, `hud_game.c`).

## Escape opens the Menu

As shipped, each Esc closed one thing: first the message, then the build bar,
then the tray, and only then the Menu. `-EscapeAll on` (the default) makes one
Esc close the open message or history, fold the build bar, close the open tray,
cancel its tool and open the Menu, like a pause key in most games. The Menu
click waits until the tray has closed.
`-EscapeAll off` restores it. Source: `ui_hud_escape` in `ui/ui_hud.c`. Checked
by reading back the patched code, not yet by pressing Esc in game (the test
bridge's key events do not reach the HUD).

## Weather no longer jumps after a save or dialog

A frame that is not the course (a save, a dialog, a report) threw away the
regional weather, and the next course frame started a new front at once: the
clouds, rain and lighting changed in a single frame. Seen in the game's log
after a save. `-KeepWeather on` (the default) lets the weather wait instead.
`-KeepWeather off` restores it. Source: `hd_native.c`, the two
`initialized = 0` lines. This fixes one cause of "the lighting resets"; if it
still happens while landscaping, there is a second cause not found yet.

## Landmark radius: 2x

A landmark's benefit reaches `(25 x design + 200) / 3` yards in vanilla, 2.7
to 7.7 tiles, small on a Huge map. `-LandmarkRadius 200` (the default; 100 to
300) scales the reach. The placement ring was drawn at 3/4 of the real reach in
vanilla; it now shows the reach itself. Both are patched in the program (the
effect and the ring). 100 restores both.

Other radii: staff are covered by `-StaffRadius`. The other users of the
game's distance function are shot and hole yardages, which must not change.
Bench, flower bed and ball washer effects use other code and were not reviewed.

## White flower beds

The standard flower bed's "White" palette (`FlowerbedA_WhitePal.pcx`) drew
magenta flowers. `-WhiteFlowers on` (the default) makes its petal colours (the
140 entries that differ from the red and yellow palettes) white: the same
brightness lifted 30% of the way to full white, with a faint cool tint. Leaves
and stems are untouched. Every
texture look (classic, smooth, Pixel HD) draws through this palette. The
original is kept as `.companion-backup`; `-WhiteFlowers off` puts it back.
Checked on the sprite sheet; not yet looked at on a course.

## Red flower beds

The standard theme's fifth flower bed colour, "Red" (`FlowerbedA_RedPal.pcx`),
drew pink-magenta flowers. `-RedFlowers on` (the default) turns its petal
colours (the 133 entries that differ from the yellow and white palettes and are
not grey) to a true red (hue 355) at the same brightness and a little more
saturation. Leaves and stems are untouched. The original is kept as
`.companion-backup`; `-RedFlowers off` puts it back. Checked on the sprite
sheet; not yet looked at on a course.

## Design names: flowers, trees and benches say what they are

The design tiles for flower beds, benches and scenic trees had tooltips like
"Flower bed design 7". With `-DesignNames on` (the default) they name the
design:

- **Flower beds**: the flower by its colour and the course theme, then the bed:
  "Red roses, curved bed". Standard: yellow daisies, orange marigolds, purple
  irises, white carnations, red roses. Desert: red poppies, California poppies,
  purple sage, blue lupines, pink primroses. Tropical: aqua hibiscus, orange
  bougainvillea, purple orchids, blue hydrangeas, red anthuriums. Beds are
  square, curved or stone-edged.
- **Scenic trees**: flowering plum, dogwood, American elm, Japanese maple,
  Monterey cypress, jacaranda, peach tree.
- **Benches**: wooden park bench, carved box bench, red bench, round wood
  bench, backless bench, lovers' bench.

The tooltip call in `place_panel` goes to 143 bytes of code in the `.cmpn`
section (+0x1400, with the names); any other tooltip prints as before. Checked
under emulation for every design in every theme. Not yet seen in the running
game. `-DesignNames off` restores the numbers. The same names are in the source
(`ui_hud.c`, `design_name`).

## Clubhouse cache: no more flicker zoomed out (upstream bug)

With the animated clubhouse (`ui\clubhouse`), zoomed out, the clubhouse and
nearby buildings kept switching between the remastered and the old drawing.
The art cache is capped at 256 MB, and zoomed out the rest of the course fills
it; the clubhouse's large animation frames were evicted between uses, and while
any frame reloads the whole clubhouse falls back to the old art. With
`-ClubCache on` (the default) the cache evicts clubhouse frames last. 64 bytes in
the `.cmpn` section (+0x1200), a new sort order for `tex_evict`. Tested zoomed
out on a copy of the game: 726 clubhouse reloads in a minute before, 1 after.
`-ClubCache off` restores the shipped order.

## Snack bar path: snack shacks work anywhere

A snack shack (golf's Snack Bar) only opened when a cart path joined it to the
clubhouse; otherwise it showed "No path" and the monthly "will not be
operational" warning. With `-SnackPath free` (the default) it works without a
path, like a bench or a ball washer. Every other building still needs its path.
golf's path flood fill (`FUN_0042f340`) already has its own branch for snack
bars; that branch now marks the building as connected. 17 bytes in the `.cmpn`
section (+0x17E0) and a jump at the branch. Tested in the running game (a copy):
a snack bar moved off the path network stays connected, other kinds do not.
`-SnackPath needed` restores the shipped rule.

## Shot distances: modern, one set of tees

The game has a single tee per hole, so short hitters must be able to play
the same yardage as long hitters. `-Distances modern` (the default) changes how
far golfers can hit, so a 7200-yard par 72 plays fairly:

| | vanilla | modern |
|---|---|---|
| base tee distance, long / short hitters (difficulty 1-3) | 200 / 150 | 230 / 210 |
| the same on Easy | 240 / 175 | 260 / 235 |
| shots from any lie except the tee | 80% of the tee | 90% |
| maximum | 330 yards | no cap |

Each golfer level adds about 17 yards, and rough and sand still cost 12.5% to
37.5%. The Power Hitter and Long Driver skills are unchanged, but with no cap
each point above 10 now counts. The pro hits 310 off the tee and 252 from the
fairway at 10/10, 360 and 270 at 15/10, and 410 and 288 at 20/10. Holes play
shorter, so build longer ones. Saves are not affected.

Two places in the maximum-distance function (`FUN_00422530`) change, 11 bytes
in all. The launch-speed solver was checked to hit its target out to 600 yards.
AI golfers' planning and par balance have not been tried in game.
`-Distances vanilla` restores it. Details and the full tables are in
`notes\shot-distances.md`. Patcher only.

## Pro free aim: hold Shift

When you aim the pro's shot, the game snaps the target to a tile centre or
corner. One tile is 25 yards, so you are aiming on a 12.5-yard lattice. With
`-ProAim shift`, holding **Shift** while aiming targets the exact point under
the mouse, to the pixel. The preview, the yardage and the club all follow it,
and the ball flies there. Skill error, wind and the lie still apply. Without
Shift, aiming is as shipped, so putts still lock onto the cup. AI golfers are
unchanged.

The code is about 460 bytes in the `.cmpn` section and is called from two
places:

- **The aim pick:** with Shift down, it searches for the ground point whose
  screen position is nearest the mouse.
- **The swing:** it aims the pro's own shot at that saved point instead of the
  tile centre.

Shift is read with `GetAsyncKeyState`. The code was checked on scratch copies
(exact round trips) and under a CPU emulator, but it has **not been tried in
the running game yet**. It is on by default; `-ProAim off` restores the
shipped aiming. Details are in
`notes\pro-shot-aim.md`. Patcher only.

## News popups: important news pauses the game

The news strip shows one message at a time for a few seconds. A new
important message also replaces one still on screen, so offers and visitors
were easy to miss. With `-NewsPopup on` (the default), each important message
also opens in the game's own OK box (the Frosted Mint dialog when
`ui.dialogs=frosted_mint`). The game waits until you close it with OK or Esc.
Messages that arrive together queue up (4 at most) and open one after another.

Popups:
- a VIP's arrival, last hole and verdict (County Commissioner, Corporate CEO,
  Wealthy Heiress), including the land approval;
- landmarks, the story events, tournaments;
- a scenario's goals, and anything else the game posts as important.

Strip only, as before:
- build and course feedback ("Can't build bench there.", path and hole hints,
  "Trees must be transplanted.");
- "Game Saved.";
- golfer chatter and other low-priority news;
- the hole-by-hole score during the pro's matches.

How it works:
- **Post:** a hook in the news function (`FUN_0040cb00`) copies each
  priority-1 post into a small queue in the `.cmpn` section.
- **Show:** a hook in the main loop, at the spot where the game already opens
  its land-offer dialog, shows the queue with the popup menu (`FUN_0046d6e0`).
  Long messages are wrapped at 44 characters.

The `.cmpn` section grows from 4 KB to 8 KB for this; an older install is
grown in place. Checked under a CPU emulator (queue, filters, wrapping,
registers) and on scratch copies (exact round trips). It is installed but **not
yet seen in the running game**. `-NewsPopup off` restores the strip-only news.
Patcher only.

## Green roll: greens no longer run the ball away

A rolling ball gets a friction value from the ground it is on (green 3,
fairway 3, rough 2, sand 1), minus the slope in the direction it rolls. From 0
to 4, friction slows the ball by 1/2 to 1/32 of its speed each tick. At 5 or
more, the game **speeds the ball up** towards a fixed top speed, for up to 128
ticks. On a green, any downhill of 2 levels reached 5, so the ball ran off the
green, often into water. The break was also strong: the ball turned by a fixed
amount each tick, whatever its speed, so it swung round onto the fall line and
then sped down it.

With `-GreenRoll on` (the default), while the ball is on a green:

- friction is at most 4, so a downhill green still lets the ball run further,
  but never speeds it up;
- the break is half as strong.

Everything else rolls as shipped.

One thing the code shows: **a putt struck from the green ignores slope
entirely** in this game, with no break and no speed change; only the green's
own friction applies. Slope acts on balls that come onto the green from off
it: approach shots, chips, and putts from the fringe. Those are the shots this
patch changes.

The two hooks are 64 bytes in the `.cmpn` section, at the friction test and at
the break in the golfer update (`FUN_004289e0`). Checked under a CPU emulator
against the original roll code (700 cases: other ground unchanged, on a green
the same as friction 4 and half the turn) and on scratch copies (exact round
trips). It is **not yet tried in the running game**. `-GreenRoll off` restores
the shipped roll. Details are in `notes\green-roll.md`. Patcher only.

## Shot fix: the pro's shot no longer gets stuck

Sometimes the pro waited for a shot and clicking the course did nothing until
a save and reload. The game commits the shot only when four things hold: a
left click, the pro's dock in "waiting" mode (3), a short delay since the turn
began, and the mouse above the old dock (more than 120 pixels from the bottom
of the game screen). Two of these could stay false:

- **The bottom strip.** The Frosted Mint HUD hides the old dock, so the course
  shows where it used to be. Aiming there worked (the aim line appears), but
  the click was still refused. With `-ShotFix on` (the default) the click uses
  the same limit as the aiming, so it works anywhere on the course. With the
  original HUD, the old limit stays.
- **Dock mode 4.** Closing one of the pro's pages while the pro waits leaves the
  dock in mode 4, which refuses the click. Now **choosing a shot type re-arms
  the shot**: while the pro waits, it clears the delay and turns mode 4 back
  into 3. If a shot ever seems stuck, click a shot type (or the same one again),
  then click the target.

The code is 128 bytes in the `.cmpn` section, at the click test in the main
loop (`FUN_0040f5c0`) and at the five shot-type buttons of the pro page
(`FUN_00436060`). Checked on scratch copies (disassembly and exact round
trips). It is installed but **not yet seen in the running game**. `-ShotFix off`
restores the shipped click. Patcher only.

## All shots: fade, draw and backspin from any lie

In the rough, sand or trees (any ground with a lie penalty), the game turned
fade, draw and backspin back into a straight shot when you aimed, and the
Frosted Mint HUD showed only straight and low punch. With `-AllShots on` (the
default) all five shot types work from every lie. The lie still counts: the
shot code sends curved shots down its bad-lie path, which applies that lie's
error and distance loss, exactly as it already did for straight shots from
there. Two byte edits (the reset in the aiming code and the HUD's button
count). `-AllShots off` restores the shipped choices. Patcher only.

## Curve fix: long draws and fades no longer fly off

A draw or fade launches a little faster than a straight shot, to make up for
its curved path. The game works that extra out as `1 + 16 / (400 - yards)`
for shots of 250 yards and more. Golf capped every shot at 330 yards, so the
extra was never more than about 23 %. Modern distances (`-Distances modern`)
have no cap, and the formula runs away near 400 yards:

| Shot | Speed vs straight, as shipped | With the fix |
|---|---|---|
| 330 yards | x1.23 | x1.23 |
| 360 yards | x1.40 | x1.23 |
| 380 yards | x1.80 | x1.23 |
| 395 yards | x4.2 (the ball flew about 700 yards in a test) | x1.23 |
| 400 yards and more | divides by zero, or no speed at all | x1.23 |

With `-CurveFix on` (the default) the extra speed counts at most 330 yards, so
a draw or fade is exactly as shipped up to 330 yards and gets the shipped 330-yard
extra beyond. Straight shots, punch and backspin are unchanged, and so is how
far the ball turns. Curved shots by AI golfers go through the same code and are
fixed too. 32 bytes in the `.cmpn` section, called from the two places in
`FUN_00424120`. Checked under emulation and on scratch copies (exact round
trips). Not yet seen in the running game. Details are in `notes\shot-fix.md`.
`-CurveFix off` restores the shipped formula. Patcher only.

## Year events every month

There are no date-based unlocks, so the calendar mostly counts how often the
game's once-a-year events come round. With `-YearEvents monthly` (the default)
they come round on the 1st of every month instead:

- **The board's review** (vanilla "END of YEAR", every March 1) now opens every
  month as "END of MONTH: March 2026". It shows the month that just ended
  against the one before it (cash, fun rating, skill rating, membership; the
  columns are "This Month" and "Previous"), with that month's highlights.
- **The SGA tournament invitation** (vanilla: July 1, when the course
  qualifies and the pro is not out on the course) can come every month.
- **The yearly drift**: the visitor mix shifts a step, and the map's
  stat layers fade by 1/8, every month.

The calendar itself is unchanged: 1024 ticks a month, March to October, the
same seasons, weather, autosaves, wages, income, debt interest and tournament
dates, and saves are fully compatible both ways. One exception is on purpose:
**the board's debt verdict stays yearly**. Its warnings ("You have two years to
return to positive cash") and its strike count (three strikes and the board
ends your contract) still happen on March 1 only. Monthly strikes would fire
you after three months in debt. With the slow calendar (next section, on by
default) a month lasts as long as a whole old year, so the verdict comes on
every 1st instead, and its warnings read "You have two months to get back in
the black." and "Just one more month to get out of debt." Three strikes still
take three old years of play.

The code is 128 bytes in the `.cmpn` section (+0x1380: the review title and the
March-only debt gate), plus seven byte edits in the main loop and the review,
three strings in `image\golf.bin` and one in the program. Details in
`notes\year-events.md`. Tested on a scratch copy of the game (monthly reviews
in April and May, the invitation in May, the debt verdict on March 1 only;
`yearly` restores the byte-identical files). `-YearEvents yearly` restores the
shipped schedule. Patcher only.

## Slow calendar: a month lasts a whole old year

With `-Calendar slow` (the default) the calendar runs 8x slower: one month
takes as long to play as the original game's whole operating year (March to
October). Everything that ran on play time keeps its real-time pace:

- **Wages** are paid exactly as often in real time as before (every
  `1024 / (difficulty + 2)` old ticks), so a calendar month now holds 8x the
  paydays. The difficulty screen says so: "2x8 per month" ... "5x8 per month".
- Golfers, staff, weeds, animations, timed events, history samples and the
  mid-month autosave keep their real-time cadence.
- What belongs to the calendar follows the calendar: the date, seasons and
  weather, the 1st-of-month events (the monthly autosave, 2 % interest on debt,
  stat fading, path warnings) and the yearly events. So interest and the 1st's
  events come 8x less often in play time. With `-YearEvents monthly` the board's
  review comes on every 1st, which is once per old year of play.
- Tournaments run on play time, so the calendar barely moves during one, and
  its wages are the same real-time wages as before. `-TourneyWages unpaid`
  (above) stops them while a tournament is on.

Saves keep their date and load in either mode. Switching a running career
from slow back to vanilla works, but timers that were set in slow mode (for
example a golfer's next decision) can wait longer than usual once.

The saved clock is still the calendar. A fast counter in the `.cmpn` section
(+0x4040), kept as `clock x 8 + sub-step`, drives the 129 play-time reads; a
hook in the main loop advances it and derives the clock. Four constants are
scaled (the 1st-of-month gate, the tutorial's dates), plus two debt strings
in `image\golf.bin` and the payroll label in the program. The section grows to
20 KB (+0x4000 to +0x407F). Details in `notes\slow-calendar.md`. Tested on a
scratch copy of the game (wage timing, the 1st of the month, autosaves, a new
career, a save loaded in both modes). `-Calendar vanilla` restores the
shipped clock. Patcher only.

## Golfer names: real names

Visiting golfers are the club's 100 regulars: golf's 75 (first names only:
Snoop, Biggie, Mahatma, J.P. ...) and the 25 the remaster added (pun names: Bea
Line, Gus Socket ...). Each is a full character with a face, traits and
history, so the game cannot have more of them without a source change. With
`-GolferNames real` (the default) each regular gets a real "First Last" name
instead, drawn from 168 male and 158 female first names and 295 surnames
(about 88,000 combinations, over 800 for every golfer). No two golfers share a
first name, so they are easy to tell apart. A new career draws a new set, and
the names are kept in the save. Loading an older save renames its golfers
once. The remaster's 25 keep their first name, because their bios use it
("Bea Simmons"). The player, club pro, celebrities and touring pros are left
alone.

The naming runs after the roster is set up (`roster_seed`, a new career) and
after each load (`roster_append_tables`). A tag in each named profile (+0x2D)
means a name is never changed again. It needs the remaster's new roster (on by
default). Code, tables and names are in the `.cmpn` section (+0x2000 to
+0x3FFF, which grows the section to 16 KB). Tested in the running game (a copy,
with a real save): every regular has a real name, both in the roster and
through golf's own name function. `-GolferNames vanilla` stops the naming;
names already kept in a save stay.

## Staff: 50 hires, 25% faster walking

- **Limit.** `-StaffMax 50` (the default) sets the remaster's own hiring limit,
  `[gameplay] staff_max` in `mods.ini` (20 as shipped, up to 100; the
  Options page's "Staff you can hire" slider writes the same key). The staff
  pool holds 128, so 50 fits with room for the other walkers.
- **Speed.** `-StaffSpeed 125` (the default, 100 to 195): employees walk 25%
  faster on every terrain. The staff AI (FUN_00402a40) moves a walker
  speed x 64 per frame (speed 2..6 by terrain); the 64 and the two special
  steps built from it (128, 192) are scaled in place, 3 immediates, no code
  added. Tested in the running game (a copy): every step per frame matched
  x80 (106, 66, 53, 50/50, 20/20), none the shipped x64.

## Tournaments: no building, no wages

While a tournament is on (game flag `0x200000`, from accepting the SGA's
offer to the results):

- `-TourneyBuild locked` (the default): no construction. Every frame, paused
  or not, any terrain, elevation or building tool is put down, so nothing can
  be painted, raised or placed until the tournament ends. Tested (a copy, a
  save in a tournament): a picked tool drops the next frame; with the flag
  clear it stays.
- `-TourneyWages unpaid` (the default): staff draw no wages, as golf already
  does in Championship mode. Tested: a wage tick during the tournament paid
  0 of 17 employees, after it 16 of 17 (as shipped).

Both are small hooks in the `.cmpn` section (+0x12A0, +0x12E0). How
tournaments and the SGA's standards work: `notes/tournaments.md`.

## Map size

Options > Gameplay > Size of new courses already goes up to Huge (158 x 158).
In the 0.1.37 build the size is read only when the game starts, so a size
picked mid-session applies after a restart.

`-MapScale 1|2|4|10` writes the size to `options.ini`
(50x50, 70x70, 100x100, 158x158).

The source fix in `port/src/port/golf/grid.c` re-reads the setting when a new
game starts, so the restart is no longer needed. It takes effect only in a
build made from this source.
