# ENAd Móvil · Flutter

Frontend docente de ENAd Móvil. MVVM, Firebase Authentication, APIs HTTP existentes y persistencia privada en Firestore.

## Ejecutar

`flutter pub get`

`flutter run -d emulator-5554`

Configuración: USE_EMULATORS, EMULATOR_HOST, AUTH_EMULATOR_PORT, FIRESTORE_EMULATOR_PORT y API_BASE_URL se pasan mediante --dart-define. Producción sigue usando enad-movil. El ID token de Firebase se obtiene al realizar cada solicitud protegida.

La navegación incluye Hoy, Mi lista, Grupos, Horas y Mis datos. Planear actividades permanece en Hoy. Los reportes administrativos de BQs se preparan para Power BI mediante tools/export_metrics.cjs y tools/build_powerbi.py.

Consultar [estructura, pruebas y límites conocidos](docs/VALIDATION.md).
