# Dark Port

An offline, landscape puzzle game for iOS and Android. **New game** opens the tutorial, and **Continue game** returns to the horizontal tutorial path. Swipe along the connected squares and solve a lesson to unlock the next. Unfinished boards resume from their last committed edit. Completed lessons can be replayed from their starting arrangement.

The required path starts with **First reflection**, **A divided beam** and **The interlock**. **Patch Lead**, **Split Ratings**, **Bench Pad** and **Keepalive** teach the wired mechanics used together in the **Test Line** capstone. After Split Ratings, take the **Four-way fan-out** practice branch or continue to Bench Pad. The practice board has its own completion mark.

**Endless** opens the group path. Select group **1**, **Signal Routing**, to open its puzzle path from **1.1** to **1.20**. Levels **1.1–1.5** are playable and save their progress separately from the tutorial. **Edge of Coverage** branches below **Antenna Test**. Each distinct winning route earns a Solution Star, and **Night Lights** also tracks a four-cable record. See the [Endless level register](endless-level-register.md) for the fixtures and solution checks.

**Achievements** on the title screen lists earned and unearned awards with their conditions. Tap the trophy beside the Night Lights stars to inspect its four-cable achievement.

Tap an optic to rotate it or drag it to move it. On a wired board, tap an output and then an input to attach a cable. Drag loose parts to change position and hold one to mirror its ports. On Drafting sheets, loose mirrors have a dashed travel ring and fixed devices use bolt marks where they have a mounting plate. The readings show the current signal and its target. A dropped live line fails the attempt. Undo the edit or reset the board to recover.

The game saves completion and committed board edits locally. Starting a new game asks before replacing existing progress. Older saves keep their board layout and earned credit. Players with a legacy Test Line save unlock it again by completing the four new wiring lessons.

## Add a lesson

Author the fixture with the existing optical or wired board types. Register a stable ID and its goal in [lib/tutorial.dart](lib/tutorial.dart). The hint button shows the goal, so state what to achieve, not how. Add a short objective where the player needs one; like the goal, it names the outcome, not the steps. Add the lesson to the required list or give it a prerequisite in the optional practice list. The picker, renderer and save format use the registry. Wired fixtures can choose their components, fixed parts, initial links and flips, receiver bands and live alarm rules in [lib/wired_boards.dart](lib/wired_boards.dart).

## Play on iPhone

Run `flutter pub get` and `flutter devices` from this directory. With an iPhone connected and Developer Mode enabled, choose your signing team in `ios/Runner.xcworkspace` and run `flutter run -d <device-id>`. The project uses a provisional `com.example.darkPort` bundle identifier for local development.

The same `flutter run -d <device-id>` command targets a booted iOS simulator or an Android device listed by Flutter.

## Verify

Run `flutter analyze` and `flutter test`. The checks cover the full tutorial and optional branch, unlocking and replay, interrupted alarms, legacy saves, serialized file writes and write retries. The Endless tests walk through levels 1.2–1.5 and exhaust their legal arrangements using the game evaluator.

Run `flutter test integration_test/onboarding_test.dart -d <device-id>` for the native tutorial walkthrough or `flutter test integration_test/endless_test.dart -d <device-id>` for the Endless walkthrough. Both exercise local save storage.

## Design references

The [current drafting references](art/reference/README.md) cover sheet finishes, optical symbols, part leaders and measurements.

The local `design-review/` folder holds earlier concepts, prototypes and the original PRD for review.
