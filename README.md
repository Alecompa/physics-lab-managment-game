# Fieldwork, iteration 8

A Godot management game about running a physics laboratory. Collect data, analyze it, publish papers, and build toward a major discovery.

## Play

Double-click **Play.command**, or open **project.godot** in Godot and press **F5**. Restart any running copy to use this iteration. Built with Godot 4.7.2 and the compatibility renderer. No plugins are required.

Iteration 8 adds Kenney furniture sprites, shaded UI controls and frames, custom cursors, and a warmer cartoon-inspired palette. It includes iteration 7’s automatic paper/grant priorities, three-room laboratory, audio, and concise UI with hover explanations. Version-5/6 saves keep their previous floor plan and receive an original-file backup. See [the progression design and playtest plan](docs/progression-design.md) and [iteration-8 notes](docs/releases/iteration-8.md).

The version-5 browser build was published on itch.io. Rebuild the current version with `python3 tools/export_web.py`; the new upload package is `exports/fieldwork-v8-web-itch.zip`. Version 8 requires a new upload and is not automatically published. See the [export and publishing guide](docs/publishing-itch.md) for template setup, local preview and upload settings. Browser saves are local to the browser profile and separate from desktop saves.

Choose a lab name and one research program at the beginning of the run. The game starts paused. **Space** pauses/resumes, and **1 / 2 / 3** select **1x / 2x / 4x**. Days remain **48 seconds at 1x**; paper evidence and writing requirements, review times, and evidence commitments are unchanged.

![Three-room laboratory with introductory detector](docs/prototype-v8.png)

## Interface and artwork

Kenney’s **Furniture Kit**, **UI Pack** and **Cursor Pack** provide furniture, shaded buttons, nine-slice borders, controls and custom pointers. A teal, cream and warm-wood palette ties the map and management screens together. Headings use Kenney Future; body text retains the standard readable font. Hover and press feedback preserve fixed hit areas, and tooltips hold the detailed explanations.

The notebook uses cream ruled pages and a teal spiral binding. Portraits and the development tree share the palette. Science field colors remain distinct, with animated instruments and visible module attachments and selection brackets.

Desks with computers, beds, plants, shelves, kitchen furniture and lounge chairs are lightweight transparent sprites baked from the Furniture Kit models. Rooms, walls, instruments and staff are drawn in Godot. The art update also applies to existing saves. All three packs are CC0; see [art credits, licenses and reproduction instructions](assets/kenney/CREDITS.md). Assets are bundled locally, including the browser export.

Music starts with the first click or keypress and continues through pauses and menus. **Settings** has independent music and effects sliders; zero mutes either. The soundtrack is Space Flight by wipics and the effects are Interface Sounds by Kenney, both CC0. See [audio credits and sources](assets/audio/CREDITS.md). Trait effects, grant formulas and detailed upgrade rules are available on hover.

## Research programs

The target icon opens a separate program window and publication archive. Choose one program per run:

| Program | Principal field | Final discovery manuscript fields |
| --- | --- | --- |
| Dark matter searches | Nuclear | Nuclear + Quantum |
| Fault-tolerant quantum computing | Quantum | Quantum + Optics |
| Unconventional superconductivity | Materials | Materials + Quantum |

Each program has four cumulative milestones:

1. **Foundations:** two accepted papers, including one in the selected program's principal field. Starter equipment is sufficient.
2. **Focused studies:** five accepted papers, including two in the principal field and one rare-or-legendary paper in that field.
3. **Independent evidence:** eight accepted papers, including two mixed-field papers involving the principal field and one legendary paper involving it.
4. **Major discovery:** ten accepted papers, including two legendary papers involving the principal field and the program's final discovery manuscript.

Earlier papers count throughout the run. Higher tiers count toward lower-tier requirements, and mixed papers count in both fields. A paper can satisfy several criteria but is counted only once within each criterion. Rejected papers grant no program credit.

After stage three, spend **12 study points** in the program window to develop the final mixed-field legendary manuscript. It is guaranteed, subject to a free idea slot, and goes through the usual evidence, writing, and review process. Rejection restores it for another attempt. Completing the program presents the discovery and lets you continue playing.

The publication archive retains every accepted paper, including both fields, tier, date, rewards, and program contribution. Filter by field and rarity.

## The laboratory

The initial grid is **28×20**, with three rooms and a corridor. Workstations can be rearranged within the available floor space. Experiments occupy **2×2** tiles, desks **2×1** plus a chair below, and beds **1×2** plus access at their foot. Place them in any room with enough clear floor. Placement respects walls and decorations and preserves workplace routes, the entrance and shared rest seats. Select an object and **Move / free** to reposition it without losing assignments, modules, upgrades or condition.

Use the wheel or pinch to zoom, middle-button drag or trackpad gestures to pan, and **Fit** to reset the view. After clicking the map, arrow keys also pan. After milestone 3, **Campus planning** costs 18 impact and requires Advanced instrumentation. The first wing costs $45,000 and opens a **34×24** grid. After the major discovery, a second $75,000 wing expands it to **40×24**. Neither is needed to complete the science.

The founding staff each have a desk and bed. Add beds before hiring if you want new staff to recover efficiently. A new bed automatically goes to the first person without one; otherwise assign ownership in **People**. Beds have exclusive owners. More beds can be placed throughout the open floor, subject to access.

- An assigned, reachable bed restores **7 energy per stationary rest hour**.
- Rest without a bed restores **40%**, initially 2.8 energy/hour.
- Rest facilities raise these values to 10 and 4 respectively.
- Working drains energy. Exhausted staff take emergency rest.

Each person has a portrait and matching appearance on the floor, with varied hair, skin, glasses, facial hair, clothing, and build. Staff follow their 24-hour routines and path around furniture. People can pass through one another; desks have one user per work hour. Movement is now **24 tiles per game hour**, up from four; time left after arrival is used for the scheduled task.

Each program starts with an introductory version of its principal instrument: particle detector, quantum rig or materials chamber. All yield **18 base capacity/day** and cost **$60/day** in upkeep. Staff specialize in the chosen field, with three common ideas and one rare idea in that field plus a common secondary-field idea. Advanced construction stays behind technology unlocks; upgrading an introductory instrument converts it to the regular instrument and its upkeep.

## Supervision and maintenance

Assign each PhD a supervisor in People. A researcher supports at most **two students** and spends the first available **two Activity hours per student each day** at a reachable desk on mentoring. Remaining Activity follows Papers first, Grants first, Study or Maintain. Rest, collection and analysis are not taken for mentoring.

PhD research productivity ranges from **60% without coverage to 100% with full coverage**. Today's actual mentoring sets tomorrow's coverage, proportionally to delivered hours. Founding students start covered; changing supervisors resets credit, and losing a supervisor immediately removes the bonus. Insufficient Activity, missing desks and exhaustion can prevent full coverage. The inspector shows reserved hours, delivered mentoring, productivity and cumulative working, walking and waiting time.

Only productive acquisition wears instruments: **0.10 condition points per PhD operating hour**, **0.04 for other roles**. Waiting at a saturated bench does not cause wear. Idle instruments no longer lose condition at midnight. Technicians restore **1.2 condition/hour** before modifiers; other staff restore **0.45**. Manual servicing costs `max($60, ceil(12 × missing condition))`.

## Data and papers

Nuclear, Quantum, Materials, and Optics each have raw data and analyzed evidence. Students collect during their collection block and analyze at a desk during their analysis block. Remaining gold hours run the selected Activity. **Papers first** works on a manuscript, then an available grant draft, then study. **Grants first** reverses the draft priority. Only researchers prepare grants. Completion can switch to the next task within the same hour. Study and Maintain remain explicit choices.

| Paper tier | Base evidence | Writing work | Acceptance | Review | Impact awarded | Lifetime impact required |
| --- | --- | --- | --- | --- | --- | --- |
| Common letter | 18 | 10 | 62% | 24h | 2 | 0 |
| Rare article | 48 | 26 | 48% | 48h | 5 | 2 |
| Legendary paper | 110 | 55 | 35% | 72h | 12 | 7 |

Common papers require no impact. Impact shown under “On publication” is a reward. Lifetime-impact requirements never spend impact.

Commit 100–200% of the minimum evidence. Double evidence adds 32 acceptance percentage points and 20% writing work. Rejection returns 75% of committed evidence and restores the idea. Shelving before review returns the full evidence but loses writing progress. Review rolls are fixed when writing starts and survive saving.

Study earns points for ideas. **Discover** costs 8 points; journal club refreshes the board for 12 after its technology unlock. Random tiers use a 55% common / 30% rare / 15% legendary base roll, with a legendary guaranteed after seven consecutive misses. The final program manuscript does not depend on this randomness.

## Grants and university support

Paper acceptance awards impact only. A new laboratory receives an equipped lab and a $30,000 startup grant. Salaries are $100/day per PhD, $200 per researcher and $140 per technician. Regular instrument upkeep starts at $60/$100/$150/$220 for optics/materials/nuclear/quantum; upgrades increase it. Every program's introductory instrument costs $60/day.

University support is `120 + min(120, 4 * lifetime impact) * recent activity` per day. The publication bonus stays at full strength for 30 days after publication, then decays linearly to 25% by day 60. Base support stays at $120. Costs and support accrue hourly. Available impact buys technology; lifetime impact determines support and grant odds. The budget strip and purchase tooltips show runway without speculative grant income. Insolvency stops the laboratory, with no automatic bailout.

| Grant | Award | Required hours | Review | Access |
| --- | ---: | ---: | ---: | --- |
| Introductory | $12,000 | 48 | 1 day | First paper submitted, acceptance not required |
| Small | $14,000 | 64 | 5 days | Introductory grant completed |
| Standard | $32,000 | 192 | 8 days | Program milestone 1 |
| Large | $72,000 | 384 | 12 days | Program milestone 2 |

The introductory award is guaranteed once. In Grants, open a draft. Researchers with either writing priority use their free Activity hours on it. A reachable desk, energy and actual productive hours matter. One draft can be worked on at a time; reviews of different sizes can overlap. Submit a completed draft explicitly. Researchers automatically return to papers or study during review.

Ordinary success starts at 55/45/35%, with bonuses from lifetime impact, milestones and extra preparation, capped at 85%. Up to 50% extra hours adds up to 15 percentage points with diminishing returns. Rejection preserves half of the proposal's work for the same proposal and offers a revision bonus of 5 percentage points that does not stack. Shelving loses draft and revision work. The draw and submitted estimate survive saving.

Calls run on fixed periods from day 1: small every 20 days, standard every 30, large every 45. One submission per ordinary size and period. The introductory award has its own application and never delays the first small. Milestones unlock larger grants without postponing existing eligibility. The tab shows the next eligible call, and drafts may be prepared early. Ready and reviewing proposals warn when cash is forecast to run out before a decision. Early version-5 saves retain their cash and historical awards; loading removes the old introductory small-call penalty. The increased startup grant applies only to new laboratories.

Settings persist separately from saves. The tutorial can be hidden without changing grant eligibility. On narrow layouts or larger UI scales, use Lab / management to switch views; overflowing content remains scrollable.

## Development and modules

The tree icon opens Development in a separate window. Technologies cost impact. Equipment upgrades and modules then cost funds. Descriptions and costs are visible, and arrows show prerequisites.

- **Instrumentation:** Precision instrumentation opens level 2 and leads to nuclear instruments and module slots. Module slots lead to mixed-mode acquisition, then level 3 and quantum instruments.
- **Computation and research:** Workstation systems opens desk upgrades, leading to analysis improvements and journal club. These lead to rest facilities and internal peer review.

Inspect an experiment to see current and next capacity, data channels, upkeep, condition, cost, and required technology. Level 2 adds 50% base capacity; level 3 doubles base capacity. Upgrading restores condition. Mixed-mode technology also enables native 75/25 primary/secondary output at level 2 and 60/40 at level 3.

Each instrument has **two module slots** after the relevant unlock. Attachments are visible on the instrument:

- **Acquisition accelerator, $1,400:** +25% capacity and operator acquisition speed.
- **Additional data channel, $1,800:** add a selected field equal to 20% of base output, preserving existing channel yields. Requires mixed-mode technology. A field already produced by that instrument cannot be installed again.

Dismantling modules, instruments and furniture provides no refund. Desk level 2 costs $700 and gives +15% analysis, writing, and study; level 3 costs $1,400 and gives +30%. Technology prerequisites apply to each level.

## Interface and time

The notebook uses paper, ruled lines, dates, and binding in both its compact and expanded views. Its contextual jokes and observations have no gameplay effects. Fatigue and equipment-wear observations reflect actual state. Flavor has separate randomness from paper outcomes.

Browsing the notebook, staff, recruitment, graphs, programs, or development **does not pause**. The clock and pause button remain visible and usable above open windows. Manual pauses remain paused when a window closes. Paper decisions, grant decisions and program milestones pause explicitly and offer a Resume/Continue button. The pause button turns amber whenever the simulation stops.

The resource graph records cash, typed raw data, evidence, grant awards and daily university/cost rates for up to 720 days.

## Saves and controls

Version 7 keeps the five named slots and autosave filenames so existing browser and desktop saves remain discoverable:

- `fieldwork_autosave_v5.json`
- `fieldwork_slot_1_v5.json` through `fieldwork_slot_5_v5.json`

Files live in Godot's game-specific `user://` folder. Use **Project → Open User Data Folder** in the editor to locate it. Autosave runs every five lab days, on return to the main menu, and on quitting an active lab. Loading restores paused and preserves pending paper, milestone and grant feedback. Version-5/6 data retains its open floor plan, cash, equipment and attained milestones. New games use the furnished three-room plan. Researchers with enough Activity are assigned up to two previously unassigned PhDs. Before the first version-7 write, the old file is copied to `.v5-backup` or `.v6-backup`. New saves use schema 7; older game versions cannot load them. Version-4 files are not imported.

| Action | Control |
| --- | --- |
| Pause / resume | Space or top button |
| Speed | 1, 2, 3 |
| Pause menu / close window | Esc |
| Place furniture | Build card's plus, then valid tile |
| Cancel placement | Esc or right-click |
| Move an object | Select it, Move / free, then destination |
| Map zoom | Wheel, pinch or + / − |
| Map pan / reset | Middle drag, trackpad or arrow keys / Fit |
| Inspect | Click a person, desk, bed, or experiment |
| Research / archive | Target icon |
| Development | Tree icon |
| Save chooser | Cmd+S / Ctrl+S or pause menu |
| Resource history | Chart icon |
| Help | H or info icon |
| Grant proposals | Grants tab or coin icon |
| Step-by-step tutorial | Guide button or pause menu |
| Fullscreen | F11 or Settings |
| UI scale | Settings, 100% / 115% / 130% |

## Development roadmap

The [original version-5 roadmap image](docs/fieldwork-roadmap-v5.png) is a historical snapshot. See the current [roadmap](docs/roadmap.md) for implemented blocks.

Iterations 5–7 implement and refine blocks 1–3: funding, onboarding, display settings, staff supervision and wear, starting specialization and lab expansion. They are in playtesting. Training and visitors, choice events and scientific rivals remain planned.

See the [roadmap](docs/roadmap.md), [iteration-5 release notes](docs/releases/iteration-5.md), and [full design and playtest gates](docs/progression-design.md). Each block is tested and rebalanced before the next begins. Future release numbers and dates are not committed.

## Project and verification

Game rules live in `scripts/simulation.gd` and `catalog.gd`; grant sizes and probability components live in `scripts/grant_rules.gd`. Program criteria are in `research_programs.gd`; physical rooms and footprints in `lab_layout.gd`. UI components include `main.gd`, `tech_tree_view.gd`, `notebook_view.gd`, `portrait.gd`, `schedule_view.gd`, and `resource_chart.gd`. `appearance.gd` keeps portrait and floor appearances consistent.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_simulation.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_progression.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/test_ui.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_funding.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/test_funding_ui.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_economy_balance.gd
```

The UI suite renders into ignored `docs/screenshots/`; add `--headless` to skip captures. Tests disable autosave and use temporary test files. See `docs/progression-design.md` for the six implementation blocks and playtest gates. `docs/design-plan.md` retains the historical iteration-4 notes.

The repository uses `main`, with [Alecompa/physics-lab-managment-game](https://github.com/Alecompa/physics-lab-managment-game) configured as `origin`. Source assets, import settings, and `.gd.uid` files are tracked; editor caches, exports, and generated screenshots are ignored.

Verified with Godot 4.7.2: 575 simulation, 238 progression, 141 interface, 158 funding, 191 balance, 60 funding interface, 67 block-2/3 and 42 opening/team checks passed. The iteration-7 suite also verifies priorities, room access, old-save migration, audio preferences and responsive UI with rendering. The moderate-expansion benchmark now survives to day 75 in 30/30 controlled runs; this is not full-program or human validation.

The block-2/3 checks and controlled opening benchmarks can be rerun with:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_blocks23.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/test_blocks23_ui.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_program_openings.gd
```

Iteration-7 checks:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/test_iteration7.gd
```
