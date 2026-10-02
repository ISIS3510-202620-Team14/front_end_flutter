/// Escuela que se puede elegir al crear la cuenta.
class School {
  final String id;
  final String name;
  final String? municipality;

  const School({required this.id, required this.name, this.municipality});

  factory School.fromJson(Map<String, dynamic> json) => School(
        id: json['id'] as String,
        name: json['name'] as String,
        municipality: json['municipality'] as String?,
      );

  /// "IE Santo Tomás · Pereira", o solo el nombre si no hay municipio.
  String get label => municipality == null ? name : '$name · $municipality';
}
