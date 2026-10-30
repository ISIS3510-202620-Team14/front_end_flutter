/**
 * Type 5 BQ: is this teacher likely to stop using the app soon, judging by how their weekly opens
 * are dropping? When they are, Hoy changes and shows a card to bring them back.
 */
class EngagementRisk {
  const EngagementRisk({
    required this.atRisk,
    required this.lastWeek,
    required this.usualWeek,
  });

  static const EngagementRisk none = EngagementRisk(
    atRisk: false,
    lastWeek: 0,
    usualWeek: 0,
  );

  /** Complete weeks looked at before the last one, to know the teacher's usual use. */
  static const int baselineWeeks = 3;

  /** Below this average there is no habit to lose yet, so no prediction is made. */
  static const double minimumUsualOpens = 1;

  final bool atRisk;
  // Opens in the last complete week.
  final int lastWeek;
  // Average opens per week in the weeks before it.
  final double usualWeek;

  /**
   * [weeklyOpens] has the opens of the last complete weeks, oldest first (the current week is
   * left out because it is not over yet). The teacher is at risk when they used to open the app
   * at least once a week and last week they opened it half as much or less.
   */
  static EngagementRisk fromWeeklyOpens(List<int> weeklyOpens) {
    if (weeklyOpens.length < baselineWeeks + 1) return none;
    final List<int> baseline = weeklyOpens.sublist(
      weeklyOpens.length - baselineWeeks - 1,
      weeklyOpens.length - 1,
    );
    final double usual =
        baseline.reduce((int a, int b) => a + b) / baseline.length;
    final int last = weeklyOpens.last;
    if (usual < minimumUsualOpens) {
      return EngagementRisk(atRisk: false, lastWeek: last, usualWeek: usual);
    }
    return EngagementRisk(
      atRisk: last <= usual / 2,
      lastWeek: last,
      usualWeek: usual,
    );
  }
}
