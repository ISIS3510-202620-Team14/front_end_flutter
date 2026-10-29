import 'package:front_end_flutter/data/remote/api_client.dart';

/** Turns a failed report request into a message for the administrator. */
String reportErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 403) {
      return 'Solo una cuenta administradora puede ver este reporte.';
    }
    if (error.statusCode == 404) {
      return 'Este reporte aún no está disponible en el servidor.';
    }
  }
  return 'No pudimos cargar el reporte. Revisa tu conexión e intenta de nuevo.';
}

/** Formats a percentage that may be missing when there is nothing to count. */
String reportPercentage(dynamic value) {
  return value is num ? '${value.toStringAsFixed(1)}%' : 'Sin datos';
}
