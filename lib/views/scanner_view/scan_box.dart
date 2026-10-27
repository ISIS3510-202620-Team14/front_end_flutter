part of 'scanner_view.dart';

/** Keeps capture available while pages are read. */
class _ScanBox extends StatelessWidget {
  /** Creates the camera action. */
  const _ScanBox({required this.status, required this.onTap});
  final ScannerStatus status;
  final VoidCallback? onTap;

  /** Shows camera access and a separate processing indicator. */
  @override
  Widget build(BuildContext context) {
    final scanning = status == ScannerStatus.scanning;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.document_scanner_outlined, color: AppTheme.red),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              status == ScannerStatus.idle
                  ? 'Abrir cámara'
                  : 'Escanear otra página',
            ),
          ),
          if (scanning) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(64)),
    );
  }
}
