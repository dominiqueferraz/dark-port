enum WorkbenchIcon {
  bolt('Bolt'),
  prism('Prism'),
  compass('Compass'),
  spark('Spark'),
  shield('Shield'),
  gear('Gear');

  const WorkbenchIcon(this.label);
  final String label;
}

typedef WorkbenchPartMark = ({String name, WorkbenchIcon? icon});

const unmarkedWorkbenchPart = (name: '', icon: null as WorkbenchIcon?);

WorkbenchPartMark readWorkbenchPartMark(Object? json) {
  if (json is! Map) return unmarkedWorkbenchPart;
  final name = json['name'];
  final icon = json['icon'];
  return (
    name: name is String ? name.trim() : '',
    icon: WorkbenchIcon.values.where((mark) => mark.name == icon).firstOrNull,
  );
}

extension WorkbenchPartNaming on WorkbenchPartMark {
  String nameOr(String fallback) => name.isEmpty ? fallback : name;

  Map<String, String> toJson() => {
    if (name.isNotEmpty) 'name': name,
    if (icon case final icon?) 'icon': icon.name,
  };
}
