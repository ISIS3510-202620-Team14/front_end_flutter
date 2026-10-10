part of 'scanner_view.dart';

class _ScanBox extends StatelessWidget {
  const _ScanBox({required this.status, required this.onTap});

  final ScannerStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scanning = status == ScannerStatus.scanning;
    final hasRows = status == ScannerStatus.review;

    final double boxHeight;
    if (hasRows) {
      boxHeight = 72.0;
    } else {
      boxHeight = 150.0;
    }
    final Widget scanContent;
    if (scanning) {
      scanContent = const CircularProgressIndicator(color: AppTheme.red);
    } else {
      final double cameraIconSize;
      if (hasRows) {
        cameraIconSize = 28.0;
      } else {
        cameraIconSize = 48.0;
      }
      final String cameraLabel;
      if (hasRows) {
        cameraLabel = 'ESCANEAR OTRA PÁGINA';
      } else {
        cameraLabel = 'ABRIR CÁMARA';
      }
      scanContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            color: AppTheme.red,
            size: cameraIconSize,
          ),
          const SizedBox(width: 12),
          Text(
            cameraLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppTheme.ink,
            ),
          ),
        ],
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: boxHeight,
        decoration: BoxDecoration(
          color: AppTheme.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.line),
        ),
        child: Center(child: scanContent),
      ),
    );
  }
}
