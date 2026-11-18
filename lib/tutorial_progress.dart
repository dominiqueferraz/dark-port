import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'assembly.dart';
import 'endless_levels.dart';
import 'game_save.dart';
import 'splitter_blueprint.dart';
import 'tutorial.dart';

typedef EndlessResult = ({
  int revision,
  Set<String> stars,
  bool fourCableRecord,
});

class TutorialProgress {
  TutorialProgress({
    Set<String> completed = const {},
    Map<String, GameSave> boards = const {},
    this.tutorialStarted = true,
    Map<String, GameSave> endlessBoards = const {},
    Map<String, EndlessResult> endlessResults = const {},
    Set<String> opened = const {},
    Set<SplitterBlueprint> blueprints = const {},
    Set<AssemblyBlueprint> assemblies = const {},
  }) : completed = Set.unmodifiable(completed),
       boards = Map.unmodifiable(boards),
       endlessBoards = Map.unmodifiable(endlessBoards),
       endlessResults = Map.unmodifiable(endlessResults),
       blueprints = Set.unmodifiable(blueprints),
       assemblies = Set.unmodifiable(assemblies),
       opened = Set.unmodifiable({
         ...opened,
         ...completed,
         ...boards.keys,
         ...endlessBoards.keys,
         ...endlessResults.keys,
       });

  final Set<String> completed;
  final Map<String, GameSave> boards;
  final bool tutorialStarted;
  final Map<String, GameSave> endlessBoards;
  final Map<String, EndlessResult> endlessResults;
  final Set<String> opened;
  final Set<SplitterBlueprint> blueprints;
  final Set<AssemblyBlueprint> assemblies;

  static TutorialLesson? _lessonFor(String id) =>
      lessonsById[id] ?? endlessLevelsByLessonId[id]?.lesson;

  Iterable<TutorialLesson> get openedLessons => opened.map(_lessonFor).nonNulls;

  TutorialProgress open(TutorialLesson lesson) {
    if (opened.contains(lesson.id) || _lessonFor(lesson.id) != lesson) {
      return this;
    }
    if (lessonsById.containsKey(lesson.id) && !isUnlocked(lesson)) return this;
    return TutorialProgress(
      completed: completed,
      boards: boards,
      tutorialStarted: tutorialStarted,
      endlessBoards: endlessBoards,
      endlessResults: endlessResults,
      opened: {...opened, lesson.id},
      blueprints: blueprints,
      assemblies: assemblies,
    );
  }

  TutorialProgress saveBlueprint(SplitterBlueprint blueprint) {
    if (blueprints.contains(blueprint)) return this;
    return _saveLibrary(
      blueprints: {...blueprints, blueprint},
      assemblies: assemblies,
    );
  }

  TutorialProgress saveAssembly(AssemblyBlueprint design) {
    if (assemblies.contains(design)) return this;
    return _saveLibrary(
      blueprints: blueprints,
      assemblies: {...assemblies, design},
    );
  }

  TutorialProgress _saveLibrary({
    required Set<SplitterBlueprint> blueprints,
    required Set<AssemblyBlueprint> assemblies,
  }) {
    return TutorialProgress(
      completed: completed,
      boards: boards,
      tutorialStarted: tutorialStarted,
      endlessBoards: endlessBoards,
      endlessResults: endlessResults,
      opened: opened,
      blueprints: blueprints,
      assemblies: assemblies,
    );
  }

  EndlessResult? resultFor(EndlessLevel level) {
    final id = level.lesson?.id;
    final result = endlessResults[id];
    if (result != null) return result;
    // Early Endless saves contain the winning board but no star metadata.
    final board = endlessBoards[id];
    if (board == null) return null;
    final star = _starFor(level, board);
    if (star == null) return null;
    return (
      revision: level.fixtureRevision,
      stars: Set.unmodifiable({star}),
      fourCableRecord:
          level == EndlessLevel.nightLights && board.links.length == 4,
    );
  }

  String? _starFor(EndlessLevel level, GameSave board) {
    if (board.lesson != level.lesson || !board.solved) return null;
    return board.signal == null
        ? level.solutionIds.single
        : level.solutionFor(board.signal!);
  }

  bool isComplete(TutorialLesson lesson) =>
      isUnlocked(lesson) && completed.contains(lesson.id);

  bool isUnlocked(TutorialLesson lesson) {
    final prerequisite = practiceLessons[lesson];
    if (prerequisite != null) return isComplete(prerequisite);
    for (final required in requiredLessons) {
      if (required == lesson) return true;
      if (!completed.contains(required.id)) return false;
    }
    return false;
  }

  TutorialProgress record(GameSave board) {
    if (!isUnlocked(board.lesson)) return this;
    return TutorialProgress(
      completed: {...completed, if (board.solved) board.lesson.id},
      boards: {...boards, board.lesson.id: board},
      endlessBoards: endlessBoards,
      endlessResults: endlessResults,
      opened: opened,
      blueprints: blueprints,
      assemblies: assemblies,
    );
  }

  TutorialProgress recordEndless(GameSave board) {
    final id = board.lesson.id;
    final level = endlessLevelsByLessonId[id]!;
    final saved = endlessBoards[id];
    final previous = resultFor(level);
    final star = _starFor(level, board);
    final record =
        level == EndlessLevel.nightLights &&
        star == 'balanced' &&
        board.links.length == 4;
    final newCredit =
        star != null &&
        (previous?.stars.contains(star) != true ||
            (record && previous?.fourCableRecord != true));
    final fittedAssembly =
        board.assemblyInstalled &&
        board.solved &&
        (saved?.assemblyInstalled != true || saved?.assembly != board.assembly);
    final updateBoard = saved?.solved != true || fittedAssembly;
    if (!updateBoard && !newCredit) return this;
    return TutorialProgress(
      completed: completed,
      boards: boards,
      tutorialStarted: tutorialStarted,
      endlessBoards: {...endlessBoards, if (updateBoard) id: board},
      opened: opened,
      blueprints: blueprints,
      assemblies: assemblies,
      endlessResults: {
        ...endlessResults,
        if (newCredit)
          id: (
            revision: level.fixtureRevision,
            stars: Set<String>.unmodifiable({...?previous?.stars, star}),
            fourCableRecord: record || previous?.fourCableRecord == true,
          ),
      },
    );
  }

  Map<String, Object> toJson() => {
    'version': 12,
    'completed': completed.toList(),
    'boards': boards.values.map((board) => board.toJson()).toList(),
    if (opened.isNotEmpty) 'opened': opened.toList(),
    if (blueprints.isNotEmpty)
      'blueprints': blueprints.map((blueprint) => blueprint.toJson()).toList(),
    if (assemblies.isNotEmpty)
      'assemblies': assemblies.map((design) => design.toJson()).toList(),
    if (!tutorialStarted) 'tutorialStarted': false,
    if (endlessBoards.isNotEmpty)
      'endlessBoards': endlessBoards.values
          .map((board) => board.toJson())
          .toList(),
    if (endlessResults.isNotEmpty)
      'endlessResults': {
        for (final MapEntry(:key, :value) in endlessResults.entries)
          key: {
            'revision': value.revision,
            'stars': value.stars.toList(),
            if (value.fourCableRecord) 'fourCableRecord': true,
          },
      },
  };

  factory TutorialProgress.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 12) return _fromJourney(json);
    final completed = json['completed'];
    final rows = json['boards'];
    if (completed is! List || rows is! List) {
      throw const FormatException('Invalid tutorial progress.');
    }
    final ids = <String>{};
    for (final id in completed) {
      if (id is! String || !lessonsById.containsKey(id) || !ids.add(id)) {
        throw const FormatException('Invalid completed lesson.');
      }
    }
    final boards = _readBoards(rows, lessonsById.containsKey);
    final endless = _readBoards(
      json['endlessBoards'] ?? const [],
      endlessLevelsByLessonId.containsKey,
    );
    final started = json['tutorialStarted'];
    final openedRows = json['opened'] ?? const [];
    if (openedRows is! List) {
      throw const FormatException('Invalid opened puzzles.');
    }
    final opened = <String>{};
    for (final id in openedRows) {
      if (id is! String || _lessonFor(id) == null || !opened.add(id)) {
        throw const FormatException('Invalid opened puzzle.');
      }
    }
    if ((started != null && started is! bool) ||
        (started == false && (ids.isNotEmpty || boards.isNotEmpty))) {
      throw const FormatException('Invalid tutorial state.');
    }
    return TutorialProgress(
      completed: ids,
      boards: boards,
      tutorialStarted: started != false,
      opened: opened,
      endlessBoards: endless,
      blueprints: _readBlueprints(json['blueprints'] ?? const []),
      assemblies: _readAssemblies(json['assemblies'] ?? const []),
      endlessResults: _readEndlessResults(
        json['endlessResults'] ?? const {},
        endless,
      ),
    );
  }

  static Set<SplitterBlueprint> _readBlueprints(Object data) {
    if (data is! List) {
      throw const FormatException('Invalid Workbench library.');
    }
    return data.map(SplitterBlueprint.fromJson).toSet();
  }

  static Set<AssemblyBlueprint> _readAssemblies(Object data) {
    if (data is! List) throw const FormatException('Invalid assembly library.');
    return data.map(AssemblyBlueprint.fromJson).toSet();
  }

  static Map<String, EndlessResult> _readEndlessResults(
    Object data,
    Map<String, GameSave> boards,
  ) {
    if (data is! Map) throw const FormatException('Invalid Endless results.');
    final results = <String, EndlessResult>{};
    for (final entry in data.entries) {
      final id = entry.key;
      final level = endlessLevelsByLessonId[id];
      if (id is! String || level == null || boards[id]?.solved != true) {
        throw const FormatException('Unknown completed Endless board.');
      }
      final result = entry.value;
      if (result case {'revision': final int revision, 'stars': final List ids}
          when revision == level.fixtureRevision) {
        final stars = <String>{};
        for (final star in ids) {
          if (star is! String ||
              !level.solutionIds.contains(star) ||
              !stars.add(star)) {
            throw const FormatException('Invalid Solution Star.');
          }
        }
        final record = result['fourCableRecord'];
        if (stars.isEmpty ||
            (record != null && record != true) ||
            (record == true &&
                (level != EndlessLevel.nightLights ||
                    !stars.contains('balanced')))) {
          throw const FormatException('Invalid Endless result.');
        }
        results[id] = (
          revision: revision,
          stars: Set.unmodifiable(stars),
          fourCableRecord: record == true,
        );
      } else {
        throw const FormatException('Invalid Endless fixture revision.');
      }
    }
    return results;
  }

  static Map<String, GameSave> _readBoards(
    Object? rows,
    bool Function(String) registered,
  ) {
    if (rows is! List) throw const FormatException('Invalid saved boards.');
    final boards = <String, GameSave>{};
    for (final row in rows) {
      if (row is! Map<String, dynamic> ||
          row['board'] is! String ||
          !registered(row['board'] as String)) {
        throw const FormatException('Invalid saved board.');
      }
      final board = GameSave.fromJson(row);
      if (boards.containsKey(board.lesson.id)) {
        throw const FormatException('Duplicate board.');
      }
      boards[board.lesson.id] = board;
    }
    return boards;
  }

  static TutorialProgress _fromJourney(Map<String, dynamic> json) {
    final version = json['version'];
    final scene = json['journey'];
    if (version == 1 && (scene == 'arrival' || scene == 'bayOpen')) {
      if (json['verified'] != false ||
          json['layout'] is! List ||
          (json['layout'] as List).isNotEmpty) {
        throw const FormatException('Unexpected legacy board.');
      }
      return TutorialProgress(
        completed: {if (scene == 'bayOpen') ..._opticalCredits},
      );
    }
    final board = GameSave.fromJson(json);
    final completed = <String>{
      if (board.lesson == testLine)
        ..._opticalCredits
      else
        for (final lesson in requiredLessons.takeWhile(
          (lesson) => lesson != board.lesson,
        ))
          lesson.id,
    };
    return TutorialProgress(
      completed: {...completed, if (board.solved) board.lesson.id},
      boards: {board.lesson.id: board},
    );
  }

  static final _opticalCredits = {
    firstReflection.id,
    dividedBeam.id,
    opticalInterlock.id,
  };
}

class GameStore {
  GameStore({Future<File> Function()? locate}) : _locate = locate ?? _saveFile;

  final Future<File> Function() _locate;
  Future<void> _pending = Future.value();

  static Future<File> _saveFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/journey.json');
  }

  Future<TutorialProgress?> load() async {
    await _pending;
    final file = await _locate();
    if (!await file.exists()) return null;
    return TutorialProgress.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
  }

  Future<void> write(TutorialProgress save) {
    final encoded = jsonEncode(save.toJson());
    final operation = _pending.then((_) async {
      final file = await _locate();
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(encoded, flush: true);
      await temporary.rename(file.path);
    });
    // A failed write is returned to its caller. Later saves can still retry.
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}
