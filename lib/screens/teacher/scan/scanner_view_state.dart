// lib/screens/teacher/scan/scanner_view_state.dart
part of 'scanner_view.dart';

/** Owns the scanner while the sheet is open. */
class _ScannerViewState extends State<ScannerView> {
  final _thumbnails = ThumbnailCache();
  late final _viewModel = ScannerViewModel(
    allowProvisional: widget.allowProvisional,
    capture: _captureWithCamera,
  );

  /** Opens own camera and, if the teacher takes a photo, returns its path and conditions. */
  Future<CapturedPhoto?> _captureWithCamera() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      throw UnsupportedError(
        'El escáner requiere la aplicación Android o iOS.',
      );
    }
    return Navigator.of(context).push<CapturedPhoto>(
      MaterialPageRoute(
        builder: (_) => const CameraCaptureView(),
        fullscreenDialog: true,
      ),
    );
  }

  /** Releases the current scan. */
  @override
  void dispose() {
    _thumbnails.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /** Shows capture, page progress and editable rows. */
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        // # micro opt
        final rows = _viewModel.rows;
        final pages = _viewModel.pages;
        final status = _viewModel.status;
        final valid = _viewModel.validRows;

        final Future<void> Function()? scanAction;
        if (_viewModel.capturing) {
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
        if (_viewModel.processing ||
            _viewModel.capturing ||
            valid.isEmpty ||
            _viewModel.validationError != null) {
          importAction = null;
        } else {
          importAction = () {
            // It registers before closing: after the ViewModel no longer exists.
            _viewModel.reportReview();
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
                  if (pages.isNotEmpty)
                    SizedBox(
                      height: 86,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final page in pages)
                            Padding(
                              padding: const EdgeInsets.only(right: 12, top: 8),
                              child: Row(
                                children: [
                                  ScannerThumbnail(
                                    key: ValueKey(page.path),
                                    path: page.path,
                                    cache: _thumbnails,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Página ${page.number}\n${_pageLabel(page)}',
                                    style: text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    _hint(status),
                    style: text.bodyLarge?.copyWith(
                      fontSize: 14,
                      color: importButtonColor,
                    ),
                  ),
                  if (rows.isNotEmpty) ...[
                    if (_viewModel.validationError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_viewModel.validationError!),
                      ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: rows.length,
                        separatorBuilder: (_, _) {
                          return const Divider(color: AppTheme.line, height: 1);
                        },
                        itemBuilder: (_, i) {
                          return _RowTile(
                            key: ValueKey(_viewModel.rowId(i)),
                            row: rows[i],
                            onRename: (v) {
                              return _viewModel.rename(i, v);
                            },
                            onCode: (v) {
                              return _viewModel.setCode(i, v);
                            },
                            onGrade: (v) {
                              _viewModel.setGrade(i, v);
                            },
                            onAge: (v) {
                              _viewModel.setAge(i, v);
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

  /** Names the page's processing state. */
  String _pageLabel(ScannerPage page) {
    switch (page.state) {
      case ScannerPageState.queued:
        return 'En cola';
      case ScannerPageState.reading:
        return 'Leyendo…';
      case ScannerPageState.ready:
        return '${page.count} estudiantes';
      case ScannerPageState.failed:
        return 'No se pudo leer';
    }
  }

  /** Explains the next action. */
  String _hint(ScannerStatus status) {
    switch (status) {
      case ScannerStatus.scanning:
        return 'Leyendo páginas… Puedes tomar otra foto mientras terminamos.';
      case ScannerStatus.review:
        return widget.allowProvisional
            ? 'Revisa los datos antes de importar. Los códigos vacíos serán provisionales; coordinación debe completar el código oficial.'
            : 'Completa los códigos reales y revisa los nombres antes de importar. Toca uno para '
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
