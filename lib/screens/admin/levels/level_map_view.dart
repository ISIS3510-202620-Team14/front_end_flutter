// lib/screens/admin/levels/level_map_view.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/domain/model/level.dart';
import 'package:front_end_flutter/domain/model/saved_data.dart';
import 'package:front_end_flutter/domain/model/school_levels.dart';
import 'package:front_end_flutter/screens/admin/levels/level_map_viewmodel.dart';
import 'package:front_end_flutter/screens/admin/report_pill.dart';
import 'package:front_end_flutter/screens/teacher/evaluation/classification_viewmodel.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/components/home_top_bar.dart';
import 'package:front_end_flutter/ui/components/offline_notice.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Sprint 4 new view (BQ): ENAd levels of every institution, Beginner share first. */
class LevelMapView extends StatefulWidget {
  const LevelMapView({super.key});

  @override
  State<LevelMapView> createState() {
    return _LevelMapViewState();
  }
}

class _LevelMapViewState extends State<LevelMapView> {
  late final LevelMapViewModel _viewModel = LevelMapViewModel()..start();

  static const Map<int, String> _grades = {
    0: 'Todos',
    3: '3°',
    4: '4°',
    5: '5°',
  };

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  List<Level> get _levels {
    return _viewModel.subject == 'matematicas'
        ? ClassificationViewModel.mathLevels
        : ClassificationViewModel.readingLevels;
  }

  String _percent(double? value) {
    return value == null ? '—' : '${value.round()} %';
  }

  Widget _status() {
    final LevelMapViewModel vm = _viewModel;
    final DateTime? savedAt = vm.savedAt;
    final String when = savedAt == null ? '' : ' ${SavedData.when(savedAt)}';
    switch (vm.status) {
      case LevelsStatus.loading:
        return const SizedBox.shrink();
      case LevelsStatus.updating:
        return Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text('Actualizando… ${vm.done} de ${vm.total} instituciones'),
          ],
        );
      case LevelsStatus.offline:
      case LevelsStatus.empty:
        if (vm.status == LevelsStatus.empty && !vm.connectionBack) {
          return const SizedBox.shrink();
        }
        return OfflineNotice(
          messages: [
            vm.connectionBack
                ? 'Volvió la conexión. Toca Actualizar para traer los niveles nuevos.'
                : 'Sin conexión · niveles guardados$when',
          ],
          onRefresh: vm.connectionBack ? () => vm.refresh() : null,
        );
      case LevelsStatus.online:
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ReportPill(
              text: 'Actualizado$when',
              background: AppTheme.assessedBackground,
              color: AppTheme.assessedText,
            ),
            if (vm.failed > 0)
              ReportPill(
                text:
                    '${vm.failed} sin actualizar · se muestran sus datos guardados',
                background: AppTheme.amberBackground,
                color: AppTheme.amberText,
              ),
          ],
        );
    }
  }

  Widget _filters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'lectura', label: Text('Lectura')),
            ButtonSegment(value: 'matematicas', label: Text('Matemáticas')),
          ],
          selected: {_viewModel.subject},
          onSelectionChanged: (Set<String> value) {
            _viewModel.choose(subject: value.first);
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final MapEntry<int, String> grade in _grades.entries)
              ChoiceChip(
                label: Text(grade.value),
                selected: _viewModel.grade == grade.key,
                onSelected: (_) => _viewModel.choose(grade: grade.key),
              ),
          ],
        ),
      ],
    );
  }

  Widget _summary(TextTheme text, List<Color> colors) {
    final int assessed = _viewModel.assessed;
    final LevelRow? worst = _viewModel.needsMostSupport;
    final List<int> totals = List<int>.filled(SchoolLevels.levels, 0);
    for (final LevelRow row in _viewModel.rows) {
      for (int level = 0; level < SchoolLevels.levels; level++) {
        totals[level] += row.levels[level];
      }
    }
    return EnadPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _percent(
              assessed == 0 ? null : _viewModel.beginners * 100 / assessed,
            ),
            style: text.displaySmall?.copyWith(color: AppTheme.red),
          ),
          Text('de $assessed estudiantes evaluados sigue en Principiante'),
          const SizedBox(height: 8),
          Text(
            worst == null
                ? 'Todavía no hay evaluaciones en este filtro.'
                : 'Necesita más apoyo: ${worst.name} (${_percent(worst.beginnerShare)})',
            style: text.titleSmall,
          ),
          const SizedBox(height: 14),
          _LevelsBar(counts: totals, colors: colors, height: 18),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (int i = 0; i < _levels.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 10,
                      child: ColoredBox(color: _levels[i].color),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_levels[i].name} ${totals[i + 1]}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  /** Developer mode: every step of the load, to show it on the phone. */
  void _showLogs() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheet) {
        return SizedBox(
          height: MediaQuery.of(sheet).size.height * 0.6,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text(
                'Cómo se cargó esta pantalla',
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final String line in _viewModel.logs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    line,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallback() {
    // Generic fallback (strategy 6): never a white page.
    return const EnadPanel(
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 40, color: AppTheme.softInk),
          SizedBox(height: 8),
          Text(
            'Aún no hay niveles guardados en este celular. Conéctate a internet '
            'y desliza hacia abajo para descargarlos; después podrás verlos sin conexión.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Niveles por institución'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: DeveloperMode.enabled,
            builder: (BuildContext context, bool enabled, Widget? child) {
              if (!enabled) return const SizedBox.shrink();
              return IconButton(
                onPressed: _showLogs,
                icon: const Icon(Icons.info_outline),
                tooltip: 'Logs',
              );
            },
          ),
          IconButton(
            onPressed: () => _viewModel.refresh(force: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (BuildContext context, Widget? child) {
          final List<LevelRow> rows = _viewModel.rows;
          final List<Color> colors = [for (final Level l in _levels) l.color];
          return RefreshIndicator(
            onRefresh: () => _viewModel.refresh(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.pageInset),
              children: [
                _status(),
                const SizedBox(height: 12),
                _filters(),
                const SizedBox(height: 12),
                if (_viewModel.status == LevelsStatus.loading && rows.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (rows.isEmpty &&
                    _viewModel.status != LevelsStatus.updating)
                  _fallback()
                else if (rows.isNotEmpty)
                  _summary(text, colors),
                const SizedBox(height: 20),
                if (rows.isNotEmpty) ...[
                  Text('Instituciones', style: text.titleMedium),
                  Text(
                    'De la que más apoyo necesita a la que menos',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 10),
                ],
                for (int i = 0; i < rows.length; i++)
                  _SchoolLevelsRow(
                    key: ValueKey(rows[i].schoolId),
                    rank: i + 1,
                    row: rows[i],
                    colors: colors,
                    stale: _viewModel.isStale(rows[i]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/** One institution: its position, stacked bar of the 6 levels and its Beginner share. */
class _SchoolLevelsRow extends StatelessWidget {
  const _SchoolLevelsRow({
    super.key,
    required this.rank,
    required this.row,
    required this.colors,
    required this.stale,
  });
  final int rank;
  final LevelRow row;
  final List<Color> colors;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double? share = row.beginnerShare;
    final bool alert = share != null && share >= 50;
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: EnadPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: rank == 1 ? AppTheme.red : AppTheme.line,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: rank == 1 ? Colors.white : AppTheme.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                ),
                ReportPill(
                  text: share == null
                      ? 'Sin evaluar'
                      : '${share.round()} % Principiante',
                  background: alert ? AppTheme.red : AppTheme.line,
                  color: alert ? Colors.white : AppTheme.ink,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LevelsBar(counts: row.levels, colors: colors, height: 14),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: '${row.assessed} evaluados · ${row.pending} sin evaluar',
                children: [
                  if (stale)
                    const TextSpan(
                      text: ' · sin actualizar',
                      style: TextStyle(color: AppTheme.amberText),
                    ),
                ],
              ),
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/** Stacked bar with one color per ENAd level (counts[0] = not assessed, not drawn). */
class _LevelsBar extends StatelessWidget {
  const _LevelsBar({
    required this.counts,
    required this.colors,
    required this.height,
  });
  final List<int> counts;
  final List<Color> colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    int assessed = 0;
    for (int level = 1; level < SchoolLevels.levels; level++) {
      assessed += counts[level];
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: assessed == 0
            ? ColoredBox(color: AppTheme.line)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int level = 1; level < SchoolLevels.levels; level++)
                    if (counts[level] > 0)
                      Expanded(
                        flex: counts[level],
                        child: ColoredBox(color: colors[level - 1]),
                      ),
                ],
              ),
      ),
    );
  }
}
