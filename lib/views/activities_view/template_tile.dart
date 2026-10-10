part of 'activities_view.dart';

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({required this.template, required this.onUse});

  final ActivityTemplate template;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  style: text.headlineLarge?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  '${template.minutes} min · ${template.description}',
                  style: text.bodyLarge?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.red,
              side: const BorderSide(color: AppTheme.red),
            ),
            onPressed: onUse,
            child: const Text('Usar'),
          ),
        ],
      ),
    );
  }
}
