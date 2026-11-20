class Diver {
  const Diver({this.id, required this.name, this.firstDiveNumber = 1});

  /// UUID v4, assigned by the repository on first save.
  final String? id;
  final String name;

  /// Number given to this diver's first logged dive (ADR 0004).
  final int firstDiveNumber;
}
