import 'package:flutter/material.dart';
import 'package:front_end_flutter/screens/admin/report_pill.dart';
import 'package:front_end_flutter/ui/components/enad_panel.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

/** Title and description of a report with the refresh button, like EncabezadoReporte in Kotlin. */
class ReportHeader extends StatelessWidget {
  const ReportHeader({
    super.key,
    required this.title,
    required this.description,
    required this.loading,
    required this.onRefresh,
  });
  final String title;
  final String description;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleLarge),
              Text(description, style: text.bodyMedium),
            ],
          ),
        ),
        IconButton(
          onPressed: loading ? null : onRefresh,
          icon: const Icon(Icons.refresh, color: AppTheme.ink),
          tooltip: 'Actualizar',
        ),
      ],
    );
  }
}

/** Spinner, error message in a panel or content, like ContenidoCarga in Kotlin. */
class ReportMessagePanel extends StatelessWidget {
  const ReportMessagePanel({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return EnadPanel(
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/** Amber pill: the data of the current week can still change, like PildoraProvisional in Kotlin. */
class ProvisionalPill extends StatelessWidget {
  const ProvisionalPill({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: ReportPill(
        text: 'Semana en curso: el dato todavía puede cambiar',
        background: AppTheme.pendingBackground,
        color: AppTheme.pendingText,
      ),
    );
  }
}

/** Centered spinner while a report loads. */
class ReportLoading extends StatelessWidget {
  const ReportLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator(color: AppTheme.ink)),
    );
  }
}
