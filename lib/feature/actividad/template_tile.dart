part of 'activities_view.dart';

/** One library activity: icon, title, minutes and description, and a full-width "Usar" button like Kotlin. */
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
        borderRadius: BorderRadius.circular(AppTheme.panelRadius),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, color: AppTheme.ink),
              const SizedBox(width: 10),
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
                      style: text.bodyLarge?.copyWith(
                        fontSize: 13,
                        color: AppTheme.softInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onUse, child: const Text('Usar')),
          ),
        ],
      ),
    );
  }
}
