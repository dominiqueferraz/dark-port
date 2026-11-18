# Dark Port Endless Level Register

This register specifies the first 20 levels of the signal-routing pack. Each entry records the winning conditions, the route the board is meant to teach, the failures to reproduce, and the target number of distinct solutions. The reference fixtures in Appendix A have exhaustive counts under their stated rules. The app proofs count solutions using the playable fixtures and evaluators. Use the [product requirements](prd.md) for the station loop and the existing [wired](prd.md#wired-signals) and [optical](prd.md#light) conventions.

## Signal rules

- **Light.** Use north as positive y. Lasers emit 100 u. An optical splitter sends half straight and half around its diagonal. Mirrors turn light 90° and preserve its power. The two reflective faces share one diagonal. In orientation N, eastbound light turns north and westbound light turns south. Orientation S reverses both exits. Each leg requires a clear sightline to the next aperture or reflective face. Sensors and converters accept direct hits from their marked approach. A hit on a housing, baffle, concrete or mesh stops the ray. Independent rays cross without interacting.
- **Radio.** The proposed attenuation is 5 u per grid step. Inside the inclusive reach limit, a clear path delivers `max(0, emitted u − 5 × distance)`. Coverage distance is Manhattan distance. Directional converter hops in this pack are axial. A clear, matching link at 0 u is quiet. Test the material along the straight radio path independently of the distance and channel. Concrete stops light and radio. Mesh stops light and passes radio. A converter emits at its accepted optical input strength, on its fixture channel.
- **Wired power.** A relay preserves the delivery. An N-way splitter always divides by N, including when sockets are unused. The actual output and input ports determine cable length. Required bands and reach boundaries are inclusive. Use exact numeric comparisons in the verifier, with rational arithmetic if a fixture introduces fractions.
- **Protected receivers.** Declare either *quiet* (no positive delivery on the monitored channel) or *below trip* (positive delivery below the stated threshold is allowed). Record which rule applies in the goal and the inspector. A local sensor and a remote receiver are separate goals even when they share a source.
- **Send.** All goals on these levels must hold on the same committed arrangement and evaluation. A moved component updates the trace and readings. A completed attempt credits the solution for that arrangement.

### Cable types and path rules

Each level declares its available lead types, quantities, and routing features. Wireless paths and optical occlusion use their own material rules. For authored cable routes, use labelled corridors and feedthroughs with deterministic paths. Cable previews and the evaluator must check the same segments.

| Lead type | Length and route | Authoring and debugging checks |
| --- | --- | --- |
| **Patch lead** | Uses the sender's reach. On open fixtures, length is the Manhattan distance between actual ports. On corridor fixtures, sum the lengths of the selected orthogonal segments. Ordinary corridors and open feedthroughs are legal. | Test exact reach and one step over. A detour around a wall can fail even when the ports are close on the grid. |
| **Shielded lead** | Uses the sender's reach, capped at 4 units. It can follow an ordinary corridor or a marked interference corridor. A labelled feedthrough is required at a wall. | Test a patch lead and a shielded lead on the same interference path. The patch lead fails with *Shielded lead required*. The shielded lead still fails beyond 4 units. |
| **Trunk lead** | Uses the sender's reach, capped at 6 units. It must use one straight, marked trunk run between its two endpoints. It may cross a wall at a marked trunk feedthrough. | Test a legal six-unit run, a missing feedthrough and a bent path. A passive trunk feedthrough leaves the original output's reach in force. |
| **All leads** | Each output supports one cable and each input accepts one cable. Crossings are independent. A cable carries the full delivery when valid. A relay starts a new cable leg at its own output. | Draw occupied ports and crossings clearly. A move can invalidate an existing cable. Keep its endpoints visible and report the blocked segment or measured length. |

An open board has no cable-routing obstacles. When a board has route constraints, declare every permitted corridor, waypoint, feedthrough, and branch junction. A cable may bend at corridor waypoints. A junction in the path is a bend or crossing point unless it is an actual powered component. A cable cannot split at a corridor junction. For the matching lead type, crossing a wall is legal only through an aligned opening or feedthrough declared by that fixture. Show the entire chosen route and its length before commit. Charge stock per installed cable, including an invalid cable that remains attached after a move.

Draw each lead leaving its output and entering its input in the socket’s facing direction. Round the bends and leave clearance around neighboring pins, including empty sockets. Keep any cable crossing and its overpass gap clear of the pins. On open boards, the drawn bends do not affect the port-to-port distance check.

The app uses a patch lead on an ordinary route and selects a specialty lead when the route requires one. A corridor preview shows the chosen lead symbol and length before installation. Inventory symbols show available and installed stock. The Parts guide identifies each symbol and explains its use. The evaluator still checks the type of every installed lead, including after a move.

E01–E03, E05, and E08 issue one patch lead each. E04, E06, and E07 list their stock in the level records. E18 issues three patch leads, one shielded lead, and one trunk lead. Its two ordinary feed legs use patch leads. E09–E17 and E19–E20 use light and radio without player-installed cables.

## Solution Stars

Award **one Solution Star per distinct winning route**, up to the fixture's verified count of one, two, or three. The first star completes the level and earns its mastery credit. Replaying a solved route earns zero additional stars. Every verified alternative stays available in replay. Show filled stars for earned routes and outlined stars for unearned routes. Display them on the entry square and in a small icon-only box overlaid inside the playing area’s top-left corner. In Hint, list each star with its earning condition below a rule separating it from the goal and instructions. Describe the required readings or constraints so the player can work out the wiring. The four-cable record in Night Lights is an [efficiency achievement](prd.md#achievements). Its trophy icon sits beside the stars and fills when earned.

Use stable solution IDs and store the set of earned IDs against the level and fixture revision. In Endless, award stars on the registered fixture. Keep random variant completion as ordinary replay or practice credit until that variant has its own authored star mapping. Repeated rooms, Undo, reset, and restarts must not duplicate credit. Save the earned ID with the solve and preserve it when reloading. When a fixture revision changes the solution set, map equivalent IDs explicitly and preserve legacy completion credit.

### What counts as distinct

A solution signature describes the paths that satisfy a required receiver or a required protection condition. Include the labelled receiver, active source, causal cable and beam branches, required mounts and headings, and any wall bypass or cable route whose geometry is part of the puzzle. Two routes can earn separate stars when they use materially different hardware, bypass different obstacles, or solve a different meaningful placement or power-allocation problem.

Collapse different move orders, redundant wiring and parked parts. Collapse exchanges of interchangeable part instances only when their ratings and role are identical and the exchange leaves the routes and labelled outcomes equivalent. Keep distinct cable types or corridors when they solve different path constraints. Include a device whose placement causally keeps a protected receiver quiet, even if it carries no accepted signal. Compare every proposed signature with a replay and verify its player-facing difference before granting a star.

## Level records

The count is the number of canonical solutions under the linked proof domain. Mounts, rotations, available parts, admissible leads and port limits are part of the search domain. Parts are fixed unless the entry names them as movable or selectable. Exact port coordinates and wall geometry must be recorded before a count is promoted to an app proof.

### Minimum component budgets

Issue the smallest set of components and leads that supports every registered route and teaching check. Give every device, including fixed sources, receivers and obstacles, a named job. A teaching comparison can justify a part when the required devices cannot show that distinction on their own. Reuse a target or change a setting wherever it demonstrates the same check. Apply this to variants and practice boards as well as the main line.

Remove each candidate spare from the fixture and rerun the replays and failure checks. Keep it only if removal loses a required goal, route, record or distinct teaching check. When testing a required receiver, keep its goal and check whether the remaining fixture can still satisfy it. Record the component and lead counts with the verified fixture.

| Playable level | Minimum fixture | Parts that justify the count |
| --- | --- | --- |
| E01 Antenna Test | 3 devices, 1 patch lead | The feed powers the broadcaster, and the antenna reads the hop. Moving the broadcaster provides the range contrast. |
| E02 Edge of Coverage | 4 devices, 1 patch lead | The feed, broadcaster and service antenna make the boundary solve. The channel-9 antenna isolates channel rejection inside coverage. |
| E03 Blind Corner | 3 devices, 1 concrete wall, 1 patch lead | One target measures the two equal-distance hops. The wall rejects one of them. |
| E04 Night Lights | 7 devices, 5 patch leads | One feed and three loads are common to both routes. The three-way serves the balanced route and four-cable record. Both two-ways and the fifth lead serve the cascade. |
| E05 Fading Signal | 3 devices, 1 patch lead | One feed, broadcaster and antenna show both sides of the strength threshold by changing the mount. |
| E06 Relay Shelf | 4 devices, 1 interference zone, 1 patch and 1 shielded lead | The relay makes two short legs possible. The interference zone requires a shielded lead on the second leg. |
| E07 Two Masts | 6 devices, 1 concrete wall with a trunk feedthrough, 2 patch and 1 trunk lead | The splitter gives each mast 60 u. The wall makes both masts necessary, and the distant mast needs the trunk feedthrough. |
| E08 Quiet Sector | 5 devices, 1 concrete wall, 1 patch lead | One mast must reach both target antennas. The protected antenna distinguishes screening from simple coverage. |
| E09 Corner Mirror | 1 laser, 1 mirror, 1 sensor and 1 baffle | The mirror supplies the required turn. The baffle shows a blocked beam from the other mount. |
| E10 Split Around the Baffle | 1 laser, 1 splitter, 1 mirror, 2 sensors and 1 baffle | The splitter powers two branches. The mirror turns the far branch and the baffle stops the lower turn. |

### Group path

The Endless group path lists **Signal Routing** as group **1**. Selecting it opens a separate path with boards numbered **1.1** through **1.20**. E02 **Edge of Coverage** is an optional branch off E01 **Antenna Test** because it reuses the two-mark fixture and adds a channel decoy. The main line goes from E01 to E03. E05 stays on the main line because it introduces attenuation as a solve constraint. E04 and E18 list different routes through their respective boards, so each has one entry on the line. All 20 sheets are playable.

### Coverage, cable reach, and fan-out

| ID and level | Fixture, goal, and intended route | Failure checks | Target |
| --- | --- | --- | --- |
| E01 **Antenna Test** | One patch lead, one channel-12 broadcaster, two marks, one receiver. Keep the feed legal at both marks. Accept at least 30 u. The inside mark is within four steps and the outside mark is beyond reach. | Unplug the feed and verify the receiver goes quiet. At the outside mark report out of reach. | **1**, Appendix A |
| E02 **Edge of Coverage** | Two broadcaster marks, reach 4, and a target and decoy on channels 12 and 9 respectively. Only the boundary mark puts the channel-12 target four steps away. It gets exactly 40 u. | Move one step farther from the target. Inspect the closer decoy and show its channel mismatch independently of range. | **1**, Appendix A |
| E03 **Blind Corner** | A concrete wall separates two in-range marks from a 35 u target. Both marks have valid patch feeds. The exposed mark sees the target around the edge. | Verify the same-distance blocked mark hits concrete. Remove the wall in a test fixture and verify both marks can win. | **1**, Appendix A |
| E04 **Night Lights** | A fixed 300 u source, one three-way, two two-ways, and three loads each accepting 75–150 u. Supply five patch leads. Valid routes are balanced three-way `100/100/100` and cascaded `150/75/75`. The balanced route earns the four-cable record. | Check the inclusive 75 and 150 bounds, that an unused output still takes its share, and that routing 100 u through a two-way yields a failing 50 u branch. | **2**, Appendix A |
| E05 **Fading Signal** | One 60 u broadcaster, two powered marks, reach 6, and a 40 u target. Marks are four and five steps from the same target. | Both paths are clear and inside reach. Read 40 u at four steps and 35 u at five. | **1**, Appendix A |
| E06 **Relay Shelf** | The mount that gives 40 u is five cable units from a source rated for four. Put the relay on the shelf where the first leg needs three units and the second needs four. Issue one patch and one shielded lead. The second leg crosses a marked interference corridor. | Direct cable fails on length. One alternate relay shelf makes a leg five units. A patch lead on the four-unit corridor fails on interference. Lose the incoming feed and the relay goes quiet. | **1**, app proof below |
| E07 **Two Masts** | Split channel 12 at 120 u into two 60 u mast feeds. A concrete partition gives each mast a different receiver. Fix one mast at distance 5 from a 35 u target. The other must use its distance-4 mark to meet a 40 u target. Route the fixed mast along an aligned six-unit trunk run through its feedthrough. Issue one trunk and two patch leads. | Wrong mark delivers 35 u at the 40 u target. Closing the trunk feedthrough cuts off only that mast. One mast alone cannot cover both receivers. | **1**, app proof below |
| E08 **Quiet Sector** | One movable mast and three powered marks. Two required receivers need at least 35 u. A same-channel protected receiver must be quiet. The close mark lights all three. The screened mark around the wall keeps both targets at 35 u or more. A third mark loses one target around the other edge. | Check the protected receiver's positive reading from the close mark. Check one target is screened on the third mark. Verify both goal readings separately on the winning mark. | **1**, app proof below |

### Mirror and optical splitter fixtures

| ID and level | Fixture, goal, and intended route | Failure checks | Target |
| --- | --- | --- | --- |
| E09 **Corner Mirror** | One 100 u laser and a rotatable mirror on two legal mounts. The mounts both intercept the ray. Only one lines up with the sensor's accepted approach on an unobstructed lane. | Wrong diagonal turns away. Wrong mount hits the baffle or misses the accepted sensor approach. Removing the baffle leaves the direction check active. | **1**, app proof below |
| E10 **Split Around the Baffle** | One laser, a splitter that rotates on its mount, and a rotatable mirror on two mounts. The straight exit reaches the local sensor at 50 u. The turned exit must use the clear lane and the mirror to reach the second sensor at 50 u. | With no split, only one target can receive light. Try every non-winning diagonal and both mounts. A route that gets 50 u into the back of either sensor fails. | **1**, app proof below |
| E11 **Both Faces** | Two opposing 100 u rays, one shared mirror with three mounts and two diagonals, and two 100 u sensors on opposite exits. Include a decoy mount that can satisfy one sensor. | Rotate on the winning mount and confirm both turn directions swap. Remove either incoming ray and confirm only its goal fails. | **1**, app proof below |
| E12 **Two Branches, Two Bends** | One rotatable splitter and two mirrors with two mounts each. Route both 50 u branches around opposite ends of a baffle. The two sensors have different accepted approaches. | Replace either mirror with empty space. Try placing both mirrors on the same branch. Check that exchanging identical mirror instances leaves one signature when the final geometry is identical. | **1**, app proof below |

### Mixed fixtures

| ID and level | Fixture, goal, and intended route | Failure checks | Target |
| --- | --- | --- | --- |
| E13 **First Conversion** | Split a 100 u beam. Local sensor needs 50 u. A mirror turns the other 50 u into a fixed converter, which delivers 30 u over a four-step hop. | Wrong mirror turn leaves converter at 0 u and the local sensor at 50 u. A five-step comparison fixture delivers 25 u. | **1**, app proof below |
| E14 **Mesh Window** | One local optical goal at 50 u and two converter marks lit by the other half of the beam. One launch lane is through mesh and the other through concrete at the same distance. Remote threshold is 30 u at four steps. | Swap the two wall materials and confirm the winning mount changes. A laser aimed directly at the mesh stops at the wall. | **1**, app proof below |
| E15 **Around the Shield** | Give one rotatable steering mirror and a converter three matched launch lanes to one remote receiver. The remote goal is 30 u from a 50 u optical input. The three-step lane hits concrete, the four-step lane passes mesh, and the five-step lane is clear. | Record blocked, 30 u accepted, and 25 u weak respectively. All distances must fit the emitter's reach. | **1**, app proof below |
| E16 **Split Twice** | Two splitters and a steering mirror. Feed two inspection sensors at 25 u apiece. Reserve one 50 u half for the four-step converter hop and its 30 u target. | A 25 u converter feed can deliver only 5 u at the remote target. A no-second-split arrangement leaves one inspection sensor quiet. | **1**, app proof below |
| E17 **Crossed Channels** | One splitter, two mirrors, and fixed channel-9 and channel-12 converters. Give each half a choice of mirror lane. The valid clear hops are four steps and deliver 30 u each to matching antennas. Use a competing lane into one of the required antennas to show wrong-channel rejection. | Swapping the converter channels rejects both targets. The competing five-step hop then reaches the correct channel with only 25 u. Remove shielding on the competing lane to check whether intended obstacles rule out an extra route. | **1**, app proof below |
| E18 **Service and Inspection** | Wire a 120 u source through a two-way to a 60 u load and a 60 u mast. The mast must deliver 40 u to the service receiver and stay below a 35 u guard trip. Switch to the optical view to split a laser between a local sensor and a converter reached through a mirror and emitting through mesh. Give the wired splitter its own mount for each mast feed: a four-unit shielded corridor, a straight six-unit trunk run, and a three-unit ordinary corridor. Keep the wired source and load in reach from all three mounts. | Isolate one wired and one optical failure. Exercise stock, the shielded distance cap, the trunk feedthrough and the ordinary corridor's clearance. Count different lead types on the same ordinary corridor as one solution if they have the same effect. Test all routes and mounts together for extra signatures. | **3**, app proof below |
| E19 **One Mirror, Two Windows** | Two opposing 100 u rays, shared two-sided mirror, and two converters fixed on opposite exits. Each radio hop crosses its own mesh window in four steps and delivers 80 u. Key each converter to its own laser and show both pairings on the board. | Any adjacent mirror mount misses both inputs. Wrong diagonal swaps sources and both converters reject the beams. Disable the source check in a test fixture and verify it admits the swapped solve. | **1**, app proof below |
| E20 **Dual Handoff** | Two opposing 100 u lasers, one rotatable 50/50 splitter each, one shared mirror on three marks, two local 50 u sensors, and two converters. Both four-step radio hops cross mesh and deliver 30 u. All four receivers must accept together. | Wrong splitter rotation drops its local goal. An adjacent mirror mark misses both converters. Wrong mirror diagonal must fail the pairing check, even when both converters still light. | **1**, app proof below and Appendix A |

## Verification and debugging

1. **Freeze the fixture.** Record level ID, revision, rule version, coordinate convention, exact port centres and reach, closed obstacle geometry, the legal ducts and feedthroughs, cable quantities, source IDs, start state, admissible mounts, orientations, and goals. Record legal edit rules such as one cable per socket and one part per mark.
2. **Enumerate the whole finite domain.** Try all legal placements, rotations, port pairs, lead assignments and permitted corridor paths. Bound a corridor search to simple paths within lead reach. Evaluate every feasible arrangement with the same evaluators as the game. All registered boards resolve from one arrangement. Verify winning replays from the real starting state. If edit order becomes part of a later puzzle, enumerate reachable states and relevant history for that board.
3. **Count canonical solutions.** Record assignments tested, raw wins, canonical signatures, tool and evaluator version, and the fixture hash. Attach a winning replay and readings to each signature. Test a duplicate replay, alternate move order, spare disconnected pieces and interchangeable parts to confirm they map as intended. A cap or timeout yields a partial result. Claim an exact count only after exhaustion.
4. **Prove necessity.** For each required mechanic freeze or remove its operative part and repeat the search. Record the goal that fails and the count. Use a deliberately successful test mutation when practical, such as adding one unit of reach to both failing paths, to show the check can detect an unintended solution.
5. **Debug from the route.** Record each cable's endpoints, type, corridor, measured length, limiting reach and first illegal segment. For light, record incident direction and branch strength at every optic. For radio, record source channel, emitted strength, range, distance, occluder and final reading. Compare these with each receiver's actual and required readings. Distinguish out of range, blocked, weak, wrong channel, and valid delivery in the inspector and test output.
6. **Release the verified count.** Require the exact intended number of signatures. If an unexpected fourth solution appears, inspect the replay and revise the fixture or its equivalence rules on their merits. Verify that each replay earns one star on first completion, none on repeat, and survives reload. Ship only the star count proved for that revision.

Proof record fields for the final fixtures are `level_id`, `fixture_revision`, `fixture_hash`, `evaluator_version`, `component_budget`, `search_domain`, `examined`, `raw_wins`, `solution_ids`, `replays`, `failed_checks`, and `status`.

## App fixture proofs · E01–E05

[The fixtures](lib/endless_boards.dart) start with no cables. All devices are anchored except the broadcaster on the radio boards. [The game evaluator](lib/signal_board.dart) uses actual socket coordinates. [The Endless tests](test/endless_test.dart) enumerate both mounts and both cable states on each radio board and all legal socket assignments on Night Lights. They replay the winning routes through the game controls and exercise the failure checks and saved credit.

The SHA-256 for the revision 1 fixture source is `cae9e6bb820e80894c4e3067b63ca8e79fd402d1978fffb6760398aba80bc751`. The evaluator source used for the proof has SHA-256 `dc94c607ace4464c0c2bc59811494cbffd856f438468dd997ad0490f2f87d77c`.

| Level and revision | Examined | Raw wins | Stable solution IDs | App replay |
| --- | ---: | ---: | --- | --- |
| E01 r1 | 4 | 1 | `coverage-boundary` | Feed the mast at `(2.5, 1.5)`. The test antenna reads 40 u. |
| E02 r1 | 4 | 1 | `coverage-boundary` | Feed the mast at `(2.5, 1.5)`. The service antenna reads 40 u at the coverage boundary. |
| E03 r1 | 4 | 1 | `around-concrete` | Feed the mast at `(2.5, 2.5)`. It clears the wall and delivers 35 u. |
| E04 r1 | 2,233 | 3 | `balanced`, `cascade` | Use the socket orders below. The three lights read 100/100/100 u or 150/75/75 u. |
| E05 r1 | 4 | 1 | `four-step-hop` | Feed the mast at `(2.5, 1.5)`. The service antenna reads 40 u. |

App coordinates increase right and down. All four radio boards issue one patch lead. The feed socket is at `(.87, 1.5)`, with reach 3. The mast input is .37 units left of its centre. E01, E02 and E05 start at `(1.5, 1.5)` and have a second mount at `(2.5, 1.5)`. E03 starts at `(2.5, .5)`, with a second mount at `(2.5, 2.5)`. All four channel-12 targets are at `(6.5, 1.5)`. The E02 channel-9 decoy is at `(1.5, 2.5)`. The E03 concrete segment is at x=4.5, from y=0 to 1.25.

Night Lights uses the app’s standard splitter sockets and five patch leads. Outputs are numbered by their internal zero-based index. The socket geometry admits the two registered routes and one redundant unpowered cable on the balanced route. A balanced solve with four installed cables earns the separate record.

| Device | Input | Outputs in index order | Reach |
| --- | --- | --- | ---: |
| Feed | — | `(.87, 1.5)` | 2 |
| Three-way | `(2.63, 1.5)` | `(3.37, 1.5), (3.29, 1.14), (3.29, 1.86)` | 6 |
| Two-way A | `(1.13, 3)` | `(1.87, 3), (1.79, 2.64)` | 4 |
| Two-way B | `(5.13, 3.5)` | `(5.87, 3.5), (5.79, 3.14)` | 2 |
| Light 1 | `(5.13, 2)` | — | — |
| Light 2 | `(7.13, 3.5)` | — | — |
| Light 3 | `(6.63, 4.5)` | — | — |

- **Balanced.** Wire the feed to the Three-way. Wire its outputs 0, 1 and 2 to Lights 2, 1 and 3 respectively.
- **Cascade.** Wire the feed to Two-way A. Wire A’s output 0 to Two-way B and output 1 to Light 1. Wire B’s outputs 0 and 1 to Lights 3 and 2 respectively.

The verified failures include unplugged feeds, out-of-range and wrong-channel receivers on E02, an in-range radio path blocked by concrete on E03, a sixth cable and a 50 u branch on E04, and a clear in-range 35 u hop on E05. Removing the E03 wall gives two winning mounts.

## App fixture proofs · E06–E10

The [fixture source](lib/endless_boards.dart) for revision 1 has SHA-256 `aed0de27daf29233ea21066483d5b0edc10367615f2c5400f59440e1a1a7b178`. The [wired evaluator](lib/signal_board.dart) has SHA-256 `ea05cc34dee67dbf0ef1df7edf29ddfc4effa9f5af8db1c80a821a5d013b96de`. The [optical evaluator](lib/optical_bay.dart) has SHA-256 `99bfb6d222c3f4db20cd3bb08c1c3e0fb8ea42a3861d63ac5d7f6c1cab081c46`.

The [exhaustive tests](test/endless_routing_test.dart) enumerate legal placements and every available lead type and destination from each output, including leaving the output open. They check one cable per socket, stock and corridor legality. A move can leave a formerly legal cable attached and unusable. Such a cable delivers zero and occupies stock, so removing it preserves the active route and cannot introduce a new winning signature on these fixtures. The optical search tries each legal mount and both diagonals per optic. The walkthrough also plays, saves and replays the fixtures through the game controls.

| Level and revision | Examined | Raw wins | Stable solution ID | Winning readings |
| --- | ---: | ---: | --- | --- |
| E06 r1 | 23 | 1 | `shielded-relay` | Service 40 u, relay and mast feeds 60 u each |
| E07 r1 | 16 | 1 | `trunk-fed-masts` | Local 40 u, Remote 35 u |
| E08 r1 | 6 | 1 | `screened-antenna` | North 35 u, West 50 u, protected 0 u |
| E09 r1 | 4 | 1 | `clear-turn` | Sensor 100 u |
| E10 r1 | 8 | 1 | `two-halves` | Local and Far 50 u each |

- **E06.** With y increasing down, the Feed output is at `(1, .75)`. Mount the relay at `(3, 2.12)` and the broadcaster at `(6.37, .75)`. The patch path bends via `(1.2, .75)` and `(1.2, 2.12)` into `(2.63, 2.12)` for 3 units. The shielded path leaves `(3.37, 2.12)`, bends via `(3.6, 2.12)` and `(3.6, .75)`, and reaches `(6, .75)` in 4 units. The interference zone spans x=4–4.75 and y=.4–1.1. The direct leg to the winning mount takes 5 units. The alternate relay shelf at `(2, 2.12)` also needs a 5-unit second leg. The parked relay starts at `(1, 3.5)` with no corridor. The other mast mark at `(5.37, .75)` yields 35 u.
- **E07.** Patch the Feed to the Two-way splitter. Mount Local at `(3.5, 1.5)` and patch it from splitter output 1. Connect splitter output 0 to Remote with the trunk lead. The run goes from `(2.37, 2.5)` to `(8.37, 2.5)` with a trunk feedthrough at `(5.5, 2.5)`. The wall spans y=0–5. The upper Local mount at `(3.5, .5)` delivers 35 u. Closing the feedthrough silences Remote while Local still receives 40 u. A bent patch corridor rejects the trunk lead.
- **E08.** Patch the mast and move it to `(1.5, 1.5)`. The wall at x=5 spans y=1.4–3.1. The close mark at `(1.5, .5)` leaks 35 u to the protected antenna. The third mark at `(4.5, 2.5)` loses North behind the wall. A 1 u leak on channel 12 also fails the protection rule. Channel 9 is outside the monitored channel.
- **E09.** With y increasing north, move the mirror from `(-2.625, -1.845)` to `(2.625, -1.845)` with the diagonal that turns eastbound light north. The sensor at `(2.625, 3.177)` accepts northbound light. The initial mount sends the northbound turn into the baffle. The opposite diagonal turns south.
- **E10.** Rotate the splitter at `(-2.625, -1.845)` to send one half north. Move the mirror to `(-2.625, 1.305)` and turn the branch east. The lower mirror mount at y=.255 sends the branch into the baffle. Reversing the approach of either sensor in the verifier gives 0 u at that sensor while the other still receives 50 u.

## App fixture proofs · E11–E20

[Fixture source](lib/handoff_boards.dart) for revision 1 has SHA-256 `93f6659291adf52ffdb3692703f51a34967097963be12174faf7fa5dc0ead960`. The evaluator snapshot comprises [optics and directional radio](lib/optical_bay.dart) at `99bfb6d222c3f4db20cd3bb08c1c3e0fb8ea42a3861d63ac5d7f6c1cab081c46`, [wired signals](lib/signal_board.dart) at `13e15bd9946ee14f80c7ceb2b359f9c12e1512ca1bee4b5ffc14c027990524d8`, and [radio loss](lib/radio_propagation.dart) at `df600f986e57a4bcf1b93979d1e86ff22af89ba91a50567e7c8d550bbae04ac3`.

The [fixture tests](test/handoff_test.dart) check each legal authored mount and rotation. A converter’s aperture and radio direction change with its mount. E18 combines every optical arrangement with all 32 legal wired states, counting open sockets and legal lead assignments. Invalid installed leads occupy stock and deliver zero. Removing one leaves its active routes equivalent. The landscape walkthrough plays all ten sheets from the Endless path and verifies replay, save and star credit.

| Level | Examined | Raw wins | Stable solution IDs | Winning readings |
| --- | ---: | ---: | --- | --- |
| E11 r1 | 6 | 1 | `shared-diagonal` | North 100 u, South 100 u |
| E12 r1 | 32 | 1 | `opposite-ends` | North 50 u, East 50 u |
| E13 r1 | 4 | 1 | `first-radio-hop` | Inspection 50 u, Remote 30 u |
| E14 r1 | 16 | 1 | `mesh-hop` | Local 50 u, Remote 30 u |
| E15 r1 | 36 | 1 | `four-step-lane` | Local 50 u, Remote 30 u |
| E16 r1 | 16 | 1 | `quarter-quarter-half` | North 25 u, East 25 u, Remote 30 u |
| E17 r1 | 32 | 1 | `matched-channels` | Channel 9 and 12 antennas 30 u each |
| E18 r1 | 128 | 5 | `shielded-service`, `trunk-service`, `ordinary-service` | Load 60 u, Service 40 u, Guard 30 u, Inspection 50 u, Remote 30 u |
| E19 r1 | 6 | 1 | `paired-windows` | Remote L and R 80 u each |
| E20 r1 | 24 | 1 | `paired-halves` | Local L and R 50 u each, Remote L and R 30 u each |

Optical coordinates use y increasing north. The two wired feed legs on E18 use y increasing down. The fixture source records the exact obstacles, apertures and starting arrangements.

- **E11.** Two lasers, one mirror and two sensors. Mount the mirror at `(5.5, 4)` in the east-to-north diagonal. The offset beams hit different points on its face. Moving to `(6, 4.5)` feeds North alone. Rotating at the winning mark misses both sensor apertures.
- **E12.** One laser, one splitter, two mirrors, two sensors and one baffle. Split at `(3, 2)`. Turn the straight half north at `(9, 2)` and the upper half east at `(3, 6)`. A turn from either earlier mount hits the baffle. Removing a mirror leaves its sensor dark.
- **E13.** One laser, one splitter, one mirror, one local sensor, one converter and one antenna. Turn the 50 u branch south at `(3, 5)` and then east from `(3, 3)` into the converter at `(5, 3)`. The antenna sits four steps east. The wrong mirror leaves Inspection lit and Remote quiet. Extending reach and moving the antenna one step farther yields 25 u.
- **E14–E15.** Each uses one laser, one splitter, one steering mirror, one movable converter, one local sensor, one antenna and two barriers. Feed the converter from the mirror at `(7, 3)` into its south mount at `(7, 1)`. The antenna is four steps north and the mesh passes the hop. E14’s west launch is also four steps and hits concrete. E15’s east launch hits concrete at three steps and its west launch arrives clear at 25 u from five steps. Swapping E14’s materials swaps its winning lane.
- **E16.** One laser, two splitters, one mirror, two sensors, one converter and one antenna. The splitter at `(3, 5)` divides the north branch for the two sensors. Turn the straight half south from `(8, 3)` to the converter. The mount at `(8, 5)` feeds the converter 25 u instead. Remote then measures 5 u.
- **E17.** One laser, one splitter, two mirrors, two converters, two antennas and one shield. Turn at `(8, 5)` toward converter 9 and at `(3, 7)` toward converter 12. The four-step hops each deliver 30 u. The five-step channel-9 path also reaches the channel-12 antenna, which rejects its channel. With swapped converter channels, antenna 9 rejects channel 12 and the remaining matching signal at antenna 12 is only 25 u.
- **E18.** The wired view has six devices, an interference zone, a concrete wall with a trunk feedthrough, three patch leads, one shielded lead and one trunk lead. Patch Feed to the splitter and output 1 to Load. The mast takes output 0 from one of three mounts. At `(4.76, 2.5)`, use the four-unit shielded corridor via x=7.5. At `(1.76, 3.5)`, use the straight six-unit trunk run through `(4, 3.5)`. At `(4.76, 3.5)`, use the three-unit ordinary route. The optional shielded lead on an ordinary leg adds no distinct route. The optical view uses E13’s parts and route plus a mesh screen. An open wired leg, missed converter aperture or guard reading of 35 u fails the joint solve.
- **E19.** Two lasers, one shared mirror, two keyed converters, two mesh windows and two antennas. Mount the mirror at `(5, 4)` and turn L north to converter L and R south to converter R. Both 100 u feeds reach their remotes at 80 u. On the other diagonal the converters see 100 u from the wrong lasers. Removing the key requirement admits that swapped route.
- **E20.** Add two splitters, two local sensors and two baffles to the E19 pairing. Turn the left splitter north and the right splitter south. Keep the shared mirror at `(5, 4)` on the same diagonal as E19. Either wrong splitter turn blanks its local sensor, and either adjacent mirror mark loses both remotes. The wrong mirror diagonal still delivers 50 u to both inputs, which reject the swapped lasers.

## Appendix A · Exhaustive reference fixtures

These are small, runnable reference models for seven boards. Counts apply to the domains below. An app fixture reaches proved status when its committed edits and app evaluator reproduce these results. Fixtures E01–E05 use open cable boards. Receiver threshold and radio reach are inclusive.

| Fixture | Search run | Distinct wins |
| --- | --- | --- |
| E01, E02, E03, E05 | 4 arrangements each | 1 each |
| E04 | 2,179 legal arrangements, 4 wins before removing redundant cables | 2 |
| E06 | 162 lead, destination, and mount assignments before legality checks | 1 |
| E20 | 63 mount and orientation arrangements | 1 with source pairing, 2 when source pairing is disabled |

### Radio marks E01, E02, E03, and E05

Each fixture has one source at `(0,1)`, output reach 3, one patch lead, and a broadcaster whose input is at the chosen mark in the point model. The point is also its radio origin. The fixed target is at `(6,1)`, channel 12. Check both disconnected and connected states at each mark.

| Level | Broadcaster marks | Power / reach / minimum | Barrier and decoy | Winning state |
| --- | --- | --- | --- | --- |
| E01 | `(2,1), (1,1)` | 60 / 4 / 30 | Open | `(2,1)`, 40 u |
| E02 | `(2,1), (1,1)` | 60 / 4 / 40 | Channel-9 decoy at `(1,0)` | `(2,1)`, 40 u |
| E03 | `(2,2), (2,0)` | 60 / 5 / 35 | Concrete segment on x=4 from y=1.25 to 2.5 | `(2,0)`, 35 u |
| E05 | `(2,1), (1,1)` | 60 / 6 / 40 | Open | `(2,1)`, 40 u |

### E04 · Night Lights port map

Shift the entire map up one unit when using a nonnegative row grid. Every input is at the first coordinate on its row. Multiple coordinates in the output column are distinct sockets. Enumerate each output's disconnected state and every legal input within its reach. Reject double occupations, occupied inputs on the wrong device type, and cycles. Trace the 300 u source through physically present ports and classify the used causal paths.

| Device | Input | Outputs | Output reach |
| --- | --- | --- | --- |
| Source S | — | `(0,0)` | 2 |
| Three-way T | `(2,0)` | `(3,-1), (3,0), (3,2)` | 6 |
| Two-way A | `(1,1)` | `(2,1), (2,2)` | 4 |
| Two-way B | `(5,2)` | `(6,2), (6,3)` | 2 |
| Load L1 | `(5,0)` | — | — |
| Load L2 | `(7,2)` | — | — |
| Load L3 | `(7,4)` | — | — |

The balanced route is S→T, then T's outputs in order to L1, L2, L3. The cascaded route is S→A, A's first output to L1 and its second to B, then B's outputs in order to L2 and L3.

### E06 · Relay Shelf cable map

Fix the 60 u source at `(0,0)` and the radio receiver at `(9,0)` with a 40 u minimum. The broadcaster has reach 6. Its near mark N at `(5,0)` delivers 40 u and its far mark F at `(4,0)` delivers 35 u. Both the source and the relay have wired reach 4. Supply one patch and one shielded lead. The relay can be parked, on the good shelf, or on the short first-leg shelf.

| Connection | Allowed corridor via | Length | Interference |
| --- | --- | --- | --- |
| Source to N or F | Straight along y=0 | 5 or 4 | Crosses x=3 to 4 |
| Source to good relay input `(1,2)` | `(0,2)` | 3 | Clear |
| Source to short first-leg input `(0,2)` | Straight | 2 | Clear |
| Good relay output `(2,1)` to N or F | `(2,0)` | 4 or 3 | Crosses x=3 to 4 |
| Short first-leg output `(1,1)` to N or F | `(1,0)` | 5 or 4 | Crosses x=3 to 4 |

The listed corridors exhaust the allowed paths for each port pair. The winning route is patch to the good relay, then shielded to N. Swapping the types fails on interference. At F the radio reading is weak even when the cables are legal.

### E20 · Dual Handoff coordinates

Lasers L and R start at `(0,4)` eastbound and `(10,4)` westbound. Their splitters are at `(2,4)` and `(8,4)`. The local sensors are at `(2,7)` from the south and `(8,1)` from the north. Put light-only baffles at `(2,2)` and `(8,6)` to terminate the wrong local turns. The shared mirror can be placed at `(4,4)`, `(5,4)`, or `(6,4)` in either diagonal, or remain parked. Converters are at `(5,6)` and `(5,2)`. They accept a 50 u optical feed from the south and north respectively.

Both converters emit east on channel 12 with reach 4. Put mesh at `(7,6)` and `(7,2)` and the remote receivers at `(9,6)` and `(9,2)`. Each remote expects at least 30 u. **Key the north converter to laser L and the south converter to laser R.** This source check is essential. Without it, rotating the mirror swaps the beams and produces a second solve. Display the L and R icons on the lasers, converters, and inspector. Introduce the source pairing on E19 so the capstone reuses a known check.

The winning sequence turns the left split north and the right split south, mounts the mirror at `(5,4)`, and sets it to bend L north, R south. Both locals read 50 u, and the remotes read 30 u. The search tries both splitter orientations and a parked splitter state for each, both mirror diagonals at all three marks, and the parked mirror. A parked splitter leaves that local sensor dark.

### Reproduce the counts

From the project root, extract and run the reference verifier with Python 3. It has no external dependencies.

```sh
awk '/^<!-- BEGIN VERIFIER -->$/{on=1; next} /^<!-- END VERIFIER -->$/{on=0} on && !/^```/' endless-level-register.md | python3 -
```

<!-- BEGIN VERIFIER -->
```python
from fractions import Fraction
from itertools import product


def distance(a, b):
    return sum(abs(i - j) for i, j in zip(a, b))


def radio(origin, target, strength, reach, channel=12, wall=None):
    length = distance(origin, target)
    if length > reach:
        return "out of reach", 0
    if wall is not None:
        wall_x, bottom, top = wall
        x1, y1 = origin
        x2, y2 = target
        if min(x1, x2) < wall_x < max(x1, x2):
            crossing = y1 + (y2 - y1) * Fraction(wall_x - x1, x2 - x1)
            if bottom <= crossing <= top:
                return "blocked", 0
    if channel != 12:
        return "wrong channel", 0
    return "clear", max(0, strength - 5 * length)


def radio_marks():
    straight_marks = ((2, 1), (1, 1))
    corner_marks = ((2, 2), (2, 0))
    wall = (4, Fraction(5, 4), Fraction(5, 2))
    fixtures = (
        ("E01", straight_marks, 4, 30, None, (2, 1), 40),
        ("E02", straight_marks, 4, 40, None, (2, 1), 40),
        ("E03", corner_marks, 5, 35, wall, (2, 0), 35),
        ("E05", straight_marks, 6, 40, None, (2, 1), 40),
    )
    for level, marks, reach, minimum, barrier, winner, expected in fixtures:
        wins = []
        for mount, connected in product(marks, (False, True)):
            if not connected or distance((0, 1), mount) > 3:
                continue
            _, units = radio(mount, (6, 1), 60, reach, wall=barrier)
            if units >= minimum:
                wins.append((mount, units))
        assert wins == [(winner, expected)], (level, wins)
        print(f"{level}: {len(wins)} solution, 4 arrangements examined")
    assert radio((1, 1), (1, 0), 60, 4, channel=9) == ("wrong channel", 0)
    assert radio((2, 2), (6, 1), 60, 5, wall=wall) == ("blocked", 0)
    assert radio((2, 2), (6, 1), 60, 5) == ("clear", 35)
    assert radio((1, 1), (6, 1), 60, 6) == ("clear", 35)
    assert radio((1, 1), (6, 1), 60, 4) == ("out of reach", 0)


def night_lights():
    inputs = {
        "T": (2, 0), "A": (1, 1), "B": (5, 2),
        "L1": (5, 0), "L2": (7, 2), "L3": (7, 4),
    }
    outputs = {
        "S": (2, [(0, 0)]),
        "T": (6, [(3, -1), (3, 0), (3, 2)]),
        "A": (4, [(2, 1), (2, 2)]),
        "B": (2, [(6, 2), (6, 3)]),
    }
    sockets = [
        (device, index)
        for device, (_, points) in outputs.items()
        for index in range(len(points))
    ]
    options = []
    for device, index in sockets:
        reach, points = outputs[device]
        options.append([None] + [
            target for target, point in inputs.items()
            if target != device and distance(points[index], point) <= reach
        ])

    signatures = set()
    raw_wins = examined = 0
    for assignment in product(*options):
        attached = [target for target in assignment if target is not None]
        if len(attached) > 5 or len(attached) != len(set(attached)):
            continue
        incoming = {
            target: socket for socket, target in zip(sockets, assignment)
            if target is not None
        }

        def read(device, ancestors=()):
            if device in ancestors:
                raise ValueError("cycle")
            if device == "S":
                return Fraction(300), ()
            if device not in incoming:
                return Fraction(0), ()
            feeder, port = incoming[device]
            units, path = read(feeder, ancestors + (device,))
            units /= len(outputs[feeder][1])
            return units, path + ((feeder, port, device),)

        try:
            readings = {device: read(device) for device in inputs}
        except ValueError:
            continue
        examined += 1
        loads = tuple(readings[load] for load in ("L1", "L2", "L3"))
        if all(75 <= units <= 150 for units, _ in loads):
            raw_wins += 1
            signatures.add(loads)

    direct = (
        (100, (("S", 0, "T"), ("T", 0, "L1"))),
        (100, (("S", 0, "T"), ("T", 1, "L2"))),
        (100, (("S", 0, "T"), ("T", 2, "L3"))),
    )
    cascade = (
        (150, (("S", 0, "A"), ("A", 0, "L1"))),
        (75, (("S", 0, "A"), ("A", 1, "B"), ("B", 0, "L2"))),
        (75, (("S", 0, "A"), ("A", 1, "B"), ("B", 1, "L3"))),
    )
    assert signatures == {direct, cascade}, signatures
    print(f"E04: {len(signatures)} solutions, {raw_wins} raw wins, "
          f"{examined} legal arrangements examined")


def relay_shelf():
    leads = (None, "patch", "shielded")

    def accepts(kind, length, interference):
        return (
            kind is not None
            and length <= 4
            and (not interference or kind == "shielded")
        )

    # For each relay location and mast location, try the lead type at
    # both outputs and every source destination, including no cable.
    wins = []
    examined = 0
    for shelf, mast, destination, first, second in product(
        (None, "good", "short first leg"),
        ((4, 0), (5, 0)),
        (None, "relay", "mast"),
        leads,
        leads,
    ):
        examined += 1
        if (destination is None) != (first is None):
            continue
        if shelf is None and (destination == "relay" or second is not None):
            continue
        if destination == "mast" and second is not None:
            continue
        if first is not None and first == second:
            continue
        direct = destination == "mast" and accepts(first, mast[0], True)
        relayed = False
        if destination == "relay":
            input_length = 3 if shelf == "good" else 2
            output_x = 2 if shelf == "good" else 1
            output_length = 1 + mast[0] - output_x
            relayed = accepts(first, input_length, False) and accepts(
                second, output_length, True
            )
        if (direct or relayed) and radio(mast, (9, 0), 60, 6)[1] >= 40:
            wins.append((shelf, mast, destination, first, second))

    assert wins == [("good", (5, 0), "relay", "patch", "shielded")], wins
    assert not accepts("patch", 4, True)
    assert not accepts("shielded", 5, True)
    print(f"E06: {len(wins)} solution, {examined} candidate assignments examined")


def dual_handoff(require_source=True):
    # This axial layout only reaches the locals from their own splitters
    # and the converters from the mirror aligned in column 5.
    splitter_states = (None, "N", "S")
    mirror_states = [None] + list(product((4, 5, 6), ("N", "S")))
    wins = []
    examined = 0
    for left_split, right_split, mirror in product(
        splitter_states, splitter_states, mirror_states
    ):
        examined += 1
        left_local = 50 if left_split == "N" else 0
        right_local = 50 if right_split == "S" else 0
        if (left_local, right_local) != (50, 50):
            continue
        if mirror is None or mirror[0] != 5:
            continue
        sources = ("L", "R") if mirror[1] == "N" else ("R", "L")
        if require_source and sources != ("L", "R"):
            continue
        north = radio((5, 6), (9, 6), 50, 4)[1]
        south = radio((5, 2), (9, 2), 50, 4)[1]
        if north >= 30 and south >= 30:
            wins.append((left_split, right_split, mirror))
    return wins, examined


radio_marks()
night_lights()
relay_shelf()
wins, examined = dual_handoff()
assert wins == [("N", "S", (5, "N"))], wins
assert len(dual_handoff(require_source=False)[0]) == 2
print(f"E20: {len(wins)} solution, {examined} arrangements examined")
```
<!-- END VERIFIER -->
