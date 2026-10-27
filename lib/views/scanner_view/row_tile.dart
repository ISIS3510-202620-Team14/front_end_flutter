part of 'scanner_view.dart';

/** Edits a reviewed student without changing its identity. */
class _RowTile extends StatelessWidget {
  /** Creates row editing callbacks. */
  const _RowTile({
    super.key,
    required this.row,
    required this.onRename,
    required this.onCode,
    required this.onGrade,
    required this.onAge,
    required this.onSex,
    required this.onRemove,
  });

  final ScannedRow row;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onCode;
  final ValueChanged<String> onGrade;
  final ValueChanged<String> onAge;
  final ValueChanged<String> onSex;
  final VoidCallback onRemove;

  /** Shows the detected fields. */
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                TextFormField(
                  initialValue: row.name,
                  onChanged: onRename,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
                TextFormField(
                  initialValue: row.code,
                  onChanged: onCode,
                  decoration: const InputDecoration(
                    labelText: 'Código del estudiante',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: row.grade?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: onGrade,
                        decoration: const InputDecoration(
                          labelText: 'Grado',
                          hintText: 'Curso elegido',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: row.age?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: onAge,
                        decoration: const InputDecoration(labelText: 'Edad'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (final s in const ['F', 'M'])
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: ChoiceChip(
                label: Text(s),
                selected: row.sex == s,
                onSelected: (_) {
                  return onSex(s);
                },
                selectedColor: AppTheme.red,
                labelStyle: TextStyle(color: _sexColor(s)),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            tooltip: 'Quitar',
            icon: const Icon(Icons.close, color: AppTheme.softInk),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  /** Uses readable text for the selected option. */
  Color _sexColor(String s) {
    if (row.sex == s) {
      return Colors.white;
    } else {
      return AppTheme.ink;
    }
  }
}
