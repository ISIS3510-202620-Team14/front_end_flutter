import 'package:flutter/material.dart';
import 'package:front_end_flutter/models/subject_progress/subject_progress.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';

class SubjectProgressCard extends StatelessWidget {
  final SubjectProgress data;

  const SubjectProgressCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.panelRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${data.percent}%',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data.percent / 100,
              minHeight: 6,
              backgroundColor: AppTheme.line,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${data.evaluated} de ${data.total} estudiantes evaluados',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ver estudiantes',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
