# Dark Port · Product requirements

Revision 3 · 17 November 2026 · Based on Dominique Ferraz’s original PRD.

## Product

Dark Port is an offline landscape puzzle game for iOS and Android. Players route light, wired signals and radio through station equipment. A solve can bring an antenna online, open a latch or play an ordered set of notes. Players learn each rule by changing a fixture and reading the result.

**Endless is the current product and development focus.** It opens directly from the title screen on a fresh save. Ship authored puzzles in numbered groups, starting with Signal Routing. A group introduces a family of related mechanisms, gives each a chance to matter on its own, and then combines them in harder boards. The campaign comes later and will reuse the tested boards and components for the missing crew story, the Station Map and the station cycles.

**Current build.** The Tutorial has eight required lessons across Sealed Bay and Test Line plus the optional Four-way fan-out branch. Endless has a group path and a separate puzzle path for group 1. All 20 Signal Routing slots appear on that path. Levels **1.1–1.10** are playable with independent saves, replays and Solution Stars. Slots **1.11–1.20** are planned.

**Status.** *Playable* means the board or part is in the mobile build. *Planned* means it has an assigned slot and still needs authoring or integration. *Trial* means it has a reserved slot and a mechanism to test before it graduates to the playable path. Slot numbers identify positions in Endless. The deferred campaign uses its own chapter and board numbers.

Every board uses placement, orientation, wiring or configuration to make at least one component’s rule matter. Teach each new rule with anchored or prewired equipment, then ask players to use it under a meaningful constraint. Give the player a short objective and a diagnostic they can act on, whether the obstacle is a concrete shield, a cable detour, a wrong mirror diagonal or a signal that arrives too weak.

## Achievements

Open **Achievements** from the title screen. List every available achievement with its icon, condition and earned or unearned status. Board-specific achievements also appear beside the Solution Stars in a small box inside the upper-left of the playing area. An earned icon fills with the sheet’s stamp color. Tap it to read the condition and status.

Grant credit from committed play and read it from local progress. The starter awards use saved Endless completions, distinct route IDs and the four-cable record, so qualifying older saves receive credit on load. Undo, replay and starting a new Tutorial preserve earned Endless achievements. Keep criteria stable through fixture migrations. Add catalog entries when their qualifying events can be verified.

| Achievement | Kind | Condition | Status |
| --- | --- | --- | --- |
| First Signal | Progress | Solve any Endless puzzle. | Available |
| Both Routes | Mastery | Earn both Solution Stars in Night Lights. | Available |
| Four-Cable Record | Efficiency | Solve Night Lights with exactly four installed patch leads. | Available |
| Open the Bay | Tutorial | Complete The interlock with the Alarm live. | Planned |
| Signal Routing Complete | Group progress | Complete every main-line Signal Routing puzzle after the full group opens. | Planned |
| Carrier Handoff | Discovery | Complete an Endless puzzle that needs a successful optical-to-radio conversion. | Planned |
| Made to Fit | Workshop | Complete two distinct authored puzzles while using the same saved blueprint. | Planned |

## Endless mode

### Navigation and progress

- **Title → Endless groups → group puzzles → board.** Groups form a horizontally scrolling linked path of numbered squares. Selecting a group opens a separate screen with another linked path, using the Tutorial’s boxes, connectors and branch geometry. Group 1 opens **Signal Routing**. Group 2 joins the group path when it is added.
- **Numbering.** A square on the puzzle path uses the group and slot, such as **1.1** or **1.20**. Display the same number on the puzzle drawing. An authored variant keeps its own slot and branches from its parent back into the main path. Only a playable fixture can be opened. Group 1 shows its planned slots as locked.
- **Teaching order.** The main path goes from a demonstration to constrained applications and a capstone. An optional branch can reuse its parent’s mechanism with one change. A required level may assume only rules taught on the required path or in its own brief. For example, 1.2 can demonstrate channel rejection, while required boards that need channel matching must cue it themselves until the player meets Marked Sockets in group 2.
- **Standalone fixtures.** Issue required leads, parts and loaner blueprints in the puzzle. Give Dispatch Code its header and Dark Port its channel, header and optical targets in the brief or test panel. Keep these values and the solution checks aligned between the two uses of the fixture. Track campaign discoveries separately from Endless completion.
- **Saves and replay.** Use stable board and fixture revision IDs for saves. Save the latest committed arrangement and completion locally. A completed board reopens from its initial arrangement for replay. Preserve Endless progress when the player starts a new Tutorial. Add groups in app updates and keep prior progress and replays usable offline.
- **Solution Stars.** The first distinct winning route completes the board and earns a star. Each additional verified route earns one more, up to the proved count of one, two or three for that fixture. Show earned stars filled and unearned stars outlined. Display them on the entry square and in a small icon-only box overlaid inside the playing area’s top-left corner. Tapping them opens Hint, including after a solve. In Hint, separate the list of star conditions from the instructions with a horizontal line. A repeat solve leaves the star total unchanged. Different edit orders or unused parts are equivalent. Night Lights tracks its four-cable record separately. The [level register](endless-level-register.md#solution-stars) specifies canonical route IDs and revision migration.

### Slot catalogue

The six groups below assign the existing puzzle designs to Endless. Groups 2–6 are planned content. A Trial slot becomes playable after its rule and fixture pass the relevant checks. The detailed [Signal Routing register](endless-level-register.md) records fixtures, routes, exact acceptance checks and reference search results. The [former campaign board references](#board-references) give the detailed original fixtures used in groups 2–4.

#### Group 1 · Signal Routing

| Slot | Puzzle | Role |
| --- | --- | --- |
| 1.1 | **Antenna Test** | **Playable.** Power a broadcaster and move it inside reach of a receiver. |
| 1.2 | **Edge of Coverage** | **Playable.** Optional variant of 1.1. Boundary reach and a wrong-channel decoy. |
| 1.3 | **Blind Corner** | **Playable.** Route radio past a concrete wall’s edge. |
| 1.4 | **Night Lights** | **Playable.** Feed three loads through either of two verified routes. Earn a record by solving with four leads. |
| 1.5 | **Fading Signal** | **Playable.** Move inside the distance at which a clear hop still has enough power. |
| 1.6 | **Relay Shelf** | **Playable.** Extend reach through a relay and use a shielded lead on the marked interference corridor. |
| 1.7 | **Two Masts** | **Playable.** Split the feed between two broadcasters and use an aligned trunk run. |
| 1.8 | **Quiet Sector** | **Playable.** Reach two targets while keeping a protected receiver quiet on channel 12. |
| 1.9 | **Corner Mirror** | **Playable.** Find the mirror mount and diagonal that turn 100 u around a baffle. |
| 1.10 | **Split Around the Baffle** | **Playable.** Send 50 u to each of two directional sensors. |
| 1.11 | Both Faces | Steer opposing beams with the two sides of one mirror. |
| 1.12 | Two Branches, Two Bends | Route each half of a beam around a different end of an obstacle. |
| 1.13 | First Conversion | Use one optical branch locally and convert the other to radio. |
| 1.14 | Mesh Window | Choose the mesh launch lane. Concrete blocks the competing path. |
| 1.15 | Around the Shield | Choose a launch lane by testing obstructions and remaining strength. |
| 1.16 | Split Twice | Reserve a full half-beam for a remote receiver and divide the other half locally. |
| 1.17 | Crossed Channels | Steer light into the converters whose channel labels match their antennas. |
| 1.18 | Service and Inspection | Combine cable corridors with optical branches. Three routes are the design target. |
| 1.19 | One Mirror, Two Windows | Deliver opposing beams to their source-keyed converters. |
| 1.20 | Dual Handoff | Solve both local sensors and both remote receivers with a shared mirror. |

#### Group 2 · Wired Control and Workshop

| Slot | Puzzle | Former campaign reference or prerequisite |
| --- | --- | --- |
| 2.1 | Long Reach | Campaign 3.1. Isolate relay reach using a strength-preserving feed. Reinforces 1.6. |
| 2.2 | Switchboard | Campaign 3.2. Introduce the selector and Send. |
| 2.3 | Marked Sockets | Campaign 3.3. Match two wired channels across crossed routes. |
| 2.4 | Service Corridors | Campaign 3.4. Combine relay reach, keyed sockets and ordered selector sends. |
| 2.5 | Tone Check | Campaign 4.1. Match one note receiver with sound and visual feedback. |
| 2.6 | Build a Splitter | Campaign 4.2. Introduce the workshop primer and save a three-way design. |
| 2.7 | Vale’s Melody | Campaign 4.3. Use the three-way to light three note receivers together. |
| 2.8 | Key Check | Campaign 5.1. Test a latch that expects the KEY channel. |
| 2.9 | Build a Gate | Campaign 5.2. Build and test the keyed two-input gate. |
| 2.10 | Relay Archive | Campaign 5.3. Relay one authorisation, then run the gate output to the latch. |
| 2.11 | Cold Start | Optional variant of 2.10. Both input legs need relays. Issue a loaner gate. |

The wired selector and keyed sockets come before later Send and data boards. Night Lights at 1.4 teaches splitter choice with the supplied parts. A compatible design saved at 2.6 can be used on replay.

#### Group 3 · Data and Timing

| Slot | Puzzle | Role |
| --- | --- | --- |
| 3.1 | One Bit | Campaign 6.1. Distinguish an empty input from a delivered zero. |
| 3.2 | Pack Four | Campaign 6.2. Build a four-bit word in order. |
| 3.3 | Breakout | Campaign 6.3. Read the audit bit from the correct lane. |
| 3.4 | Dispatch Code | Campaign 6.4. Verify the supplied header and audit bit on successive sends. |
| 3.5 | Channel Converter | Change a word’s channel in line. Builds on 2.3 and 3.2. |
| 3.6 | Two Channels | Use a selector and a converter to deliver a word to exact-match receivers on two channels. |
| 3.7 | Packet Repeater | Inspect the two preserved copies of one packet. |
| 3.8 | Full Strength Copies | Use a powered repeater where a splitter would produce two weak branches. |
| 3.9 | Store and Forward | Store and release a word and read the retained contents of a full buffer. |
| 3.10 | Out of Order | Combine a buffered word and a direct send in a required arrival order. |
| 3.11 | Count the Arrivals | Count valid deliveries across an authored sequence of sends. |
| 3.12 | Split the Count | Send the right number of arrivals to each destination in one window. |
| 3.13 | Pulse Timing | Toggle a burst and step through a three-slot sequence. |
| 3.14 | The Quiet Slot | Deliver in slots 1 and 3 and leave slot 2 empty. |

#### Group 4 · Coherent Optics and Power

| Slot | Puzzle | Role |
| --- | --- | --- |
| 4.1 | In Step | Campaign 7.1. Change the delay and compare two output readings. |
| 4.2 | Two Paths | Campaign 7.2. Restore both legs to the merge. |
| 4.3 | Interlock Check | Campaign 7.3. Enable a transmitter using two optical conditions. |
| 4.4 | Frequency Check | Campaign 7.4. Set the source channel independently of its fixed word. |
| 4.5 | Dark Port | Campaign 7.5. Rebuild the optical route and send the supplied channel and header while Enable holds. |
| 4.6 | Two Antennas | Original optical bench challenge. Account for a bolted delay plate and split the useful output between two antennas. |
| 4.7 | Power Bench | Trial. Compare incident light on one rated mirror with and without an amplifier. |
| 4.8 | Door Cutting | Trial. Keep the mirrors within their limits while bringing enough light to the door. |

#### Group 5 · Radio Links

| Slot | Puzzle | Role |
| --- | --- | --- |
| 5.1 | Send and Receive | Change transceiver modes across a radio-only gap and read the recovered delivery. |
| 5.2 | Request and Reply | Reverse the direction of the radio link and send a reply on the same setup. |
| 5.3 | Radio Repeater | Feed a directional radio repeater and inspect both hops. |
| 5.4 | Around the Screen | Put a repeater by the opening in a shield to make both hops clear. |
| 5.5 | Long-range Link | Cross an unreachable gap using matched antennas and short local leads. |
| 5.6 | Local and Remote | Send down local and bridged branches with a selector. Feed a remote broadcaster. |
| 5.7 | Base Stations | Route a word between two local cells joined by a fixed link. |
| 5.8 | The Far Cell | Cover both local endpoints and leave a protected receiver out of the far cell. |

#### Group 6 · Quantum Benches

| Slot | Puzzle | Role |
| --- | --- | --- |
| 6.1 | Paired Signal | Trial. Bring both measured reports to a terminal and choose matching analyser bases. |
| 6.2 | Route the Reports | Trial application. Steer both classical reports to the comparison terminal without losing their trial IDs. |
| 6.3 | Which Path | Trial. Compare single-photon interference with and without path marking. |
| 6.4 | Delayed Comparison | Trial. Sort the same first-detector records by a partner report and compare the recombined totals. |
| 6.5 | Teleportation | Trial. Route the two classical result bits needed to apply the receiver’s correction. |
| 6.6 | Quantum Switch | Trial. Compare coherent paths that apply the same two operations in opposite orders. |

The playable Tutorial opening remains available from the title screen. Its boards also provide the foundation for Endless. The original **Bounce**, **Through the Wall**, **Share**, **In Step**, **Dark Port** and **Two Antennas** prototypes map to 1.9, 1.13–1.15, 1.10, 4.1, 4.5 and 4.6 respectively. Reference fixtures in Appendix A are tests and authoring examples for these slots.

## Build order

### Now · Signal Routing and an installed build

1. Playtest 1.1–1.10 on an iPhone and verify the same flow on Android. Watch whether players can distinguish a cabled feed from the wireless hop, recognise the coverage footprint and diagnose channel mismatch, concrete and radio loss. Include the lead symbols and route previews in 1.6–1.7, the protected receiver in 1.8, and the direction and power readings in 1.9–1.10.
2. Build 1.11–1.12 with the existing optical tools, and add the two-sided mirror as an instrument with one shared diagonal. Build 1.13–1.20 using the converter and both material rules. Test the source-pairing constraint at 1.19 before 1.20 uses it.
3. Prove each new fixture’s Solution Star count against the game evaluator. Keep a winning replay and failing near misses for each board. The game evaluators verify 1.1–1.10, including both routes through 1.4.
4. Validate the whole group from a fresh install and from an existing save. On iOS and Android test starting, resuming, solving and replaying, and reading a blocked, weak or mismatched route with sound and animation off.

### Next · More Endless groups

Build group 2’s wired parts and workshop, then group 3’s data and timing boards. Build group 4’s coherent fixture before adding its interlock and power trials. Group 5 reuses the radio and data foundations for two-way and multi-hop links. Start quantum benches only after the paired-report mechanics and relevant optical and data prerequisites can be tested.

Ship each group or playable slice with a beginning, a result and a replay. Verify that the new group joins the group path in order and existing saves reopen the same puzzle and earned credit after an offline update. Run a closed beta and prepare a store build around the Endless groups that pass their playtest gates.

### Later · Campaign and station cycles

Reuse the solved and tested fixtures. Add the opening, notebook and clues, then prototype power routing, room eligibility and a second station cycle. Validate the cycle as a game loop before connecting its story rooms. Deliver the crew rescue and finale as campaign progress. Keep Endless directly available from the title screen throughout.

## Core rules

These rules hold on every board. Groups introduce new parts while reusing these rules. Units are game units, written `u`.

### Boards, placement and editing

- A board has **anchored** parts, drawn with bolts, and **loose** parts. Drag a loose part to reveal placement dots, preview the nearest valid dot, and commit on release. A cancelled drag restores the start state. An in-progress drag is never saved and cancels when the app loses focus.
- Each committed move, rotation, flip, link, disconnect, setting change, send or reset is one command and one undo step. **Undo**, **Redo** and **Reset** are always available.
- **Minimum fixture.** Give every level the fewest components that support its registered goals, distinct routes, optional records and teaching checks. Apply this to fixed equipment, trays, variants and practice boards. Size any issued lead stock to those same requirements. Assign each part a role and reuse existing parts for comparisons wherever possible. Remove any part whose absence leaves every registered route and check intact. Record counts and roles in the [level register](endless-level-register.md#minimum-component-budgets).
- Every board ships with a winning replay and a test that the taught rule is necessary in the legal move space.

### When a board evaluates

| Mode | Used by | Behavior |
| --- | --- | --- |
| **On commit** | The Tutorial, Signal Routing 1.1–1.10, 2.1 Long Reach, and optics in Coherent Optics and Power | Every committed edit re-evaluates the route. Previews predict the result during a drag. A solved arrangement completes the board. |
| **On Send** | Fixtures that explicitly use Send. 2.2 Switchboard teaches ordered selector sends. | Edits change only the arrangement. **Send** evaluates once from the committed arrangement and applies its effects once. Each destination shows what arrived on the last send until the next edit or send. Inline readouts may preview the route before sending. |

Devices resolve their same-send inputs together and then deliver downstream. Ordinary boards reject cycles.

**Live lines.** A board with an alarm line starts with it powered. Every committed arrangement must keep it powered. Interrupting it fails the attempt even if the new arrangement meets every goal. Show a warning in the drag preview. On Test Line boards, loss controls disable unsafe settings, and unsafe disconnects and flips are rejected with a message. A committed interruption can be undone or reset.

**Sequences.** Some Send boards need two sends. Both must come from the same committed arrangement. Changing only the selector lever between them preserves progress. A route edit, a source value edit, Reset or an unexpected send clears it.

### Light

- A laser sends a 100 u ray in its authored direction. A ray travels straight until it meets a part, a baffle or the board edge.
- A **mirror** turns a ray 90° according to its diagonal and the incoming direction. Tap to change the diagonal.
- An **optical splitter** sends half the incident light straight and half along the turned direction.
- A **baffle** blocks any ray that strikes it and occupies space.
- A **light receiver** measures incident light from its authored approach only. Sealed Bay latches and the Alarm accept any reading above zero. Later sensors use a threshold or a dark condition.
- Independent rays cross without interacting. Draw a gap at the crossing.

**Coherent benches** (group 4) add phase, shown as a clock hand.

- The laser starts with its hand at 12. A splitter’s turned branch advances the hand one quarter-step. A **delay plate** adds zero to three quarter-steps. Mirrors add none. Path length does not affect phase.
- When two coherent rays meet at a splitter, amplitudes add at each exit. For equal contributions: aligned hands give the full sum, opposite hands give dark, perpendicular hands give half.
- In the balanced 100 u loop introduced at 4.1 In Step, the plate setting alone decides the two exits:

| Plate | Carrier sensor | Relay port |
| --- | ---: | ---: |
| +0 | 0 | 100 |
| +1 or +3 | 50 | 50 |
| +2 | 100 | 0 |

- With one leg missing, 50 u reaches the merge and each exit reads 25.

### Wired signals

A **delivery** has four fields. Each is checked and displayed separately.

| Field | Values | First matters in |
| --- | --- | --- |
| **Strength** | Units. Receivers accept an inclusive band, which may be an exact value. | Tutorial · Patch Lead |
| **Source** | The originating transmitter’s name. Some receivers require one source. | Tutorial · Keepalive |
| **Channel** | A label: `12` service bus, `9` spare corridor channel, `A` and `B` archive authorisations, `KEY` gate output, `7` private link. Keyed sockets accept one channel. | 1.2 Edge of Coverage; wired lesson at 2.3 Marked Sockets |
| **Payload** | Optional data with a declared width of one bit or four bits. | 3.1 One Bit |

- **Cables.** Tap an output, then an input. A cable joins one output to one input. Connecting to an occupied standard input replaces the old cable in one undoable edit. The alarm blocker needs an empty input. Report occupied output, invalid direction, out of range and cycle errors separately.
- **Reach.** Reach is the Manhattan distance between the two actual ports, limit included. Each sender has its own reach. Draw a reach diamond when a sender is selected. A cable that falls out of reach stays attached, is drawn dashed and delivers nothing. It delivers again, unchanged, when the ports return to reach. A rejected connection states the measured distance and the reach.
- **Flip.** Hold a part to mirror its ports left to right.
- **Strength arithmetic.** A wired splitter divides by its number of physical outputs, used or not. An attenuator subtracts its loss and delivers nothing at zero or below. A relay, a selector and a cable preserve strength. The alarm blocker adds its two inputs.
- **Payload.** A bit value of `0` is a valid arrival. A strength-only delivery has no payload. A missing delivery has no signal. A four-bit word keeps its leading zeros. Lane order is `b3 b2 b1 b0`, left to right. A relay and a selector forward the whole payload. A data-capable splitter copies the payload to every branch and divides the strength. Packer and unpacker hold no state between sends, and their output strength and channel are authored so data lessons can hold those values steady.
- **Diagnostics.** Every receiver states one of quiet, weak, strong, wrong channel, wrong source or accepted, in text, with current and target readings side by side. A connected mismatch stays visible for diagnosis.

```text
Packer inputs              One cable                  Unpacker outputs
 b3 b2 b1 b0       pack      channel 7        unpack     b3 b2 b1 b0
[0][1][0][0] ──────────────── [0 1 0 0] ──────────────── [0][1][0][0]
```

Optical beams and wired deliveries use separate evaluators. In group 4 the optical interlock drives the private transmitter’s **Enable** input. The optical-to-radio converter in group 1 uses accepted light as the strength of a directional radio transmission.

### Radio and cable corridors

- **Radio coverage.** The Signal Routing broadcaster covers a Manhattan diamond with an inclusive boundary. Radio within reach delivers `max(0, emitted units − 5 × grid distance)` on a clear path. Directional converter hops are straight and axial in this group. Compare range, material, channel and strength independently. Concrete stops radio and light. Mesh passes radio and stops light.
- **Patch leads.** Use sender reach. Measure from port to port on an open board and along the selected orthogonal segments on an authored corridor. Corridors, waypoints and wall feedthroughs belong to the fixture.
- **Socket clearance.** Lead each cable straight out of its output and into its input for a short distance, then round the turns. Route around neighboring pins, including unused ones. Keep any overpass gap away from the sockets. On open boards, use the same port-to-port distance for reach even when the rendered lead curves.
- **Shielded leads.** Use sender reach capped at four units. These can traverse marked interference corridors and labelled feedthroughs. **Trunk leads** use sender reach capped at six units and require a straight marked run with any wall crossing at an aligned trunk feedthrough.
- **Placement and feedback.** Count installed leads against stock. On boards with limited stock, show one inventory symbol per lead. Use solid symbols for available leads and dashed symbols for installed leads. The route determines the lead type. Use patch leads for ordinary routes and specialty leads where required. Show the matching symbol in the preview and explain every type in the Parts guide. Recheck length and each segment after a move. Show the first failed condition on a still screen. Teach cable types at 1.6 and 1.7, then offer distinct legal corridors at 1.18. The [Signal Routing register](endless-level-register.md#cable-types-and-path-rules) gives exact stock, constraints and checks.

### Interference wording and feedback

- A laser starts with its hand at 12. A turned branch from a splitter advances the dial by one quarter-step. A delay plate adds zero to three quarter-steps, and mirrors add none. Path length does not affect phase in this model.
- Describe **one output** of a splitter at a time. Equal contributions with aligned hands make that output brightest. Opposite hands make it dark when the contributions are equally strong. Perpendicular hands give half the brightness of the aligned case for that output. Show how the other output changes as the player turns the plate.
- Add amplitudes within the same coherent group. Add intensities across observer marks or separate incoming directions at a target. Radio travels straight and ignores light-only parts. Before introducing new source or radio-combining mechanics, define their behavior explicitly and test it.
- A quarter-step rotates the dial by 90°. A combined beam can have an intermediate angle. Show its actual angle, or show the incoming hands and measured outcome. When opposing contributions are unequal, describe the result as partial cancellation and show the remainder. Explain phase and intensity from the simulator’s output so the board, meters and text agree.
- Distinguish blocked, cancelled and unlit paths in the inspector. For marked light, pair the violet tint with a beam pattern and a text label. Give numerical and textual goal states even when the board animation is paused.

## Workshop and reusable tools

Blueprints are permanent local designs. Endless introduces the workshop at **2.6 Build a Splitter**. Its first visit uses a four-step primer. Pick a core, snap on a port, press Test to see the bench reading change, then press Save. **2.9 Build a Gate** uses the same controls. The future campaign can also add saved blueprints to the Station Map kit.

Players collect compatible cores and ports on the group’s workshop and challenge boards. In the workshop they choose a core, add the ports that give it its behavior and test the assembled tool with sample inputs. The inspector shows valid combinations, how many inputs and outputs the build has, and what it sends. A saved design appears in the player’s tool library. On a puzzle board, the player places a design from the library on a clear placement node and wires it into the route.

| Design | Assembly | Behavior |
| --- | --- | --- |
| Two-way or three-way signal splitter | Fan-out core, one input port and two or three output ports. | Sends the same channel on each connected output. Each output receives an equal share of the strength based on the splitter’s output count. An unused output dissipates its share. The number of outputs matters when a board constrains links, strength or tool size. |
| Two-input AND gate | AND core, two keyed input ports and one output port. | Sends **Key** on its one output when both inputs receive their required channels in the same transmission. Empty, duplicate or wrong channels leave the output quiet. |

The library stores designs as reusable blueprints. Equipping one does not consume it or its components, and the player can reuse it on compatible boards. Per-board component limits control how many instances a puzzle accepts. Components in the first prototype unlock assembly options once acquired. Give players the pieces for a required design before the first puzzle that needs it, with compatible loaner parts issued on the board. Workshop testing can be entered directly from an open puzzle and returns the player to the same arrangement.

Use the three-way splitter on **2.7 Vale’s Melody**. **1.4 Night Lights** supplies its anchored three-way and two two-ways for its two routes from the first attempt. Use the AND gate on **2.10 Relay Archive** and its two-relay variant **2.11 Cold Start**. Check blueprint reuse on both fixtures after reopening the app.

A saved fan-out design uses the stock splitter’s reach for its output count: six units with two outputs and four with three. The gate’s Key output has a reach of three.

## Notebook and discoveries

Endless can add the Rules and Replays pages as standalone references. Each puzzle’s first solve can record the rule it taught, using the readings from that puzzle. The future campaign adds Records and Roster. In its opening the player finds Vale’s notebook behind the Sealed Bay flap.

| Section | Contents | Written when |
| --- | --- | --- |
| **Rules** | One page per rule in Vale’s voice, with the numbers from the board that taught it. The entries are listed under each board in the [campaign board references](#board-references). | On that board’s first solve. |
| **Records** | The exact clues, as text and symbols that read with sound off. | On the capstone that reveals them. |
| **Roster** | The six names and their status. | Arrival. Updated at 2.5 and 7.5. |
| **Replays** | Every completed board, replayable from its saved fixture with no effect on the live station. | On completion. |

For the future campaign, the finale depends on the Records below. They persist across cycles, replay and board reset. Endless gives the relevant readings and inputs directly on each fixture.

| Record | Campaign source | Exact content | Campaign use |
| --- | --- | --- | --- |
| **Vale’s note** | Beyond the bay | “Keep the blocker live. Once Beacon takes over, use Pilot to call us on Service.” | 2.4, 2.5 |
| **The last roll call** | 2.5 Test Line | Six names answered. “Switch to the private channel. I’m taking us off the air.” Two taps on Service. | Motive for chapter 3 |
| **Calibration recording** | 4.3 Vale’s Melody | Private receiver: **channel 7**. Acknowledgement: **II · III · I**, drawn as three lamp positions in order. | 7.4, 7.5 |
| **Maintenance record** | 5.3 Relay Archive | Header **`0100`**. “Keep the relay port dark while the carrier sensor is lit.” The account of the fault. | 6.4, 7.3, 7.5 |
| **Dispatcher log** | 6.1 One Bit | The refused all-clears on the public line. | Story only |

## Component reference

Each entry gives the part’s rule and how to read it on the board. The campaign-reference column preserves the original chapter numbers. Use the [Endless slot catalogue](#slot-catalogue) for the current introduction and reuse order. Validate each new part in a lesson and a later application.

The sketches show a light path, a wired path and a directional radio hop. The data tiles show what the cable carries. On the board, every labelled input and output has its own hit area.

```text
Light        laser ━━━━━ ╱ mirror
                         ┃
                         ▼ sensor

Cable        transmitter ○──────○ receiver
Radio        antenna    ))) · · ·  antenna
Data         word source ○──[0 1 0 0]──○ matcher
```

### Optical parts

| Part | Status | Rule | Campaign board references | Reads as |
| --- | --- | --- | --- | --- |
| **Laser** | Playable | Fixed source. Sends a 100 u ray in its authored direction. On coherent benches its phase starts at 12 o’clock. | The only light source. Taught 1.1. Returns in all of chapter 7. | Aperture in a bolted housing, directional ray and `100 u` label. |
| **Mirror** | Playable | Turns a ray 90° by its diagonal and the incoming direction. Tap to change the diagonal. Preserves phase. | The player’s steering tool. Taught 1.1. Returns 1.2, 1.3, 7.2, 7.5. | Round mount with a diagonal face. Bolts mark the anchored version. |
| **Optical splitter** | Playable | Half the light goes straight, half turns. A loose splitter rotates like a mirror. | Makes two goals from one beam. Taught 1.2. Returns 1.3 and as the coherent splitter. | Divided face with straight and turned exits. Dimmer rays and readings show both shares. |
| **Light receiver** | Playable | Measures incident light from its authored approach. Latches and the Alarm accept anything above zero. Signal Routing 1.9 and 1.10 require exact power readings. | Every optical goal. Latch 1.1, Alarm 1.3, carrier sensor and relay port 7.1. | Slotted sensor, lit or dark, with reading and target. The telemetry names each latch and the Alarm. |
| **Baffle** | Playable | Blocks light and occupies space. | Forces a route around. Appears 1.3 and 7.5. In chapter 7 it proves that blocking is not cancelling. | Solid hatched barrier. Mark the stop at the face where a path is blocked. |
| **Delay plate** | Planned | Adds 0–3 quarter-steps of phase on a coherent path without changing the path. Bolted plates have an authored setting. | The one control that decides which exit is bright. Taught 7.1. Returns 7.3, 7.5. | Double ring with `+0` to `+3`. Show the phase hand and both outcome meters. |
| **Coherent splitter and merge** | Planned | Divides a ray into equal intensities and adds one quarter-step to the turned branch. Where coherent paths rejoin, amplitudes combine at each exit. | Turns the Sealed Bay splitter into the interferometer. Taught 7.1. Returns 7.2–7.5. | Splitter face with a coherence badge. At a selected merge, show the two incoming hands and each exit’s reading. |
| **Optical interlock interface** | Planned | Reads the carrier sensor and the relay port. Drives **Enable** while the carrier sensor meets its threshold and the relay port meets its dark condition. | Passes an optical condition to a wired source. Taught 7.3. Returns 7.4, 7.5. | Two labelled sensor inputs and an Enable output. The inspector states which condition is unmet. |

### Wired parts

| Part | Status | Rule | Campaign board references | Reads as |
| --- | --- | --- | --- | --- |
| **Cable and ports** | Playable | One output to one input within the sender’s reach. Preserves the delivery. Hold a part to mirror its ports. Crossings keep routes independent. | The connection gesture for the rest of the game. Taught 2.1. Flip taught 2.3. | Directional connectors and rounded leads. Live traces thicken and glow with delivered units. Fade near the reach limit, dash beyond it, gap at an overpass. |
| **Transmitter** | Playable | One output with an authored strength, channel and source. Beacon, Auxiliary and Pilot are fixtures. Pilot has selectable output loss. | Beacon is bulk power. Pilot is the one sender Service trusts. Auxiliary is the wrong-source foil. Taught 2.1. | Round sender with output dot, source name and strength. On keyed boards pair the channel with a shape. |
| **Receiver** | Playable | Checks channel, source and an inclusive strength band. Terminal, Recorder and Service are named fixtures. | Every wired goal. Readings at the loads also show failed attempts. Taught 2.1. | Slotted face with current and target readings. Quiet, weak, strong, mismatched or accepted in text. |
| **Signal splitter** | Playable | Two, three or four outputs. Each gets an equal share of the total by physical output count. Unwired outputs dissipate theirs. | Coarse strength control and fan-out. Taught 2.2. Returns 2.5, then as the workshop design in 4.3. | Multiport body with a fork and `½`, `⅓` or `¼`. Draw each actual port. |
| **Attenuator** | Playable | One in, one out. Subtracts 0, 10 or 20 and stops delivery at zero or below. On Test Line the inspector previews the blocker total per setting. | Fine strength control and the handoff throttle. Taught 2.3. Returns 2.4, 2.5. | Tapered body, stepped-down trace and a labelled loss control. |
| **Alarm blocker** | Playable | Adds strength on inputs A and B. Accepts 25–35 on channel 12. The capstone requires the final feed to come solely from Beacon. | The wired live line. It is what makes Pilot unavailable until the player earns it. Taught 2.4. Returns 2.5. | Two input dots with feed readings, a combined meter and the accepted band. Both source names during handoff. |
| **Relay** | Playable in 1.6 | One in, one out. Extends reach while preserving source, channel and strength. The data design also preserves payload. | Introduced in Relay Shelf. The campaign reuses it from 3.1. | Two aligned sockets and a forward chevron. Readings on both legs match. |
| **Selector switch** | Planned | One input, two attached outputs. Forwards the intact delivery through the selected output on Send. | One line, two destinations, in sequence. Taught 3.2. Returns 3.4, 6.4 and as the junction selector on the Station Map. | A/B lever with both cables visible. Selected leg marked in text and with a solid trace. |
| **Keyed socket** | Planned | Accepts only its labelled channel and reports a mismatch at the socket. | Makes channel a requirement. Taught 3.3. Returns 3.4, 5.1–5.3, 7.4, 7.5. | Number or letter with a matching shape on the socket and on the arriving pulse. |
| **Note receiver and audio terminal** | Planned | A note receiver accepts its matching feed. The terminal plays the authored sequence when all notes are fed on one send. | Carries the channel clue and the acknowledgement the player recognises in 7.4. Taught 4.1. Returns 4.3. | Note labels light individually. Ordered visual cue with replay alongside the audio. |
| **Keyed AND gate and Key latch** | Planned | A and B must arrive at their matching inputs on one send. The gate emits `KEY` on its own output. The latch opens on `KEY`. | The archive’s lock, and the model for Enable. Latch taught 5.1, gate 5.2. Returns 5.3. | Two labelled input indicators into an AND face and one Key socket. A separate latch indicator. |

### Workshop parts

| Part | Status | Rule | Campaign board references | Reads as |
| --- | --- | --- | --- | --- |
| **Fan-out core** | Planned | One input and two or three standard outputs. Produces the matching strength split. | The player’s first built tool. 4.2, used in 4.3. | Fork emblem with sockets that appear as ports are fitted. Bench values update with the port count. |
| **AND core** | Planned | Two differently keyed inputs and one Key output. Implements the same-send condition. | The second built tool. 5.2, used in 5.3. | AND face with an A/B position diagram. Preview missing and matched inputs. |
| **Standard and keyed port modules** | Planned | Attach to compatible core positions as inputs or outputs. A keyed input adds its channel condition. | Port count and keys are the design decisions. | Snap-in connector with an arrow, direction text and a channel shape when keyed. |

### Data parts

| Part | Status | Rule | Campaign board references | Reads as |
| --- | --- | --- | --- | --- |
| **Bit source and word source** | Planned | Emit one bit or a whole word on Send. Tap an editable tile to toggle it. A fixed source has an authored word. | Where the player enters the header. Taught 6.1. Returns 6.2, 6.4. | One tile or an outlined strip of tiles. |
| **Data display** | Planned | Shows the payload of the expected width when a valid delivery arrives, and an empty state otherwise. Keeps the last send’s result until the next edit or send. | Makes `0`, `1` and empty visible. Taught 6.1. Returns 6.3, 6.4 as the audit display. | `[0]`, `[1]`, `[0 1 0 0]` and an empty outlined socket with a text label. |
| **Four-bit packer** | Planned | Takes four one-bit payloads on one send, one per named lane, and emits one four-bit word in lane order. A missing or incompatible lane keeps the output empty. | Turns four choices into one cable. Taught 6.2. Returns 6.4. | Four labelled bit sockets into one four-cell strip. Every position stays visible when empty. |
| **Four-bit unpacker** | Planned | Takes a valid four-bit word and emits its bits on the matching labelled outputs. | Lets one lane be audited. Taught 6.3. Returns 6.4. | A four-cell strip fanning out to four labelled sockets. |
| **Exact-match data receiver** | Planned | Checks expected channel, width and bit pattern. An accepted delivery can operate a latch or dispatcher. | The dispatcher in 6.4 and the private terminal in 7.5. Taught 6.1 as the one-bit matcher. | Expected and received strips in parallel. Mark each differing bit and state the first failed check in text. |
| **Data-capable splitter** | Planned | Copies the full payload to each branch and divides strength by the wired splitter rule. | Not required by any campaign board. Implement and test it with the payload work so 3.7 Packet Repeater can contrast with it. | The same data tiles at each output beside its branch strength. |
| **Private transmitter** | Planned | A word source with a channel control and an Enable input. Sends only while Enable holds. | The finale’s single sender. Enable taught 7.3, channel 7.4. Used in 7.5. | Four-bit strip, separate channel badge and an Enable lamp beside the Send control. |

### Radio, power and other Endless parts

The slot catalogue assigns these parts to Endless fixtures. Test each planned rule with its lesson and application before shipping.

| Part | Stage | Mechanics | Visualisation |
| --- | --- | --- | --- |
| Baffle, concrete and mesh | Playable baffles and radio-blocking concrete. Mesh is planned. | The baffle blocks light and occupies space. In mixed fixtures, concrete blocks both light and radio and mesh blocks light while passing radio. | Solid hatched barriers and an open grid for mesh. Mark the stop at the face where a path is blocked. |
| Optical-to-radio converter and antenna target | Trial | Converts an accepted beam to a straight radio path in the authored direction. The antenna reports arrival. Radio ignores light-only parts and passes the mesh in its fixture. | Optical aperture joined to a radio glyph. Use a dashed radio path and a labelled antenna socket. |
| Observer or path marker | Trial | Makes marked and unmarked paths distinguishable. Classical targets sum their intensities across marks. The quantum fixture shows the corresponding loss of interference in its balanced setup. | Marker ring, labelled path pattern and violet accent. The pattern and text identify the mark with colour off. |
| Amplifier | Trial | Multiplies incident intensity by four and preserves phase in **Door Cutting**. | `×4` gain plate with incoming and outgoing light readings. |
| Rated mirror | Trial | Reflects as usual at up to 250 incident units. A reading above 250 fails the attempt in **Door Cutting**. | Mirror with a `250 u max` plate and an overload mark. |
| Power-rated door and side output | Trial | The door absorbs light and opens at 350 incident units or more. The side output reports residual light. | Door threshold meter and a separate side-output reading. |
| Broadcaster and wireless receiver | Playable in 1.1–1.3 and 1.5–1.8 | Broadcaster takes one wired input and transmits across a diamond-shaped Manhattan coverage area, inclusive of the boundary. Signal Routing subtracts 5 u per grid step. Protected receivers in 1.8 require zero delivery on the monitored channel. | Coverage diamond, dashed radio traces and receiver channel in the inspector. |
| Radio transceiver | Trial | **Transmit** takes a cable input and emits a directional radio hop. **Receive** accepts a directional radio hop and supplies a cable output. Each mode carries the same source, channel, strength and payload through the conversion. | Label Cable and Radio ports and show the selected mode and direction. |
| Radio repeater | Trial | Accepts a valid radio delivery and retransmits it in its set direction on the same send. The second hop starts at the repeater and uses its own reach. Source, channel and payload are preserved, with an authored output strength. Both hops must clear their path checks. | Two labelled radio legs with independent reach readings. Mark the leg that is blocked, out of reach or waiting for input. |
| Packet repeater | Trial | Accepts one valid wired payload and emits two copies through independent wired ports on the same send. Preserves source, channel and word. Each output has an authored strength and reach. | Show a single incoming word and two identical output words with distinct port readings. |
| Long-range bridge | Trial | A matched antenna pair transports an intact delivery across a fixed gap. Each side uses local wiring. | Matching antenna badges and a dashed hop between them. Each side shows its local connection state. |
| Base station | Trial | Receives local radio within a marked cell and hands it to a paired station over an authored backhaul. The receiver must be eligible in the far station’s own cell. Preserve the delivery across the link. The first fixture establishes one direction per send. | Show the two cell outlines, the distinct backhaul and each terminal’s coverage and channel status. |
| Channel converter | Trial | Accepts one specified channel and forwards the same payload, strength and source on another authored channel. | One labelled socket per side with a change indicator between them. Show both channel labels at once. |
| One-packet buffer | Trial | **Store** accepts one valid packet into an empty slot. Another Store while full leaves the existing packet in place. **Release** sends the stored packet into the connected route and clears the slot on a committed release. Reset empties the slot. | A one-slot register with Empty or Full and a readable saved word. Label Store and Release separately. |
| Arrival counter | Trial | Counts valid arrivals on its input across an authored number of explicit sends. One arrival counts once per send. Reset clears the window and count. | Count and target with one mark per accepted send. The inspector lists the arrivals in order. |
| Pulse source and timed receiver | Trial | On the timing bench, an enabled slot emits one burst on **Step**. The receiver records arrival or quiet for each numbered slot. The solve checks the ordered pattern and Reset clears the record. | Numbered slots show the authored pattern and the observed arrivals side by side. The player steps by slot at their own pace. |

### Quantum trial parts

| Part | Mechanics | Visualisation |
| --- | --- | --- |
| Pair source and single-photon source | Prepare a new pair or one simulated photon per trial. Pair members share a trial ID. | Source badge with the trial number and separate outgoing quantum paths. |
| Analyser and detector | Analyser selects the measurement basis. Detector records one local result per trial as a measured bit. | Straight/Diagonal labels on the analyser. A detector flash has a static `0` or `1` report beside it. |
| Comparison terminal and archive | Collect both reports by trial ID, identify missing reports and compare or sort existing records. | Two columns of detector reports with shared trial badges and matched totals. |
| Joint measurement and correction modules | In the teleportation fixture, the joint measurement produces two classical bits. The correction module uses them and the supplied entangled partner to recover the input state. | A two-tile report path drawn separately from the prepared-system path. Mark the selected correction. |
| Coherent operation modules | In the quantum-switch fixture, operations A and B apply in the order encountered along each prepared path. Recombination exposes the relative-phase outcome. | Label both paths with their operation order and show the detector result after recombination. |

### Signal paths and blockers

The route determines what can carry a delivery and what can stop it. Laser light and radio are both electromagnetic, with separate path rules in the game. A pulse is a brief burst that can travel along a path. Test Line’s travelling pulse shows where a live delivery flows. the 3.13 Pulse Timing trial gives individual bursts numbered send slots.

| Path | Stage | What determines arrival |
| --- | --- | --- |
| **Free-space light** | Playable | The ray travels straight between optics, turns at a mirror and stops at the bay’s baffle. A sensor must receive it from the authored direction. |
| **Wired signal** | Playable | A cable links specific ports within their reach. A connected cable can stop delivering when a part moves out of reach. Receivers apply their channel, source and strength checks to an arriving signal. |
| **Directional radio** | Trial | A hop must reach a compatible antenna along a straight line. A concrete shield stops light and radio in these fixtures. The mesh fixture stops light and passes radio. Display the material’s blocked paths on inspection and draw a stop marker where the hop meets a shield. |
| **Radio coverage** | Playable | A compatible receiver can be reached anywhere in the footprint, including the boundary. A direct radio path crossing the concrete shield in Blind Corner fails even inside the footprint. An antenna can be reached from an origin beyond the shield’s edge. |
| **Backhaul between stations** | Trial | A fixed pair carries an accepted delivery between two local radio cells. Inspect each local path separately from the fixed link. |

Keep medium, channel, payload and timing legible as separate properties. A wired-to-radio transceiver changes the path while preserving the message. A channel converter changes the channel while preserving the message and path type. A signal shield interrupts a path. The Test Line **Alarm blocker** is the name of the powered two-input safety receiver.

## Later Endless fixture designs

The lesson and application in each row have separate numbered slots. Use the prototype fixture to teach the rule before adding the application’s extra constraint. Each board gives the player its own objective, parts and feedback.

| Endless slots | New mechanic and first lesson | Application and progression |
| --- | --- | --- |
| **3.5–3.6 · Channel Converter** | Swap one authored channel for another at a converter while carrying the same word. Compare its input and output labels and payloads. | Send a word to exact-match receivers on two channels, one direct via the selector and one through the converter. Builds on 2.3 Marked Sockets and 3.2 Pack Four. The source stays fixed and an inline device changes the label. |
| **3.7–3.8 · Packet Repeater** | A powered repeater accepts one word and emits one copy on each of its two wired outputs at their configured strength. Compare both copies with the input word. | Feed two receivers that each need at least 35 units from a 40-unit data source. A two-way splitter gives each 20 units. The bench repeater gives each 40 and preserves the word. Builds on the data splitter and Test Line’s receiver bands. |
| **3.9–3.10 · Store and Forward** | Use a one-packet buffer to store a received word and release it later. Change the source word and try Store again while full. Read the original word in the slot. | Route the first word into the buffer, change the source word and switch outputs to deliver the second word directly, then release the first to complete an authored two-word sequence. Builds on Dispatch Code’s separate sends and adds storage across actions. |
| **3.11–3.12 · Count the Arrivals** | Send to an arrival counter over a small fixed window. Compare a quiet or wrong-channel send with a valid arrival. | Deliver a specific count to each of two destinations through a selector over a shared send window. Builds on Switchboard and same-send validation, with a result that depends on several sends. Recirculating networks are a research question for later. |
| **3.13–3.14 · Pulse Timing** | A pulse source has three numbered send slots. Toggle a slot to emit one burst and step through the slots to see when it arrives. | Send bursts in slots 1 and 3 to a timed receiver that requires slot 2 to stay quiet. Two arrivals alone are insufficient. Builds on Count the Arrivals by making the position of each arrival matter. |
| **4.7–4.8 · Power Bench** | A rated mirror fails above its incident-light limit. Start with one mirror and a fixed amplifier fixture. Compare the incident readings at the same mirror with and without the amplifier in the path. | **Door Cutting** uses a coherent split-and-rejoin fixture to keep each mirror within its limit while the door gets enough power. Builds on In Step’s redistribution between outputs. |
| **5.1–5.2 · Send and Receive** | Set a transceiver to **Transmit** to turn a cable delivery into a radio hop. Set its partner to **Receive** to recover the same delivery on cable. Inspect the channel and payload on both sides. | Wire a terminal on each side of a radio-only gap. Send a request across, then swap the two modes and send a reply. Builds on 1.13 First Conversion and 2.2 Switchboard’s separate sends. |
| **5.3–5.4 · Radio Repeater** | Place a repeater where the first radio hop reaches it. It retransmits the same delivery from its own location. | Place the repeater beside an opening in a shield so the two hops can go around the shield’s edge. The direct path is blocked even though it is within reach. Builds on Long Reach’s two-leg route and the barriers in 1.14 Mesh Window and 1.15 Around the Shield. |
| **5.5–5.6 · Long-range Link** | Route a delivery through a matched antenna pair with two short local cables. Observe the same channel, strength and payload across an otherwise unreachable gap. | Combine the bridge with a local broadcaster on the far side. Use a selector to test the local branch and bridge branch on separate sends. Builds on the one-output relay and the coverage set. |
| **5.7–5.8 · Base Stations** | A base station accepts an uplink from a terminal in its local radio cell and hands it to a paired station over a fixed link. The paired station delivers it in its own cell. | Place or select stations so the sending terminal and intended receiver each have local coverage. Keep a protected receiver outside the far cell. Builds on Radio Coverage and Long-range Link. The long-distance leg is fixed, so the puzzle depends on both local cells. |
| **6.1–6.2 · Paired Signal** | **Paired Signal** teaches paired reports and same-basis correlation on a fixed fixture. The player brings both measured bits to a comparison terminal. | Steer each report over an ordinary cable route and use the analyser settings to meet the correlation target. Builds on 3.1 One Bit’s `0` and `1` deliveries. Each follow-up introduces its own rule after a focused playtest. |

### Release and validation

1. For each numbered slot, record the new behavior, its prerequisite and one winning replay. Include a failure that isolates the new rule. Verify optional goals and run the fixture on a small phone with static diagnostics and sound off.
2. For radio, test an in-range hop stopped by a shield, a clear hop carrying too little strength, both directions of a transceiver link, a repeater missing its first hop, and a valid backhaul with one endpoint outside a cell.
3. For data, test missing, wrong-channel and valid arrivals. Verify both strengths and both copies of the packet on a repeater. Check that two pulses in the wrong slots fail the timing goal.
4. Bundle accepted fixtures and their replays in app updates. Give each fixture stable IDs and versions. Preserve older completed boards and earned credit through upgrades. A revision that changes a legal arrangement either migrates it or starts a fresh attempt with completion retained.

### Group 6 · Quantum bench prototypes

Vale’s optical bench teaches phase with classical beams. The quantum lab builds on that lesson with individual detection events, paired outcomes and records the player can route over ordinary station cables. Give the player an action to try, a result to compare and a short notebook explanation.

#### 6.1 Paired Signal and 6.2 Route the Reports

1. A **pair source** prepares one entangled pair per trial and feeds two analysers. Each analyser has two labelled orientations, **Straight** and **Diagonal**, representing the Z and X measurement bases. Each detector produces one local result, 0 or 1.
2. The player sets the orientations and wires both detector reports to a **comparison terminal**. The terminal pairs reports by trial number. It identifies a missing report and shows separate totals for each detector and for matched pairs.
3. For the authored Bell state Φ⁺, either detector on its own has equal probabilities of 0 and 1. With both analysers in the same orientation, paired results agree. With different orientations, all four pairs of outcomes are equally probable. Show the predicted distribution alongside a short, reproducible sample batch.
4. The goal is to bring both reports to the terminal and configure the analysers so paired results always agree in the ideal model. Completion checks the wiring and predicted correlation. The sample batch provides feedback and can be replayed. Once solved, the comparison terminal sends a calibration signal over a normal cable to unlock Vale’s lab note.

Changing one analyser alters what the two reports can reveal together. Each detector’s own 50/50 distribution holds across the other analyser’s settings, and the terminal learns the correlation when both records arrive over cables. Use a shared trial badge to identify a pair and animate only the physical paths and report cables. Matching outcomes in these two settings are a lesson about the authored state. A Bell test would need additional settings. [IBM on entangled states and measurements](https://quantum.cloud.ibm.com/learning/en/courses/basics-of-quantum-information/multiple-systems/quantum-information) · [IBM’s CHSH experiment](https://quantum.cloud.ibm.com/docs/en/tutorials/chsh-inequality)

**Playtest gate.** Verify the exact joint probabilities for all four analyser combinations, both local distributions, and terminal behavior with a missing or mismatched trial ID. Check that either matching orientation solves regardless of the sample drawn. Watch whether players can predict what changing one analyser does to the paired results and explain why the lab needs both reports.

#### Follow-up benches

| Effect | Puzzle to try | Builds on |
| --- | --- | --- |
| **6.3 Which Path** | Turn the familiar delay plate to steer detections to a target. Each simulated photon registers at one detector in the ideal bench. Add a path marker that makes the two routes fully distinguishable. In the balanced fixture, the two detectors then have equal probabilities for every delay setting. | In Step’s two output meters and Paired Signal’s distinction between an individual detection and the predicted distribution. |
| **6.4 Delayed Comparison** | Record the first detector’s hits, then choose how to measure the partner and route its report to the archive. One setting reveals path labels. The other lets the player sort the same first-detector records into two groups with complementary interference patterns. Recombine the groups to recover the unsorted totals. Keep the timeline visible so the player sees when the comparison becomes available. | The path marks from the preceding bench and Paired Signal’s requirement to match two reports by trial ID. |
| **6.5 Teleportation** | Supply an entangled pair, perform a joint measurement at the sender and route its two classical result bits to the receiver. The player’s route enables the receiver to apply the appropriate correction and restore the input state there. Teach this with four known correction outcomes before combining it with a wiring constraint. | Paired Signal’s separation of quantum paths and report cables, plus Data Deck’s ordered bit fields. |
| **6.6 Quantum Switch** | In an advanced bench, send two coherent paths through the same operations in different orders, A then B and B then A. Recombine the paths and inspect which detector fires to identify the relative phase. Use a known commuting pair and a known anticommuting pair as fixtures. | The split-and-rejoin geometry from In Step and the individual detections from the single-photon bench. |

Use separate port labels for quantum paths and detector reports. A workshop splitter can copy a measured report. Quantum paths carry the prepared system through the authored operations, and a fresh trial supplies a new preparation. [Which-path and erasure experiment](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.75.3034) · [Delayed-choice experiment](https://journals.aps.org/prx/abstract/10.1103/PhysRevX.10.021055) · [Quantum teleportation protocol](https://quantum.cloud.ibm.com/learning/en/courses/basics-of-quantum-information/entanglement-in-action/quantum-teleportation) · [Quantum switch experiment](https://www.nature.com/articles/ncomms8913) · [No-cloning theorem](https://quantum.cloud.ibm.com/learning/en/courses/basics-of-quantum-information/quantum-circuits/limitations-on-quantum-information)

### 4.8 Door Cutting · Power trial

Treat power and heat as game units. Show current value and threshold together. The source emits 100 light units. A ×4 amplifier preserves phase and multiplies intensity by four, which means doubling complex amplitude. The first splitter sends 200 units into each branch. In the pictured route, the two-quarter-step plate on the turned branch sends the full 400 units to the door at the second splitter and leaves the side output dark.

| Part | Rule for the prototype |
| --- | --- |
| Door | Opens at **350 units or more** of incident light. It absorbs the beam for this bench. |
| Rated mirror | Cracks **above 250 units** of incident light. Exactly 250 is safe. In this bench, only the two routing mirrors carry the rating. |
| Splitter | Uses the existing coherent rule. It has no heat constraint on this bench, so the first splitter can accept 400 units. |
| Side output | Displays its reading when inspected. Give it a threshold only if keeping it dark becomes a separate objective. |

While editing, the meters predict the result. Each committed edit evaluates the arrangement once and animates the result. Measure incident light on each rated part before it acts. A mirror overload fails the attempt even if the door also reaches its threshold in the same evaluation. Retain the arrangement for the next edit and update the result when the player commits a change. This first bench needs no elapsed-time heat buildup or persistent damage. Treat reachable recirculating light as an unsupported arrangement for this power prototype. Use an explicit cycle result so the existing path cutoff cannot silently determine a thermal outcome.

Acceptance examples for the pictured route, with the side output visible during inspection.

| Delay | Door | Side output | Each mirror | Outcome |
| --- | ---: | ---: | ---: | --- |
| 0 quarter-steps | 0 | 400 | 200 | Door closed |
| 1 or 3 quarter-steps | 200 | 200 | 200 | Door closed |
| 2 quarter-steps | 400 | 0 | 200 | Door open |

Add threshold tests at 350 and 250, immediately below and above each, and with a simultaneous door hit and mirror overload. Decide on any wider damage or timing model after the lesson is playable.

## Visual direction

Use the same drafting sheets, part symbols and type across Tutorial and Endless. Match the selected paper and symbol styles on both puzzle paths and on the board. The [current drafting references](art/reference/README.md) show the source artwork and representative playable sheets.

- **Drafting marks.** Use DINish Condensed for the sheet lettering, letter the grid along its upper edge, and use circled part numbers with thin leaders that match the parts list. Keep notes clear of ports, live paths and the in-board awards. Draw optical incidence arcs and clearance dimensions from the current layout. Mark rays leaving the board with an arrow. First Reflection uses a dash-dot centerline from the latch to the crossing beam. On wired sheets, label an inspected lead with the board’s jack-to-jack measurement in tiles. [DINish](https://github.com/playbeing/dinish)
- **Optical details.** On the Drafting sheet, a fixed mirror has a plain circular outline and a movable mirror has a dashed travel ring. Extend the reflecting face toward the circled part number where there is room, put a short axis mark on the free side of a reflection, and attach the laser’s leader to the edge of its casing.
- **Sheet finishes.** Paper, Aged paper, and Blueprint use the background gradations from their artwork references and lighter rules inside the sheet. Aged paper and Blueprint soften the printed ink and add subtle wear. Light uses a flat background.
- **Puzzle layout.** In landscape, center the viewport vertically with equal safe margins. Place the toolbar below the viewport’s midpoint, with live readings above and the title block beneath the toolbar and any cable stock. Keep the objective, Back, Hint and Parts guide available before and after a solve. Use the same Back to puzzles control throughout Endless. Show a separate Next lesson or Finish tutorial action when the player completes a required Tutorial lesson. Show the current and target readings with status icons. Show component symbols without names on the board. Retain exact wired readings beside the symbols and optical readings in the telemetry. Component names remain available to assistive technology.
- **Path strength and reach.** Show the units carried by each live segment through its thickness and glow. On wired boards, larger deliveries draw thicker traces and larger travelling pulses. Use a shared scale based on the board’s strongest rated transmitter so split and attenuated branches can be compared even as source settings change. Compress the scale to keep low-unit feeds visible. Continue to fade cables near the reach limit and draw out-of-range cables as neutral dashes. Use exact readings at devices for thresholds and retain thickness cues with reduced motion.
- **Sealed Bay.** Keep the laser, latches and anchored mirrors at their authored positions. Drag movable parts to the revealed placement dots and tap to rotate. Lay out the movable parts around the initial beam. Draw the straight rays on their actual approach and exit sides, with a bright, thick core at full power and visibly thinner, dimmer branches after each split. Leave a visible gap where independent rays cross. The telemetry shows received light in units relative to the 100-unit laser. A latch or alarm that needs light requires a reading above zero.
- **Test Line.** Foreground signals use coral for Beacon and pale gold for Pilot. The board starts with the Recorder above the three-way splitter and the Terminal to its right. The four-way splitter has two right-side outputs and one each at the top and bottom. Move the alarm branch into reach to route it below the main split.

## Mobile interaction and presentation

The group path, puzzle path and board are the current screens. Group 2 adds the workshop. The Station Map belongs to the later campaign.

- **Parts guide.** Open on **This puzzle**, with a symbol and short rule for each part type in the current fixture. Show **Optical**, **Wired**, **Radio** and **Cables** tabs as the player encounters parts in those categories. Opening a board reveals its parts even before the first edit. Save discoveries across Tutorial and Endless and retain them when the player starts a new Tutorial. Add a **Controls** tab for placement, rotation, wiring, readings, undo and reset as applicable.
- Give each optic a generous hit area independent of the painted block. Tap a movable optic to rotate it and drag it to move it. Commit on a valid drop. A cancelled drag restores the start state and each completed move or rotation adds one undo step. On benches with adjustable delays, give the delay plate an explicit adjustment control.
- On signal boards, use tap-to-connect as the primary interaction. Show port names and current delivery in a device inspector. Give a selected cable a **Disconnect** action and keep **Undo** available for changes to wiring and tools. Give moving pulses a static equivalent with labelled links and receiver states. Pair melody playback with ordered visual cues and keep sound settings available from the board.
- In the later campaign the Station Map uses the wired board’s gestures: tap a door, then a feed socket, and drag kit parts to placement dots. Each room shows its name, band, current feed and state in text: dark, strong, weak, woken, restored or latched. Keep the front’s position and the restores left before its next climb visible. Expose the same rooms, readings and kit in a semantic list on a phone.
- Keep the brief short, use the freed space for a larger board, and show one selected part or merge readout at a time. Keep receivers and their states visible. When Clocks is on, prioritise the two incoming hands at the selected merge. Make the unlit exit visible with a dashed stub or icon when explaining cancellation.
- On a board with a delay plate, label it with two rings or a **+2** marker and show the predicted output during edits. Give the sensor an explicit reading or remove it from the default view. Show the solved-route explanation after a committed edit meets the goal. Put **Undo** within thumb reach and keep **Reset** separate from the progression action.
- Verify the densest board at phone scale. If selecting parts or destinations is error-prone, test zoom and tap-to-place. Give frequent controls platform-sized hit areas and test larger text, reduced motion, VoiceOver and TalkBack. Provide keyboard access and a semantic part list with placement controls for the board. [Apple game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls) · [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps)

## Technical direction

**Dart and Flutter for iOS and Android.** Use Flutter custom painting for the board and beams, with widgets for screens, controls, touch targets, receiver labels and the inspector. Keep the simulation in pure Dart. Bundle fonts, art, levels and audio locally. Use a versioned local save keyed by stable board and blueprint IDs. Pause decorative animation and audio in the background. [Flutter games toolkit](https://docs.flutter.dev/resources/games-toolkit)

| Layer | Responsibility |
| --- | --- |
| Simulation | Keep optical and network solvers deterministic and independent of rendering. The network evaluator returns delivery fields, payloads, paths and diagnostics. The optics solver returns beam segments, incident power, merge contributions and goals. Evaluate a send from one committed arrangement, then apply its station effects once. |
| Levels and solver | Define versioned board data with stable IDs, devices, initial positions, allowed moves, goals, hints and a winning fixture. Run the same solvers in the app and in Dart tests. Record the bounds of any search that tests whether a mechanic is necessary. |
| Campaign cycle and station · later | Generate the plan from a cycle seed and the player’s profile, built outward from a guaranteed line. Evaluate the Station Map with the wired evaluator, with rooms as devices. Apply the safing front as a pure function of committed commands. Persist the cycle separately from the profile. Check sampled seeds for every reachable mastery state in tests. |
| Game state | Apply link, disconnect, equip, move, rotate, delay, undo, reset and send as discrete commands. Store in-progress boards, blueprints, Endless results, route credit and settings locally. Give the later campaign its own discovery and story progress. Record the fixture version for each saved arrangement. Keep previews and animations outside saved state. Use saved blueprint versions for existing boards so later workshop edits cannot silently change their behavior. |
| Presentation and platform | Render a snapshot of state in Flutter. Expose receiver states, controls and the inspector through Flutter semantics. Keep storage and lifecycle calls separate from the simulation. |

The first device pass should include a small iPhone and a representative lower-end Android phone. Test first launch in airplane mode, crowded selection and placement, drag cancellation, short-screen layout, large text, background/resume, and restoration after process termination. For App Store review, ship the finished, self-contained game with enough content and polish to stand on its own. [Apple App Review Guidelines §4.2](https://developer.apple.com/app-store/review/guidelines/#minimum-functionality)

## Validation and measurements

- Start current playtests with 1.1 Antenna Test and add boards in slot order. In the first five-person session with the workshop, observe whether they can route a signal to a receiver, explain an unlit key, build a tool and recognise where it can help on a different board. Ask them to follow the note sequence with audio muted. Once the optical room is playable, ask them to predict how a new delay setting affects the relay port. Record completion, hint use and accidental edits.
- Test partial, incorrect and complete transmissions for each device. Verify that both latches and the alarm must be lit to release the bay, that the melody’s visual sequence matches playback, and that one or two wrong inputs cannot authorise the interlock. Replay the same saved tool on two distinct boards after reopening the app. Repeat the same checks when the campaign reuses the boards.
- For group 3, check an absent delivery, a delivery without a payload, `0`, `1`, a missing packer lane, wrong width and wrong channel. Round-trip all sixteen four-bit words through pack and unpack and verify that routing and splitting preserve bit order and width. Check that changing source values or wiring between the two Dispatch Code sends clears progress and that switching A to B preserves it. On the final board vary the channel, header and optical conditions independently.
- In the later campaign, regenerate a fixed seed and profile and compare the plan. For every reachable mastery state, sample seeds and check that each plan’s guaranteed line is accepted by the evaluator and that every story room becomes reachable. On the Station Map test both edges of a room’s band, a feed that reads strong until padded, a door just out of reach, a rewire that darkens a room with a board in progress, the front passing an unrestored room, an alarm trip that triggers a climb, and relaunch in the middle of a cycle. Verify that ending a cycle keeps the notebook, mastery, blueprints and latches and discards everything else.
- For every shipped bench, replay the registered winning configurations and check the minimum component budget by removing candidate spares one at a time. For lessons, test whether the taught behavior is necessary within the legal move space and inspect representative alternate wins for shortcuts. For a strength band, test both exact bounds, values just outside them, and a missing signal. Verify that each challenge’s optional goal is attainable. Record the assumptions and limits of any search.
- For an Endless group update, enter from a fresh save, finish a lesson and its application with loaner parts, then resume an older set after installing a new one. Compare progress and blueprint behavior before and after the update, including on an offline launch.
- Start with observations and manual records for the closed beta. Decide separately whether public-release measurement warrants event collection. Core play and saves work offline.

## Future campaign

The story, Station Map, and cycles are reserved for campaign development after the Endless work. The sections below preserve the mechanics, narrative and original chapter references for that phase.

### Story

#### What happened

The player never sees this as one block of text. It is the truth every scene, record and notebook page must agree with.

1. **The fault.** The station protects itself by *safing*: on an alarm it latches its doors and holds them until an all-clear arrives on the control line. A fault in the **public relay** began feeding the station’s own safing command back into that line. Every all-clear the crew sent came back as another safing command. The command is still going round the control loop. Each time it comes past, every door that is not held on manual power latches again, and the pattern of latched bulkheads is different each time. These are the station’s **cycles**.
2. **The last check-in.** When the doors first latched, Vale, the signals lead, made the last public check-in and left the bay’s optical panel on manual power for whoever came to investigate. *“If we go quiet, come to the bay. I left the light on.”*
3. **The roll call.** With doors re-latching behind them, Vale called the roll on the Test Line recorder. All six answered. Her last words on the public line were *“Switch to the private channel. I’m taking us off the air.”*
4. **The shutdown.** Vale isolated the public relay by shutting down the optical bench that feeds it. She pulled the bench’s mirrors and delay plate so it could not be relit by accident. That bench also supplies the carrier for the **private service link**, so the link went down with it. This is the deliberate shutdown the player uncovers.
5. **The refuge.** She led the crew to the shielded service refuge. Its hatch latches once under safing and then ignores the control line. It releases from inside only after a **verified all-clear dispatch** arrives on the private service link. The transmitter for that link is at the optical bench, outside the refuge. Someone outside has to send it.
6. **Two records.** The private link was built for a relay fault and its settings are deliberately stored in two places. The **calibration recording** holds the private receiver’s channel. The **maintenance record** holds the dispatch header and the optical condition that enables the transmitter. Vale left Pilot holding the Test Line alarm blocker, wrote the note beside it, and left her notebook behind the bay’s inspection flap.
7. **Arrival.** The player docks during the missed check-in. Inside the refuge, the crew can still press the test key on the Service bell line. That line carries a bare ring with no voice or data, which is why the first reply is two taps.

#### Cast and terms

| Name | What it is |
| --- | --- |
| **You** | The responder who docks after the missed check-in. Unnamed, never shown. |
| **Vale** | Signals lead and the sixth name on the roster. The PRD refers to Vale as she. Her notebook explains every rule in her voice. |
| **The crew** | Six people including Vale. Placeholder roster in roll-call order: Imre, Sato, Brandt, Noor, Quill, Vale. Only Vale’s name is fixed. Final names are a writing task before campaign recording. |
| **Safing** | The station’s protective response. Doors latch and hold for an all-clear. Sealed Bay’s Alarm and Test Line’s alarm blocker are the two places the player handles it directly: letting either line drop looks like a new fault and re-latches the room. |
| **Public relay** | The faulty station relay. Isolated, and it stays isolated at the end pending repair. |
| **Service bus · channel 12** | The local wired bus on the benches and corridors. Safe to use. Strength-only on Test Line, so it rings but cannot talk. |
| **Private service link · channel 7** | The isolated link to the refuge. Needs the channel from the calibration recording and the header from the maintenance record. |
| **Relay port** | The exit of the optical bench that feeds the public relay. It must stay dark. This is the dark port of the title. |
| **Carrier sensor** | The other exit of the same bench. When it is bright and the relay port is dark, the private transmitter is enabled. |
| **Refuge** | Where the six are. Sealed until the all-clear dispatch arrives. |
| **Cycle** | One pass of the safing command round the control loop. The station re-latches, the player returns to the bay and the rooms beyond Test Line are laid out afresh. |
| **Trunk** | The power network the player wires from Beacon to wake rooms on the Station Map. |

#### What the player learns, in order

Each beat answers one question and raises the next. The exact clue is always written to the notebook so the finale can be completed with sound off.

| When | The player sees | Question answered | Question raised |
| --- | --- | --- | --- |
| Arrival · planned | Six names on the roster, hiss on the headset, a sealed bay with a powered optical panel. Vale’s last check-in. | | Is anyone aboard? |
| 1.1 First reflection | A flap drops open. Inside is Vale’s notebook, open at a sketch of one beam branching into two. | | Why did she expect a stranger to need this? |
| 1.3 The interlock | Two bolts draw back. Beyond the bay: six headsets on their hooks, a warm bench, Vale’s note beside the blocker. | The crew left in order, not in panic. | Where did they go? |
| 2.5 Test Line | The last roll call. All six answer. Vale takes them off the air. You call on Service and two taps come back. | Someone is alive and listening. | Where is the other end of the Service line, and why only taps? |
| 3.1 Long Reach | A corridor relay wakes and places the taps beyond the next junction. | The reply is aboard and close. | What is past the junction? |
| 3.4 Service Corridors | The Station Map now shows what lies above deck 6: the **Refuge · sealed · awaiting all-clear dispatch** and the **Private link · offline · needs receiver calibration and maintenance record**. | Where the crew is and what is missing. | What do the two records say? |
| 4.3 Vale’s Melody | Vale’s calibration recording. The private receiver listens on **channel 7** and answers a good test with three notes, **II · III · I**. | The channel. | |
| 5.3 Relay Archive | Vale’s maintenance record. It shows the repeated safing command, the relay shutdown and the move to the refuge. It gives the dispatch header **`0100`** and the instruction **“Keep the relay port dark while the carrier sensor is lit.”** | What happened, the header and the optical condition. | How to send a dispatch that the relay cannot hear. |
| 6.1 One Bit | The dispatcher log lists the crew’s refused all-clears. Each was sent on the public line and came back as a safing command. | Why the public line cannot be used. | |
| 6.4 Dispatch Code | The dispatcher accepts the header and arms the private line. The Optical bench can now appear on a plan. | The header is right. | Can the link come up without waking the relay? |
| 7.1 In Step | With both paths still lit, the relay port goes dark as the carrier sensor brightens. | A port can be dark without being blocked. | |
| 7.4 Frequency Check | The local test set answers channel 7 with **II · III · I** and stays silent on 12. | The channel is right. | |
| 7.5 Dark Port | The private terminal receives a live reply. Six IDs check in. Vale explains the fault and opens the hatch. | Everything. | |

#### Scene script

This is the planned campaign script. The playable tutorial uses teaching copy on the same puzzle fixtures.

| Scene | Status | Text |
| --- | --- | --- |
| **The silent station** (Arrival) | Planned | “You call the station as you dock. Six names on the crew roster, and only the hiss of your headset.” · “The bay is sealed. Its optical panel still has enough power to run the latch tests.” · “You replay Vale’s last check-in. ‘If we go quiet, come to the bay. I left the light on.’” · Action: **Inspect the panel**. |
| 1.1 solve | Planned | “The latch clicks. A flap drops open. Inside, Vale has drawn two arrows branching from a single beam.” Planned addition: the sketch is the first page of her notebook, and the Notebook tab appears here. |
| 1.2 solve | Planned | “Both test latches click. The panel switches to the live interlock. The lamp marked Alarm is already lit.” |
| 1.3 solve | Planned | “The alarm lamp holds steady. You hear two heavy bolts draw back.” |
| **Beyond the bay** | Planned | “Beyond the bay door, six headsets hang from their hooks. The test bench is still warm.” · “The Terminal and Recorder are dark. A single cable runs from Pilot to the alarm blocker. Vale has left a note beside it.” · “‘Keep the blocker live. Once Beacon takes over, use Pilot to call us on Service.’ — Vale” · Action: **Open Test Line**. |
| 2.5 solve · **The last roll call** | Planned | “The Recorder plays the last roll call. All six answer. Vale speaks last. ‘Switch to the private channel. I’m taking us off the air.’” · “You call on Service. Two taps come back through your headset.” |
| 3.4 solve | Planned | “Above the top deck, the map draws one more compartment. It is marked Refuge. Its hatch reads Sealed.” |
| 4.3 solve · **Calibration recording** | Planned | Vale, over three notes: “Private receiver, channel seven. If you hear this back, you have the right one.” |
| 5.3 solve · **Maintenance record** | Planned | “Relay returns our own safing command. Every all-clear comes back as an alarm. Bench shut down, relay isolated. Moving all six to the refuge. All-clear header zero-one-zero-zero, private link only. Keep the relay port dark while the carrier sensor is lit. — Vale” |
| 7.5 solve · **Ending** | Planned | Replay the two taps in the headset. Vale answers, “All six here. We’re opening the hatch from inside.” Show the six names from the arrival roster changing to **Safe**. The public relay stays isolated pending repair and the map marks the private route open. From here the player can return to the Station Map, replay a completed puzzle from the notebook, or open Endless from the title screen. |

**Story across cycles.** Beats fire once, when their story room is first solved, and their order is fixed by the conditions in **Station cycles**. The first echo arrives after the last roll call: the lights drop, the doors latch and the player is back at Test Line with Vale’s notebook still in hand. The public relay stays isolated after the ending, so the station can continue cycling while the crew repairs it.

**Where story appears.** The room brief gives a practical objective. The equipment gives feedback while the player works. On a committed solve, the latch, recording or terminal reveals the consequence. Use a short full-screen transition only at a physical move between rooms, such as Arrival and Beyond the bay. A replay shows the room’s discoveries again and leaves the station map and notebook untouched.

### Station cycles

This section defines how the game is structured. The story, the core rules and the components are unchanged. What changes is delivery: after a fixed opening, every cycle latches the station into a new plan, and the player brings it back by wiring power to its rooms with the same rules the puzzles use. Each room’s puzzle is chosen to fit what that player has already learned. Every number in this section is a starting value for tuning.

#### The idea: the station is the board

The Station Map is a wired board. Its devices are rooms.

- **Beacon** is the source: 300 u on channel 12, as on Test Line.
- **A room** is a receiver with a wake band. Fed inside its band, it wakes and the player can enter it.
- **A restored room** is one whose puzzle has been solved. It becomes a splitter: it divides its feed equally across its doors, used or not, exactly as a wired splitter divides across its outputs.
- **A door** is an output. Opening a door means cabling it to the feed socket of another room within reach.
- **Kit parts** are loose parts the player places between rooms: pads, relays and splitters, with the rules they have on any board.

There are no cards and no luck at a door. The whole plan is visible when the cycle starts, and the cycle is a routing problem the player solves in stages, one room’s puzzle at a time. A player who has finished Test Line already knows every rule the station layer uses.

```text
deck 2      Workroom 45–60          Archive 90–110
                 ▲ 50                    ▲ 100
deck 1      Corridor · 2 doors      Passage · 1 door      Supply 20–60
                 ▲ 100                   ▲ 100                ▲ 100 → pad −50 → 50
hub         Test Line · 3 doors ─────────┴────────────────────┘
                 ▲ 300
            Beacon
```

#### The loop

1. **The echo arrives.** The safing command comes round the control loop and every room beyond Test Line latches. The Station Map shows the new plan: which rooms exist this cycle, where they sit, their bands, doors and rewards.
2. **Route power.** The player cables the hub’s doors to rooms in reach and adds kit parts where a feed is too strong or too far.
3. **Enter a woken room and solve its board.** The room is restored. It pays out its reward and its doors go live.
4. **Extend the network** from the new doors, deck by deck.
5. **The cycle ends** when the safing front passes the top deck, when nothing more can be woken, or when the player chooses **Return to the bay**.
6. **Knowledge carries over.** The plan and the wiring are gone. The notebook, the tools and the player’s mastery are kept.

A cycle holds eight to twelve rooms and should take 10 to 20 minutes.

#### Station rules

These are the core wired rules at station scale. The station layer evaluates on commit, like Test Line.

| Rule | At station scale |
| --- | --- |
| **Strength** | Beacon supplies 300 u. The Test Line hub has three doors, so each carries 100 u. A restored room divides what it receives by its door count. |
| **Bands** | A room wakes only inside its band. A feed above the band reads **strong** and the room stays dark, so a narrow room close to the hub needs a pad or another split in front of it. |
| **Reach** | A door reaches three plan units and Beacon reaches four, measured port to port. A relay from the kit restarts reach. |
| **Rewiring** | Free and undoable at any time. A room that falls out of band goes dark and stops forwarding. Its board keeps its state for the rest of the cycle and it wakes again when its feed returns. |
| **Entering** | The player can enter any woken room from the map. There is no walking. |
| **Second sources** | A restored Supply room is a transmitter. Its door emits a fresh 60 u feed under its own name. |

Because strength divides at every restored room, the network cannot grow forever. Reaching a high deck with a strong feed means choosing a line of one-door rooms, spending the kit’s relay there, or restoring a Supply room on the way. That choice is the cycle.

#### The safing front

The echo does not latch the whole station at once. It climbs.

- The front starts below deck 1. After every three rooms restored, it climbs one deck.
- Any room on a deck the front has passed that is **not yet restored** latches for the rest of the cycle.
- Restored rooms keep forwarding. Nothing the player has finished is taken away.
- Tripping an alarm line inside a room counts as one restore toward the next climb. Undo, Reset and retries inside a board are free.

The front makes the player choose between restoring wide on the low decks for kit parts and going up while the upper rooms are still open.

#### Room types

Every room shows its type, wake band, doors, the packs its board uses with a tier pip for each, and its reward.

| Room type | Wake band | Doors | Board | Reward when restored |
| --- | --- | ---: | --- | --- |
| **Bench** | Self-powered | 1 | The lesson for one pack | Mastery 1 and the notebook page. Forwards whatever it is fed. |
| **Corridor** | Wide, 20–150 | 2–3 | An application of one pack | Its doors |
| **Passage** | Wide, 20–150 | 1 | An application of one pack | One door that forwards the feed undivided |
| **Workroom** | Narrow, such as 45–60 | 1–2 | An application or challenge, often two packs | A kit part for this cycle |
| **Supply room** | 20–60 | 1 | An application built around a transmitter | A fresh 60 u source at its door |
| **Brake room** | Narrow | 1 | A challenge | Holds the front for three more restores |
| **Workshop** | 20–60 | 1 | A build board | A permanent blueprint |
| **Story room** | Narrow and high, such as 90–110 | 1–2 | A fixed authored capstone | A record or a latch |

#### The kit

The kit is what the player places on the Station Map. A part enters the kit only after its pack reaches mastery 1, so the station layer never needs an untaught rule.

| Kit part | Source | Rule |
| --- | --- | --- |
| **Pad** | One per cycle once Loss is taught. More from Workrooms. | Subtracts 0, 25 or 50 u. |
| **Relay** | One per cycle once Relays is taught. More from Workrooms. | One in, one out. Restarts reach and preserves the feed. |
| **Stock splitter** | Workrooms. | A two-way. Divides by two, used or not. |
| **Blueprints** | Permanent, from the workshop. One of each per cycle. | The player’s own three-way and, later, other designs. This is why a workshop design matters in every cycle. |
| **Junction selector** | Permanent, from the Junction story room. | Replaces one hub door. Sends the hub’s whole feed down branch A or branch B on Send. The other branch goes dark and keeps its state. |

#### What persists and what resets

| Kept across cycles | Reset each cycle |
| --- | --- |
| The notebook: rules, records, roster, replays | The plan: which rooms exist and where |
| Mastery of each mechanic pack | All station wiring and room states |
| Workshop blueprints and the junction selector | Kit parts won from Workrooms |
| **Latches**, a short list of permanent station changes: bay open, Pilot free, junction online, dispatcher armed, refuge open | Board arrangements |
| The list of board variants already seen | The safing front |

The clue values are fixed for a save. Channel 7 and header `0100` are things the player knows, and knowing them is the progression.

#### How a plan is generated

A plan is built from the cycle’s seed and the player’s profile. The same seed and profile always give the same plan.

1. **Decks.** The story uses six decks. Deck 1 is nearest the bay. The refuge sits above deck 6 once the junction latch is set.
2. **Eligible rooms only.** A room can appear only if the player’s mastery meets every pack its board assumes.
3. **One new idea at a time.** At most one Bench per plan, and none while two or more packs sit at mastery 1.
4. **Tier by deck.** Decks 1–2 hold single-pack rooms. Decks 3–4 add two-pack rooms. Decks 5–6 add challenges and three-pack rooms.
5. **Built from a solution.** The generator first lays down a guaranteed line: a set of rooms, doors and kit placements that the station evaluator accepts using only the kit the player is certain to hold. It then adds optional rooms around that line. A plan is never shipped to the player unless its guaranteed line restores at least six rooms and reaches any story room that is due.
6. **Story.** A story room whose conditions are met appears on the next plan, on its deck, on the guaranteed line.
7. **Variety.** No board variant the player has seen in the last five cycles while an unseen one exists. No plan repeats the previous plan’s hub layout.

#### Mechanic packs

A pack is one mechanic, packaged so it can be added to the game without touching anything else. The campaign can draw its mechanic packs from tested Endless fixtures and Tutorial boards. Pack mastery supplies room eligibility in the later campaign. Endless groups use their own authored paths.

| A pack declares | Purpose |
| --- | --- |
| ID, version and name | Saves and updates |
| The rule and its notebook page | What is taught |
| Parts it introduces, and whether they join the kit | What enters trays, the kit and the component reference |
| Packs it assumes, each with a minimum mastery | When it may appear |
| One lesson, several application templates, several challenge templates | The three tiers |
| Room types that can host it | Where it appears |

**Mastery** is tracked per pack.

| Mastery | Reached by | Rooms now generated for that pack |
| --- | --- | --- |
| 0 · Unknown | | Its Bench, once its prerequisites are met |
| 1 · Taught | Solving the lesson | Applications |
| 2 · Practised | Solving two different applications | Applications combined with other packs, and challenges |
| 3 · Fluent | Solving a challenge | Everything, including its optional goals |

A room’s board is picked at the tier one above the player’s mastery, capped by the room’s deck. A two-pack board needs both packs at mastery 2. This is how the same room type gives a new player a gentle relay puzzle and a fluent player a tight one.

#### Campaign teaching packs and story rooms

The [board references](#board-references) describe the 27 campaign fixtures. The Tutorial supplies the opening. Groups 2–4 supply the later puzzle boards. Each lesson board becomes its pack’s lesson. Each capstone becomes a story room.

| Pack | Assumes | Lesson boards | Where it is taught |
| --- | --- | --- | --- |
| Mirrors | | 1.1 | Opening |
| Beam splitters | Mirrors | 1.2 | Opening |
| Live lines | Beam splitters | 1.3 | Opening |
| Leads and reach | | 2.1 | Opening |
| Wired splitters | Leads | 2.2 | Opening |
| Loss | Leads | 2.3 | Opening |
| Handoff | Loss, Live lines | 2.4 | Opening |
| Relays | Leads | 3.1 | Bench |
| Selectors and Send | Wired splitters | 3.2 | Bench |
| Keyed sockets | Leads | 3.3 | Bench |
| Notes and fan-out | Wired splitters | 4.1, 4.2 | Bench, then Workshop |
| Keys and gates | Keyed sockets | 5.1, 5.2 | Bench, then Workshop |
| Bits | Selectors and Send | 6.1 | Bench |
| Words | Bits | 6.2, 6.3 | Bench |
| Phase | Mirrors, Beam splitters | 7.1, 7.2 | Bench |
| Enable | Phase, Keys and gates | 7.3 | Bench |
| Channel dial | Keyed sockets, Words | 7.4 | Bench |

| Story room | Board | Appears when | Deck | Wake band | Pays out |
| --- | --- | --- | ---: | --- | --- |
| **Test Line** | 2.5 | Opening | Hub | | Latch: Pilot free. The last roll call. |
| **Junction** | 3.4 | Relays, Selectors and Keyed sockets at mastery 1 | 2 | 45–60 | Latch: junction online. The junction selector joins the kit and the refuge appears above deck 6. |
| **Calibration terminal** | 4.3 | Notes and fan-out at mastery 1, junction online | 3 | 90–110 | Record: channel 7 and the three notes |
| **Relay archive** | 5.3 | Keys and gates and Relays at mastery 1, junction online | 3 | 90–110 | Record: header `0100` and the dark condition |
| **Dispatcher** | 6.4 | Words at mastery 1, junction online | 4 | 45–60 | Latch: dispatcher armed. It can appear before the archive is found, but its board cannot be solved without the header. |
| **Optical bench** | 7.5 | Phase, Enable and Channel dial at mastery 1, dispatcher armed | 6 | 100–120 | The ending. It needs the laser’s full 100 u. |

The final cycle is the one where the player brings 100 u to deck 6 before the front gets there, knows both records and sends the dispatch. A hub door gives exactly 100 u, so that feed must arrive undivided, or the junction selector must swing the hub’s whole 300 u onto that branch and the player must trim it on the way up. The order of the story beats is fixed by these conditions even though the plan around them is different every time.

#### Teach mode

Teaching is a guarantee and a place.

- **The guarantee.** No board and no plan ever needs a rule the player has not been taught. The generation rules enforce it, and a campaign check proves it for every reachable mastery state.
- **The opening.** Sealed Bay and Test Line play in a fixed order on the Tutorial screen. Each lesson, including optional practice, opens with a guide bubble on the first visit. It explains the goal and relevant mechanics. Hint makes the same guidance available on later visits. The planned cycle zero introduces the fixed, prewired Station Map so the player can see how rooms wake in sequence.
- **The first three plans** teach the station layer one rule at a time, each reusing a Test Line lesson. Plan one needs only doors cabled within reach. Plan two has a room that reads strong until it is fed from a restored two-door room. Plan three needs the pad.
- **Benches.** After that, a new pack arrives as a Bench. It is self-powered, anchors everything except the new behavior and does not move the front.
- **Practice.** Use the published Tutorial and Endless slots for stand-alone play. The campaign can use an equivalent verified lesson solve as evidence for mastery 1 and credit story discoveries when their rooms are restored.
- **Replays.** The Tutorial screen offers replays of every completed lesson. Each replay opens a fresh board. The planned notebook extends this to solved campaign variants.

#### Post-rescue station play

After the rescue the station can continue cycling while the crew makes repairs. Reopening wings could expand this campaign loop using existing Endless fixtures as room boards.

- **Wings.** Each rescued crew member reopens a wing of the station, and each wing is a family of packs. The radio wing holds Radio Coverage, Through the Wall, Send and Receive, Radio Repeater, Long-range Link and Base Stations. The data wing holds Channel Converter, Packet Repeater, Store and Forward, Count the Arrivals and Pulse Timing. The power wing holds Power Bench and Door Cutting. Vale’s wing holds the quantum benches.
- **Growth.** A new pack ships in an update, appears as a Bench when its prerequisites are met and then joins the room pool. If it declares a kit part, that part joins the station layer too. Nothing else in the game needs to change. Campaign room eligibility and Endless group releases can grow independently.
- **Height.** Plans gain a deck for every wing reopened. With no final room, the goal is the highest deck restored. The game also records most rooms restored in one cycle and fluency per pack.
- **Conditions.** Past deck 6 a cycle may start with one condition that changes the economy, such as a 240 u Beacon or a front that climbs every two restores with richer Supply rooms.
- **Station-scale mechanics.** Later packs can bring their rule to the map as well as to boards. Keyed rooms wake only on a channel that another room exports. A broadcaster wakes every room inside its coverage diamond. Trial these only after the base station layer is fun.

#### Board templates and variants

A room that repeats the same board is finished after one visit, so every application and challenge is a **template** with several verified **variants**.

- **A template** fixes what the puzzle is: the parts in play, the tray, the goals and the rule that must be necessary.
- **A variant** fills in the numbers and the layout: strengths, bands, reaches, positions from an authored set, mirrored or rotated arrangements and channel labels.
- **Variants are made offline.** A generator proposes parameters and a solver accepts a variant only if it finds a winning replay, every must-not-pass case fails and the shortest solution length is inside the template’s range. Accepted variants ship as data with their replay. No board is generated on the phone.
- **Lessons and story rooms are single authored boards.** A lesson is a controlled demonstration and a story room is a set piece.

| Campaign prototype per-pack target | Count |
| --- | ---: |
| Lesson | 1 or 2 boards |
| Application templates | 3, with 8 variants each |
| Challenge templates | 2, with 6 variants each |

That is roughly 36 boards per pack from five templates. Across the ten packs taught in the loop it is about 50 templates to author, before generating and checking variants.

```text
pack    relays · v1
  assumes   leads ≥ 1
  parts     relay (joins kit)
  lesson    corridors.reach
  hosts     corridor, passage, workroom, supply

template  relays.two-legs · application
  fixture   feed (anchored) · lamp (anchored) · relay ×1 (loose)
  goal      lamp accepts feed strength
  must fail direct cable
  params    feed reach 3–4 · gap 5–7 · layout {a, b, c} × mirrored
  length    2–4 commands
```

#### What this needs from the code

- **The station layer reuses the wired evaluator.** A room is a new device kind: a receiver with a band that, once restored, forwards `strength ÷ doors` from each door. `SignalBoard.evaluate` already divides by output count, checks reach port to port and reports weak, strong and accepted. The Station Map is a `SignalBoard` whose anchored devices are rooms and whose loose devices are the kit.
- **Profile and cycle are separate saves.** The profile holds the notebook, mastery, blueprints, latches, variant history and the installed pack versions. The cycle holds the seed, the plan, the station wiring, each room’s state and board arrangement, the kit and the front. Ending a cycle discards the cycle save.
- **Boards are data.** The tutorial registry in `lib/tutorial.dart` defines the playable boards, teaching order and optional prerequisites with stable IDs. The optical and wired renderers use those definitions. A later campaign registry adds variant and mastery metadata and supplies the tested boards to cycle state.
- **Plans are generated on the phone, boards are not.** Plan generation is constructive and checked by the evaluator, so it needs no search.
- **Three checks run in tests.** Per variant: the replay wins and the must-not-pass cases fail. Per pack: its prerequisites form no loop. Per campaign: for every reachable mastery state, a sample of seeds each yields a plan whose guaranteed line is accepted, and every story room becomes reachable.

#### Risks to test first

1. **Is a second cycle fun?** This decides whether the later campaign uses the cycle structure. Prototype the station layer with six wired packs and grey-box rooms before building story rooms.
2. **Two puzzles at once.** The station layer sits on top of every room puzzle. If testers spend more time on the map than in rooms, cut plans to six rooms and widen the bands.
3. **Seeing everything may stall players.** If a full plan causes long pauses before the first move, show only the decks next to the front.
4. **The front may be one limit too many.** Strength division already ends a cycle. If players ignore the front, remove it.
5. **Content volume.** If the solver cannot produce eight good variants per template, cycles will repeat. Measure this on the Relays pack before committing to the counts above.
6. **A long opening.** Cycle zero is eight boards before the first choice. If testers stall, start the station layer after Sealed Bay and teach the Test Line packs as Benches.

### Board references

These 27 references preserve the original campaign fixtures and story beats. The eight opening fixtures are playable in the Tutorial. The 19 later fixtures have assigned Endless slots in groups 2–4. The campaign will reuse those boards as Benches and story rooms according to [Station cycles](#station-cycles). Numbers in this section are campaign chapter references.

The planned campaign begins with Vale’s last check-in and ends when the player makes contact with the six missing crew members. The Tutorial screen covers all eight boards in Sealed Bay and Test Line. The campaign reveals below describe the story version of those fixtures.

```text
Sealed Bay → Test Line → Service Corridors
                              ├─ Vale’s Melody ──┐
                              └─ Relay Archive ──┴─ Data Deck → Dark Port
```

This is the dependency order of the story rooms. The Junction puts the refuge on the map and lets both record rooms appear on later plans. Each record’s packs issue their own parts, so either can come first. The Melody gives the channel. The Archive gives the header and the optical condition. The Dispatcher’s board cannot be solved without the header. Data Deck uses the header. Dark Port uses the channel, the header and the optical condition on one send.

#### How a chapter ramps

1. **One new thing per board.** A lesson anchors or prewires everything except the new behavior. If a board needs a second new idea, it becomes a second board.
2. **See it, need it, combine it.** The player first makes one safe change that shows the rule. The board then cannot be solved without the rule. The chapter capstone combines it with earlier tools and adds nothing new.
3. **Every capstone moves the story.** Lessons reveal bench results. Capstones reveal a scene, a record or a room.
4. **The notebook gets the rule after the solve,** in Vale’s words, with the exact numbers the player just saw.

#### The ramp at a glance

| Campaign ref. | Board | Endless slot | Status | Evaluates | The one new thing | Leans on | Reveal |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1.1 | First reflection | Tutorial | Playable | Commit | A mirror turns a ray | | Vale’s notebook |
| 1.2 | A divided beam | Tutorial | Playable | Commit | A splitter halves a ray | 1.1 | Live interlock panel |
| 1.3 | The interlock | Tutorial | Playable | Commit | A live line must stay powered | 1.1, 1.2 | The bay opens |
| 2.1 | Patch Lead | Tutorial | Playable | Commit | A cable delivers only within reach | | Bench has power |
| 2.2 | Split Ratings | Tutorial | Playable | Commit | A wired splitter divides by its output count | 1.2, 2.1 | Both bench loads run |
| 2.3 | Bench Pad | Tutorial | Playable | Commit | An attenuator subtracts a fixed loss | 2.1 | Meter reads true |
| 2.4 | Keepalive | Tutorial | Playable | Commit | Two feeds add, so a live line can change hands | 1.3, 2.3 | Pilot is free |
| 2.5 | **Test Line** | Tutorial | Playable | Commit | Capstone | 2.1–2.4 | The last roll call, two taps |
| 3.1 | Long Reach | 2.1 | Planned | Commit | A relay restarts reach | 2.1 | Taps located past the junction |
| 3.2 | Switchboard | 2.2 | Planned | Send | A selector sends everything one way, on Send | 2.2 | Either corridor can be queried |
| 3.3 | Marked Sockets | 2.3 | Planned | Send | A keyed socket accepts one channel | 2.4 | The matching route is found |
| 3.4 | **Service Corridors** | 2.4 | Planned | Send | Capstone | 3.1–3.3 | Junction online, refuge on the map |
| 4.1 | Tone Check | 2.5 | Planned | Send | A note receiver answers in sound and in sight | 2.1 | Three note positions |
| 4.2 | Build a Splitter | 2.6 | Planned | Workshop | A tool is a core plus ports | 2.2 | Saved three-way design |
| 4.3 | **Vale’s Melody** | 2.7 | Planned | Send | Capstone | 4.1, 4.2 | Channel 7 and the three notes |
| 5.1 | Key Check | 2.8 | Planned | Send | A latch opens only for the KEY channel | 3.3 | Archive self-test passes |
| 5.2 | Build a Gate | 2.9 | Planned | Workshop | An AND gate needs both inputs on one send | 5.1, 3.3 | Saved gate design |
| 5.3 | **Relay Archive** | 2.10 | Planned | Send | Capstone | 5.2, 3.1 | Header `0100` and the dark condition |
| 6.1 | One Bit | 3.1 | Planned | Send | `0`, `1` and empty are three states | 2.1 | Refused all-clears in the log |
| 6.2 | Pack Four | 3.2 | Planned | Send | Four bits become one word in lane order | 6.1, 5.2 | Word format |
| 6.3 | Breakout | 3.3 | Planned | Send | A word can be split back into lanes | 6.2 | `b2` is the audit lane |
| 6.4 | **Dispatch Code** | 3.4 | Planned | Send | Capstone | 6.1–6.3, 3.2 | Private line armed |
| 7.1 | In Step | 4.1 | Planned | Commit | A delay plate moves light between two exits | 1.2 | A port goes dark unblocked |
| 7.2 | Two Paths | 4.2 | Planned | Commit | Cancelling needs both paths at the merge | 7.1, 1.1 | The bench Vale took apart |
| 7.3 | Interlock Check | 4.3 | Planned | Commit + Send | Two optical readings enable a transmitter | 7.2, 5.2 | Transmitter can run isolated |
| 7.4 | Frequency Check | 4.4 | Planned | Send | A transmitter’s channel is a setting | 3.3, 6.4 | Three notes come back on 7 |
| 7.5 | **Dark Port** | 4.5 | Planned | Commit + Send | Capstone | Everything | Contact |

Stable board IDs follow `chapter.board`, for example `bay.reflection`, `line.patch`, `line.capstone`, `corridors.reach`, `melody.capstone`, `archive.gate`, `deck.dispatch`, `port.capstone`. Tutorial saves use the stable IDs. The loader migrates the original Journey snapshots and keeps the Test Line arrangement while the player completes the prerequisite wiring lessons.

#### 1 · Sealed Bay

**Room brief.** The bay’s optical panel has power. Use its manual light path to open the door. **Issued:** nothing to carry. The fixed laser emits 100 u. Receivers respond above zero.

**1.1 First reflection** · playable
- **New rule.** A mirror turns a ray 90° according to its diagonal and the incoming direction.
- **Fixture.** Laser, one anchored mirror that demonstrates the turn, one loose mirror, one latch.
- **Player does.** Drags the loose mirror into the path and taps to rotate it until the beam reaches the latch. The traced path updates with each placement.
- **Solve reveals.** The latch opens a flap with Vale’s sketch of one beam branching into two. The Notebook tab appears.
- **Notebook.** *Mirrors.* A mirror turns the whole beam. Tap to face it the other way.

**1.2 A divided beam** · playable
- **New rule.** A splitter sends half the light straight and half along the turned path.
- **Fixture.** Laser, one loose splitter, one anchored mirror, Latch I and Latch II.
- **Player does.** Keeps the straight branch on Latch I and sends the turned branch through the anchored mirror to Latch II.
- **Reads.** 50 u at each latch.
- **Solve reveals.** The test latches click and the panel switches to the live interlock. The Alarm is already lit.
- **Notebook.** *Splitters.* Half goes on, half turns. Read the turned half like a mirror.

**1.3 The interlock** · playable capstone
- **New rule.** A live receiver must stay powered through every committed edit.
- **Fixture.** Laser, Alarm, Latch I, Latch II, a baffle, two loose splitters, one loose mirror.
- **Player does.** Keeps the straight branch of the first splitter on Alarm. Uses the other branch, the second splitter and the mirror to reach both latches around the baffle. Uses the preview before committing, and Undo or Reset after an interruption.
- **Reads.** 50 u on Alarm, 25 u on each latch.
- **Must not pass.** An arrangement that lights both latches after the Alarm has dropped.
- **Solve reveals.** Both bolts withdraw. **Beyond the bay** plays.
- **Notebook.** *Live lines.* The station reads a dropped line as a fault and locks down. Branch off a live line. Never move it.
- **Known exception.** This board also introduces the baffle. It is self-explanatory at the point of contact and the board is already tuned, so it stays.

#### 2 · Test Line

**Room brief.** The Recorder holds the last check-in. The Terminal is down, and the only transmitter that can call Service is busy keeping the alarm blocker live. Each bench issues the parts in its fixture below. Everything is on channel 12. All boards evaluate on commit.

**2.1 Patch Lead** · playable
- **New rule.** A cable carries the sender’s delivery only while its two ports are within the sender’s reach.
- **Fixture.** One loose bench transmitter, 100 u, reach 3. Lamp I is anchored and already cabled to the transmitter, 5 units away, so the lead is dashed and the lamp is quiet. Lamp II, the goal, is anchored further along and accepts 90–110.
- **Player does.** Drags the transmitter toward Lamp I. The dashed lead turns solid and Lamp I reads 100. Selects the cable and disconnects it, taps the output and then Lamp II’s input, and moves the transmitter into reach.
- **Reads.** Measured distance against reach on a rejected or dashed lead, for example “Needs 5 length units. Output reaches 3.” Lamp II shows 100 against 90–110.
- **Must not pass.** Any arrangement with the Lamp II lead beyond 3 units.
- **Solve reveals.** The powered indicator confirms the bench can carry a signal.
- **Notebook.** *Leads.* Plugged in is not the same as delivering. Count the squares between the two ports.

**2.2 Split Ratings** · playable
- **New rule.** A wired splitter divides strength by its number of physical outputs, even when some are unused. Each splitter type has its own reach: six, four and seven units for the 2-, 3- and 4-way.
- **Fixture.** Beacon, 300 u, anchored. One loose two-way and one loose three-way splitter. Load A accepts 90–110. Load B accepts 45–60.
- **Player does.** Compares the two-way’s 150 u and the three-way’s 100 u at Load A. Adds a second cable to the three-way and sees the first reading hold. Splits that second branch through the two-way and feeds Load B at 50 u.
- **Reads.** 100 at Load A, 50 at Load B.
- **Must not pass.** A two-way first gives 150, too strong for A. Wiring a 100 u branch straight to B also exceeds its band. The three-way must come first.
- **Solve reveals.** Both bench loads accept their feeds. These are the Recorder and Terminal bands of the capstone.
- **Notebook.** *Splitters on a wire.* Count the sockets, not the cables. An empty socket still takes its share.

**2.3 Bench Pad** · playable
- **New rule.** An Attenuator subtracts a fixed loss of 0, 10 or 20 units.
- **Fixture.** A 40 u transmitter at the right and a meter that needs exactly 30 at the left, both anchored. One loose Attenuator starts off the feed line with its output facing right. The in-line dot brings the flipped ports within reach.
- **Player does.** Holds the Attenuator to flip its ports, cables it in line, and steps the loss through 0, 10 and 20 to read 40, 30 and 20. Sets 10.
- **Must not pass.** The unflipped Attenuator cannot reach the meter from any legal dot. This is where **hold to flip** is taught, because the capstone needs it.
- **Solve reveals.** The meter confirms the fine adjustment needed during a handoff.
- **Notebook.** *Loss.* A splitter gives you a fraction. A pad takes off an exact amount.

**2.4 Keepalive** · playable
- **New rule.** The alarm blocker adds its two inputs, so a second feed can take over a live line in safe steps. A receiver can also require one specific source.
- **Fixture.** Alarm blocker, accepts 25–35. Pilot supplies 30 on input A, prewired. A 25 u Beacon test feed is prewired into an Attenuator set to 20 loss. Service needs exactly 30 from Pilot. Auxiliary also sends 30.
- **Player does.** Connects the Attenuator to input B, then alternates Pilot’s loss and the Attenuator’s loss until B holds the blocker alone, then disconnects A. The loss controls preview the blocker total and disable any setting that would leave the band. Then connects Pilot to Service and restores it to 30. Trying Auxiliary on Service reads “Needs Pilot”.
- **Reads.** Blocker total **30 → 35 → 25 → 35 → 25 → 35 → 25**. At the disconnect Pilot is at 10 and Beacon at 25.
- **Must not pass.** Disconnecting A while B is below 25. Auxiliary on Service. A solve with Pilot still on the blocker.
- **Solve reveals.** The blocker stays live as Pilot becomes available. The Service inspector names the source it needs.
- **Notebook.** *Handing over.* Bring the new feed up as you bring the old one down. The total never leaves the band. Some sockets only answer to one sender.

**2.5 Test Line** · playable capstone
- **Combines.** Splitter ratios, reach, loss, flip, the live handoff and source identity.
- **Fixture.** Beacon 300 u reach 9 and Pilot 30 u reach 3 on blocker input A. One each of the loose 2-, 3- and 4-way splitters and an Attenuator at 20 loss with reach 5. Recorder accepts 90–110, Terminal 45–60, Service exactly 30 from Pilot, blocker 25–35 and must end solely on Beacon.
- **Player does.** Positions and wires the splitters from Beacon to meet the Recorder and Terminal bands. The four-way gives the blocker branch 25 u, and the Attenuator initially drops it to 5 u so it can join Pilot’s 30 u without exceeding the live band. Transfers power in safe steps, then reuses Pilot’s single output for Service at exactly 30 u.
- **Solve reveals.** **The last roll call**, then two taps on Service.
- **Notebook.** *Service line.* A bell circuit. It rings. It cannot carry a word.

**Winning replay for Test Line.** Keep the other parts in place, move the four-way to `(2.5, 4.5)` and the Attenuator to `(2.5, 6.5)`, then mirror the Attenuator. Connect Beacon’s 300-unit channel-12 feed to the three-way. Route the three-way’s side output to a two-way and then to the Terminal at 50 units (45–60). Route its top output straight to the Recorder at 100 (90–110). Route its bottom output to the four-way, whose bottom output gives 25 to the Attenuator. The 2-, 3- and 4-way splitters reach six, four and seven board-length units respectively. Pilot starts on A at 30. The Attenuator starts at 20 loss, so connecting it to B adds 5. The blocker totals go **30 → 35 → 25 → 35 → 25 → 35 → 25** as the player connects B, alternates the losses and disconnects A. At disconnection Pilot is at 10 and Beacon is at 25. Connect Pilot to Service and restore Pilot to 30.

**Optional · Four-way fan-out** · playable
- **Fixture.** A fixed 300 u Beacon, a 4-way splitter and four loads that each require 75 u.
- **Player does.** Wires the splitter, reads the first load, then uses the other three physical ports. The first load holds at 75 u as the remaining cables are added.
- **Progression.** Available after Split Ratings. Bench Pad is also available at that point.

#### 3 · Service Corridors

**Room brief.** Follow the tap response through a dead section of the station. **Issued:** the service feed, a relay, a selector and keyed sockets. The feed is channel 12 at a fixed 30 u, so strength is never the problem in this chapter.

**3.1 Long Reach** · planned · evaluates on commit
- **New rule.** A relay has one input and one output. It preserves source, channel and strength, and its output starts a fresh reach.
- **Fixture.** Service feed, 30 u, reach 3, anchored. A corridor lamp anchored 5 units away, accepts exactly 30. One loose relay, reach 3.
- **Player does.** Places the relay so each leg reaches and compares the reading on both sides with the feed’s output.
- **Must not pass.** A direct cable. The feed and lamp are both anchored beyond reach.
- **Solve reveals.** A corridor relay wakes and places the two taps beyond the next junction.
- **Notebook.** *Relays.* Same signal, new starting point.

**3.2 Switchboard** · planned · first Send board
- **New rule.** A selector forwards the whole delivery through one of two cabled outputs, chosen by its lever, when the player presses **Send**. Each destination keeps what arrived on the last send.
- **Fixture.** Service feed into an anchored selector. Lamp A and Lamp B each accept exactly 30. A two-way splitter sits in the tray for comparison.
- **Player does.** Cables A and B once. Predicts which lamp will light, sends, moves the lever and sends again. Swapping in the splitter feeds both lamps 15 and both read weak.
- **Must not pass.** The splitter. Both lamps need the full 30.
- **Solve reveals.** Either branch of the corridor system can be queried from one service line.
- **Notebook.** *Selectors.* A splitter shares. A selector chooses. Nothing moves until you send.

**3.3 Marked Sockets** · planned
- **New rule.** A keyed socket accepts only its labelled channel. Channel is checked separately from reach and strength.
- **Fixture.** Two anchored feeds, channel 12 and channel 9, both 30 u. Two anchored sockets marked 9 and 12, placed so that each feed sits opposite the wrong socket. All four pairings are within reach.
- **Player does.** Cables straight across, sends and reads “Wrong channel · carries 12, expects 9” at both sockets. Crosses the cables and sends again.
- **Must not pass.** The straight-across wiring, which is valid for reach and strength.
- **Solve reveals.** The matching socket identifies the route back to the map terminal.
- **Notebook.** *Channels.* Right strength, right distance, wrong label: still nothing. Match the number and the shape.

**3.4 Service Corridors** · planned capstone
- **Combines.** Relay reach, channel matching and an ordered pair of selector sends.
- **Fixture.** Service feed, one loose relay, one loose selector. The map terminal and the access receiver are both keyed 12. A socket keyed 9 sits closer to the selector than the access receiver and can be cabled.
- **Player does.** Relays the feed to the selector. Sends through A to wake the map terminal, then through B to the access receiver. The access receiver logs its handshake only while the terminal’s last send is recorded.
- **Must not pass.** A direct cable to the selector, a send to B first, or the nearer channel-9 socket.
- **Solve reveals.** The junction comes online. The Station Map shows the refuge and the private link above deck 6, and the junction selector joins the kit.
- **Notebook.** *The junction.* The same lever, on the station’s own doors. Swing the whole feed down one branch, then the other.

Both successful sends must come from the same arrangement. An unexpected send, a route edit or Reset clears the sequence. The player can change the selected output while both cables remain attached. Once the junction is online, the same selector sits at the hub of the Station Map.

#### 4 · Vale’s Melody

**Room brief.** The calibration terminal stores the private receiver’s settings behind a test sequence. Bring its three note lines up together. **Issued:** Beacon, cables, the fan-out core and standard port modules.

**4.1 Tone Check** · planned
- **New rule.** A correctly fed note receiver answers with a tone and a labelled visual cue. Both carry the same information.
- **Fixture.** A 100 u transmitter and note receiver II, accepts 90–110, within reach. One cable.
- **Player does.** Cables it and sends. Mutes and sends again to compare the visual cue with playback.
- **Solve reveals.** The terminal’s test strip names the first tone and shows three note positions for the full calibration.
- **Notebook.** *Notes.* Every sound on this station has a lamp that says the same thing.

**4.2 Build a Splitter** · planned · workshop
- **New rule.** A tool is a core plus ports, and a fan-out’s physical port count sets its output strength.
- **Fixture.** Workshop bench with Beacon at 300 u and three test lamps that accept 90–110.
- **Player does.** Fits one input and two outputs to the fan-out core and measures 150 per branch. Adds the third output and measures 100. Saves the three-output design.
- **Must not pass.** Saving is allowed with two outputs, and that design cannot solve the capstone. The bench shows why before the player leaves.
- **Solve reveals.** The workshop stores the design alongside the outputs it tested. If this is the player’s first workshop board, the four-step primer runs first (see **Workshop**).
- **Notebook.** *Fan-out.* Three sockets, a third each.

**4.3 Vale’s Melody** · planned capstone
- **Combines.** The saved three-way, reach and a single send.
- **Fixture.** Beacon 300 u, anchored. Note receivers I, II and III, each 90–110, spread so that only a central region of dots puts all three within the design’s reach of 4. The tray holds one fan-out design.
- **Player does.** Equips the three-way, positions it so three 100 u branches reach the three receivers, and sends once.
- **Must not pass.** The two-output design, which delivers 150. A second fan-out, which the tray does not allow.
- **Solve reveals.** The terminal plays the stored order **II · III · I** and Vale’s calibration recording names **channel 7** for the private receiver. The notebook keeps the channel and the ordered visual sequence. The sequence returns in 7.4 as the private receiver’s acknowledgement.

**1.4 Night Lights** accepts this design on replay and supplies standard splitters on the first attempt.

#### 5 · Relay Archive

**Room brief.** Retrieve the maintenance record from a locked local archive. **Issued:** the A and B transmitters, cables, a relay, the AND core and keyed port modules. These are issued here whichever branch the player visits first.

**5.1 Key Check** · planned
- **New rule.** A latch opens only on a delivery carrying the `KEY` channel. Channels can be credentials as well as routes.
- **Fixture.** The bench’s Test Key source, the A transmitter and one latch keyed `KEY`.
- **Player does.** Cables A to the latch, sends and reads “Wrong channel · carries A, expects KEY”. Cables Test Key and sends.
- **Solve reveals.** The self-test authorises work on the real archive latch. Test Key stays on this bench and never enters a tray.
- **Notebook.** *Keys.* The archive does not care how strong you are. It cares who you are.

**5.2 Build a Gate** · planned · workshop
- **New rule.** A keyed AND gate emits `KEY` on its own output only when A and B arrive at their matching inputs on the same send.
- **Fixture.** Workshop bench with A and B sources and a test latch.
- **Player does.** Fits the A input, the B input and the Key output to the AND core. Sends with A alone, then with the inputs swapped, then with both correct. Checks the Key output and the latch separately, since Key must still be cabled to the latch.
- **Reads.** Received and expected channel at each input, then whether Key reached the latch.
- **Solve reveals.** The gate design is saved for the next board. If this is the player’s first workshop board, the primer runs first.
- **Notebook.** *Both or nothing.* The gate waits for the pair. One on its own is silence.

**5.3 Relay Archive** · planned capstone
- **Combines.** The saved gate, a relay and a Key delivery through a separate output.
- **Fixture.** A and B transmitters anchored on opposite sides. The archive latch is anchored. One loose gate, one loose relay. From every legal dot for the gate, at least one authorisation leg is out of reach.
- **Player does.** Equips the gate, relays the leg that cannot reach, puts both feeds on their matching inputs, carries Key to the latch and sends.
- **Must not pass.** Any arrangement without both the gate and the relay, including at the closest legal positions.
- **Solve reveals.** Vale’s maintenance record. It gives the dispatch header **`0100`** and the instruction to keep the relay port dark while the carrier sensor is lit. It leaves the channel to the calibration recording.

**2.11 Cold Start** branches from Relay Archive and requires a relay on each input.

#### 6 · Data Deck

**Room brief.** The private transmitter’s dispatcher needs a verified four-bit header before the line can be armed. **Issued:** bit sources, a packer, an unpacker and data displays as fixtures. Channel and strength are fixed and valid on the teaching boards so the player can inspect the data field alone. **Entry:** see the Dispatcher’s conditions in **Station cycles**.

**6.1 One Bit** · planned
- **New rule.** A delivered `0`, a delivered `1` and an empty input are three different states.
- **Fixture.** One bit source showing `1`, uncabled. A matcher that expects `[0]`.
- **Player does.** Sends with no cable and reads **Empty**. Cables it, sends and reads `[1]` as a mismatch. Taps the source tile to `0` and sends.
- **Must not pass.** An empty input counted as `0`.
- **Solve reveals.** The dispatcher log opens and lists the refused all-clears.
- **Notebook.** *Zero is something.* A zero arrived. Empty means nothing did.

**6.2 Pack Four** · planned
- **New rule.** A packer places four same-send bits in lane order `b3 b2 b1 b0` and keeps leading zeros.
- **Fixture.** Four bit sources all at `0`, prewired to the packer except lane `b1`. A matcher that expects `0010`.
- **Player does.** Sends and sees the output empty with `b1` marked missing. Cables `b1`, sends `0000` as a mismatch, toggles `b1` and sends `0010`.
- **Solve reveals.** The dispatch panel shows how four tile positions become one word on one cable.
- **Notebook.** *Words.* Four lanes, read left to right. The zeros in front count.

**6.3 Breakout** · planned
- **New rule.** An unpacker takes a whole word and exposes its four lanes.
- **Fixture.** A fixed word source `0100` into an unpacker. One loose cable. An audit display labelled `b2` that expects `[1]`.
- **Player does.** Tries a lane, reads the display, and settles on `b2`, the second position from the left.
- **Must not pass.** Any other lane. In `0100` only `b2` is `1`.
- **Solve reveals.** The panel names `b2` as the audit lane for the dispatch header.
- **Notebook.** *Breaking out.* The same four lanes, back in the same order.

**6.4 Dispatch Code** · planned capstone
- **Combines.** Bit sources, the packer, a selector with two sends, the unpacker and an exact-match receiver.
- **Fixture.** Four editable bit sources, a packer, a selector, a matcher that expects `0100`, an unpacker and the `b2` audit display.
- **Player does.** Builds the header from the maintenance record. Sends through A to the matcher. Sends the same word through B to the unpacker and routes `b2` to the audit display.
- **Must not pass.** `0010`, the word from 6.2, which is the header with its lanes reversed. A changed word between sends.
- **Solve reveals.** The dispatcher accepts the header and audit bit and arms the private line. The Optical bench can now appear on a plan.

The two sends must use the same committed arrangement and word. Switching A to B preserves sequence progress. A source value or route edit, Reset or unexpected send clears it. The finale’s transmitter has a four-bit input strip so the player applies the header directly.

#### 7 · Dark Port

**Room brief.** Bring up the private service link while the relay port stays dark. The maintenance record gives the optical condition and the header. The calibration recording gives the channel. The optical and wired halves of the board meet at the transmitter’s Enable input. **Issued:** a delay plate and coherent optics as fixtures. **Entry:** an armed dispatcher.

All five boards use the balanced 100 u loop from **Core rules**. The first splitter is anchored directly in front of the laser on every board, so no single ray after it carries more than 50 u. The carrier sensor needs at least 95 u and the relay port at most 1 u. Only interference can meet both.

**7.1 In Step** · planned · evaluates on commit
- **New rule.** A delay plate changes phase on one path. Where the two paths merge, the plate setting moves light from one exit to the other.
- **Fixture.** The whole loop is anchored. The plate starts at +0, which puts all 100 u on the relay port.
- **Player does.** Steps the plate through its four settings and reads the two meters, with optional Clocks showing the two incoming hands at the merge. Both incoming paths stay lit throughout.
- **Reads.** 0/100, 50/50, 100/0, 50/50 for carrier sensor and relay port.
- **Solve reveals.** The relay port goes dark as the carrier sensor brightens. Nothing blocked it.
- **Notebook.** *In step.* Two beams that arrive out of step cancel. The light is not lost. It leaves by the other exit.

**7.2 Two Paths** · planned · evaluates on commit
- **New rule.** Cancellation needs both paths to arrive at the merge.
- **Fixture.** Laser, first splitter, merge splitter and both sensors anchored. The plate is bolted at +2. Two loose mirrors. This is the bench as Vale left it.
- **Player does.** Places one mirror and reads 25 and 25. Places the second so both paths meet at the merge and reads 100 and 0.
- **Must not pass.** One path alone, which leaves 25 u on the relay port.
- **Solve reveals.** The notebook marks where Vale pulled the mirrors.
- **Notebook.** *Both legs.* One beam cannot cancel itself. Blocking a leg does not darken the port. It lights it.

**7.3 Interlock Check** · planned · optics on commit, transmitter on Send
- **New rule.** The optical interlock reads both sensors and enables a separate wired transmitter only while the carrier sensor is bright and the relay port is dark.
- **Fixture.** The anchored loop with an adjustable plate at +0. The interlock interface, a transmitter with an Enable input and a local test lamp.
- **Player does.** Inspects Enable, which names the unmet condition. Sets the plate to +2 and sends.
- **Must not pass.** A send at +0, +1 or +3. The transmitter stays disabled.
- **Solve reveals.** The safety check confirms the private transmitter can run with the public relay isolated.
- **Notebook.** *Enable.* Two readings, one permission. The same both-or-nothing as the archive gate.

**7.4 Frequency Check** · planned
- **New rule.** A transmitter’s channel is a setting that changes independently of its word.
- **Fixture.** The loop bolted at +2 so Enable holds. The transmitter’s word is fixed at `0100`. Its channel control offers 12 and 7. A local test set is keyed to the private receiver’s channel.
- **Player does.** Sends on 12 and reads “Wrong channel”. Sets 7, sends, and gets **II · III · I** back in sound and in lamps.
- **Solve reveals.** A local test confirms Vale’s channel without contacting the refuge yet.
- **Notebook.** *The private channel.* Seven. The bus is twelve.

**7.5 Dark Port** · planned capstone
- **Combines.** Coherent routing, the delay plate, Enable, a keyed delivery and an exact payload.
- **Fixture.** A 7 × 9 board. Optical half: laser, first splitter, merge, carrier sensor, relay port and a baffle anchored, with two loose mirrors and a loose delay plate. Wired half: the private transmitter with Enable, a 16-position channel dial and a four-bit strip, one loose relay, and the private terminal keyed 7 beyond direct reach.
- **Player does.** Places the mirrors so both paths reach the merge and sets the plate so the relay port is dark and the carrier sensor is bright. Sets channel 7 and `0100`, relays the transmitter to the private terminal and sends while Enable holds.
- **Must not pass.** A blocked or missing leg. A single branch aimed at the carrier sensor. Channel 12. Any other word. A send with Enable off.
- **Solve reveals.** The private terminal receives a live reply. Six crew IDs check in. Vale explains the public relay fault and confirms the crew can release the refuge hatch from inside now that the all-clear has arrived. The **Ending** plays.

Vary the channel, the header and the optical condition independently in tests. The final terminal requires channel 7, header `0100` and both optical conditions on the same send.

## Appendix A · Routing fixtures and teaching

The examples below specify reference fixtures for authoring and testing. Coordinates use board-length units and give the position of each named port, aperture or antenna. Columns increase to the right and rows increase downwards. Give loose parts only the placement dots and settings used by the lesson. The [slot catalogue](#slot-catalogue) places the current fixtures. The numbered [campaign board references](#board-references) preserve their story versions.

### How a routing lesson plays

1. Show the objective and starting readings before the first move. Anchor the equipment the player needs to read or compare. Leave the new control or part editable and keep its first action reversible.
2. Let the player make one change and compare the two states. On an on-commit board, dropping, rotating or connecting updates the readings immediately. On a Send board, use inline readouts to preview what the player is about to send. Label the destination’s observed result after the send. Put the current and target readings together so the effect is visible on a still screen.
3. Give the player a target that requires the new rule. Include a plausible near miss that fails for one reason, such as a correctly keyed receiver just outside reach. Show the reason at the first failed hop or port. After the solve, write the rule to Vale’s notebook and connect it to the instrument the player restored.
4. In the application, combine the new rule with a known device that solves a distinct problem. A relay can bring a feed to a broadcaster, then the broadcaster’s placement determines which receivers get it. Make both decisions inspectable. In a challenge, tighten a specific limit and verify the required solve and any optional record with saved replays.

### Point-to-point delivery and reach

For a reach demonstration, use a 30 u source on channel 12, with reach 3, and a test lamp that accepts exactly 30 u on channel 12. Lighting the test lamp leaves the board open for further edits. Put the source’s output at `(1,1)` and the lamp input at `(3,2)`. Tapping the output selects it and shows its reach diamond. Tapping the input commits a cable at distance `|3−1| + |2−1| = 3`. The lamp reads **30 u · accepted**. Give the source a second placement dot that puts its output at `(0,1)`. Moving it there keeps the cable attached, changes the distance to 4 and leaves the lamp quiet. Inspecting the dashed cable shows **Needs 4 length units. Output reaches 3.** Moving back restores 30 u without a new cable. Trying to create the connection from the distant dot reports the same distance and leaves the arrangement as it was.

For an occupied-port check, use a second in-range source and a standard lamp input. Selecting the second source and tapping the lamp replaces the existing cable in one edit. Undo restores the first cable. A source output already attached to an input has no free connector for a second lead. Use a splitter or another output to branch. A visible cable crossing leaves the two routes electrically independent. Draw an overpass gap and identify each lead by its endpoints in the inspector. These actions use the same gestures when a Test Line hub door feeds a room’s socket on the Station Map.

For a relay lesson, fix the source output at `(1,2)` and the lamp input at `(6,2)` with the same 30 u delivery and reach 3. The direct route needs 5. Place a relay so its input sits at `(3,2)` and its output at `(4,2)`, with output reach 3. Cable the source to the relay input and the relay output to the lamp. Each leg needs 2. The lamp sees the original source, 30 u, channel 12 and any payload carried by the feed. Inspect each leg separately. Remove the first lead and the relay output goes quiet even though the second lead is still within reach. The application should require at least one such extra origin through the placement and reach of its ports.

### Sharing a feed, choosing a branch and checking the delivery

Use a 30 u source on channel 12, two loads that each need exactly 30 u and **Send** to evaluate. Give both loads an in-range cable route from each comparison device. With a two-way splitter, one connected load reads 15 u after Send. Add a cable to the other output and send again. The first reading stays at 15 u and the second matches it. Both are weak. Replace the splitter with a selector and cable both branches. On **Send** with A selected, A accepts 30 u and B is quiet. Switch the lever to B and send again to reverse the readings. In a board that requires the sequence A then B, show one accepted step after A and complete the sequence after B. The lever can change between sends. A wiring edit, source value change, Reset or unexpected send clears the sequence.

To isolate a channel mismatch, put a channel-12 source opposite the channel-9 socket and a channel-9 source opposite the channel-12 socket. Both emit 30 u, both sockets require 30 u and every pairing is within reach. The straight leads reach both sockets. Their inspectors show the carried and expected channels. Cross the two cables and send again to accept both feeds. In 3.6 Two Channels, fix the only source on channel 12 with the word `0100`. A target keyed 7 rejects a direct send. Through a converter with input 12 and output 7, the same source identity, strength and four-bit word reach the target on channel 7. Show the converter’s input and output labels together.

For the two-input archive gate, use sources A and B and a separate latch keyed `KEY`. The gate’s A and B inputs accept only their labels. Show the input states independently. Sending A alone leaves B quiet and the gate output quiet. Sending both with the sockets swapped shows two mismatches and still yields no Key. Sending both correctly in one evaluation produces Key. The latch remains closed until its own input is cabled to the gate output and receives Key on a send. In the archive application, use the reachable placement dots and port offsets to make one input leg too long without a relay. Test every direct placement for a shortcut.

For data fan-out, use a fixed 40 u source that sends the four-bit word `0100` on channel 12. Both receivers require at least 35 u, channel 12 and that exact word. A data-capable two-way splitter gives each 20 u with the correct word, so both read weak. An authored packet repeater sends 40 u and a copy of `0100` through each of its outputs. Each cable still checks its own reach. On the successful send, both receivers show the four tiles including the leading zero and a separate 40 u reading. Inspect a single-bit zero independently from a quiet input in the prerequisite lesson.

### Light paths, radio paths and barriers

Use an east-facing 100 u laser at `(0,2)` and an optical splitter at `(2,2)`, with its turned exit pointing south. The straight 50 u branch reaches the local light sensor at `(5,2)` from the west. Put a mirror at `(2,3)` with the diagonal that turns the southbound ray east. The resulting 50 u branch enters the converter at `(4,3)` from the west. Set the converter to accept 50 u and emit east toward the trial antenna at `(8,3)` with reach 4. The goal is the local 50 u reading and an accepted radio arrival. Show the converter’s optical input reading and the radio hop separately.

Put a wall between the converter and the antenna, crossing the path at `(6,3)`. Concrete stops the radio hop at its face, so the local sensor still reads 50 u and the antenna is quiet. With mesh in the same place, the radio hop reaches the antenna. For the material comparison, send light down that same lane in a separate fixture and show it stopping at both walls. Turning the mirror away in the combined fixture leaves the converter without optical input, and the antenna goes quiet even with mesh. Use a distinct line pattern for radio, mark blocked paths at the barrier and name the material and blocked medium in the inspector.

For a wired-to-radio trial, place the two antennas at `(2,2)` and `(8,2)` with radio reach 6. Set each local cable output’s reach to 2. The gap prevents a direct cable between sides. Each side has its own wired source and receiver. Put their ports within 2 length units of the transceiver’s corresponding cable ports. For the request-and-reply fixture, cable both directions during setup and keep each inactive port quiet in the current mode.

Set the left unit to **Transmit** and aim east. Set the right unit to **Receive** and accept from the west. On Send, the right receiver gets the left source’s 30 u channel-12 request `0100`. For the reply, swap the modes and the directional settings, then Send. The left receiver gets the right source’s 30 u channel-12 reply `0010` over the existing cables. Inspect the sender, strength, channel and word before and after each hop. Two units in Transmit mode give the hop no eligible receiving endpoint. Two in Receive mode leave it without a radio origin.

For the repeater application, anchor the sending antenna at `(1,2)` and the target at `(5,2)`. Place a shield across the direct path at column 3, spanning rows 1 through 3. Give the sender and repeater reach 5. Provide a repeater dot at `(3,5)` and authored headings for the direct and relayed paths. The direct eastward hop is in range and stops at the shield. Aim the sender southeast along the line to the repeater and the repeater northeast along the line to the target. Each leg fits the reach limit and passes below the shield. Feed the sender 30 u on channel 12 with word `0100`. Author the repeater output at 40 u. With both legs valid on one Send, the target sees the original source, channel 12 and word `0100` at 40 u. Show each hop’s reach and blocker state. Disable the first hop and verify that the repeater output goes quiet while the second path is still clear.

### One feed to an area and two local cells joined by a fixed link

For Antenna Test, use a 30 u channel-12 source with its output at `(2,0)` and cable reach 3. Feed a broadcaster with wireless radius 2 and allow it to move between `(2,2)` and `(3,2)`. In this fixture the input and the origin of the coverage diamond use the same position for distance checks. The input cable reaches from both dots. Put intended channel-12 receivers at `(4,2)` and `(3,4)`, a protected channel-12 receiver at `(0,2)` and a channel-9 receiver at `(3,1)`. Each in-range, matching receiver reads the whole 30 u independently.

| Broadcaster position | Intended at (4,2) | Intended at (3,4) | Protected at (0,2) | Channel 9 at (3,1) |
| --- | --- | --- | --- | --- |
| `(2,2)` | Accepts at distance 2 | Outside at distance 3 | Accepts at distance 2 | In range, wrong channel |
| `(3,2)` | Accepts at distance 1 | Accepts at distance 2 | Outside at distance 3 | In range, wrong channel |

The goal is both intended receivers active and the protected receiver quiet on the same send. Draw the footprint while placing the broadcaster. After Send, show an accepted, outside-coverage or wrong-channel state for each endpoint. Disconnect the feed and send again to confirm the entire area goes quiet. In the application, put the useful placement beyond the source’s cable reach and supply a relay. Both cable legs must reach before the coverage decision matters.

For Long-range Link, anchor a matched bridge pair across a gap wider than any local cable can span. Wire a source to the near bridge input and the far bridge output to a receiver using short local cables. Inspect the local leads and the fixed link individually. In a diagnostic fixture, break each local leg in turn by moving its loose endpoint beyond reach. Restore it and verify the receiver gets the original strength, channel, source and payload again.

For Base Stations, give the near cell a centre at `(2,2)` and the far cell a centre at `(8,2)`, each with a Manhattan radius of 2. Fix the backhaul between that pair. Send from a terminal at `(0,2)` to a matching receiver at `(8,4)` via the stations. Both local paths meet the boundary. A protected matching receiver at `(11,2)` is outside the far cell and stays quiet. As negative checks, move the sender to `(0,1)` to break the near leg, then put it back and move the intended receiver to `(8,5)` to break the far leg. The backhaul stays paired in both cases. Show which cell is missing an eligible endpoint. Inspect the same delivery on all three successful legs.

### Numbered bursts and optional records

In Pulse Timing, use a fixed in-reach path on the correct channel, three source slots and one timed receiver. Start with the receiver’s observed row blank. The player enables or disables each slot and presses **Step** once for each numbered slot, in order. Enabled slots emit a burst through the current route. The receiver records **Arrival** if a valid burst reaches it, or **Quiet** otherwise. Show the next slot, the target row and the observed row. An observed Quiet cell is labelled, while an untested cell is empty. After step 3, compare the entire ordered pattern with the target **Arrival · Quiet · Arrival**. Three arrivals fail, and **Arrival · Arrival · Quiet** fails with the same total as the winning pattern. Reset clears the observed row and starts a fresh run at slot 1. The player advances at their own pace, with the same result whether pulse animation is playing or paused.

In Night Lights, show the required solve in Hint and the optional cable-count goal on the blueprint’s trophy icon. With a 300 u source and three loads accepting 75–150 u, space the ports so both candidate networks fit. One source cable to a two-way, one of its outputs to a load, the other to a second two-way, and two leads to the remaining loads use five cables and give 150, 75 and 75 u. One source cable to a three-way and one from each output to a load use four cables and give 100 u each. Both arrangements complete the board. The trophy fills when all three loads accept with exactly four installed leads. Replaying lets the player earn the record after finding the balanced route.

On the Station Map, use the example in **Station cycles** to show how early wiring affects the next deck. Feed the two-door Corridor with 100 u, restore it and connect a door to the Workroom. It carries 50 u, within the Workroom’s 45–60 u band, and falls short of the Archive’s 90 u minimum. Feed and restore the one-door Passage from another hub door to carry 100 u to the Archive. Make the readings visible before room entry so the player can trace a failed feed back through earlier splits.

## Appendix B · Existing optical bench sequence

These six boards from the original HTML are the source material for optical lessons and optional puzzles. Their “private port” is the campaign’s relay port. **In step** is the starting fixture for the phase-sensitive board in the story prototype.

| Bench | Board | Lesson or challenge |
| --- | --- | --- |
| Bounce | 5 × 5 | Turn light with mirrors. |
| Through the wall | 6 × 5 | Steer light and convert to radio where concrete and mesh make the distinction matter. |
| Share | 5 × 5 | Split a beam to feed two targets. |
| In step | 6 × 5 | Change the delay and watch energy trade between the sensor and the other output. |
| Dark port | 7 × 9 | Rebuild the route, keep the private port dark and deliver radio to the antenna. |
| Two antennas | 7 × 10 | Account for a bolted delay plate, keep the private port dark and divide the useful output again. |

Bolt down unrelated parts in lessons. Let the player continue into the next bench from the result screen and revisit completed benches from the picker. Teach observer marks with a short before-and-after interaction before a bench asks the player to reason about them. Keep hints progressive. The first should direct attention to the relevant part or meter, and the last may identify the move.

## Appendix C · Review of the supplied prototype and mockup

- **HTML simulation.** Replayed one winning arrangement for each of the six supplied benches using the extracted simulation. Removing the movable delay from the tested arrangements for benches 4–6 made each fail. The original PRD reports an exhaustive necessity search for benches 5 and 6. The HTML does not contain that search, and this review did not independently reproduce it.
- **HTML interaction.** The source commits moves and can award a win during `pointermove`. `pointercancel` clears the drag flag and leaves those changes in place. Change that before phone playtests. Tapping a movable part currently also changes it, which makes inspection costly on a dense board. The page uses a CDN for Three.js and remote fonts. The standalone browser save tracks solved indices and Clocks, while Claude’s artifact hook holds in-progress piece positions. This review used source inspection and headless simulation. Rendered layout, physical touch and accessibility remain unverified.
- **HTML optics.** The splitter readout infers the result from two rounded clock positions and omits their strengths. The prototype caps displayed intensity at 100%, and its traversal uses depth and brightness cutoffs. Replace these assumptions before introducing power. Preserve the tested interference behavior as fixtures when extracting the simulator.
- **B2 mockup.** Recreated the pictured split-and-rejoin geometry in the HTML simulator and scaled the source to 400 units as a proxy for the amplifier. The reconstructed route produces the readings in the Power table. That verifies the phase relationship for the reconstructed geometry. Amplification, heat and breakage still need implementation. The mockup documents the reconstructed route.

## Appendix D · Validation of the previous PRD and what changed

### What was checked in revision 2

- **Playable boards against the code.** The Sealed Bay readings (50 on Alarm, 25 per latch), the Test Line bands, splitter reaches of six, four and seven, the 0/10/20 loss steps, the Pilot-only Service check and the handoff totals 30 → 35 → 25 → 35 → 25 → 35 → 25 all match `lib/optical_bay.dart` and `lib/signal_board.dart`. The story text quoted in **Scene script** matches `lib/game_shell.dart` and `lib/game_save.dart`. No playable board changes.
- **Planned arithmetic.** Split Ratings, Bench Pad, Keepalive and the Melody’s 300 ÷ 3 were recomputed by hand. The coherent loop was derived from the stated phase rules and agrees with the Door Cutting table at every plate setting.
- **Dependencies.** Every board’s prerequisites were traced through both branch orders. Each rule a board leans on is taught earlier on every path.
- **Open at that review.** Reach-based necessity had yet to be proved for the planned campaign boards. The subsequent [Signal Routing register](endless-level-register.md#appendix-a--exhaustive-reference-fixtures) supplies coordinate checks for seven different Endless reference fixtures. The junction-controller map that this check covered has since been replaced; see Appendix E.

### Problems found and the fix made

| # | Problem in the previous PRD | Fix in this guide |
| --- | --- | --- |
| 1 | **The channel clue was not a discovery.** The Melody revealed channel 12, the same channel on every board since Test Line. A player who skipped the recording would set it by default. | The service bus stays on 12. The private link is **channel 7**. Frequency Check contrasts 12 with 7 and the finale dial has 16 positions. |
| 2 | **The audit bit had a shortcut.** With header `0101`, lanes `b2` and `b0` are both `1`, so wiring the wrong lane passed Breakout and Dispatch Code. | The header is **`0100`**. Only `b2` is `1`. It is also the mirror of Pack Four’s `0010`, so a reversed lane order fails visibly. |
| 3 | **The finale could be passed without interference.** A full 100 u beam steered to the bright sensor met “at least 95” with the other port trivially dark. | The first splitter is anchored in front of the laser on every chapter 7 board, so no single ray exceeds 50 u. Stated as a fixture invariant with a test. |
| 4 | **“Keep the private port dark” had no reason in the story,** and “private port”, “private terminal” and “private channel” named three different things. | The port that must be dark is the **relay port**, the bench exit that feeds the faulty public relay. The bright one is the **carrier sensor**. Lighting the relay port would wake the fault. The legacy bench list in Appendix B keeps the old wording. |
| 5 | **The story left gaps.** Why only taps on Service, why the crew could not leave the refuge, why the link was down, and why the player has Vale’s notebook were not stated. | **What happened** fixes one account: Service is a bell line with no payload, the refuge holds for a verified all-clear that must be sent from outside, Vale shut the bench down to isolate the relay, and the notebook is behind the bay flap. |
| 6 | **The finale asked for an untaught skill.** In Step and Interlock Check used a fixed loop, so the capstone was the first time the player built one. | New board **7.2 Two Paths**: plate bolted, mirrors loose. |
| 7 | **Key Check taught three things at once:** the keyed latch, workshop assembly and the AND condition. The Archive branch also had one lesson fewer than the Melody. | Split into **5.1 Key Check** and **5.2 Build a Gate**. Both branches now run check, build, capstone. |
| 8 | **Hold-to-flip was required by the Test Line winning replay and taught nowhere.** | Taught in **2.3 Bench Pad**, where the Attenuator starts facing the wrong way. |
| 9 | **When a board evaluates was ambiguous** between chapters 2 and 4. | One table in **Core rules**. Commit through 3.1, Send from 3.2. |
| 10 | **The melody’s note order was recorded and never used.** | It is the private receiver’s acknowledgement in 7.4. |
| 11 | **The ordered pair of sends in Service Corridors had no reason to be ordered.** | The access receiver logs its handshake only while the map terminal’s last send is recorded. |
| 12 | **Marked Sockets was label matching with one channel.** | Two feeds and two sockets, placed so the valid-looking straight wiring is the wrong one. |
| 13 | **Board count.** 25 boards. | 27 boards with 5.2 and 7.2 added. |

### Open questions for the designer

1. **Crew names.** Five placeholder names are used. Only Vale is established.
2. **Channel 7 and header `0100`** are new constants. Any pair works if the channel differs from 12 and exactly one bit of the header matches the audit lane’s value.
3. **Keepalive still carries two ideas,** the adding blocker and source identity. If playtests show the Service step being missed, move source identity to its own short board before the capstone.
4. **Crew and wings.** Which crew member reopens which wing is not yet assigned.
5. **The Interlock** teaches the baffle and the live line together. It is playable and left alone.

## Appendix E · Design history of station cycles

| Before revision 2 | Revision 2 campaign proposal |
| --- | --- |
| A linear campaign of seven chapters | A fixed opening (chapters 1 and 2), then generated cycles. The chapters’ lessons are Benches and their capstones are story rooms. |
| A generated Station Map with a junction controller, powered doors and a hatch shortcut | The Station Map is a wired board whose devices are rooms, regenerated each cycle. The player routes Beacon’s power to it with a kit of pads, relays and blueprints. The junction adds a selector at the hub. The old map design is in the archived PRD. |
| Signal Lab as a separate title-screen mode | Signal Lab’s sets are the mechanic packs that endless mode adds, grouped into wings. |
| One authored board per position | Lessons and story rooms stay single boards. Applications and challenges are templates with solver-verified variants. |
| Progress is the current room | Progress is the notebook, mastery per pack, blueprints and five latches. |
| Seven MVPs | Nine. MVP 3 tests the loop before any story room is built. |

Revision 2 carried forward the story account, component rules and authored fixtures. Revision 3 gives the planned boards Endless slots and schedules campaign integration later.

**Design history.** The first draft of revision 2 used a three-card room draft at each door with a door-count clock. It was replaced by the station-as-board design so that the game’s own wiring rules, not card luck, drive each cycle.

**Campaign prototype status.** The cycle loop, plan generator and guaranteed line are still design work. Variant counts are estimates.
