// lib/ui/components/offline_notice.dart
import 'package:flutter/material.dart';
import 'package:front_end_flutter/ui/theme/app_theme.dart';

// Eventual connectivity Strategy: saved-list notice with refresh, matching AvisoDatosGuardados in the Kotlin EvaluacionMenuScreen.
/** Tells the teacher that the screen shows saved data or changes waiting to be sent, with the same texts as Kotlin. */
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key, required this.messages, this.onRefresh});
  final List<String> messages;
  final VoidCallback? onRefresh;

  /** Builds the lines of the notice: the saved list, then the changes that wait for connection. */
  static List<String> messagesFor({required int pending, String? savedAt}) {
    final List<String> lines = [];
    if (savedAt != null) {
      lines.add('Sin conexión. Lista guardada $savedAt');
    }
    if (pending == 1) {
      lines.add(
        '1 cambio guardado en este celular. Se enviará al recuperar conexión.',
      );
    } else if (pending > 1) {
      lines.add(
        '$pending cambios guardados en este celular. Se enviarán al recuperar conexión.',
      );
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.pendingBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.cloud_off_outlined,
              size: 20,
              color: AppTheme.pendingText,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final String line in messages)
                  Text(
                    line,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.pendingText,
                    ),
                  ),
              ],
            ),
          ),
          if (onRefresh != null)
            TextButton(
              onPressed: onRefresh,
              child: const Text(
                'Actualizar',
                style: TextStyle(color: AppTheme.pendingText),
              ),
            ),
        ],
      ),
    );
  }
}
