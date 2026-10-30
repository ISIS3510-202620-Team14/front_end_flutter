class SubjectProgress {
  final String title;
  final int percent;
  final int evaluated;
  final int total;
  // Active students with more than LastAssessment.limitDays days without an assessment.
  final int overdue;

  const SubjectProgress({
    required this.title,
    required this.percent,
    required this.evaluated,
    required this.total,
    this.overdue = 0,
  });
}
