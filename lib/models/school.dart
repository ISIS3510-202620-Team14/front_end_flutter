/// Sede de una institución.
class Campus {
  final String id;
  final String name;

  const Campus({required this.id, required this.name});

  factory Campus.fromJson(Map<String, dynamic> json) =>
      Campus(id: json['id'] as String, name: json['name'] as String);
}

/// Institución que se puede elegir al crear la cuenta, con sus sedes.
class School {
  final String id;
  final String name;
  final String? municipality;
  final List<Campus> campuses;

  const School({
    required this.id,
    required this.name,
    this.municipality,
    this.campuses = const [],
  });

  factory School.fromJson(Map<String, dynamic> json) => School(
        id: json['id'] as String,
        name: json['name'] as String,
        municipality: json['municipality'] as String?,
        campuses: (json['campuses'] as List? ?? [])
            .map((e) => Campus.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// "IE Santo Tomás · Pereira", o solo el nombre si no hay municipio.
  String get label => municipality == null ? name : '$name · $municipality';
}
