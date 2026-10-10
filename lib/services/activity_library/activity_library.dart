import 'package:front_end_flutter/models/activity/activity.dart';

/// Shared activity library.
class ActivityLibrary {
  static const templates = <ActivityTemplate>[
    ActivityTemplate(
      id: 'lec-01',
      title: 'Lectura en voz alta por turnos',
      subject: 'Lectura',
      minutes: 20,
      description: 'Cada estudiante lee un párrafo y el grupo comenta.',
    ),
    ActivityTemplate(
      id: 'lec-02',
      title: 'Palabras nuevas del cuento',
      subject: 'Lectura',
      minutes: 15,
      description: 'Subrayar palabras desconocidas y adivinar su significado.',
    ),
    ActivityTemplate(
      id: 'lec-03',
      title: 'Cambia el final',
      subject: 'Lectura',
      minutes: 30,
      description: 'Escribir un final distinto para la historia leída.',
    ),
    ActivityTemplate(
      id: 'mat-01',
      title: 'Tienda del salón',
      subject: 'Matemáticas',
      minutes: 30,
      description: 'Comprar y dar vueltas con billetes de papel.',
    ),
    ActivityTemplate(
      id: 'mat-02',
      title: 'Cálculo mental en parejas',
      subject: 'Matemáticas',
      minutes: 15,
      description: 'Sumas y restas rápidas con tarjetas.',
    ),
    ActivityTemplate(
      id: 'mat-03',
      title: 'Medir el salón',
      subject: 'Matemáticas',
      minutes: 25,
      description: 'Medir objetos con pasos, cuartas y metro.',
    ),
  ];

  static List<ActivityTemplate> bySubject(String subject) {
    return templates.where((t) {
      return t.subject == subject;
    }).toList();
  }
}
