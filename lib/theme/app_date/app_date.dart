class AppDate {
  static String label(DateTime date) {
    const List<String> weekdays = [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ];
    return '${weekdays[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
