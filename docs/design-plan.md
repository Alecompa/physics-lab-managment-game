# Iteration 3: a physical lab and clearer management

## Implemented scope

The third iteration keeps the typed-data and publication loop, adds a fixed physical laboratory, and rebuilds the interface around the map. The fourth field remains optics. Research trees, map expansion, and new long-term progression are deliberately deferred.

A lab day lasts 48 real seconds at 1x, twice the previous duration. Each simulation tick is one lab hour. Walking covers up to four tiles per lab hour, rendered at two tiles per real second at 1x. Publication decisions pause the clock and require acknowledgement; closing the result leaves time paused.

## Physical layout

The building is 20×14 tiles. Two upper rooms hold 2×2 experiments. The lower office holds 2×1 desks with a chair immediately below. The lower common room contains fixed seating and a library. Walls, windows, doors, and corridors remain fixed for this iteration.

A hypothetical construction grid checks every experiment's interaction perimeter and every chair before charging for placement. New furniture cannot occupy a chair or cut the corridor route to an existing workplace. Desks cost $600 and return $210 when removed. Removing an assigned desk returns its users to automatic desk selection.

Each desk is reserved by one person per simulation hour, including travel toward it. Explicitly assigned people wait when their desk is busy; automatic assignment chooses a nearby free reachable chair. Priority rotates each hour. People can pass through one another. Furniture blocks pathfinding, but moving people do not.

## Daily routines and movement

Each person has three editable blocks: rest, collection, and analysis. The remainder of the 24-hour budget goes to a chosen activity. These blocks occur consecutively. Editing one block preserves its requested size and trims excess from other work blocks, then rest. A night owl's schedule starts eight hours later.

Activity can be Auto, Write, Study, or Maintain. Auto writes during an active manuscript's writing stage and studies at other times. All roles can collect and analyze. Researchers write and study faster than other roles. Technicians start with a maintenance routine.

Each agent has a position, destination, route, status and energy. A grid path routes around equipment to an adjacent work position or a desk. Staff walk up to four tiles per lab hour; the travel fraction reduces the work completed that hour. Rest requires reaching a common-room seat. Analysis, writing and study require a physical desk chair.

Desk use is exclusive within an hour. Up to two operators work at an experiment in an hour, sharing its hourly capacity. Automatic collection chooses the closest reachable matching experiment; the player can assign another station to spread the team. Automatic maintenance chooses the most damaged reachable experiment, with distance breaking close choices. Staff assigned to an unavailable or enclosed experiment wait and show why.

Work drains two energy per hour. Rest recovers seven energy per stationary hour, or ten with the common-room upgrade. Work efficiency scales from 40% to 100% with energy. Energy below eight overrides the schedule with emergency rest.

## Traits and recruitment

Each candidate preview shows a specialty, trait and personality. Hiring preserves the previewed identity and attributes. All attributes and candidates are saved.

Specialties add 25% to relevant collection, analysis, writing and study. A mixed experiment uses its primary field for the collection specialty bonus.

| Trait | Bonus | Drawback |
| --- | --- | --- |
| Meticulous | +20% analysis | -20% collection |
| Inventive | +35% study | -15% writing |
| Practical | +20% collection | -15% analysis |
| Diligent | +20% writing | -20% study |

| Personality | Behavior |
| --- | --- |
| Early bird | +10% work before noon |
| Night owl | Routine shifted eight hours; +10% work after 16:00 |
| Sociable | +10% work when another person is within 1.5 tiles |
| Solitary | +10% work alone; -10% near a colleague |

## Typed evidence and experiments

Raw and analyzed evidence are separate dictionaries for nuclear, quantum, materials and optics. Analysis preserves type and quantity. The Any assignment prioritizes raw data in the person's specialty, then an available field with the largest stock. One field is analyzed per person per hour.

| Experiment | Cost | Capacity per 24 staffed hours | Upkeep/day | Fields |
| --- | --- | --- | --- | --- |
| Optical bench | $2,400 | 18 | $12 | Optics, then quantum |
| Materials chamber | $4,800 | 24 | $20 | Materials, then optics |
| Particle detector | $8,200 | 33 | $30 | Nuclear, then materials |
| Quantum rig | $14,500 | 45 | $44 | Quantum, then nuclear |

Equipment capacity is an hourly limit, derived by dividing the displayed daily capacity by 24. Actual output depends on staffed hours, travel, operator performance and condition.

Level upgrades add 50% of base capacity per level, up to level three. Condition multiplies capacity and falls by 0.45 points per day, to a floor of 35%. Technician maintenance restores 0.8 condition points per full work hour at the chosen station, before work modifiers. Manual service still costs $250.

After mixed-mode acquisition is unlocked, level 2 equipment produces a 75/25 primary/secondary split and level 3 produces 60/40. Before the unlock, all levels produce the primary type only.

## Ideas and peer review

The board holds up to six ideas. Letter, article and high-impact papers are presented as Common, Rare and Legendary. Random tier draws use 55/30/15 weights with a legendary guaranteed on the eighth draw since the last legendary. The discovery counter is saved. Fixed starter cards and journal club’s guaranteed basic cards do not consume these draws. Appearance has no impact gate; manuscript eligibility retains the existing two/seven lifetime-impact requirements. Research-route gating is deferred.

Each idea has a field, tier and flavor title. Starting ideas include a letter in each field and an optics article. Idea generation costs eight study points and favors installed fields. A journal-club refresh costs twelve points, replaces the board, and guarantees a letter for each installed field while space permits. It does not change the active manuscript. Discarding an idea frees a slot.

Researchers earn 0.35 study points per stationary work hour before modifiers; other roles earn 0.12. Study points accrue only during scheduled Study activity or Auto activity when no manuscript needs writing. Ideas do not appear for free simply because time passes.

| Tier | Minimum data | Base writing | Base acceptance | Review time | Grant | Impact | Lifetime impact required |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Letter | 18 | 10 | 62% | 24 hours | $2,600 | 2 | 0 |
| Article | 48 | 26 | 48% | 48 hours | $8,200 | 5 | 2 |
| High-impact paper | 110 | 55 | 35% | 72 hours | $22,000 | 12 | 7 |

The evidence slider runs from 100% to 200% of the minimum. Each additional 100% adds 32 percentage points to acceptance probability and 20% to writing work. Internal peer review adds another eight percentage points, with a 97% ceiling. Probabilities are shown before the player commits anything.

After mixed-mode acquisition, newly generated advanced ideas may require 75% primary and 25% secondary evidence. The UI displays rounded costs for each type. All costs are paid when writing starts.

Researchers write 0.3 work per stationary hour before modifiers; other staff write 0.12. Once enough work is complete, the manuscript enters review. Referee time passes independently of staff activity. Submitted manuscripts cannot be shelved. Before submission, shelving returns the exact dataset and idea while discarding writing progress.

Acceptance pays the tier's grant and adds both available and lifetime impact. Rejection pays nothing, returns 75% of each committed type, and restores the idea for another attempt. If the idea board is full, its newest idea is replaced by the returned manuscript idea. This keeps failure recoverable without giving back all the resources.

The review random draw is fixed when writing starts and saved with the manuscript. Saving and loading an active paper does not reroll it. Pending decisions, titles and feedback also survive loading.

## Permanent development

| Development | Impact cost | Requirement | Effect |
| --- | --- | --- | --- |
| Journal club | 2 | None | Full idea-board refresh for 12 study points |
| Nuclear instrumentation | 3 | None | Unlock particle detector construction |
| Mixed-mode acquisition | 3 | None | Level 2+ secondary data and new cross-field ideas |
| Analysis cluster | 4 | None | +25% actual analysis output |
| Quantum instrumentation | 6 | Mixed-mode acquisition | Unlock quantum rig construction |
| Staff common room | 3 | None | Rest recovery rises from 7 to 10 energy/hour |
| Internal peer review | 5 | Journal club | +8 acceptance percentage points for newly started papers |

Impact spending is separate from lifetime reputation. University support is $60 plus $3 per lifetime impact each day. Hiring fees, wages and emergency support retain the previous prototype's values. A funding shortfall adds $4,000, spends up to two available impact and pauses the lab. Unlocks remain permanent.

## Flavor and activity feedback

The notebook attempts a contextual event every 8–17 lab hours. It selects from actual working activities, energy below 30, equipment condition below 55%, and work in a matching specialty. The same template is excluded from the next 24 emitted flavor events, across all people. If no fresh applicable template exists, that attempt is skipped. Funny observations have no resource, condition, energy, or publication effects.

Flavor uses a separate saved RNG, so event generation cannot change a manuscript's review result or future discovery draws. Existing condition loss still reduces capacity to a floor of 35%; this iteration does not introduce equipment failures. Worn-equipment text reflects that limitation.

Experiments animate only when an operator is producing data. Desk screens animate during desk work. People use the same walkable grid for visual motion and show resting, studying, or writing indicators. Pausing freezes simulation activity and movement.

## Interface and resource history

The map occupies most of the screen. Four icon-led resource cards separate raw data from analyzed evidence. Build, People, Papers, and Develop share one management sidebar. People has a portrait roster and one focused routine/assignment editor. The daily schedule has draggable boundaries, numeric hour controls, and a distinct remaining Activity block.

Paper cards identify field and rarity separately. Unlocked papers appear before papers gated by lifetime impact, with fields supported by installed experiments first. Common cards explicitly say no impact is required, and the funding/impact line is labeled as a publication reward. They show commitment, acceptance odds, work, and the specific reason a manuscript cannot start. The writer banner distinguishes missing hours, missing reachable desks, and the next writing shift. “Scheduled now” describes the routine; travel or low energy can still delay actual writing.

The history graph stores daily funds, each raw/analyzed field pool, and daily publication grants for up to 720 days. It supports 30-day, 90-day and full-history views. Samples begin at lab creation and continue each midnight. New idea and publication reveals pause time. Journal club reveals the highest-tier idea from its new board.

## Saves and compatibility

The game starts at a main menu and does not overwrite anything there. It provides five named manual slots, a separate autosave, and a load list. Continue selects the most recently modified valid listed save. Autosave runs every five lab days, on return to the main menu, and on quitting an active lab. Loading always pauses.

Version 3 uses `fieldwork_autosave_v3.json` and `fieldwork_slot_N_v3.json`. Version 2 and original prototype saves can be selected for import; their source files remain untouched. Old experiments are remapped into legal positions in the fixed building. Unplaced equipment receives its original base cost back. Old staff share the three starter desks until the player adds or reassigns furniture.

Original untyped data becomes optics. Staff names and collection allocations migrate into routines. An unfinished iteration-1 manuscript returns its original dataset because it had no data field or review stage. Version 2 active papers preserve their evidence, progress, and fixed review roll.

Save validation runs before replacing current game state. Files are written through a temporary file and rename. Full-precision numbers preserve review draws. Navigation is rebuilt after loading. Furniture, history, flavor RNG/cooldown, and legendary protection persist.

## Verification and next playtest

On September 5, 2026, all **514 simulation checks and 114 interface checks** passed under Godot 4.7.2. Rendered screenshots were inspected for the main menu, gameplay, staff routine, paper tiers, publication feedback, resource graph, and full save chooser.

The regression suite covers physical routes and placement, desk contention, routines, energy, trait effects, typed-data conservation, mixed output, all twelve field/tier publication combinations, rejection, hard clock stops, development, save slots, and previous-version migration. The UI suite exercises new/load/save/pause flows, rendered movement, staff controls, construction, paper commitments, feedback, graphs, and long save names. Tests use independent temporary save slots and disable autosave.

With the controlled founding team, the first 18-evidence optics manuscript is ready after 155 lab hours (5 minutes 10 seconds at 1x), and its first decision arrives on day 12 at 18:00. A 160-day study-and-review strategy produces 10 papers from 11 decisions, reaches 20 lifetime impact, and needs no rescue grants. Those numbers are seeded checks, not expected outcomes for every lab.

The initial version of this map used three tiles/hour and took 275 hours to reach a manuscript. Four tiles/hour keeps visual walking half the previous speed because days are longer, while reducing excessive commute and recovery penalties. The physical layout still makes the opening slower than iteration 2.

Next player feedback should focus on:

- Whether 48-second days and two-tile-per-second walking feel comfortable.
- Whether the first-paper wait is too long once travel and rest are physical.
- Whether the selected-person schedule makes activity time and desk conflicts clear.
- Whether each resource icon and paper tier is recognizable without reading tooltips.
- Whether notebook messages appear often enough and avoid noticeable repetition.
- Whether legendary ideas feel special without being frustratingly rare.
- Whether the resource graph makes bottlenecks clear enough to guide assignments.

Later iterations can add research-route prerequisites, map expansion, longer-term goals, smarter automatic staffing, and more detailed breakdown or revision mechanics after this foundation is playtested.
