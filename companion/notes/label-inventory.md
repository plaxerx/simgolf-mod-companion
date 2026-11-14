# Label inventory: names and descriptions to fix

A map of the player-visible names in SimGolf Remastered 0.1.36/0.1.37, what is wrong
with them, and a proposed replacement. **Everything below is now applied**
(`-ProGolfers modern` and `-Labels on`), except the bench and flower bed names,
which are in the source and need a build. Where the applied name differs from the
proposal:

| Proposal | Applied | Why |
|---|---|---|
| Snack Bar -> Halfway House | Snack Shack | each course theme copies the name from an 11-letter slot on load |
| Pathway -> Cart Path, Benches -> Bench | unchanged | the remaster's Extras tray names these categories itself, with no room to grow |
| ravine -> creek | stream / streams | the themes set the singular themselves (burn, stream, canyon) |
| Technician -> Superintendent / Head Keeper | Agronomist | the remaster's copy holds 10 letters |
| Soda Vendor / Refresher -> Drinks Cart / Cart Server | Cart Server / Bartender | the remaster's copy holds 9 letters for the skilled form |
| Swim Club -> Pool Club | unchanged | kept (this course's theme shows it as Tennis Court anyway) |
| dinosaur tarpit -> dinosaur tar pit | unchanged | 16 letters, the slot holds 15 |
| rhododendron | azalea | 12 letters, the slot holds 11 |
| E.Muskrat, J.Bezzos, M.Zuck(erbird) | E.Muskrat, J.Bezzos, M.Zuck | slots of 11, 11 and 7 |
| flower names like "White carnations, low border" | "White flowers, square bed" | the art is three bed shapes (square, curved, stone-edged) in five theme colours |

The original wording of the inventory follows, for reference.

Source of the current text: `image\golf.bin` (the original program image, loaded at
0x400000; the remaster reads these strings from it at run time), the remaster's own
UI source (`port/src/port/ui/ui_hud.c`), and the theme files in `game\Themes\Standard`.

## How each kind of label can change

| Route | What it covers | Limit | Rebuild? |
|---|---|---|---|
| **T** theme file | celebrities, pro golfers, stories (`.dta`, `.txt`) | 31 chars a name | no (patcher copies the file) |
| **D** data mod | building names (15), terrain names (31), skill labels (24), trait labels (20), personalities | as shown | no (`mods/<id>/data/*.json`) |
| **P** in-place string in golf.bin | everything else the original game prints: landmark and flower names, staff jobs, sponsors, messages | the string's slot, shown as **max** below | no (patcher, like the other byte patches) |
| **S** remaster source | the remaster's own HUD text: tooltips, tray titles, "Bench design 3" | none | yes, or an in-place exe string patch of the same length |

"max" is the room the slot has before the next string, not counting the
terminator. A longer name needs a new string in the `.cmpn` section and a moved
pointer, which is possible but is more work per label.

---

## 1. Pro golfers (done: `-ProGolfers modern`, route T)

`companion/progolfers.dta` replaces the 57 parody pros of 2001 with the 2020s tour.
Each new pro takes the slot, skills and tier note of an old one, so tournaments are
exactly as hard as before. The amateurs, hackers and "J... Pro" characters at the
top of the file are the game's own and are unchanged.

The joke you asked for: Tiger, Phil, Ernie, Vijay, Retief and Bernhard are still
there, but they moved down to the 55-65 group. Champions Tour.

| Tier | Pros |
|---|---|
| 55 | Tiger Forest, Bernie Longer, Lexi Tomson |
| 60-65 | Brooke Hendershot, Fill Nickelsworth, Elsie Erns, J.V. Singbird, Celine Boutique, Hannah Greens, Retief Duckwalk |
| 70-73 | Shane Lowtide, Sepp Stroka, Corey Corners, Keegan Broadly, Charley Hullabaloo |
| 75-78 | Ricky Fouler, Jason Daylight, Adam Scotch, Max Homer, Rose Zing |
| 80-85 | Tony Finale, Justin Rosebud, Sam Sunburns, Rustle Henley, Minwoo Leeway, Walkin' Neiman, Bob MacTire, Cameron Younger, Will Zealotorious, Sungjay Ironman, Tommy Kimball, Windham Clerk, Cam Mullet Smith, Jin Young Go, Minjee Lea, Jeeno Titlecool |
| 87-90 | Matt Fitzpattern, Tyrell Hatin', Brooks Keepka, Jordan Speech, Justin Tomas, Hideki Matsuyummy, Patrick Cantdelay, Akshay Bhatter, Nick Dunlop, Lilia View, Lydia K.O. |
| 95 | Tommy Fleetfoot, Viktor Hoverland, Nelly Accordion |
| 98 | Bryson DeChambray, Ludvig Iceberg |
| 100-110 | Jon Ramm, Collin Moorikawa, Zander Chauffeur, Rory McIlroyal |
| 115 | Scotty Shuffler |

Checked in the game: the pro table it loads (0x58dd50) holds the new names, followed by
the mod's own touring pros (Ada Fairway, Calder Stone, ...). Saves keep the names of
pros already copied into them.

Also fixed by the rewrite: the shipped row `Brad Fiction,0,    ,0,0,0,1,7787E668CA`
had an extra empty field, so his skin, colours and skills were read from the wrong
columns. His slot (Windham Clerk) is now a normal row.

---

## 2. Outright mistakes (done: `-Labels on`)

All rows below are applied as proposed, except the stream row: the course themes
each set their own singular name for that terrain (Links "burn", Tropical
"stream", Desert "canyon"), and only the plural comes from the default row. So
the default became "stream" / "streams" (what the HUD already showed), not
"creek", and the remaster's "Stream" is unchanged.

| Current | Where | Route, max | Proposed | Why |
|---|---|---|---|---|
| `wbs` | plural of waste bunker, terrain row 0x4c1bd0 | P, 15 | `waste bunkers` | thoughts read "in the wbs" |
| `rhododedron` | flower name 0x4c4c78 | P, 11 | `azalea` | typo; `rhododendron` (12) does not fit |
| `aqua hybiscus` | flower name 0x4c4d34 | P, 15 | `aqua hibiscus` | typo |
| `Pot o'Gold` | flower/feature 0x4c4cac | P, 11 | `Pot o' Gold` | spacing |
| `stonehenge` | landmark 0x4c4bc4 | P, 11 | `Stonehenge` | proper noun |
| `Marshall` | skilled ranger job 0x4c1538, and the tip "Ranger/Marshall" 0x4e1e04 | P, 11 (+ S: `k_job` in ui_hud.c) | `Marshal` | a marshall is a misspelling |
| `...you will need expand your course` | skill message 0x4c4e88 | P | `...you will need to expand...` (drop a word elsewhere to fit) | missing "to" |
| ` increases your players speed of play.` | building unlock text 0x4c54f4 | P, 39 | ` speeds up play on your course.` | missing apostrophe, clumsy |
| `Stream` (remaster HUD) vs `ravine` (game) | `k_terrain_default` in ui_hud.c, terrain row 0x4c1c20 | S + D | one name for both: `creek` | the tool and the golfer thoughts disagree |
| `Ballwasher` vs `Ball Washer` | 0x4c8264 vs 0x4c26ec | P, 11 | `Ball Washer` | two spellings |

---

## 3. Build dock: buildings (route D, max 15)

Data mod `buildings.<row>.name`; the dock, golfer card and messages all use it.

| Current | Proposed | Note |
|---|---|---|
| Pathway | Cart Path | what it is on a real course |
| Benches | Bench | one is placed at a time |
| Flower Bed | Flower Bed | keep |
| Ball Washer | Ball Washer | keep |
| Landmark | Landmark | keep |
| Home Site | Home Lot | matches "lot value" in the panel |
| Putting Green | Practice Green | the course has 18 putting greens already |
| Snack Bar | Halfway House | the golf name for it |
| Pro Shop | Pro Shop | keep |
| Swim Club | Pool Club | keep if you prefer |
| Driving Range | Driving Range | keep |
| Cart Garage | Cart Barn | golf term |
| Marina | Marina | keep |
| Resort Hotel | Resort Hotel | keep |
| Airstrip | Airstrip | keep |
| Clubhouse | Clubhouse | keep |
| Willow Tree | Scenic Willow | the remaster's dock already says "Scenic trees" |
| TV Tower | Camera Tower | it is the broadcast camera scaffold |
| TV Booth | Broadcast Booth | 15, fits |
| Scenic Bridge | Scenic Bridge | keep |

The remaster's Buildings tray has its own copy of nine of these (`k_building_default`
in ui_hud.c), used only before the game's names load. Update it with the table if you
take the proposals (S).

## 4. Bench and flower bed designs: no names at all (route S, plus P for the flower names)

The remaster's placement card shows tooltips like "Bench design 3" and "Flower bed
design 7" (`place_panel`, ui_hud.c). The game itself already has flower names, used
in golfer thoughts ("notices the red rose bush"):

`white carnation`, `yellow daisy bed`, `green flowerbed`, `red rose bush`,
`blue hydrangea`, `purple orchid`, `orange bougainvillea`, `aqua hybiscus`,
`pink sage bush`, `blue foxglove`, `purple iris patch`, `orange flowerbed`,
`red poppy bed`, `rose bush`, `wildflower`, `rhododedron`, `ornamental grass`

Proposal: the card shows the colour and bed shape, for example "White carnations,
low border" or "Red roses, walled bed", built from the design number (shape x
palette). The flower bed art comes in three shapes per theme (`Flowers`,
`SinFlowers`, `WalledFlowers`; tropical and desert sets too) and five palettes per
theme (standard: red, white, purple, orange, yellow; tropical: red, blue, purple,
orange, aqua; desert: pink, blue, purple, orange, red). How the design number splits
into shape and palette still needs checking in the game before the names are written.

Benches: five designs plus the cut lovers' bench. Proposed: Park bench, Garden
bench, Stone bench, Rustic log bench, Teak bench, Lovers' bench (to confirm against
the art).

## 5. Landmarks and eyesores (route P)

Each has a short name (tray tooltip, "Landmark" card) and a phrase golfers use ("a
haunting Easter Island head"; a leading `n` makes it "an").

| Short name, max | Phrase, max | Proposed |
|---|---|---|
| oil pump, 11 | n unsightly oil pump, 23 | keep |
| radio antenna, 15 | n unsightly radio antenna, 27 | `cell tower` / ` hideous cell tower` (2020s) |
| water tower | n unsightly water tower | keep |
| dinosaur tarpit | dusty dinosaur tarpit | `dinosaur tar pit` if it fits |
| oriental house, 15 | n ornate oriental house, 23 | `tea house` / ` traditional tea house` (dated wording) |
| historic lighthouse | n historic Hatteras lighthouse | keep |
| pagoda | exquisite pagoda | keep |
| Easter Island head | haunting Easter Island head | keep (or `moai`) |
| windmill | Dutch windmill | keep |
| Buddha | peaceful Buddha | keep |
| lighthouse | scenic New England lighthouse | keep |
| Civil War statue | n authentic Civil War statue | keep |
| rock face | n unusual rock face | keep |
| water mill | n operating water mill | keep |
| stonehenge, 11 | ancient stonehenge rock | `Stonehenge` / ` ancient Stonehenge rock` |
| Civil War cannon | n authentic Civil War cannon | keep |
| barn | traditional barn | keep |
| sundial | garden sundial | keep |

The remaster capitalises the first letter for the tray (hud_game.c), so lower case
here is right.

## 6. Staff jobs (done: `-Labels on`)

Strings at 0x4c1504-0x4c1558, and the remaster's copy `k_job` in ui_hud.c, which
the People tray shows. The remaster's copies are packed with no spare room, so a
new title can't be longer than the old one (Technician 10, Refresher 9). The
skilled form is the second of each pair.

| Was | Now | Note |
|---|---|---|
| Club Pro / Celebrity | Club Pro / Head Pro | a skilled pro is not a celebrity |
| Ranger / Marshall | Ranger / Marshal | spelling |
| Groundskeeper / Technician | Greenkeeper / Agronomist | the golf jobs; "Head Keeper" didn't fit |
| Soda Vendor / Refresher | Cart Server / Bartender | "Refresher" is not a job |

The remaster's weeds message also changed: "Hire a Turf Technician" became "Hire a
Greenkeeper" (any groundskeeper pulls weeds).

## 7. Skills, traits, moods (route D for skills and traits)

| Current | max | Proposed |
|---|---|---|
| Power Hitter | 24 (D) | Power |
| Long Driver | 24 | Driving Distance |
| Accurate Driver | 24 | Driving Accuracy |
| Accurate Irons | 24 | Iron Play |
| Accurate Putter | 24 | Putting |
| Draw Shot (R to L) | 24 | Draw (right to left) |
| Fade Shot (L to R) | 24 | Fade (left to right) |
| High Backspin Shot | 24 | Spin Control |
| Recovery Skills | 24 | Scrambling |
| Luck | 24 | Luck |
| Positive Attitude | 24 | Confidence |
| Mental Toughness | 19 (P) | Composure |
| Stamina | P | keep |

The two power skills read as the same thing today; the proposal separates raw power
from distance off the tee. Traits (Neat, Outgoing, Active, Playful, Nice) and the
mood words (furious ... invincible; the remaster's Furious ... Delighted) are fine.

## 8. Celebrities, sponsors, visitors

- Celebrity list: done earlier (`-Celebrities modern`).
- Hard-coded celebrity fallbacks in golf.bin (0x4c2bd8...): `Sylvester Stallion`,
  `Britney Aguilera`, `Bill Clinton` (a real name, not a parody), `William Robins`,
  `Pam Andersen`, `Julius Jordan`. Used only if the file is missing; low priority.
- Celebrity type words (P): `action star`, `pop sensation`, `noted statesman`,
  `funny man`, `supermodel`, `fitness guru` (15: `influencer`), `funny lady`,
  `leading man`, `beauty` (7: `icon`), `rocker`, `superstar`.
- Investors and sponsors (P): `I.M.Picky`, `E.F.Mutton`, `J.P.Bigdome`, `B.Gates`
  (max 7), `J.W.Bigshot`, `Don Trump` (max 11), `J.P.Bigwig`, `L.Probst` (max 11, the
  EA chief of the day), `J.W.Bigguy`, `Bigdome Construction`, `Dewey Associates`.
  Proposed 2020s set: `E.Muskrat`, `J.Bezzos`, `M.Zuckerbird` (12: too long, `M.Zuck`),
  `S.Altmann`; keep the J.P./J.W. joke names.
- Visitor titles: `Wealthy Heiress`, `County commissioner`, `Corporate CEO`,
  `International celebrity`, `Famous golfer` are fine.
- Famous-golfer name parts (P, 0x4c2ad0 and 0x4c2b50): first names `Craig Colin Greg
  David Jean Arnie Tom John Karrie Jan Julie Nancy Ben Ernie Jack Tiger`, surnames
  `Stadler Montgomerie Norman Duval VanDeVelde Palmer Watson Daly Fisher Stephenson
  Inkster Lopez Hogan Els Nicklaus Woods`. These are real names, probably for the
  "Famous golfer ..." visit; not traced yet. **Done** (`-Labels on`), each pair
  within its slots: Brooks Keepka, Scotty Shuffler, Tommy Kimball, Ricky Fouler,
  Rory McIlroyal, Jordan Speech, Max Homer, Adam Scotch, Lydia K.O., Jin Young Go,
  Lilia View, Nelly Accord, Jon Ramm, Shane Low, Zander Chauffeur, Ludvig Iceberg
  (in place of Craig Stadler ... Tiger Woods, in that order).

## 9. Places and course names (route P): mostly fine

Properties and their feature: Monterey (Ocean's Edge, Scenic Cypress), San Diego
(Dolphin Coast), Rocky Mtns. (Jurassic Springs, Free Hotel), Las Vegas (Ace in the
Hole, Fun Fun Fun), Phoenix (Coyote Flats, Free Spa), Hawaii (Flamingo Shores),
Oahu (Island Palms), Nova Scotia (Windy Point), Northeast (Ravenwood Farms),
Carolina (Christmas Pines), Ireland (County Kincaide), Scotland (Harold's Keep),
Wales (Thistle Runes), Spain (Sangria Bay), Florida (Ocean Grove), Jamaica
(Scorpion Cove).

- `Rocky Mtns.` (max 23) to `Rocky Mountains`.
- Course classes ` GC`, ` Golf Club`, ` CC`, ` Country Club`, ` Championship`,
  ` MC`, ` Municipal`: fine.

## 10. Remaster HUD (route S)

| Current | Proposed |
|---|---|
| "Bench design N", "Flower bed design N" | names from section 4 |
| "Analyze golf shot" | "Shot preview" |
| "Raise or lower a point / square / area" | keep |
| Dock "People" tray tabs: Golfers, Your pro, Staff | keep |
| "Upgrade (can be rotated, Tab)" | "Upgrade (Tab rotates)" |
| `k_job` and `k_terrain_default` | follow sections 2 and 6 |

## 11. Left as they are on purpose

Golfer and staff chatter ("Me hate divots.", "Golfers are pigs.", "I hate my hat
too.") is character writing, not labelling. The 2001 course-design quotes (George
Thomas, Pete Dye, Alister Mackenzie) are real quotations and stay.

---

## Suggested order

1. ~~Section 2 (mistakes) and section 6 (jobs)~~: done.
2. Sections 3 and 7: one data mod, `companion_labels`, no binary edits.
3. Section 4: needs the design-number check, then a source change (or an exe string
   table in `.cmpn`).
4. Sections 5 and 8: wording calls for you.
