# SimGolf Remastered companion patches (personal QOL, not part of upstream).
# They patch the installed program, so no rebuild from source is needed.
# Run again after every update of the game program. Close the game first.
#
# 1. Start year (-StartYear, default 2021)
#    The game keeps the calendar year as an offset (0 = the first year,
#    DAT_005a6d3c / tick >> 13) and turns it into text with
#    _itoa(offset + 2001). Saves store the offset, so they are unaffected and
#    simply show the new years. Sites, found by byte signature:
#      8 x  _itoa(year + 2001, buf, 10)  date text, End of Year, finances, records
#      1 x  _itoa(year + 2000, buf, 10)  the "Last Year" column
#      1 x  tick >> 13 + 2001            the Shift+F12 debug overlay
#
# 2. Starting land (-StartLand, default 2)
#    The land generator (FUN_00470a60) owns the centre square of side 2k,
#    k the largest with 4k^2 <= acres * 10 * (w * h / 2500): the remaster
#    keeps the vanilla SHARE of the map. A number N makes the start N times
#    the vanilla side instead, whatever the map size (acres * 10 * N^2), so
#    on a Huge map there is still land to buy up to 156 x 156.
#    'share' restores the remaster's rule. One site: the two multiplies by the
#    map width and height become one multiply by 2500 * N^2 (same 6 bytes).
#
# 3. Staff work radius (-StaffRadius, percent, default 150): how far an
#    employee reaches from the centre of its zone (ring, golfers served,
#    mowing, ball pickup). 100 = vanilla.
#
# 4. Staff names (-StaffNames on|off, default on): random "First Last" names
#    for new and existing employees instead of one fixed name per job.
#
# 5. Night light (-NightTint twilight|vanilla|"r,g,b[,floor]", default
#    twilight): the clear-night tint, (102, 125, 176) in vanilla, (115, 145, 224)
#    twilight, and the terrain's night sky-light floor, 0.30 -> 0.36.
#
# 6. Celebrities (-Celebrities modern|vanilla, default modern): installs the
#    2020s parody guest list (celebrities.dta next to this script).
#    -ProGolfers modern|vanilla (default modern) does the same for the touring
#    pros (progolfers.dta): the 2020s tour, the 2001 legends moved down a
#    group to the "Champions Tour". Skills and tiers are unchanged.
#
# 7. Map size (optional, -MapScale 1|2|4|10): writes [map] scale= to
#    options.ini (50x50, 70x70, 100x100, 158x158). The size is read when the
#    game starts, so restart the game after changing it in Options.
#
# 8. Pixel HD flicker fix (-PixelHdFix on|off, default on): an upstream bug.
#    With Pixel HD textures, the sharp filter and a non-whole UI scale (2.4 on
#    a 1440p screen), one frame per game frame showed the course at 2x while
#    the game ran. See "Pixel HD flicker fix" below.
#
# 9. News hold (-NewsHold 1..8, default 3): news messages (events, offers,
#    golfer news) stay on screen this many times longer. The game shows each
#    for (length / 4 + 16) course ticks, which the 2x-4x speeds burn through.
#
# 10. Escape closes everything (-EscapeAll on|off, default on): one Esc
#    closes the open message or history, the build bar and the open tray and
#    cancels its tool; only an Esc with nothing open opens the Menu. As
#    shipped, each Esc closed one of those.
#
# 11. Keep the weather (-KeepWeather on|off, default on): a frame that is not
#    the course (a save, a dialog, a report) threw away the regional weather,
#    and the next course frame jumped straight to a new front's cloud and rain:
#    the lighting changed at once. Now the weather just waits.
#
# 12. Landmark radius (-LandmarkRadius 100..300 percent, default 200): how far
#    a landmark's benefit reaches, (25 x design + 200) / 3 yards in vanilla
#    (2.7 to 7.7 tiles). The placement ring, drawn at 3/4 of that in vanilla,
#    then shows the real reach.
#
# 13. White flower beds (-WhiteFlowers on|off, default on): the standard
#    flower bed's "White" palette (FlowerbedA_WhitePal.pcx) draws magenta
#    flowers. Its petal colours (the entries that differ from the red and
#    yellow palettes) become white, lifted 30% of the way to full white so the
#    shaded petals do not read grey. Every texture look draws through this
#    palette. The original is kept as .companion-backup.
#
# 14. Shot distances (-Distances modern|vanilla, default modern): one set of
#    tees for a 7200-yard par 72. Base tee distance 230 / 210 yards for long /
#    short hitters (vanilla 200 / 150; Easy 260 / 235, vanilla 240 / 175), shots
#    from any lie but the tee at 0.9 of that (vanilla 0.8), and no 330-yard
#    cap. Every golfer, the pro included; saves are unaffected. See
#    notes\shot-distances.md.
#
# 15. Labels (-Labels on|off, default on): typos and staff job titles in
#    image\golf.bin and the program ("wbs" -> "waste bunkers", "Marshall" ->
#    "Marshal", Celebrity -> Head Pro, ...), landmark, celebrity, investor and
#    place names, the famous-golfer name lists -> the 2020s tour, and a small
#    data mod (mods\companion_labels) for building and skill names. See
#    notes\label-inventory.md.
#
# 16. Pro free aim (-ProAim shift|off, default shift): hold Shift while
#    aiming the pro's shot to aim at the exact point under the mouse instead of a tile centre or corner (a 25-yard grid).
#    Without Shift, aiming is as shipped, so putts still lock onto the cup.
#    Code in the .cmpn section. See notes\pro-shot-aim.md.
#
# 17. Scroll edge (-ScrollEdge on|off, default on): an upstream bug. While the
#    course slides (smooth scrolling), the edge it uncovers (the bottom when
#    scrolling up, the top when scrolling down) still shows the previous
#    picture, outside the weather shader's material map, which counted it as
#    "not the course": no daylight lift, a dark bar. Two lines of the shader
#    text (environment_fx.cpp) now use the nearest map pixel there instead.
#
# 18. News popups (-NewsPopup on|off, default on): every important news
#    message (a VIP's visit and verdict, a land approval, a landmark, the
#    story, a tournament, a scenario's goals) also opens in the game's own OK
#    box, which pauses the game until it is closed. Build feedback ("Can't build
#    bench there."), "Game Saved.", golfer chatter and the hole-by-hole match
#    score stay in the news strip only. Code in the .cmpn section, which grows
#    to 8 KB. See "News popups" below.
#
# 19. Clubhouse cache (-ClubCache on|off, default on): an upstream bug. With
#    the animated clubhouse (ui\clubhouse) the art cache is capped at 256 MB,
#    and zoomed out the rest of the course fills it, so the clubhouse's 15
#    animation frames were thrown out between uses. Each time the animation
#    reached one, the whole clubhouse fell back to the old drawing until it
#    reloaded: it flickered between the two. The cache now throws out
#    clubhouse frames last. Code in the .cmpn section.
#
# 20. Red flower beds (-RedFlowers on|off, default on): the standard flower
#    bed's "Red" palette (FlowerbedA_RedPal.pcx) is hot pink and magenta (hue
#    about 321 degrees). Its petal colours turn true red (355 degrees) at the
#    same brightness, a touch more saturated; near-grey highlights stay. The
#    original is kept as .companion-backup.
#
# 21. Green roll (-GreenRoll on|off, default on): on a green, a downhill slope
#    no longer speeds the ball up (it only slows it less), and the break is
#    half as strong. Balls that come onto the green from off it (approaches,
#    chips, putts from the fringe) no longer run off it into the water. Putts
#    struck from the green are unchanged (the game ignores slope for those).
#    Code in the .cmpn section. See notes\green-roll.md.
#
# 22. Design names (-DesignNames on|off, default on): the tooltips on the
#    bench, flower bed and scenic tree design tiles said "Flower bed design 7".
#    They now name what it is: "Red roses, curved bed" (the flower by colour
#    and course theme, and the bed's shape), "Japanese maple", "Lovers' bench".
#    Code and names in the .cmpn section.
#
# 23. Shot fix (-ShotFix on|off, default on): the pro's shot could get stuck,
#    the click doing nothing until a save and reload. With the Frosted Mint HUD
#    the click was refused in the bottom strip where the old dock used to be
#    (aiming there worked), and after closing a pro page while the pro waited
#    the dock stayed in a mode that refuses the click. The click now works
#    anywhere on the course, and choosing a shot type (or the same one again)
#    re-arms a waiting pro. Code in the .cmpn section.
#
# 24. All shots (-AllShots on|off, default on): fade, draw and backspin from
#    any lie. The game turned them back into a straight shot in the rough,
#    sand or trees (only low punch was allowed); the shot still pays that lie's
#    penalty. The Frosted Mint HUD shows all five shot buttons there too.
#
# 25. Snack bar path (-SnackPath free|needed, default free): a Snack Shack
#    (golf's Snack Bar) works without a cart path to the clubhouse, like a
#    bench or a ball washer; no "will not be operational" warning, no "No path"
#    marker. Other buildings still need the path. Code in the .cmpn section.
#
# 26. Year events monthly (-YearEvents monthly|yearly, default monthly): what
#    the game does once a year happens on the 1st of every month: the board's
#    review (now "END of MONTH", this month against last), the SGA's
#    tournament invitation, the visitor mix drift and the fading of the
#    map's stat layers. The calendar, seasons, wages and income are
#    unchanged, and so are saves. The board's debt warnings and strikes stay on
#    March 1 only, so three years in debt still ends the career, not three
#    months. Code in the .cmpn section. See notes\year-events.md.
#
# 27. Curve fix (-CurveFix on|off, default on): draws and fades launch faster
#    than a straight shot, by 1 + 16/(400 - yards) past 250 yards. Golf capped
#    shots at 330 yards (x1.23 at most); with -Distances modern there is no
#    cap, so a 380-yard draw flew x1.8, a 395-yard one x4.2, and 400 yards and
#    up divided by zero or went nowhere. The boost now counts at most 330
#    yards: as shipped up to 330, x1.23 beyond. Code in the .cmpn section.
#
# 28. Golfer names (-GolferNames real|vanilla, default real): the regular
#    visitors were golf's 75 first names (Snoop, Biggie, Mahatma, J.P. ...) and
#    the remaster's 25 pun names (Bea Line, Gus Socket). Each now gets a real
#    "First Last" name (about 88,000 combinations; no two golfers share a first
#    name), drawn anew for each career and kept in the save. The remaster's 25
#    keep their first name, which their bios use. Older saves are renamed when
#    loaded. vanilla stops naming; names already in a save stay. Code and
#    names in the .cmpn section, which grows to 16 KB.
#
# Usage (PowerShell):
#   .\Apply-CompanionPatches.ps1                                # 2021, 2x vanilla starting side
#   .\Apply-CompanionPatches.ps1 -StartYear 2001 -StartLand share -StaffRadius 100 -StaffNames off -NightTint vanilla -Celebrities vanilla -ProGolfers vanilla -PixelHdFix off -NewsHold 1 -EscapeAll off -KeepWeather off -LandmarkRadius 100 -WhiteFlowers off -Distances vanilla -Labels off -ProAim off -ScrollEdge off -NewsPopup off -ClubCache off -RedFlowers off -GreenRoll off -DesignNames off -ShotFix off -AllShots off -SnackPath needed -YearEvents yearly -CurveFix off -GolferNames vanilla   # unpatched
#   .\Apply-CompanionPatches.ps1 -DryRun                        # report only
#   .\Apply-CompanionPatches.ps1 -MapScale 10                   # also set new-course size

[CmdletBinding()]
param(
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA "Programs\SimGolf Remastered"),
  [ValidateRange(1901, 2199)][int]$StartYear = 2021,
  [ValidateSet('share', '1', '1.5', '2', '2.5', '3')][string]$StartLand = '2',
  [ValidateSet(0, 1, 2, 4, 10)][int]$MapScale = 0,
  [ValidateRange(100, 200)][int]$StaffRadius = 150,
  [ValidateSet('on', 'off')][string]$StaffNames = 'on',
  [string]$NightTint = 'twilight',
  [ValidateSet('modern', 'vanilla')][string]$Celebrities = 'modern',
  [ValidateSet('modern', 'vanilla')][string]$ProGolfers = 'modern',
  [ValidateSet('on', 'off')][string]$PixelHdFix = 'on',
  [ValidateRange(1, 8)][int]$NewsHold = 3,
  [ValidateSet('on', 'off')][string]$EscapeAll = 'on',
  [ValidateSet('on', 'off')][string]$KeepWeather = 'on',
  [ValidateRange(100, 300)][int]$LandmarkRadius = 200,
  [ValidateSet('on', 'off')][string]$WhiteFlowers = 'on',
  [ValidateSet('modern', 'vanilla')][string]$Distances = 'modern',
  [ValidateSet('on', 'off')][string]$Labels = 'on',
  [ValidateSet('shift', 'off')][string]$ProAim = 'shift',
  [ValidateSet('on', 'off')][string]$ScrollEdge = 'on',
  [ValidateSet('on', 'off')][string]$NewsPopup = 'on',
  [ValidateSet('on', 'off')][string]$ClubCache = 'on',
  [ValidateSet('on', 'off')][string]$RedFlowers = 'on',
  [ValidateSet('on', 'off')][string]$GreenRoll = 'on',
  [ValidateSet('on', 'off')][string]$DesignNames = 'on',
  [ValidateSet('on', 'off')][string]$ShotFix = 'on',
  [ValidateSet('on', 'off')][string]$AllShots = 'on',
  [ValidateSet('free', 'needed')][string]$SnackPath = 'free',
  [ValidateSet('real', 'vanilla')][string]$GolferNames = 'real',
  [ValidateSet('monthly', 'yearly')][string]$YearEvents = 'monthly',
  [ValidateSet('on', 'off')][string]$CurveFix = 'on',
  [switch]$DryRun,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$latin1 = [System.Text.Encoding]::GetEncoding(28591)   # 1 byte <-> 1 char

# ---------------------------------------------------------------- start year
# Each pattern captures the 2 low bytes of the 32-bit year constant.
$yearPatterns = @(
  @{ name = 'add eax,Y; itoa';        rx = '\x05([\x00-\xFF]{2})\x00\x00\x6A\x0A\x68' },
  @{ name = 'add r32,Y; itoa';        rx = '\x81[\xC0-\xC7]([\x00-\xFF]{2})\x00\x00\x6A\x0A\x68' },
  @{ name = 'mov ecx,Y; add; itoa';   rx = '\xB9([\x00-\xFF]{2})\x00\x00\x01\xC8\x6A\x0A\x68' },
  @{ name = 'tick>>13 + Y (overlay)'; rx = '\xC1\xE9\x0D\x81\xC1([\x00-\xFF]{2})\x00\x00\x89\x0D' }
)
# movsx r32, word ptr [0x5a6d3c]: the year offset, read just before the "last year" site
$yearLoad = New-Object System.Text.RegularExpressions.Regex('\x0F\xBF[\x05\x0D\x15\x1D\x2D\x35\x3D]\x3C\x6D\x5A\x00')

function Find-YearSites([byte[]]$bytes, [string]$text) {
  $found = @()
  foreach ($p in $yearPatterns) {
    foreach ($m in [regex]::Matches($text, $p.rx)) {
      $g = $m.Groups[1]
      $value = [int]$bytes[$g.Index] + 256 * [int]$bytes[$g.Index + 1]
      if ($value -lt 1900 -or $value -gt 2200) { continue }
      $from = [Math]::Max(0, $m.Index - 64)
      $loadsYear = $yearLoad.IsMatch($text.Substring($from, $m.Index - $from))
      $found += [pscustomobject]@{ Offset = $g.Index; Value = $value; Kind = $p.name; LoadsYear = $loadsYear }
    }
  }
  if (-not $found) { return $null }
  # The current base year is the value most sites agree on; "last year" sites hold base - 1.
  $base = ($found | Group-Object Value | Sort-Object Count -Descending | Select-Object -First 1).Name -as [int]
  return [pscustomobject]@{
    Base  = $base
    Years = @($found | Where-Object { $_.Value -eq $base })
    Last  = @($found | Where-Object { $_.Value -eq $base - 1 -and $_.LoadsYear })
  }
}

# ------------------------------------------------------------- starting land
# movzx eax, byte [ecx+eax-0x19ccb]   (0x58bcc0 - 0x19ccb = 0x571ff5: the property's acres)
# mov esi, [g_map_h]; mov [esp+8], edx
# imul eax, edx; imul eax, esi        (original: acres * w * h)   or
# imul eax, eax, imm32                (patched:  acres * 2500 * N^2)
# add eax, eax; lea eax, [eax+eax*4]  (* 10); mov edx, 0x68db8bad   (/ 2500)
$landRx = '\x0F\xB6\x84\x01\x35\x63\xFE\xFF\x8B\x35[\x00-\xFF]{4}\x89\x54\x24\x08((?:\x0F\xAF\xC2\x0F\xAF\xC6)|(?:\x69\xC0[\x00-\xFF]{4}))\x01\xC0\x8D\x04\x80\xBA\xAD\x8B\xDB\x68'
$landShare = [byte[]](0x0F, 0xAF, 0xC2, 0x0F, 0xAF, 0xC6)

function Find-LandSite([byte[]]$bytes, [string]$text) {
  $ms = [regex]::Matches($text, $landRx)
  if ($ms.Count -ne 1) { return [pscustomobject]@{ Count = $ms.Count } }
  $g = $ms[0].Groups[1]
  $mode = if ($bytes[$g.Index] -eq 0x0F) { 'share' } else { [BitConverter]::ToInt32($bytes, $g.Index + 2) }
  return [pscustomobject]@{ Count = 1; Offset = $g.Index; Mode = $mode }
}

function Land-Bytes([string]$want) {
  if ($want -eq 'share') { return $landShare }
  $n = [double]::Parse($want, [Globalization.CultureInfo]::InvariantCulture)
  $imm = [int][Math]::Round(2500 * $n * $n)
  return [byte[]](@(0x69, 0xC0) + [BitConverter]::GetBytes($imm))
}

function Describe-Land($mode) {
  if ($mode -eq 'share') { return 'remaster rule (same share of the map as vanilla)' }
  return ('{0}x the vanilla side' -f [Math]::Round([Math]::Sqrt($mode / 2500.0), 2))
}

# ------------------------------------------------------- world-map acre label
# The world map writes a property's acres with _itoa straight from the byte
# (two sites: "40 acres: $50,000" and "Buy 40 acres of ..."):
#   movzx eax, byte [ebx+eax+0x57f8d]   (0x51a068 + 0x57f8d = 0x571ff5); push 10; push buf
# With more starting land the label scales with it (x N^2), so it stays as
# accurate as vanilla's. Each site becomes `call cave; nop x3`, and a cave in
# the int3 padding of .text does the load, `imul eax, eax, 4N^2; shr eax, 2; ret`.
$acreLoad = [byte[]](0x0F, 0xB6, 0x84, 0x03, 0x8D, 0x7F, 0x05, 0x00)
$acreOrigRx = '\x0F\xB6\x84\x03\x8D\x7F\x05\x00(?=\x6A\x0A\x68)'
$acreCallRx = '\xE8[\x00-\xFF]{4}\x90\x90\x90(?=\x6A\x0A\x68)'

function Get-TextSection([byte[]]$bytes) {
  $pe = [BitConverter]::ToInt32($bytes, 0x3C)
  $n = [BitConverter]::ToUInt16($bytes, $pe + 6)
  $table = $pe + 24 + [BitConverter]::ToUInt16($bytes, $pe + 20)
  for ($i = 0; $i -lt $n; $i++) {
    $s = $table + 40 * $i
    if ([BitConverter]::ToUInt32($bytes, $s + 36) -band 0x20000000) {
      # mapped bytes only: raw padding past the virtual size is not loaded
      $size = [Math]::Min([BitConverter]::ToInt32($bytes, $s + 16), [BitConverter]::ToInt32($bytes, $s + 8))
      return [pscustomobject]@{ Start = [BitConverter]::ToInt32($bytes, $s + 20); Size = $size }
    }
  }
  throw "no code section"
}

# Code caves: runs of 16+ int3 bytes in .text, each used by one patch. A run
# a patch already uses is no longer all int3, so it is never handed out twice;
# $script:cavesTaken covers caves claimed earlier in this same run.
function Take-Cave([byte[]]$bytes) {
  $sec = Get-TextSection $bytes
  foreach ($m in [regex]::Matches($latin1.GetString($bytes, $sec.Start, $sec.Size), '\xCC{16,}')) {
    $at = $sec.Start + $m.Index
    if (-not $script:cavesTaken.Contains($at)) { [void]$script:cavesTaken.Add($at); return $at }
  }
  throw "no free 16-byte padding gap left in the code section"
}

function Find-AcreSites([byte[]]$bytes, [string]$text) {
  $orig = @([regex]::Matches($text, $acreOrigRx) | ForEach-Object { $_.Index })
  $calls = @()
  $caves = @{}
  foreach ($m in [regex]::Matches($text, $acreCallRx)) {
    $target = $m.Index + 5 + [BitConverter]::ToInt32($bytes, $m.Index + 1)
    if ($target -lt 0 -or $target + 15 -gt $bytes.Length) { continue }
    $ok = $true
    for ($i = 0; $i -lt 8; $i++) { if ($bytes[$target + $i] -ne $acreLoad[$i]) { $ok = $false } }
    if ($ok -and $bytes[$target + 8] -eq 0x6B -and $bytes[$target + 9] -eq 0xC0 -and $bytes[$target + 11] -eq 0xC1 -and
        $bytes[$target + 12] -eq 0xE8 -and $bytes[$target + 13] -eq 0x02 -and $bytes[$target + 14] -eq 0xC3) {
      $calls += $m.Index; $caves[$target] = $bytes[$target + 10]
    }
  }
  $state = if ($orig.Count -eq 2 -and $calls.Count -eq 0) { 'original' }
           elseif ($calls.Count -eq 2 -and $orig.Count -eq 0 -and $caves.Count -eq 1) { 'patched' }
           else { 'unknown' }
  $cave = if ($caves.Count -eq 1) { @($caves.Keys)[0] } else { -1 }
  $factor = if ($cave -ge 0) { $caves[$cave] } else { 4 }
  return [pscustomobject]@{ State = $state; Sites = @($orig + $calls); Cave = $cave; Factor = [int]$factor }
}

function Acre-Factor([string]$want) {   # 4 x the label multiple; 4 = the label as shipped
  if ($want -eq 'share') { return 4 }
  $n = [double]::Parse($want, [Globalization.CultureInfo]::InvariantCulture)
  return [int][Math]::Round(4 * $n * $n)
}

function Acre-Changes([byte[]]$bytes, $acres, [int]$factor) {
  $changes = @()
  if ($factor -eq 4) {   # restore the original label
    if ($acres.State -eq 'patched') {
      foreach ($s in $acres.Sites) { $changes += ,@($s, $acreLoad) }
      $changes += ,@($acres.Cave, [byte[]](@(0xCC) * 15))
    }
    return ,$changes
  }
  $cave = $acres.Cave
  if ($acres.State -eq 'original') {
    $cave = Take-Cave $bytes
    foreach ($s in $acres.Sites) {
      $changes += ,@($s, [byte[]](@(0xE8) + [BitConverter]::GetBytes([int]($cave - ($s + 5))) + @(0x90, 0x90, 0x90)))
    }
  }
  $changes += ,@($cave, [byte[]]($acreLoad + @(0x6B, 0xC0, $factor, 0xC1, 0xE8, 0x02, 0xC3)))
  return ,$changes
}

function Describe-Acres([int]$factor) {
  if ($factor -eq 4) { return 'as shipped' }
  return ('x{0}' -f ($factor / 4.0))
}

# -------------------------------------------------------------- staff radius
# An employee works around the centre of its zone (staff record +0x10/+0x11,
# FUN_00402a40 = the staff AI, FUN_00436e50 = the zone ring). Vanilla reach:
#   ring              4 tiles (club pro, marshal, vendor), groundskeeper 6, skilled 8
#   golfers served    4 tiles from the centre (cmp dist*25/1024, 0x63; jg)
#   mowing search     tiles within +-16 of the centre, octagonal limit 24 (32 skilled)
#                     on (2*tile - centre - position), i.e. 12 (16) tiles
#   ball pickup       0x1400 (5 tiles)
# -StaffRadius P scales all of them by P%. Immediates are patched in place; the
# two that no longer fit (golfer limit imm8, the 24 + (flags & 8) limit) call a cave.
function Scaled([int]$base, [int]$pct) { [int][Math]::Round($base * $pct / 100.0, [MidpointRounding]::AwayFromZero) }

# Each group: base value, extra offset (value = Scaled(base) + off), width 4 or 1.
$staffSites = @(
  @{ name = 'ring (pro/marshal/vendor)'; rx = '\xB8([\x00-\xFF]{4})\x81\xF9\xFB\x00\x00\x00\x74'; g = @(,@(100, 0, 4)) },
  @{ name = 'ring (groundskeeper)';      rx = '\xB8([\x00-\xFF]{4})\xB9([\x00-\xFF]{4})\x0F\x44\xC1\xB9\xF0\x7F\x00\x80'; g = @(@(200, 0, 4), @(150, 0, 4)) },
  @{ name = 'HD ring (pro/marshal/vendor)'; rx = '\xBB([\x00-\xFF]{4})\x3D\xFB\x00\x00\x00\x74'; g = @(,@(100, 0, 4)) },
  @{ name = 'HD ring (groundskeeper)';   rx = '\xB8([\x00-\xFF]{4})\xBB([\x00-\xFF]{4})\x0F\x44\xD8\xC7\x44\x24\x20\xF0\x7F\x00\x80'; g = @(@(150, 0, 4), @(200, 0, 4)) },
  @{ name = 'ball pickup';               rx = '\xBF\xB0\x36\x57\x00\xC7\x44\x24\x04([\x00-\xFF]{4})\x31\xD2\x31\xC0'; g = @(,@(5120, 0, 4)) },
  @{ name = 'mowing box start';          rx = '(?:\x83\xE0\x08\x83\xC0\x18|\xE8[\x00-\xFF]{4}\x90)\x89\x44\x24\x04\xC1\x7C\x24\x10\x0A\xC1\x7C\x24\x14\x0A\xC7\x44\x24\x0C([\x00-\xFF]{4})\x31\xC0\x48\x89\x44\x24\x18\x89\x44\x24\x34\x89\x44\x24\x30\xBF([\x00-\xFF]{4})\xE8'; g = @(@(-16, 0, 4), @(-16, 0, 4)) },
  @{ name = 'mowing box end';            rx = '\x47\x83\xFF([\x00-\xFF])\x0F\x85[\x00-\xFF]{4}\x8B\x44\x24\x0C\x40\x89\x44\x24\x0C\x83\xF8([\x00-\xFF])\x0F\x85'; g = @(@(16, 1, 1), @(16, 1, 1)) }
)
# Cave sites: the original bytes, or `call cave` (+ nop), each followed by fixed context.
$tileOrig = [byte[]](0x83, 0xE0, 0x08, 0x83, 0xC0, 0x18)
$tileRx = '(?:(\x83\xE0\x08\x83\xC0\x18)|\xE8([\x00-\xFF]{4})\x90)(?=\x89\x44\x24\x04\xC1\x7C\x24\x10\x0A)'
$golferOrig = [byte[]](0x83, 0x7C, 0x24, 0x14, 0x63)
$golferRx = '(?:(\x83\x7C\x24\x14\x63)|\xE8([\x00-\xFF]{4}))(?=\x8B\x5C\x24\x08\x7F)'

function Tile-Cave([int]$pct) {   # test al,8; mov eax,B; jz +5; mov eax,BS; ret
  [byte[]](@(0xA8, 0x08, 0xB8) + [BitConverter]::GetBytes((Scaled 24 $pct)) + @(0x74, 0x05, 0xB8) + [BitConverter]::GetBytes((Scaled 32 $pct)) + @(0xC3))
}
function Golfer-Cave([int]$pct) { # cmp dword [esp+0x18], G-1; ret   (the caller's [esp+0x14])
  [byte[]](@(0x81, 0x7C, 0x24, 0x18) + [BitConverter]::GetBytes([int]((Scaled 100 $pct) - 1)) + @(0xC3))
}

# Finds a cave site: Orig (offset of original bytes), Call (offset of the call) + Cave, or neither.
function Find-CaveSite([byte[]]$bytes, [string]$text, [string]$rx, [int]$caveLen) {
  $ms = [regex]::Matches($text, $rx)
  if ($ms.Count -ne 1) { return $null }
  $m = $ms[0]
  if ($m.Groups[1].Success) { return [pscustomobject]@{ Orig = $m.Index; Call = -1; Cave = -1; Code = $null } }
  $cave = $m.Index + 5 + [BitConverter]::ToInt32($bytes, $m.Groups[2].Index)
  if ($cave -lt 0 -or $cave + $caveLen -gt $bytes.Length) { return $null }
  return [pscustomobject]@{ Orig = -1; Call = $m.Index; Cave = $cave; Code = [byte[]]$bytes[$cave..($cave + $caveLen - 1)] }
}

function Find-StaffSites([byte[]]$bytes, [string]$text) {
  $imm = @()
  foreach ($s in $staffSites) {
    $ms = [regex]::Matches($text, $s.rx)
    if ($ms.Count -ne 1) { return [pscustomobject]@{ State = 'unknown'; Why = "$($s.name): $($ms.Count) matches" } }
    for ($i = 0; $i -lt $s.g.Count; $i++) {
      $grp = $ms[0].Groups[$i + 1]; $w = $s.g[$i][2]
      $v = if ($w -eq 4) { [BitConverter]::ToInt32($bytes, $grp.Index) } else { [int][sbyte]$bytes[$grp.Index] }
      $imm += [pscustomobject]@{ Name = $s.name; Offset = $grp.Index; Base = $s.g[$i][0]; Off = $s.g[$i][1]; Width = $w; Value = $v }
    }
  }
  $tile = Find-CaveSite $bytes $text $tileRx 15
  $golfer = Find-CaveSite $bytes $text $golferRx 9
  if (-not $tile -or -not $golfer) { return [pscustomobject]@{ State = 'unknown'; Why = 'cave sites not found' } }
  # The current percentage, from the ball pickup distance; everything must agree with it.
  $ball = $imm | Where-Object { $_.Base -eq 5120 }
  $pct = [int][Math]::Round($ball.Value * 100.0 / 5120)
  $ok = $true
  foreach ($x in $imm) { if ($x.Value -ne (Scaled $x.Base $pct) + $x.Off) { $ok = $false } }
  if ($pct -eq 100) { if ($tile.Orig -lt 0 -or $golfer.Orig -lt 0) { $ok = $false } }
  else {
    if ($tile.Cave -lt 0 -or (Compare-Object $tile.Code (Tile-Cave $pct) -SyncWindow 0)) { $ok = $false }
    if ($golfer.Cave -lt 0 -or (Compare-Object $golfer.Code (Golfer-Cave $pct) -SyncWindow 0)) { $ok = $false }
  }
  if (-not $ok) { return [pscustomobject]@{ State = 'unknown'; Why = 'values do not agree' } }
  return [pscustomobject]@{ State = 'ok'; Percent = $pct; Imm = $imm; Tile = $tile; Golfer = $golfer }
}

function Staff-Changes([byte[]]$bytes, $staff, [int]$pct) {
  $changes = @()
  foreach ($x in $staff.Imm) {
    $v = (Scaled $x.Base $pct) + $x.Off
    $b = if ($x.Width -eq 4) { [BitConverter]::GetBytes([int]$v) } else { [byte[]]@([byte]($v -band 0xFF)) }
    $changes += ,@($x.Offset, [byte[]]$b)
  }
  foreach ($c in @(@($staff.Tile, $tileOrig, 15, { param($p) Tile-Cave $p }, 0x90), @($staff.Golfer, $golferOrig, 9, { param($p) Golfer-Cave $p }, $null))) {
    $site = $c[0]; $orig = $c[1]; $len = $c[2]
    if ($pct -eq 100) {
      if ($site.Call -ge 0) {
        $changes += ,@($site.Call, $orig)
        $changes += ,@($site.Cave, [byte[]](@(0xCC) * $len))
      }
      continue
    }
    $cave = $site.Cave
    if ($site.Orig -ge 0) {
      $cave = Take-Cave $bytes
      $call = @(0xE8) + [BitConverter]::GetBytes([int]($cave - ($site.Orig + 5)))
      if ($null -ne $c[4]) { $call += $c[4] }
      $changes += ,@($site.Orig, [byte[]]$call)
    }
    $changes += ,@($cave, [byte[]](& $c[3] $pct))
  }
  return ,$changes
}

# ---------------------------------------------------------------- PE helpers
function Get-Pe([byte[]]$bytes) {
  $pe = [BitConverter]::ToInt32($bytes, 0x3C); $opt = $pe + 24
  $n = [BitConverter]::ToUInt16($bytes, $pe + 6)
  $table = $opt + [BitConverter]::ToUInt16($bytes, $pe + 20)
  $secs = @()
  for ($i = 0; $i -lt $n; $i++) {
    $s = $table + 40 * $i
    $secs += [pscustomobject]@{ Name = $latin1.GetString($bytes, $s, 8).TrimEnd([char]0); Header = $s
      VSize = [BitConverter]::ToInt32($bytes, $s + 8); Rva = [BitConverter]::ToInt32($bytes, $s + 12)
      RawSize = [BitConverter]::ToInt32($bytes, $s + 16); Raw = [BitConverter]::ToInt32($bytes, $s + 20) }
  }
  [pscustomobject]@{ Pe = $pe; Opt = $opt; Table = $table; Count = $n; Sections = $secs
    Base = [BitConverter]::ToUInt32($bytes, $opt + 28); SizeOfImage = [BitConverter]::ToInt32($bytes, $opt + 56)
    Headers = [BitConverter]::ToInt32($bytes, $opt + 60) }
}
function Off-ToVa($pe, [int]$off) {
  foreach ($s in $pe.Sections) { if ($off -ge $s.Raw -and $off -lt $s.Raw + $s.RawSize) { return [int64]$pe.Base + $s.Rva + $off - $s.Raw } }
  return -1
}
function Va-ToOff($pe, [int64]$va) {
  $rva = $va - $pe.Base
  foreach ($s in $pe.Sections) { if ($rva -ge $s.Rva -and $rva -lt $s.Rva + [Math]::Min($s.VSize, $s.RawSize)) { return [int]($rva - $s.Rva + $s.Raw) } }
  return -1
}
function Rel32([int64]$from, [int64]$to) { [BitConverter]::GetBytes([int]($to - $from)) }

# ---------------------------------------------------------------- night tint
# environment_sample (environment.c) multiplies the course by
#   red mix(0.40, 1, day), green mix(0.49, 1, day), blue mix(0.69, 1, day)
# so a clear night is (102, 125, 176). green/blue are private constants and are
# rewritten in place; red shares 0.40 with other code, so its load is pointed at
# a copy in a cave: [double red][u32 original address]['NRED'].
# The terrain lighting (terrain_lighting.cpp) also falls to a sky-light floor
# of 0.30 at night (skyFloor = 0.30 + 0.45 * day, a private float, patched in
# place). Values: red, green, blue, floor.
$nightRx = '\xF2\x0F\x11\x54\x24\x70\xF2\x0F\x10\x05([\x00-\xFF]{4})\xE8[\x00-\xFF]{4}\xF2\x0F\x59\x05[\x00-\xFF]{4}\xF2\x0F\x59\x44\x24\x48\xF2\x0F\x11\x04\x24\xE8[\x00-\xFF]{4}\x88\x46\x18\xF2\x0F\x10\x05([\x00-\xFF]{4})'
$nightBlueRx = '\x89\xC3\xF2\x0F\x10\x05([\x00-\xFF]{4})\xF2\x0F\x10\x0D'
$nightFloorRx = '\x0F\x58\x1D([\x00-\xFF]{4})\x0F\x28\xC3\x0F\xC6\xC3\x55'   # addps xmm3, [0.30, 0.5, 0, 0]
$nightVanilla = @(0.40, 0.49, 0.69, 0.30)
$nightMagic = [byte[]](0x4E, 0x52, 0x45, 0x44)   # 'NRED'

function Night-Want([string]$spec) {
  switch ($spec) {
    'vanilla'  { return $nightVanilla }
    'twilight' { return @(0.45, 0.57, 0.88, 0.36) }   # a bit brighter and bluer: (115, 145, 224)
  }
  $v = @($spec -split ',' | ForEach-Object { [double]::Parse($_.Trim(), [Globalization.CultureInfo]::InvariantCulture) })
  if ($v.Count -eq 3) { $v += 0.30 }
  if ($v.Count -ne 4 -or ($v | Where-Object { $_ -lt 0.2 -or $_ -gt 1 })) { throw "-NightTint: 'twilight', 'vanilla' or 'r,g,b[,floor]', each 0.2..1" }
  return $v
}

function Find-Night([byte[]]$bytes, [string]$text, $pe) {
  $m = [regex]::Matches($text, $nightRx); $mb = [regex]::Matches($text, $nightBlueRx); $mf = [regex]::Matches($text, $nightFloorRx)
  if ($m.Count -ne 1 -or $mb.Count -ne 1 -or $mf.Count -ne 1) { return $null }
  $floorOff = Va-ToOff $pe ([BitConverter]::ToUInt32($bytes, $mf[0].Groups[1].Index))
  $redOp = $m[0].Groups[1].Index
  $redVa = [BitConverter]::ToUInt32($bytes, $redOp); $redOff = Va-ToOff $pe $redVa
  $greenOff = Va-ToOff $pe ([BitConverter]::ToUInt32($bytes, $m[0].Groups[2].Index))
  $blueOff = Va-ToOff $pe ([BitConverter]::ToUInt32($bytes, $mb[0].Groups[1].Index))
  if ($redOff -lt 0 -or $greenOff -lt 0 -or $blueOff -lt 0 -or $floorOff -lt 0) { return $null }
  $moved = $true
  for ($i = 0; $i -lt 4; $i++) { if ($bytes[$redOff + 12 + $i] -ne $nightMagic[$i]) { $moved = $false } }
  $vals = @([BitConverter]::ToDouble($bytes, $redOff), [BitConverter]::ToDouble($bytes, $greenOff), [BitConverter]::ToDouble($bytes, $blueOff),
    [double][BitConverter]::ToSingle($bytes, $floorOff))
  $orig = if ($moved) { [BitConverter]::ToUInt32($bytes, $redOff + 8) } else { $redVa }
  [pscustomobject]@{ RedOp = $redOp; RedOff = $redOff; Moved = $moved; GreenOff = $greenOff; BlueOff = $blueOff; FloorOff = $floorOff; Values = $vals; Orig = $orig }
}

function Same-Night($a, $b) { for ($i = 0; $i -lt 4; $i++) { if ([Math]::Abs($a[$i] - $b[$i]) -gt 1e-6) { return $false } }; return $true }
function Describe-Night($v) { '({0}, {1}, {2}), sky floor {3}' -f [int][Math]::Round(255 * $v[0]), [int][Math]::Round(255 * $v[1]), [int][Math]::Round(255 * $v[2]), [Math]::Round($v[3], 2) }

function Night-Changes([byte[]]$bytes, $night, $want, $pe) {
  $changes = @()
  $changes += ,@($night.GreenOff, [BitConverter]::GetBytes([double]$want[1]))
  $changes += ,@($night.BlueOff, [BitConverter]::GetBytes([double]$want[2]))
  $changes += ,@($night.FloorOff, [BitConverter]::GetBytes([single]$want[3]))
  if (Same-Night $want $nightVanilla) {
    if ($night.Moved) {
      $changes += ,@($night.RedOp, [BitConverter]::GetBytes([uint32]$night.Orig))
      $changes += ,@($night.RedOff, [byte[]](@(0xCC) * 16))
    }
    return ,$changes
  }
  $cave = $night.RedOff
  if (-not $night.Moved) {
    $cave = Take-Cave $bytes
    $changes += ,@($night.RedOp, [BitConverter]::GetBytes([uint32](Off-ToVa $pe $cave)))
  }
  $changes += ,@($cave, [byte[]]([BitConverter]::GetBytes([double]$want[0]) + [BitConverter]::GetBytes([uint32]$night.Orig) + $nightMagic))
  return ,$changes
}

# --------------------------------------------------------------- staff names
# FUN_00467600 (employee name -> text buffer) prints the name typed in the
# Rename box (+0x2a, 34 bytes) or else a fixed nickname + job ("Randy
# Groundskeeper" for every groundskeeper). Its first staff_base() call becomes a
# call into an added section ".cmpn" that, for a paid employee whose name is
# empty (or one it generated for another job), writes a random "First Last"
# (female first names for vendors) and tags it at +0x4a/+0x4b. Names typed in
# the Rename box are kept. The name is stored in the staff record, so it is
# saved with the game.
$hookRx = '\x6B\xF8\x4C\xE8([\x00-\xFF]{4})\x89\xC6\xE8([\x00-\xFF]{4})\x80\x7C\x38\x2A\x00'
$sectionName = '.cmpn'
$sectionSize = 0x4000   # 0x1000 before news popups, 0x2000 before golfer names; an older section is grown in place
$sectionFlags = [uint32]3758096416   # 0xE0000020: code, execute, read, write

$maleNames = @('James','Marcus','Diego','Kenji','Raj','Omar','Liam','Noah','Mateo','Ethan','Lucas','Mason','Elijah','Jamal',
  'Andre','Carlos','Luis','Javier','Hiroshi','Wei','Minh','Arjun','Dev','Tariq','Kwame','Kofi','Tyler','Brandon','Austin',
  'Caleb','Logan','Owen','Wyatt','Hunter','Cody','Travis','Dustin','Derek','Rico','Manny','Sal','Vinnie','Tony','Frankie',
  'Ray','Earl','Hank','Walt','Gus','Otis','Rusty','Duke','Buck','Dale','Marty','Lenny','Felix','Hugo','Theo','Milo',
  'Jasper','Ezra','Kai','Ravi','Sanjay','Mikhail','Sven','Lars','Pierre','Giovanni','Malik','Darnell','DeShawn','Terrence')
$femaleNames = @('Emma','Olivia','Sophia','Mia','Ava','Isabella','Chloe','Zoe','Lily','Grace','Hannah','Priya','Aisha',
  'Fatima','Mei','Yuki','Sakura','Ana','Lucia','Camila','Valentina','Gabriela','Rosa','Maria','Keisha','Tasha','Jasmine',
  'Imani','Brianna','Kayla','Madison','Ashley','Brittany','Tiffany','Amber','Crystal','Dolores','Peggy','Doris','Marge',
  'Flo','Bev','Trish','Deb','Wanda','Norma','Rita','Sally','Gloria','Nadia','Ingrid','Freya','Siobhan','Niamh','Chiara',
  'Leilani','Kiana','Rania')
$lastNames = @('Smith','Johnson','Garcia','Martinez','Nguyen','Kim','Patel','Chen','Okafor','Mensah','Rodriguez','Hernandez',
  'Lopez','Gonzalez','Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin','Lee','Thompson','White','Harris',
  'Sanchez','Clark','Ramirez','Lewis','Robinson','Walker','Young','Allen','King','Wright','Scott','Torres','Hill','Flores',
  'Green','Adams','Nelson','Baker','Hall','Rivera','Campbell','Mitchell','Carter','Roberts','Gomez','Phillips','Evans',
  'Turner','Diaz','Parker','Cruz','Edwards','Collins','Reyes','Stewart','Morris','Murphy','Cook','Rogers','Morgan',
  'Cooper','Peterson','Reed','Bailey','Bell','Kelly','Howard','Ward','Cox','Richardson','Wood','Watson','Brooks',
  'Bennett','Gray','Hughes','Price','Sanders','Myers','Long','Ross','Foster','Tanaka','Sato','Yamamoto','Singh','Kumar',
  'Shah','Ali','Haddad','Novak','Kowalski','Schmidt','Muller','Rossi','Bianchi',"O'Brien",'McCarthy','Fitzgerald',
  'Lindqvist','Larsen','Dubois','Moreau','Silva','Santos','Oliveira','Pereira','Mwangi','Diallo','Haile','Abara')

# The section: 0x000 code (entry at 0x10), 0x200 pointer tables, 0x600 strings.
function Names-Blob([int64]$va, [int64]$staffBase) {
  $blob = New-Object byte[] $sectionSize
  $tables = @{}; $at = 0x200; $str = 0x600
  foreach ($list in @(@('male', $maleNames), @('female', $femaleNames), @('last', $lastNames))) {
    $tables[$list[0]] = $va + $at
    foreach ($n in $list[1]) {
      [Array]::Copy([BitConverter]::GetBytes([uint32]($va + $str)), 0, $blob, $at, 4); $at += 4
      $b = $latin1.GetBytes($n); [Array]::Copy($b, 0, $blob, $str, $b.Length); $str += $b.Length + 1
    }
  }
  if ($at -gt 0x600 -or $str -gt $aimAt) { throw "name tables too large" }
  $code = [byte[]](
    @(0xC3) +                                                     # 00 done: ret
    @(0xAC, 0x84, 0xC0, 0x74, 0x03, 0xAA, 0xEB, 0xF8, 0xC3) +     # 01 copy: lodsb; test al; jz; stosb; jmp; ret
    @(0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC) +
    @(0xE8) + (Rel32 ($va + 0x15) $staffBase) +                   # 10 entry: call staff_base
    @(0x80, 0x7C, 0x38, 0x12, 0x00, 0x74, 0xE4) +                 # record not in use -> done
    @(0x0F, 0xBE, 0x4C, 0x38, 0x13) +                             # ecx = job
    @(0x83, 0xF9, 0xFB, 0x7C, 0xDA, 0x83, 0xF9, 0xFE, 0x7F, 0xD5) + # only paid jobs -5..-2
    @(0x80, 0x7C, 0x38, 0x2A, 0x00, 0x74, 0x0D) +                 # empty name -> gen
    @(0x80, 0x7C, 0x38, 0x4A, 0xC5, 0x75, 0xC7) +                 # not a generated name -> keep
    @(0x38, 0x4C, 0x38, 0x4B, 0x74, 0xC1) +                       # generated for this job -> keep
    @(0xC6, 0x44, 0x38, 0x4A, 0xC5, 0x88, 0x4C, 0x38, 0x4B) +     # 3f gen: tag C5, job
    @(0x50, 0x53, 0x56, 0x57, 0x8D, 0x7C, 0x38, 0x2A) +           # save; edi = name field
    @(0xBE) + [BitConverter]::GetBytes([uint32]$tables['male']) + @(0xBB) + [BitConverter]::GetBytes([uint32]$maleNames.Count) +
    @(0x83, 0xF9, 0xFB, 0x75, 0x0A) +                             # vendors (-5): female names
    @(0xBE) + [BitConverter]::GetBytes([uint32]$tables['female']) + @(0xBB) + [BitConverter]::GetBytes([uint32]$femaleNames.Count) +
    @(0x0F, 0x31, 0x50, 0x31, 0xD2, 0xC1, 0xE8, 0x03, 0xF7, 0xF3, 0x8B, 0x34, 0x96) +  # rdtsc; first = table[(t>>3) % n]
    @(0xE8) + (Rel32 ($va + 0x7B) ($va + 1)) +
    @(0xB0, 0x20, 0xAA, 0x58, 0x31, 0xD2, 0xC1, 0xE8, 0x0B) +     # ' '; last = (t>>11) % n
    @(0xBB) + [BitConverter]::GetBytes([uint32]$lastNames.Count) + @(0xF7, 0xF3, 0x8B, 0x34, 0x95) + [BitConverter]::GetBytes([uint32]$tables['last']) +
    @(0xE8) + (Rel32 ($va + 0x97) ($va + 1)) +
    @(0xC6, 0x07, 0x00, 0x5F, 0x5E, 0x5B, 0x58, 0xC3))           # NUL; restore; ret
  if ($code.Length -ne 0x9F) { throw "names hook assembled to $($code.Length) bytes, expected 0x9F" }
  [Array]::Copy($code, 0, $blob, 0, $code.Length)
  return ,$blob
}

function Find-Names([byte[]]$bytes, [string]$text, $pe) {
  $m = [regex]::Matches($text, $hookRx)
  if ($m.Count -ne 1) { return $null }
  $site = $m[0].Index + 3
  $staffBase = (Off-ToVa $pe ($m[0].Index + 10)) + 5 + [BitConverter]::ToInt32($bytes, $m[0].Groups[2].Index)
  $firstVa = (Off-ToVa $pe $site) + 5 + [BitConverter]::ToInt32($bytes, $m[0].Groups[1].Index)
  $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
  $on = $firstVa -ne $staffBase
  if ($on -and (-not $sec -or $firstVa -ne [int64]$pe.Base + $sec.Rva + 0x10)) { return $null }
  [pscustomobject]@{ Site = $site; SiteVa = Off-ToVa $pe $site; StaffBase = $staffBase; On = $on; Section = $sec }
}

# Appends an empty .cmpn section (code, read, write, execute: the Pixel HD fix
# keeps the render scale in it); returns the new bytes.
function Add-Section([byte[]]$bytes, $pe) {
  $last = $pe.Sections[-1]
  if ($bytes.Length -ne $last.Raw + $last.RawSize) { throw "the program has data after its last section; not adding one" }
  $h = $pe.Table + 40 * $pe.Count
  if ($h + 40 -gt $pe.Headers -or $h + 40 -gt $pe.Sections[0].Raw) { throw "no room for another section header" }
  $out = New-Object byte[] ($bytes.Length + $sectionSize)
  [Array]::Copy($bytes, $out, $bytes.Length)
  $hdr = New-Object byte[] 40
  [Array]::Copy($latin1.GetBytes($sectionName), $hdr, $sectionName.Length)
  [Array]::Copy([BitConverter]::GetBytes([int]$sectionSize), 0, $hdr, 8, 4)
  [Array]::Copy([BitConverter]::GetBytes([int]$pe.SizeOfImage), 0, $hdr, 12, 4)
  [Array]::Copy([BitConverter]::GetBytes([int]$sectionSize), 0, $hdr, 16, 4)
  [Array]::Copy([BitConverter]::GetBytes([int]$bytes.Length), 0, $hdr, 20, 4)
  [Array]::Copy([BitConverter]::GetBytes([uint32]$sectionFlags), 0, $hdr, 36, 4)
  [Array]::Copy($hdr, 0, $out, $h, 40)
  [Array]::Copy([BitConverter]::GetBytes([uint16]($pe.Count + 1)), 0, $out, $pe.Pe + 6, 2)
  [Array]::Copy([BitConverter]::GetBytes([int]($pe.SizeOfImage + $sectionSize)), 0, $out, $pe.Opt + 56, 4)
  return ,$out
}

# Removes the .cmpn section (it must be the last one, of any size this script
# made); returns the new bytes.
function Remove-Section([byte[]]$bytes, $pe) {
  $sec = $pe.Sections[-1]
  if ($sec.Name -ne $sectionName) { throw "$sectionName is not the last section; not removing it" }
  if ($pe.SizeOfImage -ne $sec.Rva + $sec.VSize) { throw "$sectionName does not end the image; not removing it" }
  $out = New-Object byte[] $sec.Raw
  [Array]::Copy($bytes, $out, $sec.Raw)
  for ($i = 0; $i -lt 40; $i++) { $out[$sec.Header + $i] = 0 }
  [Array]::Copy([BitConverter]::GetBytes([uint16]($pe.Count - 1)), 0, $out, $pe.Pe + 6, 2)
  [Array]::Copy([BitConverter]::GetBytes([int]$sec.Rva), 0, $out, $pe.Opt + 56, 4)
  return ,$out
}

# Grows (or shrinks) the last section, .cmpn, to $sectionSize in place: same
# place in the file and in memory, so the hooks into it stay valid.
function Resize-Section([byte[]]$bytes, $pe) {
  $sec = $pe.Sections[-1]
  if ($sec.Name -ne $sectionName) { throw "$sectionName is not the last section; not resizing it" }
  if ($bytes.Length -ne $sec.Raw + $sec.RawSize) { throw "the program has data after $sectionName; not resizing it" }
  if ($pe.SizeOfImage -ne $sec.Rva + $sec.VSize) { throw "$sectionName does not end the image; not resizing it" }
  $out = New-Object byte[] ($sec.Raw + $sectionSize)
  [Array]::Copy($bytes, $out, [Math]::Min($bytes.Length, $out.Length))
  [Array]::Copy([BitConverter]::GetBytes([int]$sectionSize), 0, $out, $sec.Header + 8, 4)
  [Array]::Copy([BitConverter]::GetBytes([int]$sectionSize), 0, $out, $sec.Header + 16, 4)
  [Array]::Copy([BitConverter]::GetBytes([int]($sec.Rva + $sectionSize)), 0, $out, $pe.Opt + 56, 4)
  return ,$out
}

# ---------------------------------------------------- Pixel HD flicker fix
# hd_native.c draw_layer_ref: at a non-whole UI scale the sharp filter keeps a
# whole-multiple copy of each layer and rebuilds it on every new game frame,
# switching the render target to the copy and back. SDL_SetRenderTarget resets
# the render scale, and Pixel HD draws the course into a small picture at
# scale 1/2, so that one presented frame showed the top-left quarter of the
# course at 2x: the "zooming" flicker while the game runs (paused, no new
# frames, no flicker). Upstream bug; the source fix is in hd_native.c.
# The two SDL_SetRenderTarget calls (push [edi+4] / push [ebp+8]) go to helpers
# in .cmpn: +0xF00 saves the scale (SDL_RenderGetScale into +0xFF0) and jumps
# on to SDL_SetRenderTarget; +0xF20 calls it and then SDL_RenderSetScale.
$scaleRx = '\xFF\x77\x04\xFF\x33\xE8([\x00-\xFF]{4})\x83\xC4\x08\x6A\x00\xFF\x37\xE8[\x00-\xFF]{4}\x83\xC4\x08\x6A\x00\xFF\x37\xE8[\x00-\xFF]{4}\x83\xC4\x08\x8D\x44\x24\x20\x6A\x00\x50\xFF\x37\xFF\x33\xE8[\x00-\xFF]{4}\x83\xC4\x10\x8B\x47\x14\x89\x47\x18\xFF\x75\x08\xFF\x33\xE8([\x00-\xFF]{4})\x83\xC4\x08'
$fixAt = 0xF00; $fixB = 0xF20; $fixData = 0xFF0; $fixEnd = 0x1000

# SDL2 is delay-loaded: each function has a `jmp [slot]` stub in .text.
# Returns @{ name = stub VA } for the names found.
function Get-SdlStubs([byte[]]$bytes, [string]$text, $pe, [string[]]$want) {
  $out = @{}
  $dir = [BitConverter]::ToInt32($bytes, $pe.Opt + 96 + 13 * 8)   # PE32 data directory 13: delay imports
  if ($dir -le 0) { return $out }
  $d = Va-ToOff $pe ([int64]$pe.Base + $dir)
  if ($d -lt 0) { return $out }
  for (; [BitConverter]::ToInt32($bytes, $d + 4) -ne 0; $d += 32) {
    $iat = [BitConverter]::ToInt32($bytes, $d + 12)
    $io = Va-ToOff $pe ([int64]$pe.Base + [BitConverter]::ToInt32($bytes, $d + 16))
    if ($io -lt 0) { continue }
    for ($k = 0; ($e = [BitConverter]::ToUInt32($bytes, $io + 4 * $k)) -ne 0; $k++) {
      if ($e -band 0x80000000) { continue }   # by ordinal
      $no = (Va-ToOff $pe ([int64]$pe.Base + $e)) + 2
      if ($no -lt 2) { continue }
      $end = [Array]::IndexOf($bytes, [byte]0, $no)
      $fn = $latin1.GetString($bytes, $no, $end - $no)
      if ($want -notcontains $fn) { continue }
      $slot = [BitConverter]::GetBytes([uint32]([int64]$pe.Base + $iat + 4 * $k))
      $at = $text.IndexOf($latin1.GetString([byte[]](@(0xFF, 0x25) + $slot)), [StringComparison]::Ordinal)
      if ($at -ge 0) { $out[$fn] = Off-ToVa $pe $at }
    }
  }
  return $out
}

function Find-ScaleFix([byte[]]$bytes, [string]$text, $pe) {
  $m = [regex]::Matches($text, $scaleRx)
  if ($m.Count -ne 1) { return $null }
  $s = Get-SdlStubs $bytes $text $pe @('SDL_SetRenderTarget', 'SDL_RenderGetScale', 'SDL_RenderSetScale')
  if ($s.Count -ne 3) { return $null }
  $a = $m[0].Groups[1].Index - 1; $b = $m[0].Groups[2].Index - 1   # the two E8 calls
  $aVa = Off-ToVa $pe $a; $bVa = Off-ToVa $pe $b
  $ta = $aVa + 5 + [BitConverter]::ToInt32($bytes, $a + 1); $tb = $bVa + 5 + [BitConverter]::ToInt32($bytes, $b + 1)
  $srt = $s['SDL_SetRenderTarget']
  $on = $ta -ne $srt
  if ($on) {
    $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
    if (-not $sec -or $ta -ne [int64]$pe.Base + $sec.Rva + $fixAt -or $tb -ne [int64]$pe.Base + $sec.Rva + $fixB) { return $null }
  } elseif ($tb -ne $srt) { return $null }
  [pscustomobject]@{ A = $a; AVa = $aVa; B = $b; BVa = $bVa; On = $on
    Srt = $srt; GetScale = $s['SDL_RenderGetScale']; SetScale = $s['SDL_RenderSetScale'] }
}

# The helpers for section VA $va, as the bytes from +0xF00 to +0xFFF.
function Fix-Code([int64]$va, $fix) {
  $l = New-Object System.Collections.Generic.List[byte]
  $sx = [BitConverter]::GetBytes([uint32]($va + $fixData)); $sy = [BitConverter]::GetBytes([uint32]($va + $fixData + 4))
  $rel = { param([byte]$op, [int64]$to) $l.Add($op); $l.AddRange([BitConverter]::GetBytes([int]($to - ($va + $fixAt + $l.Count + 4)))) }
  # +F00 (renderer, texture): SDL_RenderGetScale(renderer, &sx, &sy); jmp SDL_SetRenderTarget
  $l.AddRange([byte[]](0x8B, 0x44, 0x24, 0x04)); $l.Add(0x68); $l.AddRange($sy); $l.Add(0x68); $l.AddRange($sx); $l.Add(0x50)
  & $rel 0xE8 $fix.GetScale
  $l.AddRange([byte[]](0x83, 0xC4, 0x0C))
  & $rel 0xE9 $fix.Srt
  if ($l.Count -gt $fixB - $fixAt) { throw "Pixel HD helper A too long" }
  while ($l.Count -lt $fixB - $fixAt) { $l.Add(0xCC) }
  # +F20 (renderer, texture): r = SDL_SetRenderTarget(renderer, texture); SDL_RenderSetScale(renderer, sx, sy); return r
  $l.AddRange([byte[]](0xFF, 0x74, 0x24, 0x08, 0xFF, 0x74, 0x24, 0x08))
  & $rel 0xE8 $fix.Srt
  $l.AddRange([byte[]](0x83, 0xC4, 0x08, 0x50, 0xFF, 0x35)); $l.AddRange($sy); $l.AddRange([byte[]](0xFF, 0x35)); $l.AddRange($sx)
  $l.AddRange([byte[]](0xFF, 0x74, 0x24, 0x10))
  & $rel 0xE8 $fix.SetScale
  $l.AddRange([byte[]](0x83, 0xC4, 0x0C, 0x58, 0xC3))
  if ($l.Count -gt $fixData - $fixAt) { throw "Pixel HD helper B too long" }
  while ($l.Count -lt $fixData - $fixAt) { $l.Add(0xCC) }
  $one = [BitConverter]::GetBytes([single]1)
  $l.AddRange($one); $l.AddRange($one)                                   # +FF0 the saved scale (1, 1)
  while ($l.Count -lt $fixEnd - $fixAt) { $l.Add(0) }
  return ,$l.ToArray()
}

# --------------------------------------------------------- clubhouse cache
# hd_art.c tex_evict drops the textures not drawn in the last two frames,
# oldest first (qsort with tex_oldest_first), until the cache is under its
# budget: 256 MB while the animated clubhouse pack is in use. Zoomed out, the
# clubhouse's animation frames (1024x1024 each) aged out between uses, and
# hd_art_prepare draws the whole clubhouse in the old art while any of its
# current frame is missing. The qsort call gets a comparator at .cmpn +0x1200
# that sorts textures of clubhouse files (ArtFile.clubhouse, +0x30 in the
# 0x3c-byte g_files rows; the file is Tex.key.a >> 16) after all others and
# otherwise defers to the original one. Upstream bug.
$clubAt = 0x1200; $clubEnd = 0x1240
$clubSiteRx = '\x68([\x00-\xFF]{4})\x6A\x04\x57\x50\xE8[\x00-\xFF]{4}\x83\xC4\x10\x85\xFF\x7E'
$clubCmpRx = '^\x56\x8B\x44\x24\x0C\x8B\x4C\x24\x08\x8B\x09\x8B\x10\x8B\x42\x20\x39\x41\x20\x75'
$clubFilesRx = '\xA1([\x00-\xFF]{4})\x6B\xD2\x3C\x83\x7C\x10\x30\x00'

# The comparator for section VA $va (64 bytes, +0x1200 to +0x123F).
function Club-Code([int64]$va, $club) {
  $rel = { param([int]$at, [int64]$to) [BitConverter]::GetBytes([int]($to - ($va + $clubAt + $at + 5))) }
  $c = [byte[]](@(0x56, 0x8B, 0x44, 0x24, 0x08, 0xE8) + (& $rel 0x05 ($va + $clubAt + 0x26)) +   # x = clubhouse(*a)
    @(0x89, 0xC6, 0x8B, 0x44, 0x24, 0x0C, 0xE8) + (& $rel 0x10 ($va + $clubAt + 0x26)) +           # y = clubhouse(*b)
    @(0x29, 0xC6, 0x96, 0x5E, 0x85, 0xC0, 0x74, 0x01, 0xC3, 0xE9) + (& $rel 0x1E $club.Orig) +     # x - y, or the original order
    @(0x31, 0xC0, 0xC3, 0x8B, 0x00, 0x0F, 0xB7, 0x40, 0x02, 0x8B, 0x0D) + [BitConverter]::GetBytes([uint32]$club.Files) +
    @(0xE3, 0xEF, 0x6B, 0xC0, 0x3C, 0x83, 0x7C, 0x01, 0x30, 0x01, 0x19, 0xC0, 0x40, 0xC3))         # g_files[file].clubhouse != 0
  if ($c.Length -ne $clubEnd - $clubAt) { throw "clubhouse cache code built to $($c.Length) bytes, expected $($clubEnd - $clubAt)" }
  return ,$c
}

# $null when the site is not in this program; Bad when it points somewhere unexpected.
function Find-ClubCache([byte[]]$bytes, [string]$text, $pe) {
  $m = [regex]::Matches($text, $clubSiteRx); $f = [regex]::Matches($text, $clubFilesRx)
  if ($m.Count -ne 1 -or $f.Count -ne 1) { return $null }
  $site = $m[0].Index + 1
  $to = [int64][BitConverter]::ToUInt32($bytes, $site)
  $files = [int64][BitConverter]::ToUInt32($bytes, $f[0].Groups[1].Index)
  $r = [pscustomobject]@{ Site = $site; Orig = $to; Files = $files; On = $false; Bad = $false }
  $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
  if ($sec -and $to -eq [int64]$pe.Base + $sec.Rva + $clubAt) {
    $r.On = $true
    $j = $sec.Raw + $clubAt + 0x1E
    $r.Orig = [int64]$pe.Base + $sec.Rva + $clubAt + 0x23 + [BitConverter]::ToInt32($bytes, $j + 1)
    $want = Club-Code ([int64]$pe.Base + $sec.Rva) $r
    if (Compare-Object $bytes[($sec.Raw + $clubAt)..($sec.Raw + $clubEnd - 1)] $want -SyncWindow 0) { $r.Bad = $true; return $r }
  }
  $o = Va-ToOff $pe $r.Orig
  if ($o -lt 0 -or [regex]::Matches($latin1.GetString($bytes, $o, 20), $clubCmpRx).Count -ne 1) { $r.Bad = $true }
  return $r
}

# -------------------------------------------------------------- green roll
# FUN_004289e0, a grounded ball: friction = terrain byte +0x21 (green 3) minus
# the slope along the roll, clamped 0..99. 0..4 slow the ball by 1/2..1/32 of
# its speed a tick; 5 and up SPEED IT UP towards a fixed top speed for up to
# 128 ticks, so any downhill of 2 on a green sent it off the green. The break
# turns the ball by side slope x 2^25 (1/128 turn) every tick, whatever its
# speed. A putt struck from the green skips both (no slope, no break); balls
# arriving from off the green (approaches, chips, putts from the fringe) get
# them. Two hooks into .cmpn, both only while the ball is on a green tile
# (terrain [esp+0x68] == 1):
#   friction site (cmp ecx,5; jl; mov esi,[tick], 15 bytes) -> call +0x1240:
#     friction at most 4 (no speeding up), then the mov and cmp; the jl is kept.
#   break site (shl eax,0x1a; sar eax,1) -> call +0x1260: half the break.
# Run under unicorn against the original roll code: other terrain unchanged.
$greenAt = 0x1240; $greenBreak = 0x1260; $greenEnd = 0x1280
$greenSiteRx = '\x8B\x44\x24\x68\x8D\x04\x40\xC1\xE0\x04\xB9\xC8\x94\x57\x00\x0F\xBE\x8C\x01[\x00-\xFF]{4}\x31\xC0(\x83\xF9\x05\x0F\x8C[\x00-\xFF]{4}\x8B\x35[\x00-\xFF]{4}|\xE8[\x00-\xFF]{4}\x0F\x8C[\x00-\xFF]{4}\x0F\x1F\x40\x00)\xBB\xC8\x94\x57\x00\x2B\xB4\x93'
$greenBreakRx = '\xBB\xC8\x94\x57\x00(\xC1\xE0\x1A\xD1\xF8|\xE8[\x00-\xFF]{4})\x8B\x54\x24\x0C\x29\x84\x13\xD0\x00\x00\x00'
$greenTpl = @('837c246c01750a83f9047e05b9040000008b35', 'a:tick', '83f905c3cccccccccc',
  'c1e01ad1f8837c246c017502d1f8c3cccccccccccccccccccccccccccccccccc')

# $null when the sites are not in this program; Bad when they call somewhere unexpected.
function Find-GreenRoll([byte[]]$bytes, [string]$text, $pe) {
  $a = [regex]::Matches($text, $greenSiteRx); $b = [regex]::Matches($text, $greenBreakRx)
  if ($a.Count -ne 1 -or $b.Count -ne 1) { return $null }
  $site = $a[0].Groups[1].Index; $brk = $b[0].Groups[1].Index
  $siteVa = Off-ToVa $pe $site; $brkVa = Off-ToVa $pe $brk
  $on1 = $bytes[$site] -eq 0xE8; $on2 = $bytes[$brk] -eq 0xE8
  $r = [pscustomobject]@{ Site = $site; SiteVa = $siteVa; Break = $brk; BreakVa = $brkVa; Target = $null; Tick = $null; On = $on1; Bad = $false }
  if ($on1 -ne $on2) { $r.Bad = $true; return $r }
  if (-not $on1) {
    $r.Target = $siteVa + 9 + [BitConverter]::ToInt32($bytes, $site + 5)
    $r.Tick = [int64][BitConverter]::ToUInt32($bytes, $site + 11)
  } else {
    $r.Target = $siteVa + 11 + [BitConverter]::ToInt32($bytes, $site + 7)
    $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
    $t1 = $siteVa + 5 + [BitConverter]::ToInt32($bytes, $site + 1); $t2 = $brkVa + 5 + [BitConverter]::ToInt32($bytes, $brk + 1)
    if (-not $sec -or $sec.RawSize -lt $greenEnd -or $t1 -ne [int64]$pe.Base + $sec.Rva + $greenAt -or $t2 -ne [int64]$pe.Base + $sec.Rva + $greenBreak) { $r.Bad = $true; return $r }
    $f = Tpl-Read $bytes $greenTpl ($sec.Raw + $greenAt) $pe
    if (-not $f -or [regex]::Matches($latin1.GetString($bytes, $sec.Raw + $greenAt, $greenEnd - $greenAt), '^' + (Tpl-Rx $greenTpl)).Count -ne 1) { $r.Bad = $true; return $r }
    $r.Tick = $f['tick']
  }
  if ($r.Target -ne $brkVa - 5) { return $null }   # the jl lands on the mov ebx just before the break site
  return $r
}

# The code for section VA $va: the bytes from +0x1240 to +0x127F.
function Green-Code([int64]$va, $green) {
  $b = Tpl-Build $greenTpl @{ tick = $green.Tick } ($va + $greenAt)
  if ($b.Length -ne $greenEnd - $greenAt) { throw "green roll code built to $($b.Length) bytes, expected $($greenEnd - $greenAt)" }
  return ,$b
}

function Green-SiteBytes($green, [bool]$on, [int64]$secVa) {
  if (-not $on) {
    return @([byte[]](@(0x83, 0xF9, 0x05, 0x0F, 0x8C) + (Rel32 ($green.SiteVa + 9) $green.Target) + @(0x8B, 0x35) + [BitConverter]::GetBytes([uint32]$green.Tick)),
             [byte[]](0xC1, 0xE0, 0x1A, 0xD1, 0xF8))
  }
  $s = [byte[]](@(0xE8) + (Rel32 ($green.SiteVa + 5) ($secVa + $greenAt)) + @(0x0F, 0x8C) + (Rel32 ($green.SiteVa + 11) $green.Target) + @(0x0F, 0x1F, 0x40, 0x00))
  $k = [byte[]](@(0xE8) + (Rel32 ($green.BreakVa + 5) ($secVa + $greenBreak)))
  return @($s, $k)
}

# --------------------------------------------------------------- shot fix
# The pro's shot is committed by a course click in FUN_0040f5c0 only when
# [0x822d68] == 1, dock mode [0x567afc] == 3, the delay [0x5a34e4] <= 0 and the
# mouse is above the old dock: [0x822d64] < screen height - 0x78. Two ways it
# got stuck:
#   - With the Frosted Mint HUD the old dock is hidden and the course shows in
#     that bottom strip. Aiming there worked (the port lifted the hover gate
#     with hud_ylim) but the click gate kept the old limit, so the click did
#     nothing. The gate's mov eax,[screen h]; add eax,-0x78 (8 bytes) ->
#     call +0x1300, which passes the limit through hud_ylim as the hover does.
#   - Closing a pro sub-page (FUN_00436c00) sets dock mode 4 while the pro still
#     waits (R+0xcc == -1); only mode 3 commits. The five shot-type buttons in
#     FUN_00436060 (mov [0x58f330], imm32) -> push imm8; call +0x1320, which sets
#     the shot type and, while the pro waits, clears the delay and turns mode 4
#     back into 3. So choosing a shot type (or the same one again) re-arms it.
$shotGate = 0x1300; $shotPick = 0x1320; $shotEnd = 0x1380
$shotGateRx = '\x83\x3D\xE4\x34\x5A\x00\x00\x7F[\x00-\xFF](\xA1([\x00-\xFF]{4})\x83\xC0\x88|\xE8[\x00-\xFF]{4}\x0F\x1F\x00)\x39\x05\x64\x2D\x82\x00\x0F\x8C'
$shotHoverRx = '\xA1([\x00-\xFF]{4})\x83\xC0\x88\x50\xE8([\x00-\xFF]{4})\x83\xC4\x04\x39\xC6\xBE\x68\xA0\x51\x00'
$shotYlimRx = '^\x8B\x4C\x24\x04\x83\x3D[\x00-\xFF]{4}\x00\xB8\xA0\x86\x01\x00\x0F\x45\xC1\x83\x3D[\x00-\xFF]{4}\x00\x0F\x44\xC1\xC3'
$shotSiteRx = '(?:\xC7\x05\x30\xF3\x58\x00([\x00-\xFF]{4})|\x6A([\x00-\xFF])\xE8([\x00-\xFF]{4})\x0F\x1F\x00)\xE9([\x00-\xFF]{4})'
$shotTpl = @('a1', 'a:h', '83c08851', '50e8', 'r:ylim', '83c40459c3cccccccccccccccccccccccc',
  # +0x1320: mov eax,[esp+4]; mov [0x58f330],eax; mov eax,[0x5a59f8]; cmp eax,0x98; jae done; shl eax,8;
  # cmp dword [eax+0x579584],-1; jne done; mov dword [0x5a34e4],0; cmp dword [0x567afc],4; jne done;
  # mov dword [0x567afc],3; done: ret 4
  '8b442404a330f35800a1f8595a003d980000007329c1e00883b884955700ff751dc705e4345a0000000000',
  '833dfc7a560004750ac705fc7a560003000000c20400',
  ('cc' * 31))

# $null when the sites are not in this program; Bad when they are half patched or call somewhere unexpected.
function Find-ShotFix([byte[]]$bytes, [string]$text, $pe) {
  $g = [regex]::Matches($text, $shotGateRx); $h = [regex]::Matches($text, $shotHoverRx)
  if ($g.Count -ne 1 -or $h.Count -ne 1) { return $null }
  $hoverOff = $h[0].Index
  $hVa = [int64][BitConverter]::ToUInt32($bytes, $hoverOff + 1)
  $ylim = (Off-ToVa $pe ($hoverOff + 14)) + [BitConverter]::ToInt32($bytes, $hoverOff + 10)
  $yo = Va-ToOff $pe $ylim
  if ($yo -lt 0 -or [regex]::Matches($latin1.GetString($bytes, $yo, 30), $shotYlimRx).Count -ne 1) { return $null }
  $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
  $pickVa = if ($sec) { [int64]$pe.Base + $sec.Rva + $shotPick } else { -1 }
  $sites = @()
  foreach ($m in [regex]::Matches($text, $shotSiteRx)) {
    $o = $m.Index; $exit = (Off-ToVa $pe ($o + 15)) + [BitConverter]::ToInt32($bytes, $o + 11)
    $eo = Va-ToOff $pe $exit
    if ($eo -lt 0 -or $latin1.GetString($bytes, $eo, 5) -ne $latin1.GetString([byte[]](0x31, 0xC0, 0x48, 0x5E, 0xC3))) { continue }
    if ($m.Groups[1].Success) { $sites += [pscustomobject]@{ Off = $o; Va = Off-ToVa $pe $o; Value = [BitConverter]::ToInt32($bytes, $o + 6); On = $false } }
    elseif ((Off-ToVa $pe ($o + 7)) + [BitConverter]::ToInt32($bytes, $o + 3) -eq $pickVa) {
      $sites += [pscustomobject]@{ Off = $o; Va = Off-ToVa $pe $o; Value = $(if ($bytes[$o + 1] -ge 128) { [int]$bytes[$o + 1] - 256 } else { [int]$bytes[$o + 1] }); On = $true }
    }
  }
  $values = ($sites | ForEach-Object { $_.Value } | Sort-Object) -join ','
  if ($sites.Count -ne 5 -or $values -ne '-1,0,1,3,4') { return $null }
  $gate = $g[0].Groups[1].Index; $gateVa = Off-ToVa $pe $gate
  $on = $bytes[$gate] -eq 0xE8
  $r = [pscustomobject]@{ Gate = $gate; GateVa = $gateVa; H = $hVa; Ylim = $ylim; Sites = $sites; On = $on; Bad = $false }
  if (@($sites | Where-Object { $_.On -ne $on }).Count) { $r.Bad = $true; return $r }
  if (-not $on) {
    if ([int64][BitConverter]::ToUInt32($bytes, $gate + 1) -ne $hVa) { return $null }
  } else {
    $t = $gateVa + 5 + [BitConverter]::ToInt32($bytes, $gate + 1)
    if (-not $sec -or $sec.RawSize -lt $shotEnd -or $t -ne [int64]$pe.Base + $sec.Rva + $shotGate) { $r.Bad = $true; return $r }
    $f = Tpl-Read $bytes $shotTpl ($sec.Raw + $shotGate) $pe
    if (-not $f -or [regex]::Matches($latin1.GetString($bytes, $sec.Raw + $shotGate, $shotEnd - $shotGate), '^' + (Tpl-Rx $shotTpl)).Count -ne 1 -or
        $f['h'] -ne $hVa -or $f['ylim'] -ne $ylim) { $r.Bad = $true; return $r }
  }
  return $r
}

# The code for section VA $va: the bytes from +0x1300 to +0x137F.
function Shot-Code([int64]$va, $shot) {
  $b = Tpl-Build $shotTpl @{ h = $shot.H; ylim = $shot.Ylim } ($va + $shotGate)
  if ($b.Length -ne $shotEnd - $shotGate) { throw "shot fix code built to $($b.Length) bytes, expected $($shotEnd - $shotGate)" }
  return ,$b
}

# @(file offset, bytes) for the gate and the five shot-type sites.
function Shot-SiteBytes($shot, [bool]$on, [int64]$secVa) {
  $out = @()
  if ($on) { $out += ,@($shot.Gate, [byte[]](@(0xE8) + (Rel32 ($shot.GateVa + 5) ($secVa + $shotGate)) + @(0x0F, 0x1F, 0x00))) }
  else { $out += ,@($shot.Gate, [byte[]](@(0xA1) + [BitConverter]::GetBytes([uint32]$shot.H) + @(0x83, 0xC0, 0x88))) }
  foreach ($s in $shot.Sites) {
    if ($on) { $out += ,@($s.Off, [byte[]](@(0x6A, [byte]($s.Value -band 0xFF), 0xE8) + (Rel32 ($s.Va + 7) ($secVa + $shotPick)) + @(0x0F, 0x1F, 0x00))) }
    else { $out += ,@($s.Off, [byte[]](@(0xC7, 0x05, 0x30, 0xF3, 0x58, 0x00) + [BitConverter]::GetBytes([int]$s.Value))) }
  }
  return ,$out
}

# --------------------------------------------------------------- curve fix
# FUN_00424120 speeds a draw (VA 0x6006edf0) or fade (0x6006ee7c) up by
# 1 + 16/(K - yards), K = 330 up to 249 yards and 400 from 250. Golf capped the
# shot at 330 yards; -Distances modern has no cap, so the boost ran away (x4.2
# at 395, divide by zero at 400). Both sites, mov edx,[esp+0x64]; cmp edx,0x12b
# (10 bytes, before a jg), become call .cmpn +0x1280 plus a 5-byte nop. The code
# there loads the yards clamped to 330 into edx and redoes the cmp; ret keeps
# the flags for the jg. Only the boost sees the clamp.
$curveAt = 0x1280; $curveEnd = 0x12A0
$curveRx = '\xC7\x44\x24\x70(?:\xAB\x56\xC6\xFD|\x55\xA9\x39\x02)(\x8B\x54\x24\x64\x81\xFA\x2B\x01\x00\x00|\xE8[\x00-\xFF]{4}\x0F\x1F\x44\x00\x00)(?:\x0F\x8F|\x7F)'
$curveVanilla = [byte[]](0x8B, 0x54, 0x24, 0x64, 0x81, 0xFA, 0x2B, 0x01, 0x00, 0x00)
# mov edx,[esp+0x68]; cmp edx,330; jle +5; mov edx,330; cmp edx,0x12b; ret
$curveCode = [byte[]]((0x8B, 0x54, 0x24, 0x68, 0x81, 0xFA, 0x4A, 0x01, 0x00, 0x00, 0x7E, 0x05, 0xBA, 0x4A, 0x01, 0x00, 0x00,
  0x81, 0xFA, 0x2B, 0x01, 0x00, 0x00, 0xC3) + @(0xCC) * 8)

# $null when the sites are not in this program; Bad when half patched or calling somewhere unexpected.
function Find-CurveFix([byte[]]$bytes, [string]$text, $pe) {
  $m = [regex]::Matches($text, $curveRx)
  if ($m.Count -ne 2) { return $null }
  $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
  $at = if ($sec) { [int64]$pe.Base + $sec.Rva + $curveAt } else { -1 }
  $sites = @(); $ons = 0
  foreach ($x in $m) {
    $o = $x.Groups[1].Index; $va = Off-ToVa $pe $o; $on = $bytes[$o] -eq 0xE8
    $t = if ($on) { $ons++; $va + 5 + [BitConverter]::ToInt32($bytes, $o + 1) } else { 0 }
    $sites += [pscustomobject]@{ Off = $o; Va = $va; Target = $t }
  }
  $r = [pscustomobject]@{ Sites = $sites; On = $ons -eq 2; Bad = $ons -eq 1 }
  if ($r.On) {
    if (-not $sec -or $sec.RawSize -lt $curveEnd -or @($sites | Where-Object { $_.Target -ne $at }).Count -or
        (Compare-Object ([byte[]]$bytes[($sec.Raw + $curveAt)..($sec.Raw + $curveEnd - 1)]) $curveCode -SyncWindow 0)) { $r.Bad = $true }
  }
  return $r
}

# @(file offset, bytes) for the two sites.
function Curve-SiteBytes($curve, [bool]$on, [int64]$secVa) {
  $out = @()
  foreach ($s in $curve.Sites) {
    if ($on) { $out += ,@($s.Off, [byte[]](@(0xE8) + (Rel32 ($s.Va + 5) ($secVa + $curveAt)) + @(0x0F, 0x1F, 0x44, 0x00, 0x00))) }
    else { $out += ,@($s.Off, $curveVanilla) }
  }
  return ,$out
}

# --------------------------------------------------------------- all shots
# Fade, draw and backspin from any lie. The aiming code in FUN_0040f5c0 reset
# them to straight (and said so) when the ball's lie has a hazard (terrain
# byte +0x22 > 0: rough, sand, trees ...); only low punch was let through. The
# shot itself already takes the lie into account (FUN_00424120 sends curved
# shots down its bad-lie path, with that lie's error). Two byte edits:
#   aiming: cmp byte [hazard], 0; jle -> jmp (no reset)
#   Frosted Mint HUD read_pro: pro_shots = hazard > 0 ? 1 : 2 -> always 2
$allLieRx = '\x80\xBC\x02\x0A\xE3\x05\x00\x00(\x7E|\xEB)\x22\x31\xC0\xA3\x30\xF3\x58\x00'
$allHudRx = '\x0F\xB6\x80\x72\x83\x57\x00(\x31\xC9\x84\xC0\x0F\x9E\xC1\x41|\xB9\x02\x00\x00\x00\x0F\x1F\x00)\x89\x0D'
$allHudVanilla = [byte[]](0x31, 0xC9, 0x84, 0xC0, 0x0F, 0x9E, 0xC1, 0x41)
$allHudOn = [byte[]](0xB9, 0x02, 0x00, 0x00, 0x00, 0x0F, 0x1F, 0x00)

function Find-AllShots([string]$text) {
  $a = [regex]::Matches($text, $allLieRx); $b = [regex]::Matches($text, $allHudRx)
  if ($a.Count -ne 1 -or $b.Count -ne 1) { return $null }
  $lie = $a[0].Groups[1].Index; $hud = $b[0].Groups[1].Index
  $on1 = $text[$lie] -eq [char]0xEB; $on2 = $text[$hud] -eq [char]0xB9
  return [pscustomobject]@{ Lie = $lie; Hud = $hud; On = $on1 -and $on2; Mixed = $on1 -ne $on2 }
}

# ------------------------------------------------------------ design names
# ui_hud.c place_panel builds each design tile's tooltip with
# snprintf(tip, 80, "%s %d", title, i + 1). That call goes to .cmpn +0x1400:
# for the titles "Scenic tree" and "Bench design" it prints the design's name
# ("%s"), for "Flower bed design" "%s, %s" with the flower (colour i % 5 in the
# course theme's set, [0x5a34e0]: 1 desert, 2 tropical, else standard; the
# palettes the theme loader 0x440b90 gives slots 45..49) and the bed (shape
# i / 5: Flowers_, SinFlowers_, WalledFlowers_); anything else as before.
# Scenic tree i is art group 0x12f + i (0x4431xx loads Plum, Dogwood,
# ScenicElm, JapaneseMaple, Cypress, Scenic_Tree, PeachTree); bench i is group
# 0x208 + i (benW01, box, red, round wood, backless, lovers).
$dnAt = 0x1400; $dnTab = 0x14A0; $dnStr = 0x1520; $dnEnd = 0x17E0
$dnSiteRx = '\x55\xFF\x74\x24\x08\x68[\x00-\xFF]{4}\x6A\x50\x8D\x84\x24\x94\x01\x00\x00\x50\xE8([\x00-\xFF]{4})\x83\xC4\x14\x85\xDB'
$dnFlowers = @('Yellow daisies', 'Orange marigolds', 'Purple irises', 'White carnations', 'Red roses',          # standard
  'Red poppies', 'California poppies', 'Purple sage', 'Blue lupines', 'Pink primroses',                          # desert
  'Aqua hibiscus', 'Orange bougainvillea', 'Purple orchids', 'Blue hydrangeas', 'Red anthuriums')                # tropical
$dnShapes = @('square bed', 'curved bed', 'stone-edged bed')
$dnTrees = @('Flowering plum', 'Dogwood', 'American elm', 'Japanese maple', 'Monterey cypress', 'Jacaranda', 'Peach tree')
$dnBenches = @('Wooden park bench', 'Carved box bench', 'Red bench', 'Round wood bench', 'Backless bench', "Lovers' bench")

# The bytes from +0x1400 to +0x17FF for section VA $va.
function Dn-Code([int64]$va, $dn) {
  $blob = New-Object byte[] ($dnEnd - $dnAt)
  $u32 = { param([int64]$v) [BitConverter]::GetBytes([uint32]$v) }
  $str = @{}; $at = $dnStr
  foreach ($t in @('%s', '%s, %s') + $dnFlowers + $dnShapes + $dnTrees + $dnBenches) {
    if ($str.ContainsKey($t)) { continue }
    $b = $latin1.GetBytes($t); [Array]::Copy($b, 0, $blob, $at - $dnAt, $b.Length); $str[$t] = $va + $at; $at += $b.Length + 1
  }
  if ($at -gt $dnEnd) { throw "design names too long" }
  $tab = @{}; $t = $dnTab
  foreach ($list in @(@('flowers', $dnFlowers), @('shapes', $dnShapes), @('trees', $dnTrees), @('benches', $dnBenches))) {
    $tab[$list[0]] = $va + $t
    foreach ($n in $list[1]) { [Array]::Copy((& $u32 $str[$n]), 0, $blob, $t - $dnAt, 4); $t += 4 }
  }
  if ($t -gt $dnStr) { throw "design name tables too long" }
  $c = [byte[]](@(0x8B, 0x44, 0x24, 0x10, 0x8B, 0x4C, 0x24, 0x14, 0x49) +   # title, i = n - 1
    @(0x3D) + (& $u32 $dn.Tree) + @(0x75, 0x0E, 0x83, 0xF9, 0x07, 0x73, 0x75, 0x8B, 0x04, 0x8D) + (& $u32 $tab['trees']) + @(0xEB, 0x60) +
    @(0x3D) + (& $u32 $dn.Bench) + @(0x75, 0x0E, 0x83, 0xF9, 0x06, 0x73, 0x60, 0x8B, 0x04, 0x8D) + (& $u32 $tab['benches']) + @(0xEB, 0x4B) +
    @(0x3D) + (& $u32 $dn.Flower) + @(0x75, 0x50, 0x83, 0xF9, 0x0F, 0x73, 0x4B) +
    @(0x89, 0xC8, 0x99, 0xB9, 0x05, 0x00, 0x00, 0x00, 0xF7, 0xF1) +                       # eax = shape, edx = colour
    @(0x8B, 0x0D, 0xE0, 0x34, 0x5A, 0x00, 0x83, 0xF9, 0x02, 0x76, 0x02, 0x31, 0xC9) +     # theme 1 desert, 2 tropical, else standard
    @(0x8D, 0x0C, 0x89, 0x01, 0xD1, 0x8B, 0x14, 0x8D) + (& $u32 $tab['flowers']) +
    @(0x89, 0x54, 0x24, 0x10, 0x8B, 0x04, 0x85) + (& $u32 $tab['shapes']) + @(0x89, 0x44, 0x24, 0x14) +
    @(0xC7, 0x44, 0x24, 0x0C) + (& $u32 $str['%s, %s']) + @(0xE9) + [BitConverter]::GetBytes([int]($dn.Print - ($va + $dnAt + 0x7E))) +
    @(0x89, 0x44, 0x24, 0x10, 0xC7, 0x44, 0x24, 0x0C) + (& $u32 $str['%s']) +            # one name
    @(0xE9) + [BitConverter]::GetBytes([int]($dn.Print - ($va + $dnAt + 0x8F))))           # snprintf
  if ($c.Length -ne 0x8F) { throw "design names code built to $($c.Length) bytes, expected 0x8F" }
  [Array]::Copy($c, 0, $blob, 0, $c.Length)
  for ($i = $c.Length; $i -lt $dnTab - $dnAt; $i++) { $blob[$i] = 0xCC }
  return ,$blob
}

# $null when the site or titles are not in this program; Bad when the call goes somewhere unexpected.
function Find-DesignNames([byte[]]$bytes, [string]$text, $pe) {
  $m = [regex]::Matches($text, $dnSiteRx)
  if ($m.Count -ne 1) { return $null }
  $va = @{}
  foreach ($k in @(@('Tree', 'Scenic tree'), @('Bench', 'Bench design'), @('Flower', 'Flower bed design'))) {
    $f = [regex]::Matches($text, [regex]::Escape("`0$($k[1])`0"))
    if ($f.Count -ne 1) { return $null }
    $va[$k[0]] = Off-ToVa $pe ($f[0].Index + 1)
  }
  $call = $m[0].Groups[1].Index - 1
  $callVa = Off-ToVa $pe $call
  $to = $callVa + 5 + [BitConverter]::ToInt32($bytes, $call + 1)
  $r = [pscustomobject]@{ Call = $call; CallVa = $callVa; Print = $to; Tree = $va['Tree']; Bench = $va['Bench']; Flower = $va['Flower']; On = $false; Bad = $false }
  $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
  if ($sec -and $to -eq [int64]$pe.Base + $sec.Rva + $dnAt) {
    $r.On = $true
    $j = $sec.Raw + $dnAt + 0x8A
    $r.Print = [int64]$pe.Base + $sec.Rva + $dnAt + 0x8F + [BitConverter]::ToInt32($bytes, $j + 1)
    if ($sec.RawSize -lt $dnEnd -or (Compare-Object $bytes[($sec.Raw + $dnAt)..($sec.Raw + $dnEnd - 1)] (Dn-Code ([int64]$pe.Base + $sec.Rva) $r) -SyncWindow 0)) { $r.Bad = $true }
  }
  return $r
}

# ------------------------------------------------------------ pro free aim
# Hold Shift while aiming the pro's shot for an exact target instead of a tile
# centre or corner. Released, everything is as shipped (putts keep the cup).
# FUN_0040f5c0 (dock mode 3) picks the tile centre or corner nearest the mouse
# and stores the tile in R+0xc4/c8; FUN_00424120 (the swing, param3 -1) aims
# at (tile << 10) + 0x200. Two hooks into .cmpn:
#   aim site (the two cmovb that pick centre or corner, 18 bytes) -> call +0xD00:
#     does the cmovb, then, with Shift down (GetAsyncKeyState, looked up once
#     through GetModuleHandleA/GetProcAddress), refines the point by a
#     coarse-to-fine search (steps 512..16 world units, 8 neighbours each)
#     that projects with FUN_0042fb90 and keeps the point nearest the mouse;
#     writes it to the preview, the hovered tile and R+0xc4/c8, and keeps it
#     at +0xC90 with its tile (+0xC88) and a valid flag (+0xC84).
#   launch site (mov eax,0x200; add edi,eax; add esi,eax) -> call +0xDFA:
#     for the pro's own shot (param2 != 0, slot = [0x5a59f8]) whose target
#     tile is the saved one, aims at the saved point; otherwise + 0x200.
# The template is section +0xC80..+0xEFF: data and strings, then the code
# (assembled with keystone and run under unicorn against a mock projection;
# see notes\pro-shot-aim.md). 'a:sXXX' = section VA + 0xXXX.
$aimAt = 0xC80; $aimEntry = 0xD00; $aimLaunch = 0xDFA; $aimEnd = 0xF00
$aimSiteRx = '\x89\x84\x3B\x14\xF5\x05\x00\xA1\xF8\x59\x5A\x00\x89\x8C\x3B\x18\xF5\x05\x00(\x0F\x42\x54\x24\x0C\x89\x54\x24\x0C\x0F\x42\x74\x24\x08\x89\x74\x24\x08|\xE8[\x00-\xFF]{4}\x0F\x1F\x80\x00\x00\x00\x00\x66\x0F\x1F\x44\x00\x00)\x50\xE8'
$aimLaunchRx = '\x8B\xBC\x3A\x12\x12\x00\x00\xC1\xE7\x0A\x29\xCF\xC1\xE6\x0A\x29\xDE(\xB8\x00\x02\x00\x00\x01\xC7\x01\xC6|\xE8[\x00-\xFF]{4}\x0F\x1F\x40\x00)\x8D\x04\xB6'
$aimProjRx = '\x8D\x94\x24\x24\x02\x00\x00\x52\x51\x50\xE8([\x00-\xFF]{4})\x83\xC4\x14\x8B\x84\x24\x18\x02\x00\x00\x8B\x8C\x24\x28\x02\x00\x00'
$aimSiteVanilla = [byte[]](0x0F,0x42,0x54,0x24,0x0C,0x89,0x54,0x24,0x0C,0x0F,0x42,0x74,0x24,0x08,0x89,0x74,0x24,0x08)
$aimLaunchVanilla = [byte[]](0xB8,0x00,0x02,0x00,0x00,0x01,0xC7,0x01,0xC6)
$aimTpl = @(
  '00000000000000000000000000000000000000000000000000000000000000000000000000000000ffff00ff01ffff000100ff01000101015553455233322e646c6c0000000000004765744173796e634b65795374617465000000000000000000000000000000000000000000000000000000000000000000000000000000000f42542410895424100f4274240c8974240c60c705',
  'a:sC84', '00000000e86201000085c00f84ce0000008b84244c020000a3', 'a:sC98', '8b84243c020000a3', 'a:sC9C',
  '8b74242c8b7c2430bd0002000089f189fae8f600000089c356576a008b04240fbe0c45', 'a:sCA8', '0fbe1445', 'a:sCA9',
  '0fafcd034c24080fafd5035424045152e8c80000005a5939d87d0689c389ce89d7ff0424833c240872c383c40cd1ed83fd1073b58974242c897c24308935',
  'a:sC90', '893d', 'a:sC94', '89f0c1f80a89f9c1f90aa3', 'a:sC88', '890d', 'a:sC8C',
  'a3083d5400890d0c3d54008b15f8595a00c1e20889827c955700898a80955700c705', 'a:sC84',
  '0100000061c3837d0c0074418b45083b05f8595a007536833d', 'a:sC84', '00742d8d040fc1f80a3b05', 'a:sC88',
  '751f8d041ec1f80a3b05', 'a:sC8C', '75118b3d', 'a:sC90', '29cf8b35', 'a:sC94',
  '29dec381c70002000081c600020000c36a0068', 'a:sCA4', '68', 'a:sCA0', '5251e8', 'r:proj', '83c414a1', 'a:sCA0', '2b05',
  'a:sC98', '8b0d', 'a:sCA4', '2b0d', 'a:sC9C', '0fafc00fafc901c8c3a1', 'a:sC80', '83f801743c85c0752468', 'a:sCB8',
  'ff15', 'a:gmh', '85c0741f68', 'a:sCC8', '50ff15', 'a:gpa', '85c0740fa3', 'a:sC80', '6a10ffd02500800000c3c705',
  'a:sC80',
  '0100000031c0c3cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc')

# The IAT slot VA of an imported function, or $null.
function Get-ImportSlot([byte[]]$bytes, $pe, [string]$dll, [string]$fn) {
  $dir = [BitConverter]::ToInt32($bytes, $pe.Opt + 96 + 8)   # data directory 1: imports
  $d = Va-ToOff $pe ([int64]$pe.Base + $dir)
  if ($dir -le 0 -or $d -lt 0) { return $null }
  for (; [BitConverter]::ToInt32($bytes, $d + 12) -ne 0; $d += 20) {
    $no = Va-ToOff $pe ([int64]$pe.Base + [BitConverter]::ToInt32($bytes, $d + 12))
    if ($no -lt 0) { continue }
    if ($latin1.GetString($bytes, $no, [Array]::IndexOf($bytes, [byte]0, $no) - $no) -ne $dll) { continue }
    $ilt = [BitConverter]::ToInt32($bytes, $d); $iat = [BitConverter]::ToInt32($bytes, $d + 16)
    $io = Va-ToOff $pe ([int64]$pe.Base + $(if ($ilt) { $ilt } else { $iat }))
    if ($io -lt 0) { continue }
    for ($k = 0; ($e = [BitConverter]::ToUInt32($bytes, $io + 4 * $k)) -ne 0; $k++) {
      if ($e -band 0x80000000) { continue }
      $fo = (Va-ToOff $pe ([int64]$pe.Base + $e)) + 2
      if ($fo -lt 2) { continue }
      if ($latin1.GetString($bytes, $fo, [Array]::IndexOf($bytes, [byte]0, $fo) - $fo) -eq $fn) { return [int64]$pe.Base + $iat + 4 * $k }
    }
  }
  return $null
}

# $null when the sites are not in this program; Bad when they call somewhere unexpected.
function Find-ProAim([byte[]]$bytes, [string]$text, $pe) {
  $a = [regex]::Matches($text, $aimSiteRx); $l = [regex]::Matches($text, $aimLaunchRx); $p = [regex]::Matches($text, $aimProjRx)
  if ($a.Count -ne 1 -or $l.Count -ne 1 -or $p.Count -ne 1) { return $null }
  $gmh = Get-ImportSlot $bytes $pe 'KERNEL32.dll' 'GetModuleHandleA'; $gpa = Get-ImportSlot $bytes $pe 'KERNEL32.dll' 'GetProcAddress'
  if (-not $gmh -or -not $gpa) { return $null }
  $site = $a[0].Groups[1].Index; $launch = $l[0].Groups[1].Index
  $siteVa = Off-ToVa $pe $site; $launchVa = Off-ToVa $pe $launch
  $proj = (Off-ToVa $pe ($p[0].Groups[1].Index + 4)) + [BitConverter]::ToInt32($bytes, $p[0].Groups[1].Index)
  $on1 = $bytes[$site] -eq 0xE8; $on2 = $bytes[$launch] -eq 0xE8
  $r = [pscustomobject]@{ Site = $site; SiteVa = $siteVa; Launch = $launch; LaunchVa = $launchVa; Proj = $proj; Gmh = $gmh; Gpa = $gpa; On = $on1; Bad = $false }
  if ($on1 -ne $on2) { $r.Bad = $true; return $r }
  if ($on1) {
    $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
    $t1 = $siteVa + 5 + [BitConverter]::ToInt32($bytes, $site + 1); $t2 = $launchVa + 5 + [BitConverter]::ToInt32($bytes, $launch + 1)
    if (-not $sec -or $t1 -ne [int64]$pe.Base + $sec.Rva + $aimEntry -or $t2 -ne [int64]$pe.Base + $sec.Rva + $aimLaunch) { $r.Bad = $true }
  }
  return $r
}

# The template for section VA $va: the bytes from +0xC80 to +0xEFF.
function Aim-Code([int64]$va, $aim) {
  $f = @{ proj = $aim.Proj; gmh = $aim.Gmh; gpa = $aim.Gpa }
  foreach ($t in $aimTpl) { if ($t -match '^a:s([0-9A-F]{3})$') { $f["s$($Matches[1])"] = $va + [Convert]::ToInt32($Matches[1], 16) } }
  $b = Tpl-Build $aimTpl $f ($va + $aimAt)
  if ($b.Length -ne $aimEnd - $aimAt) { throw "pro aim code built to $($b.Length) bytes, expected $($aimEnd - $aimAt)" }
  return ,$b
}

function Aim-SiteBytes($aim, [bool]$on, [int64]$secVa) {
  if (-not $on) { return @($aimSiteVanilla, $aimLaunchVanilla) }
  $s = [byte[]](@(0xE8) + (Rel32 ($aim.SiteVa + 5) ($secVa + $aimEntry)) + @(0x0F,0x1F,0x80,0x00,0x00,0x00,0x00,0x66,0x0F,0x1F,0x44,0x00,0x00))
  $l = [byte[]](@(0xE8) + (Rel32 ($aim.LaunchVa + 5) ($secVa + $aimLaunch)) + @(0x0F,0x1F,0x40,0x00))
  return @($s, $l)
}

# --------------------------------------------------------------- news popups
# FUN_0040cb00 (tag, priority, subject) posts the text in golf's buffer
# 0x51a068 to the one-slot news strip, which hides it after a few seconds and
# lets a priority-1 post replace one still showing. Two hooks into .cmpn:
#   post site (its prologue's mov eax,[trace flag], 5 bytes) -> call +0x1000:
#     for priority >= 1, outside mode [0x567afc] = 3 (where the strip refuses
#     all news too), and not the match commentary call (return address
#     'skip'), copies the text (up to 511 chars) into a ring of 4 slots at
#     +0x1800 (read +0x11F0, write +0x11F4). Not queued: subject < 0 with tag
#     0x80006000 (build and course advice), 0x80004210 (tree moving) or
#     0x80001284 ("Game Saved.").
#   show site (FUN_0040f5c0 main loop, the land-offer test, 12 bytes; golf
#     shows its own land dialog here) -> call +0x10A0: for each queued text,
#     wraps it at 44 chars into 0x51a068 + "\n OK\n" and calls the popup menu
#     FUN_0046d6e0(400, 100, 0, 1, 0), golf's modal OK box (a Frosted Mint one
#     with ui.dialogs=frosted_mint); the game waits until it is closed. Then
#     the land-offer test as before.
# Assembled with keystone and run under unicorn (queue, filters, wrap, ring,
# registers and flags). 'a:sXXXX' = section VA + 0xXXXX.
$popAt = 0x1000; $popShow = 0x10A0; $popCodeEnd = 0x11F0
$popPostRx = '(\xA1|\xE8)([\x00-\xFF]{4})\x85\xC0\x74[\x00-\xFF]\xF6\x05[\x00-\xFF]{4}\x01\x74[\x00-\xFF]\x68\x00\xCB\x40\x00\xE8'
$popShowRx = '\x68\x60\x9A\x51\x00\xE8[\x00-\xFF]{4}\x83\xC4\x04(\xF6\x05\x1C\x7A\x56\x00\x01\xBE\x68\xA0\x51\x00|\xE8[\x00-\xFF]{4}\x0F\x1F\x80\x00\x00\x00\x00)\x0F\x84'
$popDlgRx = '\xC7\x44\x24\x10\x00\x00\x00\x00\xE8([\x00-\xFF]{4})\x83\xC4\x14\x85\xC0\x75[\x00-\xFF]\xE8[\x00-\xFF]{4}\x85\xC0\x74[\x00-\xFF]\xFF\x05\x50\xA4\x53\x00'
$popTalkRx = '\x31\xFF\x8A\x1C\x3A\x88\x1C\x39\x47\x39\xF8\x75\xF5\x56\x6A\x01\x68\x08\x21\x00\x80\xE8([\x00-\xFF]{4})'
$popShowVanilla = [byte[]](0xF6,0x05,0x1C,0x7A,0x56,0x00,0x01,0xBE,0x68,0xA0,0x51,0x00)
$popTpl = @(
  '60837c243c017c75833dfc7a560003746c817c2434', 'a:skip',
  '7462837c2440007d198b4424383d0060008074503d1042008074493d841200807442803d68a05100007439a1', 'a:s11F4',
  '89c22b15', 'a:s11F0', '83fa04732783e003c1e0098db8', 'a:s1800',
  'be68a05100b9ff010000ac84c07403aae2f8c60700ff05', 'a:s11F4', '61a1', 'a:tg',
  'c3cccccccccccccccccccccccccccccccccccccccccccccccccccccccc60a1', 'a:s11F0', '3b05', 'a:s11F4',
  '747a83e003c1e0098db0', 'a:s1800',
  'bf68a0510031c931d2ac84c074343c0a74293c20750c85c974ef807fff2074e989faaa4183f92c72e085d2740cc6020a89f929d14931d2ebd0b00aaa31c931d2ebc7c7070a204f4b66c747040a00ff05',
  'a:s11F0', '6a006a016a006a646890010000e8', 'r:dlg',
  '83c414e979ffffff61be68a05100f6051c7a560001c3')

# $null when the sites are not in this program; Bad when they call somewhere unexpected.
function Find-NewsPopup([byte[]]$bytes, [string]$text, $pe) {
  $p = [regex]::Matches($text, $popPostRx); $s = [regex]::Matches($text, $popShowRx)
  $d = [regex]::Matches($text, $popDlgRx); $t = [regex]::Matches($text, $popTalkRx)
  if ($p.Count -ne 1 -or $s.Count -ne 1 -or $d.Count -ne 1 -or $t.Count -ne 1) { return $null }
  $post = $p[0].Index; $show = $s[0].Groups[1].Index
  $postVa = Off-ToVa $pe $post; $showVa = Off-ToVa $pe $show
  $dlg = (Off-ToVa $pe ($d[0].Groups[1].Index + 4)) + [BitConverter]::ToInt32($bytes, $d[0].Groups[1].Index)
  $skip = Off-ToVa $pe ($t[0].Groups[1].Index + 4)
  $talkTo = $skip + [BitConverter]::ToInt32($bytes, $t[0].Groups[1].Index)
  $on1 = $bytes[$post] -eq 0xE8; $on2 = $bytes[$show] -eq 0xE8
  $r = [pscustomobject]@{ Post = $post; PostVa = $postVa; Show = $show; ShowVa = $showVa; Dlg = $dlg; Skip = $skip; Tg = $null; On = $on1; Bad = $false }
  if ($talkTo -ne $postVa - 4) { return $null }   # the commentary must call this news function (its prologue is 4 pushes)
  if ($on1 -ne $on2) { $r.Bad = $true; return $r }
  if (-not $on1) { $r.Tg = [int64][BitConverter]::ToUInt32($bytes, $post + 1); return $r }
  $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
  $t1 = $postVa + 5 + [BitConverter]::ToInt32($bytes, $post + 1); $t2 = $showVa + 5 + [BitConverter]::ToInt32($bytes, $show + 1)
  if (-not $sec -or $sec.RawSize -lt $popCodeEnd -or $t1 -ne [int64]$pe.Base + $sec.Rva + $popAt -or $t2 -ne [int64]$pe.Base + $sec.Rva + $popShow) { $r.Bad = $true; return $r }
  $f = Tpl-Read $bytes $popTpl ($sec.Raw + $popAt) $pe
  if (-not $f -or [regex]::Matches($latin1.GetString($bytes, $sec.Raw + $popAt, $popCodeEnd - $popAt), '^' + (Tpl-Rx $popTpl)).Count -ne 1) { $r.Bad = $true; return $r }
  $r.Tg = $f['tg']
  return $r
}

# The code for section VA $va: the bytes from +0x1000 to +0x11EF (the queue after it starts empty).
function Pop-Code([int64]$va, $pop) {
  $f = @{ tg = $pop.Tg; skip = $pop.Skip; dlg = $pop.Dlg }
  foreach ($t in $popTpl) { if ($t -match '^a:s([0-9A-F]{4})$') { $f["s$($Matches[1])"] = $va + [Convert]::ToInt32($Matches[1], 16) } }
  $b = New-Object System.Collections.Generic.List[byte]
  $b.AddRange([byte[]](Tpl-Build $popTpl $f ($va + $popAt)))
  if ($b.Count -gt $popCodeEnd - $popAt) { throw "news popup code built to $($b.Count) bytes, more than $($popCodeEnd - $popAt)" }
  while ($b.Count -lt $popCodeEnd - $popAt) { $b.Add(0xCC) }
  return ,$b.ToArray()
}

function Pop-SiteBytes($pop, [bool]$on, [int64]$secVa) {
  if (-not $on) { return @([byte[]](@(0xA1) + [BitConverter]::GetBytes([uint32]$pop.Tg)), $popShowVanilla) }
  $p = [byte[]](@(0xE8) + (Rel32 ($pop.PostVa + 5) ($secVa + $popAt)))
  $s = [byte[]](@(0xE8) + (Rel32 ($pop.ShowVa + 5) ($secVa + $popShow)) + @(0x0F,0x1F,0x80,0x00,0x00,0x00,0x00))
  return @($p, $s)
}

# ---------------------------------------------------------------- news hold
# FUN_0040cb00 (post a news message) sets the display timer [0x5a7144] to
# length / (3 or 4) + 16; the strip tick counts it down on 2 of every 3 course
# frames and hides the message at 0. The same 27 bytes, re-encoded (push 4;
# pop ecx and cdq are shorter), make room for imul eax, eax, K.
$newsVanilla = [byte[]](0x83,0x3D,0x88,0x2C,0x82,0x00,0x01, 0xB9,0x04,0x00,0x00,0x00, 0x83,0xD9,0x00, 0x31,0xD2,
  0xF7,0xF1, 0x83,0xC0,0x10, 0xA3,0x44,0x71,0x5A,0x00)
function News-Bytes([int]$k) {
  if ($k -eq 1) { return ,$newsVanilla }
  return ,[byte[]](0x83,0x3D,0x88,0x2C,0x82,0x00,0x01, 0x6A,0x04, 0x59, 0x83,0xD9,0x00, 0x99,
    0xF7,0xF1, 0x83,0xC0,0x10, 0x6B,0xC0,$k, 0xA3,0x44,0x71,0x5A,0x00)
}
function Find-NewsHold([byte[]]$bytes, [string]$text) {
  $hits = @()
  for ($k = 1; $k -le 8; $k++) {
    foreach ($m in [regex]::Matches($text, [regex]::Escape($latin1.GetString((News-Bytes $k))))) { $hits += [pscustomobject]@{ Offset = $m.Index; Hold = $k } }
  }
  if ($hits.Count -ne 1) { return $null }
  return $hits[0]
}

# ------------------------------------------------------- Escape closes all
# ui_hud_escape (ui_hud.c) did one step per Esc: close the message/history,
# else fold the build bar, else close or tuck the tray, else cancel the tool,
# else open the Menu. Its body (194 bytes after the active_item call) is
# rewritten to do every step that applies at once, and the Menu only when
# none did. Both forms are templates: 'a:name' a 4-byte address, 'r:name' a
# rel32 target; the patched form keeps the "tool" and "tray" strings at its
# end so the original can be rebuilt.
$escVanilla = @('837f2c007506837f30007438c7472c00000000c7473000000000b8', 'a:msg', '85f6740289068b4424048b4c240c31e18b15', 'a:cookie',
  '39ca0f85', 'r:fail', '83c4105e5f5bc38b4f0483f911751b837f18007415c7471800000000c7470801000000b8', 'a:bar',
  'ebb885c07819837f0800742689e1ba06000000e8', 'r:goal', 'b8', 'a:tool', 'eb9b89e1ba05000000e8', 'r:wheel', 'b8', 'a:menu',
  'eb8885c97411c7470801000000b8', 'a:tray', 'e973ffffff89e1ba06000000e8', 'r:goal', 'b8', 'a:close', 'e95dffffff')
$escPatched = @('31db837f2c007506837f30007413c7472c00000000c7473000000000bb', 'a:msg', '837f04117519837f18007413c7471800000000c7470801000000bb', 'a:bar',
  '85c0781e837f04007407c747080100000089e1ba06000000e8', 'r:goal', 'bb', 'a:close', '85db751189e1ba05000000e8', 'r:wheel', 'bb', 'a:menu',
  '85f67402891e8b4424048b4c240c31e13b0d', 'a:cookie', '0f85', 'r:fail', '83c4105e5f5bc3', 'a:tool', 'a:tray',
  'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc')
function Hex-Bytes([string]$h) {
  $b = New-Object byte[] ($h.Length / 2)
  for ($i = 0; $i -lt $b.Length; $i++) { $b[$i] = [Convert]::ToByte($h.Substring(2 * $i, 2), 16) }
  return ,$b
}
function Tpl-Rx($tpl) {
  ($tpl | ForEach-Object { if ($_ -match '^[ar]:') { '([\x00-\xFF]{4})' } else { [regex]::Escape($latin1.GetString((Hex-Bytes $_))) } }) -join ''
}
# Reads the fields of a template match at file offset $off; $null if a field repeats with another value.
function Tpl-Read([byte[]]$bytes, $tpl, [int]$off, $pe) {
  $f = @{}; $at = $off
  foreach ($t in $tpl) {
    if ($t -match '^([ar]):(.+)$') {
      $v = if ($Matches[1] -eq 'a') { [int64][BitConverter]::ToUInt32($bytes, $at) } else { (Off-ToVa $pe ($at + 4)) + [BitConverter]::ToInt32($bytes, $at) }
      if ($f.ContainsKey($Matches[2]) -and $f[$Matches[2]] -ne $v) { return $null }
      $f[$Matches[2]] = $v; $at += 4
    } else { $at += $t.Length / 2 }
  }
  return $f
}
function Tpl-Build($tpl, $f, [int64]$va) {
  $l = New-Object System.Collections.Generic.List[byte]
  foreach ($t in $tpl) {
    if ($t -match '^([ar]):(.+)$') {
      $v = $f[$Matches[2]]
      if ($Matches[1] -eq 'a') { $l.AddRange([BitConverter]::GetBytes([uint32]$v)) } else { $l.AddRange([BitConverter]::GetBytes([int]($v - ($va + $l.Count + 4)))) }
    } else { $l.AddRange((Hex-Bytes $t)) }
  }
  return ,$l.ToArray()
}
function Find-Escape([byte[]]$bytes, [string]$text, $pe) {
  $hits = @()
  foreach ($form in @(@($false, $escVanilla), @($true, $escPatched))) {
    foreach ($m in [regex]::Matches($text, (Tpl-Rx $form[1]))) {
      $f = Tpl-Read $bytes $form[1] $m.Index $pe
      if ($f) { $hits += [pscustomobject]@{ Offset = $m.Index; Va = Off-ToVa $pe $m.Index; On = $form[0]; Fields = $f } }
    }
  }
  if ($hits.Count -ne 1) { return $null }
  return $hits[0]
}

# ---------------------------------------------------------- keep the weather
# hd_native.c, after the regional weather and display-air updates:
# `else g_climate.initialized = 0;` and `else g_air.initialized = 0;` run on
# every frame that is not the course. Each store (C7 05 addr 00000000) gets a
# short jump over itself (EB 08).
$weatherRx = @(
  '\x83\xC4\x3C\x8B\x5C\x24\x14\xEB\x0A(\xC7\x05|\xEB\x08)[\x00-\xFF]{4}\x00\x00\x00\x00\xF2\x0F\x10\x05',
  '\x74\x1C\x8B\x15[\x00-\xFF]{4}\xEB\x49(\xC7\x05|\xEB\x08)[\x00-\xFF]{4}\x00\x00\x00\x00\x8B\x7D\x08\x89\xF3\xE9')
function Find-Weather([byte[]]$bytes, [string]$text) {
  $sites = @()
  foreach ($rx in $weatherRx) {
    $m = [regex]::Matches($text, $rx)
    if ($m.Count -ne 1) { return $null }
    $sites += [pscustomobject]@{ Offset = $m[0].Groups[1].Index; Keep = $bytes[$m[0].Groups[1].Index] -eq 0xEB }
  }
  if ($sites[0].Keep -ne $sites[1].Keep) { return $null }
  [pscustomobject]@{ Sites = $sites; Keep = $sites[0].Keep }
}

# ---------------------------------------------------------- scroll edge
# environment_fx.cpp, the HLSL text the game compiles at start (fixed length,
# sizeof - 1): receiver_value and feature_value return 0 outside the receiver.
# Same-length replacements clamp to the nearest receiver pixel instead.
$edgeText = @(
  @('if (any(q < 0) || any(q >= size)) return 0.0;', 'q = clamp(q, int2(0, 0), size - 1);'),
  @('if(any(q<0)||any(q>=int2(receiver_size.xy))||receiver.w<.5)return 0;', 'if(receiver.w<.5)return 0;q=clamp(q,0,int2(receiver_size.xy)-1);'))
function Find-ScrollEdge([string]$text) {
  $sites = @(); $on = 0
  foreach ($e in $edgeText) {
    $new = $e[1].PadRight($e[0].Length)
    $a = $text.IndexOf($e[0], [StringComparison]::Ordinal); $b = $text.IndexOf($new, [StringComparison]::Ordinal)
    if ($a -ge 0 -and $text.IndexOf($e[0], $a + 1, [StringComparison]::Ordinal) -lt 0 -and $b -lt 0) { $sites += [pscustomobject]@{ Offset = $a; Old = $e[0]; New = $new } }
    elseif ($b -ge 0 -and $text.IndexOf($new, $b + 1, [StringComparison]::Ordinal) -lt 0 -and $a -lt 0) { $sites += [pscustomobject]@{ Offset = $b; Old = $e[0]; New = $new }; $on++ }
    else { return $null }
  }
  if ($on -ne 0 -and $on -ne $sites.Count) { return $null }
  [pscustomobject]@{ Sites = $sites; On = $on -gt 0 }
}

# ---------------------------------------------------------- landmark radius
# FUN_00407000 (the landmark benefits at a point): a landmark of design d counts
# while FUN_0040c4b0's distance (yards) < (25 d + 200) / 3. The placement
# preview rings (25 d + 200) / 4. Both multiplies become imul by M (same
# length) and the 200 becomes C; the ring gets 4/3 of the reach so it shows it.
$lmEffectRx = '\x8B\x6E\x04(\x8D\x04\xAD\x00\x00\x00\x00\x01\xE8\x8D\x04\x80|\x69\xC5[\x00-\xFF]{4}\x66\x0F\x1F\x44\x00\x00)\x05([\x00-\xFF]{4})\xF7\xEB'
$lmRingRx = '\x0F\xBE\x05\x14\xA5\x56\x00\x31\xC9\x83\xF8\xF8\x0F\x9C\xC1(\x8D\x04\x80\x8D\x04\x80|\x69\xC0[\x00-\xFF]{4})\x8D\x0C\x49\x01\xC8\x05([\x00-\xFF]{4})\xC1\xF8\x02'
function Find-Landmark([byte[]]$bytes, [string]$text) {
  $e = [regex]::Matches($text, $lmEffectRx); $r = [regex]::Matches($text, $lmRingRx)
  if ($e.Count -ne 1 -or $r.Count -ne 1) { return $null }
  $c = [BitConverter]::ToInt32($bytes, $e[0].Groups[2].Index)
  $pct = if ($bytes[$e[0].Groups[1].Index] -eq 0x8D) { 100 } else { [int]($c / 2) }
  $ringVanilla = $bytes[$r[0].Groups[1].Index] -eq 0x8D
  if ($pct -ne 100 -and $ringVanilla) { return $null }   # (a patched ring with a vanilla effect is put back with the effect)
  [pscustomobject]@{ Effect = $e[0].Groups[1].Index; Ring = $r[0].Groups[1].Index; Percent = $pct }
}
function Landmark-Changes($lm, [int]$pct) {
  if ($pct -eq 100) {
    return @(@($lm.Effect, [byte[]](0x8D,0x04,0xAD,0x00,0x00,0x00,0x00,0x01,0xE8,0x8D,0x04,0x80,0x05,0xC8,0x00,0x00,0x00)),
             @($lm.Ring, [byte[]](0x8D,0x04,0x80,0x8D,0x04,0x80,0x8D,0x0C,0x49,0x01,0xC8,0x05,0xC8,0x00,0x00,0x00)))
  }
  $m = [int][Math]::Round(25 * $pct / 100.0); $c = 2 * $pct
  $rm = [int][Math]::Round(100 * $pct / 300.0); $rc = [int][Math]::Round(800 * $pct / 300.0)
  $e = [byte[]](@(0x69, 0xC5) + [BitConverter]::GetBytes([int]$m) + @(0x66, 0x0F, 0x1F, 0x44, 0x00, 0x00, 0x05) + [BitConverter]::GetBytes([int]$c))
  $r = [byte[]](@(0x69, 0xC0) + [BitConverter]::GetBytes([int]$rm) + @(0x8D, 0x0C, 0x49, 0x01, 0xC8, 0x05) + [BitConverter]::GetBytes([int]$rc))
  return @(@($lm.Effect, $e), @($lm.Ring, $r))
}

# ------------------------------------------------------------ shot distances
# FUN_00422530 (a golfer's maximum shot, yards). Base site:
#   mov ecx,SE; mov esi,LE; cmove esi,ecx      Easy extra: short SE, long LE
#   lea ecx,[esi+LO]; add esi,SO; ...cmovne    offsets: long LO, short SO
# (difficulty 1-3 puts level * 16.67 in esi instead of the Easy extra). End
# site: the non-tee factor esi + (esi * C >> 33) (C = -0.4 * 2^32 gives 0.8,
# -0.2 * 2^32 gives 0.9) and the cap min(esi, CAP). The launch-speed solver
# (FUN_00422430) bisects up to 2x its fitted guess and lands on target well
# past 600 yards, so the cap can go.
$distBaseRx = '\xB9([\x00-\xFF])\x00\x00\x00\xBE([\x00-\xFF])\x00\x00\x00\x0F\x44\xF1\x8D\x8E([\x00-\xFF]{4})\x81\xC6([\x00-\xFF]{4})\x84\xC0\x0F\x45\xF1'
$distEndRx = '\xB9([\x00-\xFF]{4})\x89\xF0\xF7\xE9\x89\xD0\xD1\xF8\xC1\xEA\x1F\x01\xF0\x01\xD0\x89\xC6\xB8([\x00-\xFF]{4})\x39\xC6\x0F\x4C\xC6'
$distForms = @{
  vanilla = @{ SE = 25; LE = 40; LO = 200; SO = 150; C = [uint32]0x99999999L; Cap = 330 }
  modern  = @{ SE = 25; LE = 30; LO = 230; SO = 210; C = [uint32]0xCCCCCCCCL; Cap = 0x7FFFFFFF }
}
function Find-Distances([byte[]]$bytes, [string]$text) {
  $b = [regex]::Matches($text, $distBaseRx); $e = [regex]::Matches($text, $distEndRx)
  if ($b.Count -ne 1 -or $e.Count -ne 1) { return $null }
  $g = $b[0].Groups; $h = $e[0].Groups
  $have = @{ SE = [int]$bytes[$g[1].Index]; LE = [int]$bytes[$g[2].Index]; LO = [BitConverter]::ToInt32($bytes, $g[3].Index)
             SO = [BitConverter]::ToInt32($bytes, $g[4].Index); C = [BitConverter]::ToUInt32($bytes, $h[1].Index); Cap = [BitConverter]::ToInt32($bytes, $h[2].Index) }
  $form = $null
  foreach ($k in $distForms.Keys) {
    $f = $distForms[$k]; $same = $true
    foreach ($p in $f.Keys) { if ($have[$p] -ne $f[$p]) { $same = $false } }
    if ($same) { $form = $k }
  }
  if (-not $form) { return $null }
  [pscustomobject]@{ Base = $b[0].Index; End = $e[0].Index; Form = $form }
}
function Describe-Distances([string]$form) {
  $f = $distForms[$form]; $pct = if ($f.C -eq [uint32]0x99999999L) { 80 } else { 90 }
  $cap = if ($f.Cap -ge 0x7FFFFFFF) { 'no cap' } else { "cap $($f.Cap)" }
  '{0}: tee {1}/{2} yards (Easy {3}/{4}), other lies {5}%, {6}' -f $form, $f.LO, $f.SO, ($f.LO + $f.LE), ($f.SO + $f.SE), $pct, $cap
}
function Distance-Changes($d, [string]$form) {
  $f = $distForms[$form]
  $base = [byte[]](@(0xB9, $f.SE, 0, 0, 0, 0xBE, $f.LE, 0, 0, 0, 0x0F, 0x44, 0xF1, 0x8D, 0x8E) + [BitConverter]::GetBytes([int]$f.LO) +
    @(0x81, 0xC6) + [BitConverter]::GetBytes([int]$f.SO) + @(0x84, 0xC0, 0x0F, 0x45, 0xF1))
  $end = [byte[]](@(0xB9) + [BitConverter]::GetBytes([uint32]$f.C) + @(0x89, 0xF0, 0xF7, 0xE9, 0x89, 0xD0, 0xD1, 0xF8, 0xC1, 0xEA, 0x1F, 0x01, 0xF0, 0x01, 0xD0, 0x89, 0xC6, 0xB8) +
    [BitConverter]::GetBytes([int]$f.Cap) + @(0x39, 0xC6, 0x0F, 0x4C, 0xC6))
  return @(@($d.Base, $base), @($d.End, $end))
}

# --------------------------------------------------------------- celebrities
# Celebrity guests come from game\Themes\Standard\celebrities.dta, read when the game starts.
# Touring pros come from progolfers.dta in the same folder, read the same way.
function Set-ThemeList([string]$file, [string]$mode) {
  $dta = Join-Path $InstallDir "game\Themes\Standard\$file"
  $mine = Join-Path $PSScriptRoot $file
  $backup = "$dta.companion-backup"
  if (-not (Test-Path -LiteralPath $dta)) { Write-Warning "$file not found under game\Themes\Standard; left alone."; return }
  if ($mode -eq 'modern') {
    if (-not (Test-Path -LiteralPath $mine)) { Write-Warning "companion $file missing next to the script; left alone."; return }
    if ((Get-FileHash -LiteralPath $dta).Hash -eq (Get-FileHash -LiteralPath $mine).Hash) { Write-Host "${file}: modern list in place."; return }
    if ($DryRun) { Write-Host "${file}: would install the modern list (dry run)."; return }
    if (-not (Test-Path -LiteralPath $backup)) { Copy-Item -LiteralPath $dta -Destination $backup }
    Copy-Item -LiteralPath $mine -Destination $dta -Force
    Write-Host "${file}: modern list installed (original kept as $file.companion-backup)."
  } else {
    if (-not (Test-Path -LiteralPath $backup)) { Write-Host "${file}: original list in place."; return }
    if ($DryRun) { Write-Host "${file}: would restore the original list (dry run)."; return }
    Copy-Item -LiteralPath $backup -Destination $dta -Force; Remove-Item -LiteralPath $backup
    Write-Host "${file}: original list restored."
  }
}

# ------------------------------------------------------------ white flowers
# A 256-colour PCX ends with 0x0C and its 768-byte palette.
function Pcx-Palette([byte[]]$b) {
  if ($b.Length -lt 769 -or $b[$b.Length - 769] -ne 0x0C) { return $null }
  return ,[byte[]]$b[($b.Length - 768)..($b.Length - 1)]
}
function Set-WhiteFlowers([string]$mode) {
  $dir = Join-Path $InstallDir 'game\Flics\Flowers'
  $white = Join-Path $dir 'FlowerbedA_WhitePal.pcx'
  $backup = "$white.companion-backup"
  if (-not (Test-Path -LiteralPath $white)) { Write-Warning "FlowerbedA_WhitePal.pcx not found; flower beds left alone."; return }
  if ($mode -eq 'off') {
    if (-not (Test-Path -LiteralPath $backup)) { Write-Host "white flower bed: original palette in place."; return }
    if ($DryRun) { Write-Host "white flower bed: would restore the original palette (dry run)."; return }
    Copy-Item -LiteralPath $backup -Destination $white -Force; Remove-Item -LiteralPath $backup
    Write-Host "white flower bed: original (magenta) palette restored."; return
  }
  $src = if (Test-Path -LiteralPath $backup) { $backup } else { $white }
  $orig = [IO.File]::ReadAllBytes($src)
  $pw = Pcx-Palette $orig
  $redSrc = Join-Path $dir 'FlowerbedA_RedPal.pcx'
  if (Test-Path -LiteralPath "$redSrc.companion-backup") { $redSrc = "$redSrc.companion-backup" }   # -RedFlowers changes it
  $pr = Pcx-Palette ([IO.File]::ReadAllBytes($redSrc))
  $py = Pcx-Palette ([IO.File]::ReadAllBytes((Join-Path $dir 'FlowerbedA_YelPal.pcx')))
  if (-not $pw -or -not $pr -or -not $py) { Write-Warning "flower bed palettes not recognised; flower beds left alone."; return }
  $out = [byte[]]$orig.Clone(); $at = $out.Length - 768; $n = 0
  for ($i = 0; $i -lt 256; $i++) {
    $k = 3 * $i
    $petal = $false
    for ($c = 0; $c -lt 3; $c++) { if ($pw[$k + $c] -ne $pr[$k + $c] -or $pw[$k + $c] -ne $py[$k + $c]) { $petal = $true } }
    if (-not $petal) { continue }
    $v = [Math]::Max([Math]::Max([int]$pw[$k], [int]$pw[$k + 1]), [int]$pw[$k + 2])
    $v = $v + (255 - $v) * 0.3   # lifted towards white: the shaded petals read white, not grey
    $out[$at + $k] = [byte][Math]::Round($v * 0.97); $out[$at + $k + 1] = [byte][Math]::Round($v * 0.98); $out[$at + $k + 2] = [byte][Math]::Round($v)
    $n++
  }
  $have = [IO.File]::ReadAllBytes($white)
  if (-not (Compare-Object $have $out -SyncWindow 0)) { Write-Host "white flower bed: white palette in place ($n petal colours)."; return }
  if ($DryRun) { Write-Host "white flower bed: would make $n petal colours white (dry run)."; return }
  if (-not (Test-Path -LiteralPath $backup)) { Copy-Item -LiteralPath $white -Destination $backup }
  [IO.File]::WriteAllBytes($white, $out)
  Write-Host "white flower bed: $n petal colours made white (original kept as FlowerbedA_WhitePal.pcx.companion-backup)."
}

# The standard bed's Red palette is magenta-pink: its petal colours (the
# entries that differ from the yellow palette or the original white one) turn
# hue 355 at the same value, saturation x1.1; near-grey entries (s < 0.15) stay.
function Set-RedFlowers([string]$mode) {
  $dir = Join-Path $InstallDir 'game\Flics\Flowers'
  $red = Join-Path $dir 'FlowerbedA_RedPal.pcx'
  $backup = "$red.companion-backup"
  if (-not (Test-Path -LiteralPath $red)) { Write-Warning "FlowerbedA_RedPal.pcx not found; red flower beds left alone."; return }
  if ($mode -eq 'off') {
    if (-not (Test-Path -LiteralPath $backup)) { Write-Host "red flower bed: original palette in place."; return }
    if ($DryRun) { Write-Host "red flower bed: would restore the original palette (dry run)."; return }
    Copy-Item -LiteralPath $backup -Destination $red -Force; Remove-Item -LiteralPath $backup
    Write-Host "red flower bed: original (pink) palette restored."; return
  }
  $src = if (Test-Path -LiteralPath $backup) { $backup } else { $red }
  $orig = [IO.File]::ReadAllBytes($src)
  $whiteSrc = Join-Path $dir 'FlowerbedA_WhitePal.pcx'
  if (Test-Path -LiteralPath "$whiteSrc.companion-backup") { $whiteSrc = "$whiteSrc.companion-backup" }
  $pr = Pcx-Palette $orig
  $py = Pcx-Palette ([IO.File]::ReadAllBytes((Join-Path $dir 'FlowerbedA_YelPal.pcx')))
  $pw = Pcx-Palette ([IO.File]::ReadAllBytes($whiteSrc))
  if (-not $pr -or -not $py -or -not $pw) { Write-Warning "flower bed palettes not recognised; red flower beds left alone."; return }
  $out = [byte[]]$orig.Clone(); $at = $out.Length - 768; $n = 0
  for ($i = 0; $i -lt 256; $i++) {
    $k = 3 * $i
    $petal = $false
    for ($c = 0; $c -lt 3; $c++) { if ($pr[$k + $c] -ne $py[$k + $c] -or $pr[$k + $c] -ne $pw[$k + $c]) { $petal = $true } }
    if (-not $petal) { continue }
    $mx = [Math]::Max([Math]::Max([int]$pr[$k], [int]$pr[$k + 1]), [int]$pr[$k + 2])
    $mn = [Math]::Min([Math]::Min([int]$pr[$k], [int]$pr[$k + 1]), [int]$pr[$k + 2])
    if ($mx -eq 0 -or ($mx - $mn) / $mx -lt 0.15) { continue }
    $sat = [Math]::Min(1.0, ($mx - $mn) / $mx * 1.1)
    $out[$at + $k] = [byte]$mx
    $out[$at + $k + 1] = [byte][Math]::Round($mx * (1 - $sat))
    $out[$at + $k + 2] = [byte][Math]::Round($mx * (1 - $sat * (355 / 60 - 5)))
    $n++
  }
  $have = [IO.File]::ReadAllBytes($red)
  if (-not (Compare-Object $have $out -SyncWindow 0)) { Write-Host "red flower bed: red palette in place ($n petal colours)."; return }
  if ($DryRun) { Write-Host "red flower bed: would make $n petal colours red (dry run)."; return }
  if (-not (Test-Path -LiteralPath $backup)) { Copy-Item -LiteralPath $red -Destination $backup }
  [IO.File]::WriteAllBytes($red, $out)
  Write-Host "red flower bed: $n petal colours made red (original kept as FlowerbedA_RedPal.pcx.companion-backup)."
}

# -------------------------------------------------------------------- labels
# Strings in image\golf.bin (the original program, loaded raw at 0x400000, so
# file offset = address - 0x400000), each rewritten in its own slot: the old and
# the new text are both zero-padded to the longer of the two, and the slot was
# measured to hold that. Every address is checked to hold the old or the new
# text before anything is written.
$labelBin = @(
  @(0x4c1bd0, 'wbs', 'waste bunkers'),            # plural of waste bunker
  @(0x4c1c20, 'ravine', 'stream'),                 # default name; the course themes set their own
  @(0x4c1c30, 'ravines', 'streams'),               # (burn, stream, canyon) but keep this plural
  @(0x4c4c78, 'rhododedron', 'azalea'),            # typo; rhododendron does not fit
  @(0x4c4d34, 'aqua hybiscus', 'aqua hibiscus'),
  @(0x4c4cac, "Pot o'Gold", "Pot o' Gold"),
  @(0x4c4bc4, 'stonehenge', 'Stonehenge'),
  @(0x4c4bd0, ' ancient stonehenge rock', ' ancient Stonehenge rock'),
  @(0x4c8264, 'Ballwasher', 'Ball Washer'),
  @(0x4c4e88, 'To further improve this skill you will need expand your course to a ', 'To further improve this skill you will need to expand your course to a '),
  @(0x4c54f4, ' increases your players speed of play.', ' speeds up play on your course.'),
  @(0x4e1e04, ' Placing a Ranger/Marshall near the tee will speed up play on this hole.', ' Placing a Ranger/Marshal near the tee will speed up play on this hole.'),
  # staff jobs (plain / skilled)
  @(0x4c154c, 'Celebrity', 'Head Pro'),
  @(0x4c1538, 'Marshall', 'Marshal'),
  @(0x4c1528, 'Groundskeeper', 'Greenkeeper'),
  @(0x4c151c, 'Technician', 'Agronomist'),
  @(0x4c1510, 'Soda Vendor', 'Cart Server'),
  @(0x4c1504, 'Refresher', 'Bartender'),
  # landmarks and eyesores: short name / phrase after "a" (a leading n makes "an")
  @(0x4c49b0, 'radio antenna', 'cell tower'),
  @(0x4c49c0, 'n unsightly radio antenna', ' hideous cell tower'),
  @(0x4c4a28, 'oriental house', 'tea house'),
  @(0x4c4a38, 'n ornate oriental house', ' traditional tea house'),
  # a skill past the data table, celebrity types, investors, a fallback, a place
  @(0x4c3724, 'Mental Toughness', 'Composure'),
  @(0x4c396c, 'fitness guru', 'influencer'),
  @(0x4c394c, 'beauty', 'icon'),
  @(0x4c383c, 'Don Trump', 'E.Muskrat'),
  @(0x4c3824, 'L.Probst', 'J.Bezzos'),
  @(0x4c3854, 'B.Gates', 'M.Zuck'),
  @(0x4c3900, 'Bill Clinton', 'Bubba Klinton'),
  @(0x4c1f94, 'Rocky Mtns.', 'Rocky Mountains'),
  @(0x4c96e8, 'Snack Bar', 'Snack Shack'),         # the course themes copy this into the building row
  # famous golfers (first and last name lists): the 2020s tour
  @(0x4c3a9c, 'Craig', 'Brooks'),   @(0x4c3a44, 'Stadler', 'Keepka'),
  @(0x4c3a94, 'Colin', 'Scotty'),   @(0x4c3a38, 'Montgomerie', 'Shuffler'),
  @(0x4c3a8c, 'Greg', 'Tommy'),     @(0x4c3a30, 'Norman', 'Kimball'),
  @(0x4c3a84, 'David', 'Ricky'),    @(0x4c3a28, 'Duval', 'Fouler'),
  @(0x4c3a7c, 'Jean', 'Rory'),      @(0x4c3a1c, 'VanDeVelde', 'McIlroyal'),
  @(0x4c3a74, 'Arnie', 'Jordan'),   @(0x4c3a14, 'Palmer', 'Speech'),
  @(0x4c3a70, 'Tom', 'Max'),        @(0x4c3a0c, 'Watson', 'Homer'),
  @(0x4c3a68, 'John', 'Adam'),      @(0x4c3a04, 'Daly', 'Scotch'),
  @(0x4c3cc4, 'Karrie', 'Lydia'),   @(0x4c39fc, 'Fisher', 'K.O.'),
  @(0x4c3cc0, 'Jan', 'Jin'),        @(0x4c39f0, 'Stephenson', 'Young Go'),
  @(0x4c3cb8, 'Julie', 'Lilia'),    @(0x4c39e8, 'Inkster', 'View'),
  @(0x4c3cb0, 'Nancy', 'Nelly'),    @(0x4c39e0, 'Lopez', 'Accord'),
  @(0x4c3a64, 'Ben', 'Jon'),        @(0x4c39d8, 'Hogan', 'Ramm'),
  @(0x4c3a5c, 'Ernie', 'Shane'),    @(0x4c39d4, 'Els', 'Low'),
  @(0x4c3a54, 'Jack', 'Zander'),    @(0x4c39c8, 'Nicklaus', 'Chauffeur'),
  @(0x4c3a4c, 'Tiger', 'Ludvig'),   @(0x4c39c0, 'Woods', 'Iceberg')
)
# The remaster's own copies (people tray, Extras tray, tooltips, a message), found as a
# unique zero-terminated string in each program. New text is never longer.
$labelExe = @(
  @('Celebrity', 'Head Pro'),
  @('Marshall', 'Marshal'),
  @('Groundskeeper', 'Greenkeeper'),
  @('Technician', 'Agronomist'),
  @('Soda Vendor', 'Cart Server'),
  @('Refresher', 'Bartender'),
  @('Home site', 'Home lot'),
  @('Analyze golf shot', 'Shot preview'),
  @('Upgrade (can be rotated, Tab)', 'Upgrade (Tab rotates)'),
  @('Weeds are spreading on hole %d (%s). Hire a Turf Technician or move one to cover it.', 'Weeds are spreading on hole %d (%s). Hire a Greenkeeper or move one to cover it.')
)
function Label-Pad([string]$s, [int]$len) { return $s + ([string][char]0 * ($len + 1 - $s.Length)) }

# Returns the edits to make (offset, bytes) or $null when the file is not recognised.
# The text the program labels are looked for in: a program's own strings end
# before the added section, whose golfer names repeat some of them (Watson).
function Label-Text([byte[]]$bytes, [bool]$isBin) {
  if (-not $isBin) {
    $sec = (Get-Pe $bytes).Sections | Where-Object { $_.Name -eq $sectionName }
    if ($sec) { return $latin1.GetString($bytes, 0, $sec.Raw) }
  }
  return $latin1.GetString($bytes)
}

function Label-Edits([string]$text, [bool]$on, [bool]$isBin, [ref]$state) {
  $edits = @(); $old = 0; $new = 0
  $list = if ($isBin) { $labelBin } else { $labelExe }
  foreach ($e in $list) {
    if ($isBin) { $a = $e[0] - 0x400000; $o = $e[1]; $n = $e[2] } else { $o = $e[0]; $n = $e[1] }
    $len = [Math]::Max($o.Length, $n.Length)
    $po = Label-Pad $o $len; $pn = Label-Pad $n $len
    if ($isBin) {
      if ($a + $len + 1 -gt $text.Length) { return $null }
      $have = $text.Substring($a, $len + 1)
      if ($have -ceq $po) { $old++ } elseif ($have -ceq $pn) { $new++ } else { return $null }
      $at = $a
    } else {
      $ko = [char]0 + $po; $kn = [char]0 + $pn
      $io = $text.IndexOf($ko, [StringComparison]::Ordinal); $in = $text.IndexOf($kn, [StringComparison]::Ordinal)
      if ($io -ge 0 -and $text.IndexOf($ko, $io + 1, [StringComparison]::Ordinal) -ge 0) { return $null }
      if ($in -ge 0 -and $text.IndexOf($kn, $in + 1, [StringComparison]::Ordinal) -ge 0) { return $null }
      if ($io -ge 0 -and $in -lt 0) { $old++; $at = $io + 1 } elseif ($in -ge 0 -and $io -lt 0) { $new++; $at = $in + 1 } else { return $null }
    }
    $want = if ($on) { $pn } else { $po }
    if ($text.Substring($at, $len + 1) -cne $want) { $edits += ,@($at, $latin1.GetBytes($want)) }
  }
  $state.Value = if ($new -eq 0) { 'vanilla' } elseif ($old -eq 0) { 'renamed' } else { "mixed ($new of $($old + $new) renamed)" }
  return ,$edits
}

# Building and skill names go through the game's own data tables: a small mod
# (mods\companion_labels next to this script) copied into the game's mods
# folder and switched on in mods.ini ([mods] companion_labels=1).
function Set-LabelMod([bool]$on) {
  $src = Join-Path $PSScriptRoot 'mods\companion_labels'
  $dst = Join-Path $InstallDir 'mods\companion_labels'
  $ini = Join-Path $InstallDir 'mods.ini'
  $line = 'companion_labels=1   ; companion: building and skill names'
  $text = if (Test-Path -LiteralPath $ini) { [IO.File]::ReadAllText($ini) } else { '' }
  $has = $text -match '(?m)^companion_labels=1'
  if ($on) {
    if (-not (Test-Path -LiteralPath $src)) { Write-Warning "companion mods\companion_labels missing next to the script; label mod left alone."; return }
    $same = (Test-Path -LiteralPath $dst) -and -not (Compare-Object (Get-ChildItem -LiteralPath $src -Recurse -File | ForEach-Object { (Get-FileHash -LiteralPath $_.FullName).Hash }) (Get-ChildItem -LiteralPath $dst -Recurse -File | ForEach-Object { (Get-FileHash -LiteralPath $_.FullName).Hash }))
    if ($same -and $has) { Write-Host "label mod: installed and on."; return }
    if ($DryRun) { Write-Host "label mod: would install and switch on (dry run)."; return }
    if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
    Copy-Item -LiteralPath $src -Destination $dst -Recurse
    if (-not $has) {
      if ((Test-Path -LiteralPath $ini) -and -not (Test-Path -LiteralPath "$ini.companion-backup")) { Copy-Item -LiteralPath $ini -Destination "$ini.companion-backup" }
      if ($text -match '(?m)^\[mods\]\s*$') { $text = $text -replace '(?m)^\[mods\]\s*$', "[mods]`n$line" }
      else { $text = $text.TrimEnd() + "`n`n[mods]`n$line`n" }
      [IO.File]::WriteAllText($ini, $text)
    }
    Write-Host "label mod: installed (mods\companion_labels) and switched on in mods.ini."
  } else {
    if (-not $has -and -not (Test-Path -LiteralPath $dst)) { Write-Host "label mod: not installed."; return }
    if ($DryRun) { Write-Host "label mod: would remove (dry run)."; return }
    if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
    if ($has) {
      $text = $text -replace '(?m)^companion_labels=1[^\n]*\n?', ''
      $text = $text -replace '\n*\[mods\]\s*$', "`n"
      $bak = "$ini.companion-backup"
      if ((Test-Path -LiteralPath $bak) -and ([IO.File]::ReadAllText($bak).TrimEnd() -ceq $text.TrimEnd())) { Copy-Item -LiteralPath $bak -Destination $ini -Force }
      else { [IO.File]::WriteAllText($ini, $text) }
    }
    if (Test-Path -LiteralPath "$ini.companion-backup") { Remove-Item -LiteralPath "$ini.companion-backup" }
    Write-Host "label mod: removed."
  }
}

function Set-Labels([string]$mode) {
  $on = $mode -eq 'on'
  Set-LabelMod $on
  $files = New-Object System.Collections.ArrayList
  [void]$files.Add(@((Join-Path $InstallDir 'image\golf.bin'), $true))
  foreach ($x in $exes) { [void]$files.Add(@($x, $false)) }
  foreach ($f in $files) {
    $path = $f[0]; $isBin = $f[1]; $name = Split-Path $path -Leaf
    if (-not (Test-Path -LiteralPath $path)) { Write-Warning "$name not found; labels left alone."; continue }
    $bytes = [IO.File]::ReadAllBytes($path)
    $state = ''
    $edits = Label-Edits (Label-Text $bytes $isBin) $on $isBin ([ref]$state)
    if ($null -eq $edits) { Write-Warning "$name : labels not recognised (another version?); left alone."; continue }
    Write-Host "$name : labels = $state"
    if ($edits.Count -eq 0) { continue }
    if ($DryRun) { Write-Host "$name : would rewrite $($edits.Count) labels (dry run)."; continue }
    if ($isBin -and $state -eq 'vanilla' -and -not (Test-Path -LiteralPath "$path.companion-backup")) { Copy-Item -LiteralPath $path -Destination "$path.companion-backup" }
    foreach ($e in $edits) { [Array]::Copy($e[1], 0, $bytes, $e[0], $e[1].Length) }
    [IO.File]::WriteAllBytes($path, $bytes)
    $check = ''
    $left = Label-Edits (Label-Text ([IO.File]::ReadAllBytes($path)) $isBin) $on $isBin ([ref]$check)
    if ($null -eq $left -or $left.Count -ne 0) { throw "$name : label check failed after writing." }
    Write-Host "$name : labels -> $check ($($edits.Count) rewritten)"
  }
}

# ------------------------------------------------------------ snack bar path
# golf's path flood fill (FUN_0042f340, translated into the program) clears
# bit 0x40 at +7 of every building record of kind 6..16, then sets it again
# when a footprint tile is on the clubhouse's path network; only a building
# with the bit runs. The Snack Bar (kind 7) has its own branch there
# (cmp edi, 7; mov [esp], ecx; je, past the level). That is now a jmp to
# .cmpn +0x17E0, which sends kind 7 straight to the "connected" store
# (or byte [ecx], 0x40, +0xB3 from the site) and every other kind back.
$snackAt = 0x17E0; $snackEnd = 0x1800
$snackOrig = [byte[]](0x83, 0xFF, 0x07, 0x89, 0x0C, 0x24, 0x74, 0x20)
$snackRx = '\x80\x21\xBF\x8D\x04\xBF\x0F\xBE\x1C\x86(\x83\xFF\x07\x89\x0C\x24\x74\x20|\xE9[\x00-\xFF]{4}\x90\x90\x90)\x8B\x41\x01\x40\x6A\x63'

# The bytes from +0x17E0 to +0x17FF for section VA $va.
function Snack-Code([int64]$va, $snack) {
  $c = [byte[]](@(0x89, 0x0C, 0x24, 0x83, 0xFF, 0x07, 0x0F, 0x84) + (Rel32 ($va + $snackAt + 12) $snack.Set) +   # snack bar: connected
    @(0xE9) + (Rel32 ($va + $snackAt + 17) $snack.Next))                                                       # others: as before
  $blob = New-Object byte[] ($snackEnd - $snackAt)
  for ($i = 0; $i -lt $blob.Length; $i++) { $blob[$i] = 0xCC }
  [Array]::Copy($c, 0, $blob, 0, $c.Length)
  return ,$blob
}

function Snack-SiteBytes($snack, [bool]$on, [int64]$secVa) {
  if ($on) { return ,[byte[]](@(0xE9) + (Rel32 ($snack.SiteVa + 5) ($secVa + $snackAt)) + @(0x90, 0x90, 0x90)) }
  return ,$snackOrig
}

# $null when the site is not in this program; Bad when the jmp goes somewhere unexpected.
function Find-SnackPath([byte[]]$bytes, [string]$text, $pe) {
  $m = [regex]::Matches($text, $snackRx)
  if ($m.Count -ne 1) { return $null }
  $site = $m[0].Groups[1].Index; $siteVa = Off-ToVa $pe $site
  if ($latin1.GetString($bytes, $site + 0xB3, 6) -ne $latin1.GetString([byte[]](0x80, 0x09, 0x40, 0x83, 0xC1, 0x10))) { return $null }
  $r = [pscustomobject]@{ Site = $site; SiteVa = $siteVa; Set = $siteVa + 0xB3; Next = $siteVa + 8; On = $false; Bad = $false }
  if ($bytes[$site] -eq 0xE9) {
    $to = $siteVa + 5 + [BitConverter]::ToInt32($bytes, $site + 1)
    $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
    if (-not $sec -or $to -ne [int64]$pe.Base + $sec.Rva + $snackAt -or $sec.RawSize -lt $snackEnd -or
        (Compare-Object $bytes[($sec.Raw + $snackAt)..($sec.Raw + $snackEnd - 1)] (Snack-Code ([int64]$pe.Base + $sec.Rva) $r) -SyncWindow 0)) { $r.Bad = $true }
    else { $r.On = $true }
  }
  return $r
}

# ------------------------------------------------------------- year events
# The calendar (DAT_00834170: 1024 ticks a month, 8 months March..October) is
# left alone; what the game does once a year happens every month instead. Both
# yearly blocks of the main loop sit inside its 1st-of-month block:
#   July 1  (t & 0x1FFF == 0x1000): with the pro not out on the course
#           ([0x5a59f8] == -1), FUN_0044fb30(2) picks an event and, if the
#           course qualifies ([0x567b04]), the SGA's tournament invitation
#   March 1 (t & 0x1FFF == 0): the map's stat layers fade by 1/8, the visitor
#           mix drifts, and the board's End of Year review (FUN_0044cff0)
# Both masks become 0x3FF (the July compare 0), so both run on every 1st. The
# review compares this month's history sample with the one 8 months back; that
# becomes 1 month back. Two hooks into .cmpn:
#   debt verdict (cmp [cash], 0; 7 bytes) -> call +0x1380: the board's debt
#     warnings and strikes (3 = fired) still only on March 1; other months
#     skip the verdict and keep the strike count.
#   review title (_itoa(year)) -> call +0x13A0: "<Month> <year>" of the month
#     that just ended (month names at 0x4c2908, 16-byte buffer 0x821c50).
# Strings: "END of  YEAR:", "Last Year", "This Year" (image\golf.bin) and
# "YEAR IN REVIEW" (the program) get month wording.
$yeAt = 0x1380; $yeTitle = 0x13A0; $yeEnd = 0x1400
$yeJulyRx = '\x8B\x0D\x70\x41\x83\x00\x89\xC8\x25(\xFF\x1F|\xFF\x03)\x00\x80\x8D\x51\xFF\x81\xCA\x00(\xE0|\xFC)\xFF\xFF\x42\x85\xC9\x0F\x49\xD0\x81\xFA\x00(\x10|\x00)\x00\x00\xBE\x68\xA0\x51\x00\x0F\x85([\x00-\xFF]{4})'
$yeYearRx = '\x8B\x0D\x70\x41\x83\x00\x89\xC8\x25(\xFF\x1F|\xFF\x03)\x00\x80\x89\xCA\xF7\xDA\x81\xE2(\xFF\x1F|\xFF\x03)\x00\x00\x85\xC9\x0F\x49\xD0\x85\xD2\x0F\x85'
$yeBackRx = '\x69\xDA\xF4\x01\x00\x00\x8D\x41([\xF8\xFF])\xF7\xEF\x89\xD0\xC1\xE8\x1F\xC1\xFA\x05\x01\xC2\x69\xC2\xF4\x01\x00\x00\xF7\xD8\x01\xC8\x83\xC0([\xF8\xFF])\x29\xD9'
$yeTitleRx = '\x0F\xBF\x15\x3C\x6D\x5A\x00\x89\x14\x24\x83\xE1\x03\x74\x0D[\x00-\xFF]{13}\x8B\x04\x24\x05[\x00-\xFF]{4}\x6A\x0A\x68\x50\x1C\x82\x00\x50\xE8([\x00-\xFF]{4})\x83\xC4\x0C'
$yeDebtRx = '\x8B\x44\x24\x2C\x3B\x44\x24\x08\x0F\x8E[\x00-\xFF]{4}(\x83\x3D\xD4\x1F\x57\x00\x00|\xE8[\x00-\xFF]{4}\x66\x90)\x79([\x00-\xFF])\xF6\x05\xBB\xE7\x59\x00\x01\x75'
$yeDebtCmp = [byte[]](0x83, 0x3D, 0xD4, 0x1F, 0x57, 0x00, 0x00)                    # cmp dword [cash], 0
$yeReset = [byte[]](0xC7, 0x05, 0x74, 0x63, 0x5A, 0x00, 0x00, 0x00, 0x00, 0x00)    # mov dword [debt strikes], 0
$yeTpl = @(
  # +0x1380: test [tick], 0x1FFF; jnz; cmp [cash], 0; ret; mov [esp], skip; ret
  'f70570418300ff1f00007508833dd41f570000c3c70424', 'a:skip', 'c3cccccccc',
  # +0x13A0 (cdecl like _itoa): month name of tick - 1, a space, then _itoa(value + 1 - year + year of tick - 1)
  '56578b7c2410a1704183004889c1c1e90a83e1078b348d08294c00acaa84c075fac647ff208b0d70418300c1e90dc1e80d29c80344240c406a0a5750e8',
  'r:itoa', ('83c40c8b4424105f5ec3' + ('cc' * 21)))
$yeLabelBin = @(
  @(0x4d29e8, 'Last Year', 'Previous'),           # "Last Month" is cut off in the review's right column
  @(0x4d29f4, 'This Year', 'This Month'),
  @(0x4d2a00, 'END of  YEAR:  ', 'END of MONTH:  '))
$yeLabelExe = @(,@('YEAR IN REVIEW', 'MONTHLY REVIEW'))

# $null when the sites are not in this program; Bad when a hook calls somewhere unexpected.
function Find-YearEvents([byte[]]$bytes, [string]$text, $pe) {
  $j = [regex]::Matches($text, $yeJulyRx); $y = [regex]::Matches($text, $yeYearRx); $k = [regex]::Matches($text, $yeBackRx)
  $t = [regex]::Matches($text, $yeTitleRx); $d = [regex]::Matches($text, $yeDebtRx)
  if ($j.Count -ne 1 -or $y.Count -ne 1 -or $k.Count -ne 1 -or $t.Count -ne 1 -or $d.Count -ne 1) { return $null }
  $j = $j[0]; $y = $y[0]; $k = $k[0]; $t = $t[0]; $d = $d[0]
  # the July block's jne lands in the year test, just after its own mask (mov edx, ecx)
  $jne = $j.Groups[4].Index
  if ((Off-ToVa $pe ($jne + 4)) + [BitConverter]::ToInt32($bytes, $jne) -ne (Off-ToVa $pe ($y.Index + 13))) { return $null }
  $jns = $d.Groups[2].Index
  $reset = $jns + 1 + [int][sbyte]$bytes[$jns]
  for ($i = 0; $i -lt 10; $i++) { if ($bytes[$reset + $i] -ne $yeReset[$i]) { return $null } }
  $r = [pscustomobject]@{
    July1 = $j.Groups[1].Index; July2 = $j.Groups[2].Index; July3 = $j.Groups[3].Index
    Year1 = $y.Groups[1].Index; Year2 = $y.Groups[2].Index; Back1 = $k.Groups[1].Index; Back2 = $k.Groups[2].Index
    Title = $t.Groups[1].Index - 1; TitleVa = (Off-ToVa $pe ($t.Groups[1].Index - 1)); Debt = $d.Groups[1].Index; DebtVa = (Off-ToVa $pe $d.Groups[1].Index)
    Skip = (Off-ToVa $pe $reset) + 10; Itoa = $null; Masks = 'mixed'; On = $false; Mixed = $false; Bad = $false }
  $mon = @(($bytes[$r.July1 + 1] -eq 0x03), ($bytes[$r.July2] -eq 0xFC), ($bytes[$r.July3] -eq 0x00), ($bytes[$r.Year1 + 1] -eq 0x03),
           ($bytes[$r.Year2 + 1] -eq 0x03), ($bytes[$r.Back1] -eq 0xFF), ($bytes[$r.Back2] -eq 0xFF))
  $n = @($mon | Where-Object { $_ }).Count
  if ($n -eq $mon.Count) { $r.Masks = 'monthly' } elseif ($n -eq 0) { $r.Masks = 'yearly' }
  $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
  $secVa = if ($sec) { [int64]$pe.Base + $sec.Rva } else { -1 }
  $tTarget = $r.TitleVa + 5 + [BitConverter]::ToInt32($bytes, $r.Title + 1)
  $titleOn = [bool]$sec -and $tTarget -eq $secVa + $yeTitle
  $debtOn = $bytes[$r.Debt] -eq 0xE8
  if ($debtOn) {
    if ($bytes[$r.Debt + 5] -ne 0x66 -or $bytes[$r.Debt + 6] -ne 0x90 -or
        $r.DebtVa + 5 + [BitConverter]::ToInt32($bytes, $r.Debt + 1) -ne $secVa + $yeAt) { $r.Bad = $true; return $r }
  }
  if (-not $titleOn -and $sec -and $tTarget -ge $secVa -and $tTarget -lt $secVa + $sec.VSize) { $r.Bad = $true; return $r }
  if ($titleOn -or $debtOn) {
    if (-not $sec -or $sec.RawSize -lt $yeEnd) { $r.Bad = $true; return $r }
    $f = Tpl-Read $bytes $yeTpl ($sec.Raw + $yeAt) $pe
    if (-not $f -or [regex]::Matches($latin1.GetString($bytes, $sec.Raw + $yeAt, $yeEnd - $yeAt), '^' + (Tpl-Rx $yeTpl)).Count -ne 1 -or
        $f['skip'] -ne $r.Skip) { $r.Bad = $true; return $r }
    $r.Itoa = $f['itoa']
  } else { $r.Itoa = $tTarget }
  $r.On = $titleOn -and $debtOn -and $r.Masks -eq 'monthly'
  $r.Mixed = -not $r.On -and ($titleOn -or $debtOn -or $r.Masks -ne 'yearly')
  return $r
}

# The code for section VA $va: the bytes from +0x1380 to +0x13FF.
function Ye-Code([int64]$va, $ye) {
  $b = Tpl-Build $yeTpl @{ skip = $ye.Skip; itoa = $ye.Itoa } ($va + $yeAt)
  if ($b.Length -ne $yeEnd - $yeAt) { throw "year events code built to $($b.Length) bytes, expected $($yeEnd - $yeAt)" }
  return ,$b
}

# (offset, bytes) for every site, monthly ($on) or as shipped.
function Ye-SiteBytes($ye, [bool]$on, [int64]$secVa) {
  $c = @()
  $c += ,@($ye.July1, [byte[]]@(0xFF, $(if ($on) { 0x03 } else { 0x1F })))
  $c += ,@($ye.July2, [byte[]]@($(if ($on) { 0xFC } else { 0xE0 })))
  $c += ,@($ye.July3, [byte[]]@($(if ($on) { 0x00 } else { 0x10 })))
  $c += ,@($ye.Year1, [byte[]]@(0xFF, $(if ($on) { 0x03 } else { 0x1F })))
  $c += ,@($ye.Year2, [byte[]]@(0xFF, $(if ($on) { 0x03 } else { 0x1F })))
  $c += ,@($ye.Back1, [byte[]]@($(if ($on) { 0xFF } else { 0xF8 })))
  $c += ,@($ye.Back2, [byte[]]@($(if ($on) { 0xFF } else { 0xF8 })))
  $c += ,@(($ye.Title + 1), [byte[]](Rel32 ($ye.TitleVa + 5) $(if ($on) { $secVa + $yeTitle } else { $ye.Itoa })))
  $c += ,@($ye.Debt, $(if ($on) { [byte[]](@(0xE8) + (Rel32 ($ye.DebtVa + 5) ($secVa + $yeAt)) + @(0x66, 0x90)) } else { $yeDebtCmp }))
  return ,$c
}

function Describe-YearEvents($ye) {
  if ($ye.On) { return 'monthly (yearly events every 1st, debt verdict on March 1)' }
  if ($ye.Mixed) { return 'half patched' }
  return 'yearly (as shipped)'
}

# The review's strings: Label-Edits reads $labelBin / $labelExe from the
# caller's scope, so these locals hand it the month wording instead.
function Set-YearEventLabels([string]$mode) {
  # Label-Edits picks its list through an if, whose output unrolls one level:
  # a one-entry list needs one more wrap to stay a list of pairs.
  $labelBin = $yeLabelBin; $labelExe = @(, $yeLabelExe)
  $on = $mode -eq 'monthly'
  $files = @(,@((Join-Path $InstallDir 'image\golf.bin'), $true)) + @($exes | ForEach-Object { ,@($_, $false) })
  foreach ($f in $files) {
    $path = $f[0]; $isBin = $f[1]; $name = Split-Path $path -Leaf
    if (-not (Test-Path -LiteralPath $path)) { Write-Warning "$name not found; review wording left alone."; continue }
    $bytes = [IO.File]::ReadAllBytes($path)
    $state = ''
    $edits = Label-Edits (Label-Text $bytes $isBin) $on $isBin ([ref]$state)
    if ($null -eq $edits) { Write-Warning "$name : review wording not recognised; left alone."; continue }
    Write-Host "$name : review wording = $(if ($state -eq 'vanilla') { 'year (as shipped)' } elseif ($state -eq 'renamed') { 'month' } else { $state })"
    if ($edits.Count -eq 0) { continue }
    if ($DryRun) { Write-Host "$name : would rewrite $($edits.Count) review strings (dry run)."; continue }
    foreach ($e in $edits) { [Array]::Copy($e[1], 0, $bytes, $e[0], $e[1].Length) }
    try { [IO.File]::WriteAllBytes($path, $bytes) }
    catch { throw "$name : could not write ($($_.Exception.Message)). Close the game and try again." }
    $check = ''
    $left = Label-Edits (Label-Text ([IO.File]::ReadAllBytes($path)) $isBin) $on $isBin ([ref]$check)
    if ($null -eq $left -or $left.Count -ne 0) { throw "$name : review wording check failed after writing." }
    Write-Host "$name : review wording -> $(if ($on) { 'month' } else { 'year (as shipped)' })"
  }
}

# ------------------------------------------------------------ golfer names
# Regular visitors are 100 roster profiles (560 bytes each from 0x4d6088, the
# name at +0x10, 16 bytes; +0x21 bit 0x80 female): golf's 75 first names
# (Snoop, Biggie, Mahatma, J.P. ...) at 1..75 and the remaster's 25 pun names
# (Bea Line, Gus Socket ...) at 84..108. A save keeps the profiles, so a name
# written there stays with that golfer. The roster's two setup logs, after a
# new career (roster_seed) and after every load (roster_append_tables), now
# call .cmpn +0x2000 first: each regular profile still without the tag
# 0xC7 0x4E at +0x2D gets a real "First Last" name; a new career draws a new
# set. First names come from the male or female list (all different within a
# draw: start + profile * 37, mod the list length), surnames at random; the
# remaster's 25 keep their first name (their bios use it). Player, club pro,
# celebrities and touring pros are left alone. Needs the remaster's new roster
# (on by default). Code, tables and names in .cmpn +0x2000..+0x3FFF.
$gnAt = 0x2000; $gnTab = 0x2200; $gnEnd = 0x4000
$gnMale = @("James", "John", "Robert", "Michael", "William", "David", "Richard", "Joseph", "Thomas", "Charles", "Daniel",
  "Matthew", "Anthony", "Mark", "Steven", "Paul", "Andrew", "Joshua", "Kevin", "Brian", "George", "Timothy",
  "Ryan", "Jason", "Jeffrey", "Eric", "Jacob", "Gary", "Nicholas", "Jonathan", "Stephen", "Larry", "Justin",
  "Scott", "Brandon", "Benjamin", "Samuel", "Gregory", "Patrick", "Frank", "Raymond", "Jack", "Dennis", "Jerry",
  "Tyler", "Aaron", "Jose", "Adam", "Nathan", "Henry", "Douglas", "Peter", "Zachary", "Kyle", "Noah", "Ethan",
  "Jeremy", "Walter", "Christian", "Keith", "Roger", "Terry", "Austin", "Sean", "Gerald", "Carl", "Harold",
  "Dylan", "Arthur", "Lawrence", "Jordan", "Jesse", "Bryan", "Bruce", "Gabriel", "Logan", "Alan", "Juan",
  "Albert", "Elijah", "Wayne", "Randy", "Vincent", "Mason", "Roy", "Russell", "Bradley", "Philip", "Eugene",
  "Liam", "Owen", "Lucas", "Luke", "Marcus", "Carlos", "Miguel", "Luis", "Diego", "Mateo", "Rafael", "Hiroshi",
  "Kenji", "Takeshi", "Raj", "Arjun", "Vikram", "Omar", "Hassan", "Malik", "Andre", "Darius", "Terrence", "Isaac",
  "Caleb", "Colin", "Graham", "Ian", "Neil", "Simon", "Rory", "Callum", "Declan", "Hugo", "Felix", "Lars", "Sven",
  "Anders", "Pieter", "Marco", "Luca", "Paolo", "Javier", "Pablo", "Tomas", "Erik", "Viktor", "Dmitri", "Wei",
  "Jun", "Hyun", "Kwame", "Kofi", "Emeka", "Tariq", "Ahmed", "Yusuf", "Ravi", "Sanjay", "Nikhil", "Mitchell",
  "Grant", "Spencer", "Trevor", "Derek", "Shane", "Wesley", "Dustin", "Marshall", "Calvin", "Leon", "Victor",
  "Martin", "Edward", "Howard", "Stanley", "Glenn", "Clifford", "Desmond")
$gnFemale = @("Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Susan", "Jessica", "Sarah", "Karen", "Lisa",
  "Nancy", "Betty", "Margaret", "Sandra", "Ashley", "Kimberly", "Emily", "Donna", "Michelle", "Carol", "Amanda",
  "Dorothy", "Melissa", "Deborah", "Stephanie", "Rebecca", "Sharon", "Laura", "Cynthia", "Kathleen", "Amy",
  "Angela", "Shirley", "Anna", "Brenda", "Pamela", "Emma", "Nicole", "Helen", "Samantha", "Katherine",
  "Christine", "Rachel", "Carolyn", "Janet", "Catherine", "Maria", "Heather", "Diane", "Ruth", "Julie", "Olivia",
  "Joyce", "Virginia", "Victoria", "Kelly", "Lauren", "Christina", "Joan", "Evelyn", "Judith", "Megan", "Andrea",
  "Cheryl", "Hannah", "Martha", "Gloria", "Teresa", "Ann", "Sara", "Madison", "Frances", "Kathryn", "Janice",
  "Jean", "Abigail", "Alice", "Julia", "Judy", "Sophia", "Grace", "Denise", "Amber", "Doris", "Marilyn",
  "Danielle", "Beverly", "Isabella", "Theresa", "Diana", "Natalie", "Brittany", "Charlotte", "Marie", "Kayla",
  "Alexis", "Lori", "Chloe", "Ava", "Mia", "Zoe", "Lily", "Priya", "Anjali", "Aisha", "Fatima", "Leila", "Yasmin",
  "Mei", "Yuki", "Keiko", "Hana", "Sofia", "Lucia", "Elena", "Carmen", "Gabriela", "Valeria", "Camila", "Ines",
  "Ingrid", "Astrid", "Freya", "Siobhan", "Niamh", "Fiona", "Claire", "Imogen", "Harriet", "Eleanor", "Rosalind",
  "Amara", "Nia", "Imani", "Keisha", "Monica", "Paula", "Tina", "Wendy", "Holly", "Erin", "Molly", "Jenna",
  "Leah", "Naomi", "Ruby", "Stella", "Audrey", "Vivian", "Lillian", "Irene", "Esther", "Miriam", "Gwen", "Nora",
  "Ellen", "Joanna")
$gnLast = @("Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez",
  "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee",
  "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker", "Young",
  "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores", "Green", "Adams", "Nelson", "Baker",
  "Hall", "Rivera", "Campbell", "Mitchell", "Carter", "Roberts", "Gomez", "Phillips", "Evans", "Turner", "Diaz",
  "Parker", "Cruz", "Edwards", "Collins", "Reyes", "Stewart", "Morris", "Morales", "Murphy", "Cook", "Rogers",
  "Gutierrez", "Ortiz", "Morgan", "Cooper", "Peterson", "Bailey", "Reed", "Kelly", "Howard", "Ramos", "Kim",
  "Cox", "Ward", "Richardson", "Watson", "Brooks", "Chavez", "Wood", "James", "Bennett", "Gray", "Mendoza",
  "Ruiz", "Hughes", "Price", "Alvarez", "Castillo", "Sanders", "Patel", "Myers", "Long", "Ross", "Foster",
  "Jimenez", "Powell", "Jenkins", "Perry", "Russell", "Sullivan", "Bell", "Coleman", "Butler", "Henderson",
  "Barnes", "Fisher", "Vasquez", "Simmons", "Romero", "Jordan", "Patterson", "Alexander", "Hamilton", "Graham",
  "Reynolds", "Griffin", "Wallace", "Moreno", "West", "Cole", "Hayes", "Bryant", "Herrera", "Gibson", "Ellis",
  "Tran", "Medina", "Aguilar", "Stevens", "Murray", "Ford", "Castro", "Marshall", "Owens", "Harrison",
  "Fernandez", "McDonald", "Woods", "Washington", "Kennedy", "Wells", "Vargas", "Henry", "Chen", "Freeman",
  "Webb", "Tucker", "Guzman", "Burns", "Crawford", "Olson", "Simpson", "Porter", "Hunter", "Gordon", "Mendez",
  "Silva", "Shaw", "Snyder", "Mason", "Dixon", "Munoz", "Hunt", "Hicks", "Holmes", "Palmer", "Wagner", "Black",
  "Robertson", "Boyd", "Rose", "Stone", "Salazar", "Fox", "Warren", "Mills", "Meyer", "Rice", "Schmidt", "Garza",
  "Daniels", "Ferguson", "Nichols", "Stephens", "Soto", "Weaver", "Ryan", "Gardner", "Payne", "Grant", "Dunn",
  "Kelley", "Spencer", "Hawkins", "Arnold", "Pierce", "Vazquez", "Hansen", "Peters", "Santos", "Hart", "Bradley",
  "Knight", "Elliott", "Cunningham", "Duncan", "Armstrong", "Hudson", "Carroll", "Lane", "Riley", "Andrews",
  "Alvarado", "Ray", "Delgado", "Berry", "Perkins", "Hoffman", "Johnston", "Matthews", "Pena", "Richards",
  "Contreras", "Willis", "Carpenter", "Lawrence", "Sandoval", "Wang", "Liu", "Zhang", "Yamamoto", "Tanaka",
  "Sato", "Suzuki", "Nakamura", "Park", "Choi", "Kang", "Singh", "Sharma", "Gupta", "Shah", "Mehta", "Okafor",
  "Mensah", "Adeyemi", "Boateng", "Haddad", "Khan", "Ali", "Hussein", "O'Brien", "O'Connor", "Byrne", "Doyle",
  "Walsh", "MacLeod", "Fraser", "Lindqvist", "Larsen", "Jensen", "Nilsson", "Berg", "Novak", "Kowalski", "Muller",
  "Weber", "Schneider", "Rossi", "Russo", "Ricci", "Bianchi", "Costa", "Ferreira", "Oliveira", "Dubois", "Moreau",
  "Laurent", "Petrov", "Volkov", "Barrett", "Fleming", "Hale", "Maddox", "Quinn", "Sutton", "Whitaker", "Lowe",
  "Bishop", "Chambers")
$gnHex = @(
  '6083EC086888604D00E80000000083C40489C50F3131D083C8018904240FB7D289542404BB0100000083FB4C7505BB540000' +
  '0083FB6D0F83E700000069FB3002000001EF807F10000F84CF00000066817F2DC74E0F84C300000083FB54721631C98A440F' +
  '1084C074443C2074404183F90A72EEEB38BE00000000B900000000F6472180740ABE00000000B9000000006BC32503442404' +
  '31D2F7F18B349631C98A040E88440F1084C0740341EBF2C6440F1020416A108B44240489C2C1E20D31D089C2C1EA1131D089' +
  'C2C1E20531D08944240451B90000000031D2F7F1598B34950000000031D2803C1600740342EBF78D041183F80F7605FF0C24' +
  '75B983C40483F90F730E8A0684C0740888440F104641EBEDC6440F100066C7472DC74E43E906FFFFFF83C40861E900000000')
$gnFix = @(@(118, 'tab', 'male'), @(134, 'tab', 'female'), @(224, 'tab', 'last'), @(123, 'count', 'male'), @(139, 'count', 'female'), @(212, 'count', 'last'), @(10, 'roster', ''), @(296, 'log', ''))
$gnSiteRx = { param([int64]$str) '\x68' + [regex]::Escape($latin1.GetString([BitConverter]::GetBytes([uint32]$str))) + '\xE8([\x00-\xFF]{4})' }
$gnRosterRx = '\x68\x88\x60\x4D\x00\xE8([\x00-\xFF]{4})'

# The bytes from +0x2000 to +0x3FFF for section VA $va.
function Gn-Code([int64]$va, $gn) {
  $blob = New-Object byte[] ($gnEnd - $gnAt)
  $h = $gnHex -join ''; $code = New-Object byte[] ($h.Length / 2)
  for ($i = 0; $i -lt $code.Length; $i++) { $code[$i] = [Convert]::ToByte($h.Substring(2 * $i, 2), 16) }
  $lists = @{ male = $gnMale; female = $gnFemale; last = $gnLast }
  if ($gnMale.Count % 37 -eq 0 -or $gnFemale.Count % 37 -eq 0 -or $gnMale.Count -lt 110 -or $gnFemale.Count -lt 110) { throw "golfer first-name lists must hold 110+ names, not a multiple of 37" }
  $tab = @{}; $t = $gnTab; $at = $gnTab + 4 * ($gnMale.Count + $gnFemale.Count + $gnLast.Count)
  foreach ($k in @('male', 'female', 'last')) {
    $tab[$k] = $va + $t
    foreach ($n in $lists[$k]) {
      if ($n.Length -gt 10) { throw "golfer name $n is longer than 10 letters" }
      [Array]::Copy([BitConverter]::GetBytes([uint32]($va + $at)), 0, $blob, $t - $gnAt, 4); $t += 4
      $b = $latin1.GetBytes($n); [Array]::Copy($b, 0, $blob, $at - $gnAt, $b.Length); $at += $b.Length + 1
    }
  }
  if ($at -gt $gnEnd) { throw "golfer names too long" }
  foreach ($f in $gnFix) {
    $v = switch ($f[1]) { 'tab' { [BitConverter]::GetBytes([uint32]$tab[$f[2]]) } 'count' { [BitConverter]::GetBytes([uint32]$lists[$f[2]].Count) }
                          'roster' { Rel32 ($va + $gnAt + $f[0] + 4) $gn.Roster } 'log' { Rel32 ($va + $gnAt + $f[0] + 4) $gn.Log } }
    [Array]::Copy([byte[]]$v, 0, $code, $f[0], 4)
  }
  [Array]::Copy($code, 0, $blob, 0, $code.Length)
  for ($i = $code.Length; $i -lt $gnTab - $gnAt; $i++) { $blob[$i] = 0xCC }
  return ,$blob
}

# $null when the sites are not in this program; Bad when they call somewhere unexpected.
function Find-GolferNames([byte[]]$bytes, [string]$text, $pe) {
  $sites = @()
  foreach ($s in @('roster: ready 25 regulars', 'roster: appended touring pros')) {
    $f = [regex]::Matches($text, "`0" + [regex]::Escape($s))
    if ($f.Count -ne 1) { return $null }
    $m = [regex]::Matches($text, (& $gnSiteRx (Off-ToVa $pe ($f[0].Index + 1))))
    if ($m.Count -ne 1) { return $null }
    $call = $m[0].Groups[1].Index - 1; $callVa = Off-ToVa $pe $call
    $sites += [pscustomobject]@{ Call = $call; CallVa = $callVa; To = $callVa + 5 + [BitConverter]::ToInt32($bytes, $call + 1) }
  }
  $ra = @([regex]::Matches($text, $gnRosterRx) | ForEach-Object { $c = $_.Groups[1].Index - 1; (Off-ToVa $pe $c) + 5 + [BitConverter]::ToInt32($bytes, $c + 1) } | Sort-Object -Unique)
  if ($ra.Count -ne 1) { return $null }
  $r = [pscustomobject]@{ Sites = $sites; Roster = $ra[0]; Log = $sites[0].To; On = $false; Bad = $false }
  if ($sites[0].To -ne $sites[1].To) { $r.Bad = $true; return $r }
  $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
  if ($sec -and $sites[0].To -eq [int64]$pe.Base + $sec.Rva + $gnAt) {
    $r.On = $true
    $j = $sec.Raw + $gnAt + 295
    if ($sec.RawSize -lt $gnEnd -or $bytes[$j] -ne 0xE9) { $r.Bad = $true; return $r }
    $r.Log = [int64]$pe.Base + $sec.Rva + $gnAt + 300 + [BitConverter]::ToInt32($bytes, $j + 1)
    if (Compare-Object $bytes[($sec.Raw + $gnAt)..($sec.Raw + $gnEnd - 1)] (Gn-Code ([int64]$pe.Base + $sec.Rva) $r) -SyncWindow 0) { $r.Bad = $true }
  } elseif ($sec -and $sites[0].To -ge [int64]$pe.Base + $sec.Rva -and $sites[0].To -lt [int64]$pe.Base + $sec.Rva + $sec.VSize) { $r.Bad = $true }
  return $r
}

# ------------------------------------------------------------------- patcher
function Patch-Exe([string]$path) {
  $name = Split-Path $path -Leaf
  $bytes = [IO.File]::ReadAllBytes($path)
  $text = $latin1.GetString($bytes)
  $script:cavesTaken = New-Object System.Collections.Generic.HashSet[int]
  $years = Find-YearSites $bytes $text
  $land = Find-LandSite $bytes $text
  $changes = @()
  $yearChanged = $false

  if (-not $years) { Write-Warning "$name : no year sites found; year left alone." }
  else {
    $ny = $years.Years.Count; $nl = $years.Last.Count
    Write-Host ("{0}: start year {1} ({2} year sites, {3} last-year sites)" -f $name, $years.Base, $ny, $nl)
    if (($ny -ne 9 -or $nl -ne 1) -and -not $Force) {
      Write-Warning "$name : expected 9 + 1 year sites (the 0.1.36/0.1.37 build). Year left alone; check with -DryRun, then -Force."
      $years.Years + $years.Last | Format-Table @{n='Offset';e={'0x{0:X}' -f $_.Offset}}, Value, Kind -AutoSize | Out-String | Write-Host
    } elseif ($years.Base -ne $StartYear) {
      foreach ($s in $years.Years) { $changes += ,@($s.Offset, [byte[]]@(($StartYear -band 0xFF), ($StartYear -shr 8))) }
      foreach ($s in $years.Last)  { $v = $StartYear - 1; $changes += ,@($s.Offset, [byte[]]@(($v -band 0xFF), ($v -shr 8))) }
      $yearChanged = $true
      Write-Host "$name : start year $($years.Base) -> $StartYear"
    }
  }

  if ($land.Count -ne 1) { Write-Warning "$name : starting-land site found $($land.Count) times (expected 1); land left alone." }
  else {
    Write-Host "$name : starting land = $(Describe-Land $land.Mode)"
    $want = Land-Bytes $StartLand
    $have = $bytes[$land.Offset..($land.Offset + 5)]
    if (Compare-Object $have $want -SyncWindow 0) {
      $changes += ,@($land.Offset, $want)
      $wantMode = if ($StartLand -eq 'share') { 'share' } else { [BitConverter]::ToInt32($want, 2) }
      Write-Host "$name : starting land -> $(Describe-Land $wantMode)"
    }
  }

  $acres = Find-AcreSites $bytes $text
  $acreFactor = Acre-Factor $StartLand
  if ($acres.State -eq 'unknown') { Write-Warning "$name : world-map acre label sites not recognised; label left alone." }
  else {
    Write-Host "$name : world-map acres label = $(Describe-Acres $acres.Factor)"
    if ($acres.Factor -ne $acreFactor) {
      $changes += Acre-Changes $bytes $acres $acreFactor
      Write-Host "$name : world-map acres label -> $(Describe-Acres $acreFactor)"
    }
  }

  $staff = Find-StaffSites $bytes $text
  if ($staff.State -ne 'ok') { Write-Warning "$name : staff radius sites not recognised ($($staff.Why)); staff left alone." }
  else {
    Write-Host "$name : staff work radius = $($staff.Percent)%"
    if ($staff.Percent -ne $StaffRadius) {
      $changes += Staff-Changes $bytes $staff $StaffRadius
      Write-Host "$name : staff work radius -> $StaffRadius%"
    }
  }

  $pe = Get-Pe $bytes
  $night = Find-Night $bytes $text $pe
  $nightWant = Night-Want $NightTint
  if (-not $night) { Write-Warning "$name : night tint sites not recognised; night left alone." }
  else {
    Write-Host "$name : clear-night light = $(Describe-Night $night.Values)"
    if (-not (Same-Night $night.Values $nightWant) -or ($night.Moved -and (Same-Night $nightWant $nightVanilla))) {
      $changes += Night-Changes $bytes $night $nightWant $pe
      Write-Host "$name : clear-night light -> $(Describe-Night $nightWant)"
    }
  }

  $news = Find-NewsHold $bytes $text
  if (-not $news) { Write-Warning "$name : news timer site not recognised; news hold left alone." }
  else {
    Write-Host "$name : news hold = $($news.Hold)x"
    if ($news.Hold -ne $NewsHold) {
      $changes += ,@($news.Offset, (News-Bytes $NewsHold))
      Write-Host "$name : news hold -> $($NewsHold)x"
    }
  }

  $esc = Find-Escape $bytes $text $pe
  $escWant = $EscapeAll -eq 'on'
  if (-not $esc) { Write-Warning "$name : Escape handler not recognised; Escape left alone." }
  else {
    Write-Host "$name : Escape = $(if ($esc.On) { 'closes everything' } else { 'one step per press (as shipped)' })"
    if ($esc.On -ne $escWant) {
      $changes += ,@($esc.Offset, (Tpl-Build $(if ($escWant) { $escPatched } else { $escVanilla }) $esc.Fields $esc.Va))
      Write-Host "$name : Escape -> $(if ($escWant) { 'closes everything' } else { 'one step per press (as shipped)' })"
    }
  }

  $weather = Find-Weather $bytes $text
  $weatherWant = $KeepWeather -eq 'on'
  if (-not $weather) { Write-Warning "$name : weather reset sites not recognised; weather left alone." }
  else {
    Write-Host "$name : weather on a non-course frame = $(if ($weather.Keep) { 'kept' } else { 'reset (as shipped)' })"
    if ($weather.Keep -ne $weatherWant) {
      foreach ($w in $weather.Sites) { $changes += ,@($w.Offset, [byte[]]$(if ($weatherWant) { @(0xEB, 0x08) } else { @(0xC7, 0x05) })) }
      Write-Host "$name : weather on a non-course frame -> $(if ($weatherWant) { 'kept' } else { 'reset (as shipped)' })"
    }
  }

  $edge = Find-ScrollEdge $text
  $edgeWant = $ScrollEdge -eq 'on'
  if (-not $edge) { Write-Warning "$name : weather shader edge lines not recognised; scroll edge left alone." }
  else {
    Write-Host "$name : scroll edge shading = $(if ($edge.On) { 'fixed' } else { 'dark bar (as shipped)' })"
    if ($edge.On -ne $edgeWant) {
      foreach ($e in $edge.Sites) { $changes += ,@($e.Offset, $latin1.GetBytes($(if ($edgeWant) { $e.New } else { $e.Old }))) }
      Write-Host "$name : scroll edge shading -> $(if ($edgeWant) { 'fixed' } else { 'dark bar (as shipped)' })"
    }
  }

  $lm = Find-Landmark $bytes $text
  if (-not $lm) { Write-Warning "$name : landmark radius sites not recognised; landmarks left alone." }
  else {
    Write-Host "$name : landmark radius = $($lm.Percent)%"
    if ($lm.Percent -ne $LandmarkRadius) {
      $changes += Landmark-Changes $lm $LandmarkRadius
      Write-Host "$name : landmark radius -> $LandmarkRadius%"
    }
  }

  $dist = Find-Distances $bytes $text
  if (-not $dist) { Write-Warning "$name : shot distance sites not recognised; distances left alone." }
  else {
    Write-Host "$name : shot distances = $(Describe-Distances $dist.Form)"
    if ($dist.Form -ne $Distances) {
      $changes += Distance-Changes $dist $Distances
      Write-Host "$name : shot distances -> $(Describe-Distances $Distances)"
    }
  }

  $all = Find-AllShots $text
  $allWant = $AllShots -eq 'on'
  if (-not $all) { Write-Warning "$name : shot choice sites not recognised; all shots left alone." }
  else {
    Write-Host "$name : shot choices in a bad lie = $(if ($all.On) { 'all five' } elseif ($all.Mixed) { 'half patched' } else { 'straight and low punch only (as shipped)' })"
    if ($all.On -ne $allWant -or $all.Mixed) {
      $changes += ,@($all.Lie, [byte[]]@($(if ($allWant) { 0xEB } else { 0x7E })))
      $changes += ,@($all.Hud, $(if ($allWant) { $allHudOn } else { $allHudVanilla }))
      Write-Host "$name : shot choices in a bad lie -> $(if ($allWant) { 'all five' } else { 'straight and low punch only (as shipped)' })"
    }
  }

  # Staff names, the Pixel HD fix, pro free aim and news popups live in the
  # added section; last, since adding, growing or removing it changes the file length.
  $names = Find-Names $bytes $text $pe
  $fix = Find-ScaleFix $bytes $text $pe
  $aim = Find-ProAim $bytes $text $pe
  $pop = Find-NewsPopup $bytes $text $pe
  $club = Find-ClubCache $bytes $text $pe
  $green = Find-GreenRoll $bytes $text $pe
  $dn = Find-DesignNames $bytes $text $pe
  $shot = Find-ShotFix $bytes $text $pe
  $shotWant = $ShotFix -eq 'on'
  $curve = Find-CurveFix $bytes $text $pe
  $curveWant = $CurveFix -eq 'on'
  $ye = Find-YearEvents $bytes $text $pe
  $snack = Find-SnackPath $bytes $text $pe
  $gn = Find-GolferNames $bytes $text $pe
  $gnWant = $GolferNames -eq 'real'
  $snackWant = $SnackPath -eq 'free'
  $yeWant = $YearEvents -eq 'monthly'
  $greenWant = $GreenRoll -eq 'on'
  $sec = $pe.Sections | Where-Object { $_.Name -eq $sectionName }
  $addSection = $false; $dropSection = $false; $resizeSection = $false
  $namesWant = $StaffNames -eq 'on'; $fixWant = $PixelHdFix -eq 'on'; $aimWant = $ProAim -eq 'shift'; $popWant = $NewsPopup -eq 'on'; $clubWant = $ClubCache -eq 'on'; $dnWant = $DesignNames -eq 'on'
  if (-not $names) { Write-Warning "$name : staff name site not recognised; names left alone." }
  else { Write-Host "$name : staff names = $(if ($names.On) { 'random' } else { 'one per job (as shipped)' })" }
  if (-not $fix) { Write-Warning "$name : Pixel HD scale site not recognised; flicker fix left alone." }
  else { Write-Host "$name : Pixel HD flicker fix = $(if ($fix.On) { 'on' } else { 'off (as shipped)' })" }
  if (-not $aim) { Write-Warning "$name : pro aim sites not recognised; pro aim left alone." }
  elseif (-not $aim.Bad) { Write-Host "$name : pro aim = $(if ($aim.On) { 'Shift for free aim' } else { 'tile centres and corners (as shipped)' })" }
  if (-not $pop) { Write-Warning "$name : news popup sites not recognised; news popups left alone." }
  elseif (-not $pop.Bad) { Write-Host "$name : news popups = $(if ($pop.On) { 'on' } else { 'off (news strip only, as shipped)' })" }
  if (-not $club) { Write-Warning "$name : clubhouse cache site not recognised; clubhouse cache left alone." }
  elseif (-not $club.Bad) { Write-Host "$name : clubhouse cache = $(if ($club.On) { 'clubhouse frames kept (fixed)' } else { 'oldest first (as shipped, clubhouse flickers zoomed out)' })" }
  if (-not $green) { Write-Warning "$name : green roll sites not recognised; green roll left alone." }
  elseif (-not $green.Bad) { Write-Host "$name : green roll = $(if ($green.On) { 'no speed-up, half break' } else { 'as shipped (downhill speeds the ball up)' })" }
  if ($green -and $green.Bad) { Write-Warning "$name : green roll sites call somewhere unexpected." }
  if (-not $dn) { Write-Warning "$name : design tooltip site not recognised; design names left alone." }
  elseif (-not $dn.Bad) { Write-Host "$name : design names = $(if ($dn.On) { 'flower, tree and bench names' } else { 'numbers (as shipped)' })" }
  if (-not $shot) { Write-Warning "$name : pro shot click sites not recognised; shot fix left alone." }
  elseif (-not $shot.Bad) { Write-Host "$name : shot fix = $(if ($shot.On) { 'click anywhere, shot type re-arms' } else { 'as shipped (bottom strip refused, can get stuck)' })" }
  if (-not $curve) { Write-Warning "$name : draw and fade speed sites not recognised; curve fix left alone." }
  elseif (-not $curve.Bad) { Write-Host "$name : curve fix = $(if ($curve.On) { 'draw and fade boost counts at most 330 yards' } else { 'as shipped (boost runs away past 330 yards)' })" }
  if (-not $ye) { Write-Warning "$name : year event sites not recognised; year events left alone." }
  elseif (-not $ye.Bad) { Write-Host "$name : year events = $(Describe-YearEvents $ye)" }
  if (-not $snack) { Write-Warning "$name : snack bar path site not recognised; snack bar path left alone." }
  elseif (-not $snack.Bad) { Write-Host "$name : snack bar path = $(if ($snack.On) { 'not needed' } else { 'needed (as shipped)' })" }
  if (-not $gn) { Write-Warning "$name : roster sites not recognised; golfer names left alone." }
  elseif (-not $gn.Bad) { Write-Host "$name : golfer names = $(if ($gn.On) { 'real names' } else { 'as shipped' })" }
  if (($sec -and (-not $names -or -not $fix)) -or ($aim -and $aim.Bad) -or ($pop -and $pop.Bad) -or ($club -and $club.Bad) -or ($green -and $green.Bad) -or ($dn -and $dn.Bad) -or ($shot -and $shot.Bad) -or ($curve -and $curve.Bad) -or ($ye -and $ye.Bad) -or ($snack -and $snack.Bad) -or ($gn -and $gn.Bad)) {
    Write-Warning "$name : $sectionName is in use by a part not recognised; staff names, the Pixel HD fix, pro aim and news popups left alone."
    $names = $null; $fix = $null; $aim = $null; $pop = $null; $club = $null; $green = $null; $dn = $null; $shot = $null; $curve = $null; $ye = $null; $snack = $null; $gn = $null
  }
  $secWant = ($names -and $namesWant) -or ($fix -and $fixWant) -or ($aim -and $aimWant) -or ($pop -and $popWant) -or ($club -and $clubWant) -or ($green -and $greenWant) -or ($dn -and $dnWant) -or ($shot -and $shotWant) -or ($curve -and $curveWant) -or ($ye -and $yeWant) -or ($snack -and $snackWant) -or ($gn -and $gnWant)
  if ($names -or $fix -or $aim -or $pop -or $club -or $green -or $dn -or $shot -or $curve -or $ye -or $snack -or $gn) {
    $secVa = 0
    if ($secWant) {
      if (-not $sec) { $addSection = $true; $secVa = [int64]$pe.Base + $pe.SizeOfImage; $secOff = $bytes.Length }
      else {
        $secVa = [int64]$pe.Base + $sec.Rva; $secOff = $sec.Raw
        if ($sec.RawSize -ne $sectionSize -or $sec.VSize -ne $sectionSize) {
          $resizeSection = $true
          Write-Host "$name : $sectionName -> $($sectionSize / 1024) KB (was $($sec.RawSize / 1024) KB)"
        }
      }
      $blob = if ($names -and $namesWant) { Names-Blob $secVa $names.StaffBase } else { New-Object byte[] $sectionSize }
      if ($fix -and $fixWant) { $fc = Fix-Code $secVa $fix; [Array]::Copy($fc, 0, $blob, $fixAt, $fc.Length) }
      if ($aim -and $aimWant) { $ac = Aim-Code $secVa $aim; [Array]::Copy($ac, 0, $blob, $aimAt, $ac.Length) }
      if ($pop -and $popWant) { $pc = Pop-Code $secVa $pop; [Array]::Copy($pc, 0, $blob, $popAt, $pc.Length) }
      if ($club -and $clubWant) { $cc = Club-Code $secVa $club; [Array]::Copy($cc, 0, $blob, $clubAt, $cc.Length) }
      if ($green -and $greenWant) { $gc = Green-Code $secVa $green; [Array]::Copy($gc, 0, $blob, $greenAt, $gc.Length) }
      if ($dn -and $dnWant) { $dc = Dn-Code $secVa $dn; [Array]::Copy($dc, 0, $blob, $dnAt, $dc.Length) }
      if ($shot -and $shotWant) { $tc = Shot-Code $secVa $shot; [Array]::Copy($tc, 0, $blob, $shotGate, $tc.Length) }
      if ($curve -and $curveWant) { [Array]::Copy($curveCode, 0, $blob, $curveAt, $curveCode.Length) }
      if ($ye -and $yeWant) { $yc = Ye-Code $secVa $ye; [Array]::Copy($yc, 0, $blob, $yeAt, $yc.Length) }
      if ($snack -and $snackWant) { $kc = Snack-Code $secVa $snack; [Array]::Copy($kc, 0, $blob, $snackAt, $kc.Length) }
      if ($gn -and $gnWant) { $nc = Gn-Code $secVa $gn; [Array]::Copy($nc, 0, $blob, $gnAt, $nc.Length) }
      $have = if ($sec -and -not $resizeSection) { [byte[]]$bytes[$secOff..($secOff + $sectionSize - 1)] } else { $null }
      if (-not $have -or (Compare-Object $have $blob -SyncWindow 0)) { $changes += ,@($secOff, $blob) }
      if ($sec -and [BitConverter]::ToUInt32($bytes, $sec.Header + 36) -ne $sectionFlags) {
        $changes += ,@(($sec.Header + 36), [BitConverter]::GetBytes([uint32]$sectionFlags))
      }
    } elseif ($sec) { $dropSection = $true }
    if ($names) {
      $to = if ($namesWant) { $secVa + 0x10 } else { $names.StaffBase }
      $call = [byte[]](@(0xE8) + (Rel32 ($names.SiteVa + 5) $to))
      if (Compare-Object $bytes[$names.Site..($names.Site + 4)] $call -SyncWindow 0) {
        $changes += ,@($names.Site, $call)
        Write-Host "$name : staff names -> $(if ($namesWant) { 'random' } else { 'one per job (as shipped)' })"
      }
    }
    if ($fix) {
      $ca = [byte[]](@(0xE8) + (Rel32 ($fix.AVa + 5) $(if ($fixWant) { $secVa + $fixAt } else { $fix.Srt })))
      $cb = [byte[]](@(0xE8) + (Rel32 ($fix.BVa + 5) $(if ($fixWant) { $secVa + $fixB } else { $fix.Srt })))
      if ((Compare-Object $bytes[$fix.A..($fix.A + 4)] $ca -SyncWindow 0) -or (Compare-Object $bytes[$fix.B..($fix.B + 4)] $cb -SyncWindow 0)) {
        $changes += ,@($fix.A, $ca); $changes += ,@($fix.B, $cb)
        Write-Host "$name : Pixel HD flicker fix -> $(if ($fixWant) { 'on' } else { 'off (as shipped)' })"
      }
    }
    if ($aim) {
      $sb = Aim-SiteBytes $aim $aimWant $secVa
      if ((Compare-Object $bytes[$aim.Site..($aim.Site + 17)] $sb[0] -SyncWindow 0) -or (Compare-Object $bytes[$aim.Launch..($aim.Launch + 8)] $sb[1] -SyncWindow 0)) {
        $changes += ,@($aim.Site, $sb[0]); $changes += ,@($aim.Launch, $sb[1])
        Write-Host "$name : pro aim -> $(if ($aimWant) { 'Shift for free aim' } else { 'tile centres and corners (as shipped)' })"
      }
    }
    if ($dn) {
      $dcall = [byte[]](@(0xE8) + (Rel32 ($dn.CallVa + 5) $(if ($dnWant) { $secVa + $dnAt } else { $dn.Print })))
      if (Compare-Object $bytes[$dn.Call..($dn.Call + 4)] $dcall -SyncWindow 0) {
        $changes += ,@($dn.Call, $dcall)
        Write-Host "$name : design names -> $(if ($dnWant) { 'flower, tree and bench names' } else { 'numbers (as shipped)' })"
      }
    }
    if ($club) {
      $cs = [BitConverter]::GetBytes([uint32]$(if ($clubWant) { $secVa + $clubAt } else { $club.Orig }))
      if (Compare-Object $bytes[$club.Site..($club.Site + 3)] $cs -SyncWindow 0) {
        $changes += ,@($club.Site, $cs)
        Write-Host "$name : clubhouse cache -> $(if ($clubWant) { 'clubhouse frames kept (fixed)' } else { 'oldest first (as shipped)' })"
      }
    }
    if ($pop) {
      $pb = Pop-SiteBytes $pop $popWant $secVa
      if ((Compare-Object $bytes[$pop.Post..($pop.Post + 4)] $pb[0] -SyncWindow 0) -or (Compare-Object $bytes[$pop.Show..($pop.Show + 11)] $pb[1] -SyncWindow 0)) {
        $changes += ,@($pop.Post, $pb[0]); $changes += ,@($pop.Show, $pb[1])
        Write-Host "$name : news popups -> $(if ($popWant) { 'on' } else { 'off (news strip only, as shipped)' })"
      }
    }
    if ($green) {
      $gb = Green-SiteBytes $green $greenWant $secVa
      if ((Compare-Object $bytes[$green.Site..($green.Site + 14)] $gb[0] -SyncWindow 0) -or (Compare-Object $bytes[$green.Break..($green.Break + 4)] $gb[1] -SyncWindow 0)) {
        $changes += ,@($green.Site, $gb[0]); $changes += ,@($green.Break, $gb[1])
        Write-Host "$name : green roll -> $(if ($greenWant) { 'no speed-up, half break' } else { 'as shipped' })"
      }
    }
    if ($shot) {
      $tb = Shot-SiteBytes $shot $shotWant $secVa; $diff = $false
      foreach ($c in $tb) { if (Compare-Object $bytes[$c[0]..($c[0] + $c[1].Length - 1)] $c[1] -SyncWindow 0) { $diff = $true } }
      if ($diff) {
        foreach ($c in $tb) { $changes += ,$c }
        Write-Host "$name : shot fix -> $(if ($shotWant) { 'click anywhere, shot type re-arms' } else { 'as shipped' })"
      }
    }
    if ($curve) {
      $vb = Curve-SiteBytes $curve $curveWant $secVa; $diff = $false
      foreach ($c in $vb) { if (Compare-Object $bytes[$c[0]..($c[0] + $c[1].Length - 1)] $c[1] -SyncWindow 0) { $diff = $true } }
      if ($diff) {
        foreach ($c in $vb) { $changes += ,$c }
        Write-Host "$name : curve fix -> $(if ($curveWant) { 'draw and fade boost counts at most 330 yards' } else { 'as shipped' })"
      }
    }
    if ($ye) {
      $yb = Ye-SiteBytes $ye $yeWant $secVa; $diff = $false
      foreach ($c in $yb) { if (Compare-Object $bytes[$c[0]..($c[0] + $c[1].Length - 1)] $c[1] -SyncWindow 0) { $diff = $true } }
      if ($diff) {
        foreach ($c in $yb) { $changes += ,$c }
        Write-Host "$name : year events -> $(if ($yeWant) { 'monthly' } else { 'yearly (as shipped)' })"
      }
    }
    if ($snack) {
      $kb = Snack-SiteBytes $snack $snackWant $secVa
      if (Compare-Object $bytes[$snack.Site..($snack.Site + 7)] $kb -SyncWindow 0) {
        $changes += ,@($snack.Site, $kb)
        Write-Host "$name : snack bar path -> $(if ($snackWant) { 'not needed' } else { 'needed (as shipped)' })"
      }
    }
    if ($gn) {
      $diff = $false
      foreach ($st in $gn.Sites) {
        $gc = [byte[]](@(0xE8) + (Rel32 ($st.CallVa + 5) $(if ($gnWant) { $secVa + $gnAt } else { $gn.Log })))
        if (Compare-Object $bytes[$st.Call..($st.Call + 4)] $gc -SyncWindow 0) { $changes += ,@($st.Call, $gc); $diff = $true }
      }
      if ($diff) { Write-Host "$name : golfer names -> $(if ($gnWant) { 'real names' } else { 'as shipped' })" }
    }
  }

  if (-not $changes -and -not $dropSection) { Write-Host "$name : nothing to change."; return }
  if ($DryRun) { Write-Host "$name : dry run, nothing written."; return }

  $backup = "$path.companion-backup"
  if (-not (Test-Path -LiteralPath $backup) -and $years -and $years.Base -eq 2001 -and $land.Mode -eq 'share' -and
      $acres.State -eq 'original' -and $staff.State -eq 'ok' -and $staff.Percent -eq 100 -and
      $night -and -not $night.Moved -and (Same-Night $night.Values $nightVanilla) -and $names -and -not $names.On -and -not $names.Section -and $fix -and -not $fix.On -and
      $news -and $news.Hold -eq 1 -and $esc -and -not $esc.On -and
      $weather -and -not $weather.Keep -and $edge -and -not $edge.On -and $lm -and $lm.Percent -eq 100 -and $dist -and $dist.Form -eq 'vanilla' -and $aim -and -not $aim.On -and
      $pop -and -not $pop.On -and $club -and -not $club.On -and $green -and -not $green.On -and $dn -and -not $dn.On -and
      $shot -and -not $shot.On -and $curve -and -not $curve.On -and $all -and -not $all.On -and -not $all.Mixed -and $ye -and -not $ye.On -and -not $ye.Mixed -and $snack -and -not $snack.On -and $gn -and -not $gn.On) {
    Copy-Item -LiteralPath $path -Destination $backup
    Write-Host "$name : original saved as $(Split-Path $backup -Leaf)"
  }
  if ($addSection) { $bytes = Add-Section $bytes $pe }
  if ($resizeSection) { $bytes = Resize-Section $bytes $pe }
  foreach ($c in $changes) { [Array]::Copy($c[1], 0, $bytes, $c[0], $c[1].Length) }
  if ($dropSection) { $bytes = Remove-Section $bytes (Get-Pe $bytes) }
  try { [IO.File]::WriteAllBytes($path, $bytes) }
  catch { throw "$name : could not write ($($_.Exception.Message)). Close the game and try again." }

  $after = [IO.File]::ReadAllBytes($path); $afterText = $latin1.GetString($after)
  $y2 = Find-YearSites $after $afterText; $l2 = Find-LandSite $after $afterText
  if ($yearChanged -and ($y2.Base -ne $StartYear -or $y2.Years.Count -ne 9 -or $y2.Last.Count -ne 1)) { throw "$name : year verification failed." }
  if ($land.Count -eq 1 -and (Compare-Object $after[$l2.Offset..($l2.Offset + 5)] (Land-Bytes $StartLand) -SyncWindow 0)) { throw "$name : land verification failed." }
  if ($acres.State -ne 'unknown') {
    $a2 = Find-AcreSites $after $afterText
    if ($a2.State -eq 'unknown' -or $a2.Factor -ne $acreFactor) { throw "$name : acre label verification failed." }
  }
  if ($staff.State -eq 'ok') {
    $s2 = Find-StaffSites $after $afterText
    if ($s2.State -ne 'ok' -or $s2.Percent -ne $StaffRadius) { throw "$name : staff radius verification failed." }
  }
  $pe2 = Get-Pe $after
  if ($night) {
    $n2 = Find-Night $after $afterText $pe2
    if (-not $n2 -or -not (Same-Night $n2.Values $nightWant)) { throw "$name : night tint verification failed." }
  }
  if ($news) {
    $h2 = Find-NewsHold $after $afterText
    if (-not $h2 -or $h2.Hold -ne $NewsHold) { throw "$name : news hold verification failed." }
  }
  if ($esc) {
    $e2 = Find-Escape $after $afterText $pe2
    if (-not $e2 -or $e2.On -ne $escWant) { throw "$name : Escape verification failed." }
  }
  if ($lm) {
    $l2 = Find-Landmark $after $afterText
    if (-not $l2 -or $l2.Percent -ne $LandmarkRadius) { throw "$name : landmark radius verification failed." }
  }
  if ($dist) {
    $d2 = Find-Distances $after $afterText
    if (-not $d2 -or $d2.Form -ne $Distances) { throw "$name : shot distance verification failed." }
  }
  if ($weather) {
    $w2 = Find-Weather $after $afterText
    if (-not $w2 -or $w2.Keep -ne $weatherWant) { throw "$name : weather verification failed." }
  }
  if ($edge) {
    $g2 = Find-ScrollEdge $afterText
    if (-not $g2 -or $g2.On -ne $edgeWant) { throw "$name : scroll edge verification failed." }
  }
  if ($names) {
    $m2 = Find-Names $after $afterText $pe2
    if (-not $m2 -or $m2.On -ne $namesWant) { throw "$name : staff names verification failed." }
  }
  if ($fix) {
    $f2 = Find-ScaleFix $after $afterText $pe2
    if (-not $f2 -or $f2.On -ne $fixWant) { throw "$name : Pixel HD fix verification failed." }
  }
  if ($aim) {
    $p2 = Find-ProAim $after $afterText $pe2
    if (-not $p2 -or $p2.Bad -or $p2.On -ne $aimWant) { throw "$name : pro aim verification failed." }
  }
  if ($pop) {
    $q2 = Find-NewsPopup $after $afterText $pe2
    if (-not $q2 -or $q2.Bad -or $q2.On -ne $popWant -or $q2.Tg -ne $pop.Tg) { throw "$name : news popup verification failed." }
  }
  if ($club) {
    $c2 = Find-ClubCache $after $afterText $pe2
    if (-not $c2 -or $c2.Bad -or $c2.On -ne $clubWant -or $c2.Orig -ne $club.Orig) { throw "$name : clubhouse cache verification failed." }
  }
  if ($green) {
    $r2 = Find-GreenRoll $after $afterText $pe2
    if (-not $r2 -or $r2.Bad -or $r2.On -ne $greenWant -or $r2.Tick -ne $green.Tick -or $r2.Target -ne $green.Target) { throw "$name : green roll verification failed." }
  }
  if ($all) {
    $x2 = Find-AllShots $afterText
    if (-not $x2 -or $x2.Mixed -or $x2.On -ne $allWant) { throw "$name : all shots verification failed." }
  }
  if ($shot) {
    $t2 = Find-ShotFix $after $afterText $pe2
    if (-not $t2 -or $t2.Bad -or $t2.On -ne $shotWant -or $t2.H -ne $shot.H -or $t2.Ylim -ne $shot.Ylim) { throw "$name : shot fix verification failed." }
  }
  if ($curve) {
    $u2 = Find-CurveFix $after $afterText $pe2
    if (-not $u2 -or $u2.Bad -or $u2.On -ne $curveWant) { throw "$name : curve fix verification failed." }
  }
  if ($dn) {
    $n2 = Find-DesignNames $after $afterText $pe2
    if (-not $n2 -or $n2.Bad -or $n2.On -ne $dnWant -or $n2.Print -ne $dn.Print) { throw "$name : design names verification failed." }
  }
  if ($ye) {
    $v2 = Find-YearEvents $after $afterText $pe2
    if (-not $v2 -or $v2.Bad -or $v2.Mixed -or $v2.On -ne $yeWant -or $v2.Itoa -ne $ye.Itoa -or $v2.Skip -ne $ye.Skip) { throw "$name : year events verification failed." }
  }
  if ($snack) {
    $k2 = Find-SnackPath $after $afterText $pe2
    if (-not $k2 -or $k2.Bad -or $k2.On -ne $snackWant -or $k2.Set -ne $snack.Set) { throw "$name : snack bar path verification failed." }
  }
  if ($gn) {
    $o2 = Find-GolferNames $after $afterText $pe2
    if (-not $o2 -or $o2.Bad -or $o2.On -ne $gnWant -or $o2.Log -ne $gn.Log -or $o2.Roster -ne $gn.Roster) { throw "$name : golfer names verification failed." }
  }
  if ($names -or $fix -or $aim -or $pop -or $club -or $green -or $dn -or $shot -or $curve -or $ye -or $snack -or $gn) {
    $sec2 = $pe2.Sections | Where-Object { $_.Name -eq $sectionName }
    if ([bool]$sec2 -ne [bool]$secWant) { throw "$name : $sectionName section verification failed." }
    if ($sec2 -and ($sec2.RawSize -ne $sectionSize -or $sec2.VSize -ne $sectionSize -or $pe2.SizeOfImage -ne $sec2.Rva + $sectionSize -or
                    $after.Length -ne $sec2.Raw + $sectionSize)) { throw "$name : $sectionName size verification failed." }
  }
  Write-Host "$name : patched."
}

function Set-MapScale([int]$scale) {
  $ini = Join-Path $InstallDir 'options.ini'
  $lines = if (Test-Path -LiteralPath $ini) { [IO.File]::ReadAllLines($ini) } else { @('; options.ini: your choices from the in-game Options page') }
  $out = New-Object System.Collections.Generic.List[string]
  $inMap = $false; $done = $false
  foreach ($l in $lines) {
    if ($l -match '^\s*\[(.+)\]\s*$') {
      if ($inMap -and -not $done) { $out.Add("scale=$scale"); $done = $true }
      $inMap = $Matches[1] -ieq 'map'
    } elseif ($inMap -and $l -match '^\s*scale\s*=') { if (-not $done) { $out.Add("scale=$scale"); $done = $true }; continue }
    $out.Add($l)
  }
  if ($inMap -and -not $done) { $out.Add("scale=$scale"); $done = $true }
  if (-not $done) { $out.Add(''); $out.Add('[map]'); $out.Add("scale=$scale") }
  if ($DryRun) { Write-Host "options.ini: would set [map] scale=$scale (dry run)."; return }
  [IO.File]::WriteAllLines($ini, $out)
  Write-Host "options.ini: [map] scale=$scale (applies to new courses after the next game start)."
}

if (-not (Test-Path -LiteralPath $InstallDir)) { throw "Install folder not found: $InstallDir (use -InstallDir)." }
if (Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($InstallDir, [StringComparison]::OrdinalIgnoreCase) }) {
  throw "SimGolf Remastered is running from $InstallDir. Close it first."
}

$exes = @('Sim Golf Remastered.exe', 'golf.exe') | ForEach-Object { Join-Path $InstallDir $_ } | Where-Object { Test-Path -LiteralPath $_ }
if (-not $exes) { throw "No game program found in $InstallDir." }
foreach ($exe in $exes) { Patch-Exe $exe }
if ($MapScale) { Set-MapScale $MapScale }
Set-ThemeList 'celebrities.dta' $Celebrities
Set-ThemeList 'progolfers.dta' $ProGolfers
Set-WhiteFlowers $WhiteFlowers
Set-RedFlowers $RedFlowers
Set-Labels $Labels
Set-YearEventLabels $YearEvents

