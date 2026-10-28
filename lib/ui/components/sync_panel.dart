import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:front_end_flutter/data/sync/offline_runtime.dart';

class SyncPanel extends StatelessWidget {
  const SyncPanel({super.key, this.history = false});
  final bool history;
  String _label(String state) {
    switch (state) {
      case 'confirmed':
        return '✓✓ Confirmado por Firebase';
      case 'sending':
        return 'Enviando';
      case 'conflict':
        return 'No enviado: el registro cambió';
      case 'failed':
      case 'blocked':
        return 'Requiere atención';
      default:
        return '✓ Guardado en este celular';
    }
  }

  String _title(Map<String, dynamic> op) {
    final key = op['key'] as String;
    if (key.contains('/attendance/')) {
      return 'Asistencia · ${key.split('/').last}';
    }
    if (key.startsWith('hours/')) return 'Horas · ${key.split('/').last}';
    if (op['action'] == 'evaluate') return 'Evaluación';
    if (key.startsWith('students/')) return 'Estudiante';
    if (key.startsWith('groups/')) return 'Grupo';
    if (key.startsWith('plans/')) return 'Plan de actividades';
    if (key == 'profile') return 'Mis datos';
    return 'Actividad registrada';
  }

  String _details(Map<String, dynamic> op) {
    final body = Map<String, dynamic>.from(
      jsonDecode(op['body'] as String) as Map,
    );
    const labels = {
      'fullName': 'Nombre',
      'name': 'Nombre',
      'code': 'Código',
      'grade': 'Grado',
      'gender': 'Sexo',
      'age': 'Edad',
      'sample': 'Muestra',
      'status': 'Asistencia',
      'plannedHours': 'Horas programadas',
      'workedHours': 'Horas realizadas',
      'reason': 'Motivo',
      'date': 'Fecha',
      'title': 'Actividad',
      'minutes': 'Minutos',
      'subject': 'Materia',
      'type': 'Momento',
      'level': 'Nivel',
      'retired': 'Retirado',
    };
    const values = {
      'vino': 'Asistió',
      'no_vino': 'No asistió',
      'sin_registro': 'Sin registrar',
      'lectura': 'Lectura',
      'matematicas': 'Matemáticas',
      'inicial': 'Inicial',
      'media': 'Media',
      'final': 'Final',
      'especifica': 'Específica',
    };
    return body.entries
        .where((entry) {
          return labels.containsKey(entry.key) && entry.value != null;
        })
        .map((entry) {
          return '${labels[entry.key]}: ${values[entry.value.toString()] ?? entry.value}';
        })
        .join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final runtime = OfflineRuntime.current;
    if (runtime == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: runtime,
      builder: (context, child) {
        final title = runtime.downloading
            ? 'Descargando datos para trabajar sin conexión…'
            : runtime.paused
            ? 'Inicia sesión de nuevo para enviar pendientes'
            : runtime.pending > 0
            ? '${runtime.pending} pendientes · guardados en este celular'
            : runtime.attention > 0
            ? '${runtime.attention} registros requieren atención'
            : 'Datos disponibles sin conexión';
        if (!history) {
          return Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.cloud_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      runtime.message ?? title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Envíos y conexión',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(title),
            if (runtime.downloadedAt != null)
              Text(
                'Última descarga: ${DateTime.parse(runtime.downloadedAt!).toLocal()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (runtime.message != null) Text(runtime.message!),
            TextButton.icon(
              onPressed: runtime.running || runtime.downloading
                  ? null
                  : () async {
                      await runtime.retry();
                      if (runtime.pending == 0) await runtime.download();
                    },
              icon: const Icon(Icons.sync),
              label: const Text('Actualizar y enviar pendientes'),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: runtime.db.history(runtime.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('No pudimos leer el historial local.');
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final entries = snapshot.data!.reversed.where((op) {
                  return !RegExp(r'^(events|groupingEvents)/')
                      .hasMatch(op['key'] as String);
                }).toList();
                return Column(
                  children: [
                    for (final op in entries)
                      ExpansionTile(
                        title: Text(_title(op)),
                        subtitle: Text(_label(op['state'] as String)),
                        children: [
                          ListTile(
                            title: Text(op['created_at'] as String),
                            subtitle: Text(op['error'] as String? ?? ''),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(_details(op)),
                          ),
                        ],
                      ),
                    if (entries.isEmpty)
                      const Text(
                        'Todavía no hay envíos guardados en este dispositivo.',
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
