import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../viewmodels/scanner_viewmodel.dart';


Future<List<ScannedRow>?> showStudentScanner(BuildContext context) {
  return showModalBottomSheet<List<ScannedRow>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const ScannerView(),
  );
}

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final _viewModel = ScannerViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final status = _viewModel.status;
        final valid = _viewModel.validRows;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, 16 + MediaQuery.of(context).viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Escanear lista de estudiantes',
                      style: text.headlineLarge),
                  const SizedBox(height: 16),
                  _ScanBox(
                    status: status,
                    onTap: status == ScannerStatus.scanning
                        ? null
                        : _viewModel.scan,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _hint(status),
                    style: text.bodyLarge?.copyWith(
                      fontSize: 14,
                      color: status == ScannerStatus.error
                          ? AppTheme.red
                          : AppTheme.softInk,
                    ),
                  ),
                  if (_viewModel.rows.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _viewModel.rows.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: AppTheme.line, height: 1),
                        itemBuilder: (_, i) => _RowTile(
                          key: ObjectKey(_viewModel.rows[i]),
                          row: _viewModel.rows[i],
                          onRename: (v) => _viewModel.rename(i, v),
                          onSex: (s) => _viewModel.setSex(i, s),
                          onRemove: () => _viewModel.remove(i),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.red,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: valid.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(valid),
                    child: Text(valid.isEmpty
                        ? 'Importar lista'
                        : 'Importar ${valid.length} estudiantes'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.ink,
                      side: const BorderSide(color: AppTheme.line),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _hint(ScannerStatus status) {
    switch (status) {
      case ScannerStatus.scanning:
        return 'Leyendo nombres…';
      case ScannerStatus.review:
        return 'Revisa los nombres antes de importar. Toca uno para '
            'corregirlo. Puedes escanear otra página.';
      case ScannerStatus.empty:
        return 'No encontramos nombres. Toma la foto de frente, con buena luz.';
      case ScannerStatus.error:
        return _viewModel.error ?? '';
      case ScannerStatus.idle:
        return 'Toma una foto de la lista impresa o escrita a mano '
            '(un estudiante por renglón: nombre y apellido).';
    }
  }
}

class _ScanBox extends StatelessWidget {
  const _ScanBox({required this.status, required this.onTap});

  final ScannerStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scanning = status == ScannerStatus.scanning;
    final hasRows = status == ScannerStatus.review;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: hasRows ? 72 : 150,
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.line),
        ),
        child: Center(
          child: scanning
              ? const CircularProgressIndicator(color: AppTheme.red)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.document_scanner_outlined,
                        color: AppTheme.red, size: hasRows ? 28 : 48),
                    const SizedBox(width: 12),
                    Text(
                      hasRows ? 'ESCANEAR OTRA PÁGINA' : 'ABRIR CÁMARA',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    super.key,
    required this.row,
    required this.onRename,
    required this.onSex,
    required this.onRemove,
  });

  final ScannedRow row;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onSex;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: row.name,
              onChanged: onRename,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          for (final s in const ['F', 'M'])
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: ChoiceChip(
                label: Text(s),
                selected: row.sex == s,
                onSelected: (_) => onSex(s),
                selectedColor: AppTheme.red,
                labelStyle: TextStyle(
                    color: row.sex == s ? Colors.white : AppTheme.ink),
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
}
