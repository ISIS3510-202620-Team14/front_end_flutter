part of 'scanner_view.dart';

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

        final Future<void> Function()? scanAction;
        if (status == ScannerStatus.scanning) {
          scanAction = null;
        } else {
          scanAction = _viewModel.scan;
        }
        final Color importButtonColor;
        if (status == ScannerStatus.error) {
          importButtonColor = AppTheme.red;
        } else {
          importButtonColor = AppTheme.softInk;
        }
        final void Function()? importAction;
        if (valid.isEmpty || valid.length != _viewModel.rows.length) {
          importAction = null;
        } else {
          importAction = () {
            return Navigator.of(context).pop(valid);
          };
        }
        final String importLabel;
        if (valid.isEmpty) {
          importLabel = 'Importar lista';
        } else {
          importLabel = 'Importar ${valid.length} estudiantes';
        }
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Escanear lista de estudiantes',
                    style: text.headlineLarge,
                  ),
                  const SizedBox(height: 16),
                  _ScanBox(status: status, onTap: scanAction),
                  const SizedBox(height: 12),
                  Text(
                    _hint(status),
                    style: text.bodyLarge?.copyWith(
                      fontSize: 14,
                      color: importButtonColor,
                    ),
                  ),
                  if (_viewModel.rows.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _viewModel.rows.length,
                        separatorBuilder: (_, _) {
                          return const Divider(color: AppTheme.line, height: 1);
                        },
                        itemBuilder: (_, i) {
                          return _RowTile(
                            key: ObjectKey(_viewModel.rows[i]),
                            row: _viewModel.rows[i],
                            onRename: (v) {
                              return _viewModel.rename(i, v);
                            },
                            onCode: (v) {
                              return _viewModel.setCode(i, v);
                            },
                            onSex: (s) {
                              return _viewModel.setSex(i, s);
                            },
                            onRemove: () {
                              return _viewModel.remove(i);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.red,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: importAction,
                    child: Text(importLabel),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.ink,
                      side: const BorderSide(color: AppTheme.line),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      return Navigator.of(context).pop();
                    },
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
        return 'Completa los códigos reales y revisa los nombres antes de importar. Toca uno para '
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
