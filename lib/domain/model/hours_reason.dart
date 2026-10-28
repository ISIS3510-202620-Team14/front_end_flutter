class HoursReason {
  const HoursReason({this.category, this.detail = ''});
  final String? category;
  final String detail;
  static const List<String> categories = [
    'Familiar',
    'Personal',
    'Salud',
    'Transporte',
    'Institucional',
    'Otro',
  ];

  factory HoursReason.fromStored(String value) {
    for (final String category in categories) {
      if (value == category) {
        return HoursReason(category: category);
      }
      if (value.startsWith('$category: ')) {
        return HoursReason(
          category: category,
          detail: value.substring(category.length + 2),
        );
      }
    }
    if (value.trim().isEmpty) {
      return const HoursReason();
    }
    return HoursReason(category: 'Otro', detail: value);
  }

  String? get error {
    if (!categories.contains(category)) {
      return 'Selecciona un motivo.';
    }
    if (category == 'Otro' && detail.trim().isEmpty) {
      return 'Escribe el motivo.';
    }
    if (stored.length > 500) {
      return 'Acorta el detalle a 480 caracteres.';
    }
    return null;
  }

  String get stored {
    if (category == null) {
      return '';
    }
    if (detail.trim().isEmpty) {
      return category!;
    }
    return '$category: ${detail.trim()}';
  }
}
