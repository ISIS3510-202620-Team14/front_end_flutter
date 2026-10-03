import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../viewmodels/top_activities_viewmodel.dart';
import '../widgets/section_label.dart';

class TopActivitiesView extends StatefulWidget {
  const TopActivitiesView({super.key});

  @override
  State<TopActivitiesView> createState() => _TopActivitiesViewState();
}

class _TopActivitiesViewState extends State<TopActivitiesView> {
  late final _viewModel = TopActivitiesViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.ink,
        foregroundColor: Colors.white,
        title: const Text('Actividades más usadas'),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.red),
            );
          }
          if (_viewModel.activities.isEmpty) {
            return const Center(
              child: Text('Todavía no hay actividades planeadas.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            itemCount: _viewModel.activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final a = _viewModel.activities[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.line),
                ),
                child: Row(
                  children: [
                    Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (a.subject != null) ...[
                            const SizedBox(height: 2),
                            SectionLabel(a.subject!.toUpperCase()),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '${a.count}  (${a.percentage?.toStringAsFixed(1) ?? "–"}%)',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
