import 'package:flutter/material.dart';
import '../models/subject_progress.dart';
import '../theme/app_theme.dart';

class SubjectProgressCard extends StatelessWidget {
  final SubjectProgress data;

  const SubjectProgressCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontSize: 20),
              ),
              Text(
                '${data.percent}%',
                style: const TextStyle(
                  color: AppTheme.red,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
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
              valueColor: const AlwaysStoppedAnimation(AppTheme.red),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${data.evaluated} de ${data.total} estudiantes evaluados',
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
