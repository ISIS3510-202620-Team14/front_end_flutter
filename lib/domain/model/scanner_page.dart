enum ScannerPageState { queued, reading, ready, failed }

/** Shows the progress of one captured page. */
class ScannerPage {
  /** Creates a page snapshot. */
  const ScannerPage(
    this.number,
    this.path, {
    this.state = ScannerPageState.queued,
    this.count = 0,
  });
  final int number;
  final String path;
  final ScannerPageState state;
  final int count;

  /** Returns a page with its latest result. */
  ScannerPage updated(ScannerPageState state, [int count = 0]) {
    return ScannerPage(number, path, state: state, count: count);
  }
}
