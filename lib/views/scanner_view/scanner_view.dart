import 'package:flutter/material.dart';
import 'package:front_end_flutter/theme/app_theme/app_theme.dart';
import 'package:front_end_flutter/viewmodels/scanner_viewmodel/scanner_viewmodel.dart';
part 'scanner_view_state.dart';
part 'scan_box.dart';
part 'row_tile.dart';

Future<List<ScannedRow>?> showStudentScanner(BuildContext context) {
  return showModalBottomSheet<List<ScannedRow>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return const ScannerView();
    },
  );
}

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() {
    return _ScannerViewState();
  }
}
