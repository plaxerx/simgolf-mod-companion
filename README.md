# SimGolf Remastered: Companion fork

A personal quality-of-life fork of
[SimGolf Remastered](https://github.com/finalpantasy/simgolf-mod) 0.1.37, the
fan-made Windows upgrade of Sid Meier's SimGolf. It builds on the remastered
mod; it does not replace it.

**For the full description of SimGolf Remastered, its features, the download
and installation help, go to the original mod:
[finalpantasy/simgolf-mod](https://github.com/finalpantasy/simgolf-mod).**
Install it from there first; this fork's patcher then works on top of that
install. The upstream documentation in this repository (`INSTALL.md`,
`CHANGELOG.md`, `docs/`) is kept as shipped.

The fork adds quality-of-life changes in two layers:

1. **Companion patcher** (`companion/`): `Apply-CompanionPatches.ps1` (or
   double-click `Apply-CompanionPatches.cmd`) patches an **installed**
   SimGolf Remastered, so no build is needed. Close the game first, and run it
   again after every game update. Every change has an option to turn it off,
   and the README's undo line gives back the byte-identical program and data
   files. Details, tests and options: [companion/README.md](companion/README.md);
   research notes in `companion/notes/`.
2. **Source changes** (`port/`, `data/mods.ini`): a few of the same changes
   made in the mod's source, each marked with a `companion:` comment, so a
   build from this repository includes them. They are small edits inside
   upstream files plus one new file (`port/src/port/golf/money_labels.c`).

## What the fork changes

**Pace and progression**
- Calendar starts in 2021 instead of 2001.
- Year events every month: the board's review ("END of MONTH"), the SGA
  invitation and the yearly drift come on the 1st of every month. The debt
  verdict stays yearly.
- News messages stay up 3x longer; important news opens a popup and pauses.

**Course and buildings**
- Starting land 2x the vanilla side on any map size (source and patcher).
- New map sizes apply without a restart (source).
- Snack shacks work without a cart path to the clubhouse.
- Staff work radius 1.5x; landmark reach 2x, and the placement ring shows
  the real reach.
- Flower beds: true white and true red palettes. Design tooltips name the
  flower, bed, tree or bench ("Red roses, curved bed", "Japanese maple").

**Golf**
- Modern shot distances with one set of tees.
- Fade, draw and backspin from any lie.
- Curve fix: long draws and fades no longer fly 500+ yards.
- Pro aim: hold Shift for free aim; the pro's shot no longer gets stuck.
- Greens no longer speed the ball up downhill (gentler break).

**People and names**
- Golfers: the 100 regulars get real "First Last" names (about 88,000
  combinations, a new set per career, kept in the save).
- Staff get random real names; clearer job titles and labels; 2020s
  celebrities and touring pros.
- Hire up to 50 staff; they walk 25% faster.

**Tournaments**
- No building while a tournament is on, and no staff wages.
- How the SGA scores a course for tournaments: `companion/notes/tournaments.md`.

**Look and controls**
- Brighter, bluer nights (source and patcher).
- Upstream bugs fixed: Pixel HD zoom flicker, the dark bar while scrolling,
  weather jumping after a save or dialog, and the clubhouse flicking to old
  art when zoomed out.
- One Escape closes everything and opens the Menu (source and patcher).
- Money popups fade in and out (source only).

## Legal

This is an unofficial fan project. It is not affiliated with or endorsed by
Firaxis Games, Electronic Arts or Take-Two Interactive. SimGolf and its
assets are their property. This project distributes **none** of the game's
files: you supply your own copy. The optional HD art pack is a separate,
unofficial fan-made upscale of the game's own art; it is removed on request
by the rights holders.

The program code in this repository is MIT licensed ([LICENSE](LICENSE)).
It is built on [RichardAtCT/simgolf-web](https://github.com/RichardAtCT/simgolf-web)
(MIT), which translated the decompiled game into C. Third-party pieces keep
their own licences (see [CREDITS.md](CREDITS.md)).
