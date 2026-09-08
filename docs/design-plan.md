# Iteration 4 design and playtest notes

Historical record. For the current funding economy, implementation sequence and playtest gates, see [progression-design.md](progression-design.md).

## Scope

This iteration adds long-term research programs, a development tree, equipment modules and desk upgrades, individually assigned beds, more varied staff appearances, a literal notebook, and clearer time controls. It retains the 48-second day, base publication rules, and evidence commitments.

The selected design decisions are cumulative publication credit, modules installed in equipment slots with visible attachments, and sleeping space within the existing building. Save compatibility was explicitly dropped. Only version-4 saves are supported.

## Research programs

Three programs share four milestone levels, with different principal fields and final manuscripts:

| Program | Principal field | Final evidence fields |
| --- | --- | --- |
| Dark matter searches | Nuclear | Nuclear + Quantum |
| Fault-tolerant quantum computing | Quantum | Quantum + Optics |
| Unconventional superconductivity | Materials | Materials + Quantum |

The program is selected at the beginning of the run and cannot be changed. Qualifying papers count cumulatively. The simulation counts each publication once within a criterion; the same paper may satisfy complementary criteria. For example, one mixed Nuclear/Quantum legendary counts toward total papers, Nuclear papers, mixed Nuclear papers, and Nuclear legendary papers.

| Level | Requirements |
| --- | --- |
| Foundations | 2 accepted papers; at least 1 Optics paper |
| Focused studies | 5 accepted papers; 2 principal-field papers; 1 rare-or-legendary principal-field paper |
| Independent evidence | 8 accepted papers; 2 mixed papers involving the principal field; 1 legendary involving it |
| Major discovery | 10 accepted papers; 2 legendary papers involving the principal field; accepted program-specific final manuscript |

Early milestones are reachable using the starting optical bench. Spending impact does not reduce publication credit or lifetime reputation. Rejected papers give no credit. Programs and the archive have their own window, accessed through the target icon.

At level three, the program window offers a guaranteed final manuscript for 12 study points and one free idea slot. It is a legendary paper with the program's fixed field pair and title, using ordinary evidence, writing and review rules. Rejection or shelving preserves its program identity so a retry remains possible. A new final manuscript cannot be created while one is already on the board or active. Completing the program produces a victory popup and allows continued play.

All publication decisions are retained; the archive displays accepted papers with both fields, tier, title, date, rewards, and matching milestone stages. Field filters match either field. The previous 40-entry history limit is removed.

## Development tree

Technologies cost spendable impact; purchases cost funds. The two branches are connected visually, with effects permanently visible.

| Technology | Impact | Prerequisite | Effect |
| --- | --- | --- | --- |
| Precision instrumentation | 2 | None | Permit purchased experiment level 2 |
| Modular instruments | 3 | Precision | Two module slots and acquisition accelerator |
| Mixed-mode acquisition | 3 | Modular instruments | Native secondary channels, field modules and mixed paper ideas |
| Advanced instrumentation | 6 | Mixed-mode | Permit purchased experiment level 3 |
| Nuclear instrumentation | 3 | Precision | Permit particle detectors |
| Quantum instrumentation | 6 | Mixed-mode | Permit quantum rigs |
| Workstation systems | 2 | None | Permit purchased desk level 2 |
| Analysis cluster | 4 | Workstation systems | +25% global analysis and permit desk level 3 |
| Journal club | 2 | Workstation systems | Board refresh for 12 study points |
| Internal peer review | 5 | Journal club | +8 acceptance percentage points, capped at 97% |
| Rest facilities | 3 | Analysis cluster | Assigned bed recovery rises from 7 to 10 energy/hour |

Experiments remain capped at level three. Each level adds 50% of base capacity; condition multiplies actual capacity. Upgrade cost is 65% of base equipment price times current level. Upgrading restores condition. The inspector previews capacity, data channels, upkeep, price, and the exact technology gate.

Native mixed channels remain 75/25 at level 2 and 60/40 at level 3 after mixed-mode technology. Module effects are additive:

- Acquisition accelerator costs $1,400 and multiplies instrument capacity and operator acquisition speed by 1.25.
- Each extra field module costs $1,800 and adds that field at 0.2 times base output. Existing data yields stay unchanged. No duplicate module or already-present field is allowed at installation.
- Two slots are available per instrument, regardless of level, after Modular instruments. Removing a module refunds 35% of its purchase price.

For example, an upgraded optical bench can produce 0.75 Optics and 0.25 Quantum per base data unit, plus 0.20 Nuclear from an attached module. Its total evidence output is 1.20 per base unit. This is an explicit productivity benefit; it is not a normalized redistribution.

Desk level 2 costs $700 and multiplies its seated user's analysis, writing and study by 1.15. Level 3 costs $1,400 and multiplies those tasks by 1.30. The analysis-cluster multiplier stacks with the desk multiplier. Travel and energy still affect work.

## Beds and appearance

The building footprint remains 20×14. The former common room becomes a sleeping area with three starter beds, a coffee table, and seats for bedless rest. Beds occupy 1×2 tiles along the upper wall. Their access tile is at the foot. Up to six beds fit while leaving an entrance route clear; construction checks every workplace and bed before charging funds.

Beds cost $450 and return $157 when removed. One person owns each bed; an occupied bed cannot be assigned to someone else until its owner releases it. Newly placed beds go to the first unassigned staff member. Hires take a free bed if available and otherwise show a missing-bed warning.

Assigned and reachable beds restore seven energy per stationary hour, or ten with Rest facilities. Bedless rest restores 40%, initially 2.8 and later four energy/hour. Walking consumes the corresponding fraction of rest time. Work continues to drain two energy/hour, and energy below eight forces emergency rest.

Appearance is generated once per person and saved independently of specialties. Portrait and floor rendering share skin, hair, hairstyle, glasses, beard, clothing accents, and build. Researchers wear coats; students have colored clothing. Sleeping staff render in their assigned beds, while their navigation access point remains on walkable floor.

## Time and interface

The clock, cash, impact and pause controls have fixed-width areas. Numeric changes cannot shift the speed buttons. The pause control is amber while stopped and remains visible and clickable above management windows.

Browsing staff, recruitment, statistics, notebook, programs, modules, and development does not pause or resume time. Existing manual pauses are preserved. Referee decisions, program milestones, loading and the pause menu explicitly stop time. Referee and milestone windows offer a clear continuation action. A pending result or milestone also blocks direct hourly advancement and large-frame catch-up.

Referee feedback precedes any earned milestone. The next feedback window is deferred until the current one closes, preventing overlapping/orphaned windows when users switch management views. The program and development windows replace management popups, not sidebar tabs.

Both notebook views use paper, ruling, margins, binding, and dated entries. Event text remains contextual flavor only; it uses a separate RNG and recent-template exclusion. Old place names and iteration labels have been removed from the in-game interface. Upgrade effects are fixed small text; tooltips supplement details rather than hide the main benefit.

## Saves

Only version 4 is loaded. It uses a separate autosave and five named slots. Old files are not read, migrated or overwritten by these paths. Fresh runs select a program before entering the laboratory.

Saved state includes the full publication history, both evidence fields, program-specific manuscript identity, program level, pending milestone/victory, beds and ownership, staff appearance, equipment modules, desk levels, unlocked technologies, and all existing economy/routine data. Full-precision review draws and atomic writes remain in use.

## Validation and playtest priorities

The core suite checks collection, analysis, routines, traits, energy, navigation, publication commitments, all field/tier combinations, acceptance/rejection, hard pauses, saving, and a 160-day study/publication strategy.

The progression suite verifies exclusive bed ownership, 40% fallback recovery, placement access, technology prerequisites, actual module output, actual upgraded-desk productivity, all three program completions, final-paper rejection and shelving, publication history beyond 40 entries, and saves with pending victory feedback. Program-completion tests provide evidence and accelerate writing/review setup to isolate progression logic; they are not full economy playthroughs.

The UI suite renders the main menu, lab, staff, equipment, modules, notebook, tree, program, archive, publication decisions, milestone and victory feedback. It exercises an actual pointer click on the toolbar above an open window, checks clock-layout stability, and verifies that browsing does not auto-pause.

The controlled founding team reaches 18 Optics evidence after 132 lab hours, around 4 minutes 24 seconds at 1x, and its first decision arrives on day 11 at 20:00. The changed rest-room routes make this slightly faster than iteration 3. A seeded 160-day base-loop strategy produces ten papers from eleven decisions with no rescue grants.

Next playtests should focus on:

- Whether the two technology branches create useful choices rather than mandatory chores.
- Whether mixed and legendary paper requirements make the programs distinct enough.
- Whether milestone counts and acquisition modules shorten or prolong the intended run length.
- Whether six fully rested staff plus less-efficient bedless staff is a useful starting-space constraint.
- Whether program/archive windows and visible upgrade effects answer the player's immediate questions.
- Whether the reduced pauses remain comfortable while reviewing long-term plans.

Map expansion, additional bed capacity, more programs, deeper personnel interactions and revised final-manuscript mechanics can follow these playtests.

Verified in Godot 4.7.2: **509 core simulation checks, 238 progression checks, and 131 interface checks** passed.
