part of 'week_day_selector.dart';

class _WeekDaySelectorState extends State<WeekDaySelector> {
  final ScrollController _scroll = ScrollController();
  double _extent = 0;

  void _centerSelected() {
    WidgetsBinding.instance.addPostFrameCallback((Duration elapsed) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo((widget.selected.weekday - 1) * _extent);
      }
    });
  }

  @override
  void didUpdateWidget(WeekDaySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.selected, widget.selected)) {
      _centerSelected();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static const List<String> _labels = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  @override
  Widget build(BuildContext context) {
    final DateTime start = DateTime(
      widget.selected.year,
      widget.selected.month,
      widget.selected.day,
    ).subtract(Duration(days: widget.selected.weekday - 1));
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double extent =
            72 * MediaQuery.textScalerOf(context).scale(14) / 14;
        if (_extent != extent) {
          _extent = extent;
          _centerSelected();
        }
        final double padding =
            (constraints.maxWidth - extent).clamp(0, double.infinity) / 2;
        return SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            children: [
              for (int index = 0; index < 7; index++)
                SizedBox(
                  width: extent,
                  child: _day(context, start.add(Duration(days: index)), index),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _day(BuildContext context, DateTime day, int index) {
    final bool active = DateUtils.isSameDay(day, widget.selected);
    Color background = AppTheme.surface;
    Color foreground = AppTheme.ink;
    if (active) {
      background = AppTheme.ink;
      foreground = AppTheme.surface;
    }
    VoidCallback? action;
    if (!day.isAfter(widget.lastDate) &&
        day.year == widget.lastDate.year &&
        widget.onChanged != null) {
      action = () {
        widget.onChanged!(day);
      };
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        selected: active,
        child: OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            minimumSize: const Size(52, 60),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.controlRadius),
            ),
          ),
          child: Column(
            children: [
              Text(
                _labels[index],
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: foreground),
              ),
              Text(
                '${day.day}',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
