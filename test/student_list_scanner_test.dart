import 'package:flutter_test/flutter_test.dart';
import 'package:front_end_flutter/services/student_list_scanner.dart';

void main() {
  test('parseNames limpia numeración, encabezados y duplicados', () {
    final names = StudentListScanner.parseNames([
      'LISTA DE ESTUDIANTES GRADO 3',
      'Nombre y apellido',
      '1. laura PÉREZ garcía',
      '2) Mateo Ruiz Salazar',
      '3 - Mateo Ruiz Salazar',
      'Ana',
      '14/09/2026',
      'María-José López',
    ]);
    expect(names, [
      'Laura Pérez García',
      'Mateo Ruiz Salazar',
      'María-José López',
    ]);
  });
}
