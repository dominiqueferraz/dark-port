# Dark Port

An offline, landscape puzzle game for iOS and Android. **New game** opens the tutorial, and **Continue game** returns to the horizontal tutorial path. Swipe along the connected squares and solve a lesson to unlock the next. Unfinished boards resume from their last committed edit. Completed lessons can be replayed from their starting arrangement.

The required path starts with **First reflection**, **A divided beam** and **The interlock**. **Patch Lead**, **Split Ratings**, **Bench Pad** and **Keepalive** teach the wired mechanics used together in the **Test Line** capstone. After Split Ratings, take the **Four-way fan-out** practice branch or continue to Bench Pad. The practice board has its own completion mark.

The first time you open a tutorial lesson, a bubble explains its goal and controls. Tap **Start lesson** to play. The game remembers which lessons you’ve opened, and **Hint** shows the guidance whenever you need it.

**Endless** opens the group path. Select group **1**, **Signal Routing**, to open its puzzle path from **1.1** to **1.28**. Puzzles save their progress separately from the tutorial. **Edge of Coverage** branches below **Antenna Test**. Each distinct winning route earns a Solution Star, and **Night Lights** also tracks a four-cable record. See the [Endless level register](endless-level-register.md) for the fixtures and solution checks.

Open **Workbench** from the title screen or a compatible puzzle. Choose **Add part** or tap an empty mount to pick an optical splitter or a wired module. Select a part or socket to turn it with the same controls, and open **Blueprints** to preview and load either kind of design. Use **Tutorial** to learn how to aim an optical splitter at a latch.

Fabrication puzzles open with an empty socket marked **Fabrication required**. Open **Workbench** to build a part, or use **Insert part** to choose a compatible saved design. **Save blueprint** lets you name the part and pick an icon. **Fit to puzzle** installs it as one part so the level can test its signals.

For a splitter, aim the test laser and press **Test** to check the input’s sightline and read the power at each output. Clip a half-power filter to either output. For a wired assembly, drag parts between mounts, fit up to three inputs and three outputs with the perimeter plus buttons, and tap an output followed by an input to connect them. Tap a test input in the parts list to toggle its feed. In Signal Routing, **Workbench sheets** jumps to the build puzzles.

**Achievements** on the title screen lists earned and unearned awards with their conditions. Tap the trophy beside the Night Lights stars to inspect its four-cable achievement.

Tap an optic to rotate it or drag it to move it. On a wired board, tap an output and then an input to attach a cable. Drag loose parts to change position and hold one to mirror its ports. On Drafting sheets, loose mirrors have a dashed travel ring and fixed devices use bolt marks where they have a mounting plate. The readings show the current signal and its target. A dropped live line fails the attempt. Undo the edit or reset the board to recover.

On Relay Shelf, Two Masts and Service and Inspection, tap an output and an input to preview the route and its length. The game matches the lead to the route. Tap the same input again to install it. The inventory uses the same lead symbols as the Parts guide. A move can leave an installed lead dashed if its new route fails a check.

On conversion sheets, solid lines show light and dashed lines show radio. Mesh stops light and passes radio. Starting with One Mirror, Two Windows, match the letters on the lasers and converters. In Service and Inspection, switch between **Wired** and **Optical** to complete both circuits and replay for the three corridor stars.

Open **Parts guide** with the **?** button. **This puzzle** lists the types of parts on the current board. The category tabs collect parts from boards you’ve opened in Tutorial and Endless. **Controls** covers placement, rotation, wiring, readings, and undo as applicable. The guide remembers these discoveries when you start a new Tutorial.

The game saves completion and committed board edits locally. Starting a new game asks before replacing existing progress. Older saves keep their board layout and earned credit. Players with a legacy Test Line save unlock it again by completing the four new wiring lessons.

## Add a lesson

Author the fixture with the existing optical or wired board types. Register a stable ID and its goal in [lib/tutorial.dart](lib/tutorial.dart). The hint button shows the goal, so state what to achieve, not how. Add a short objective where the player needs one; like the goal, it names the outcome, not the steps. Add the lesson to the required list or give it a prerequisite in the optional practice list. The picker, renderer and save format use the registry. Wired fixtures can choose their components, fixed parts, initial links and flips, receiver bands and live alarm rules in [lib/wired_boards.dart](lib/wired_boards.dart).

## Play on iPhone

Run `flutter pub get` and `flutter devices` from this directory. With an iPhone connected and Developer Mode enabled, choose your signing team in `ios/Runner.xcworkspace` and run `flutter run -d <device-id>`. The project uses a provisional `com.example.darkPort` bundle identifier for local development.

The same `flutter run -d <device-id>` command targets a booted iOS simulator or an Android device listed by Flutter.

## Verify

Run `flutter analyze` and `flutter test`. The checks cover the full tutorial and optional branch, unlocking and replay, interrupted alarms, legacy saves, serialized file writes and write retries. The Endless tests exercise levels 1.1–1.20, enumerate every authored arrangement for 1.11–1.20, exhaust the legal optical Workbench arrangements on 1.21–1.26, and verify insertion, blueprint reuse, and alternative wired designs on 1.27–1.28.

Run the walkthroughs in `integration_test/` with `flutter test <test-file> -d <device-id>`. Use `onboarding_test.dart` for the Tutorial, `endless_test.dart` for Signal Routing, or `workbench_test.dart` for the Workbench tutorial and blueprint reuse. All three exercise local save storage.

## Design references

The [current drafting references](art/reference/README.md) cover sheet finishes, optical symbols, part leaders and measurements.

The local `design-review/` folder holds earlier concepts, prototypes and the original PRD for review.
