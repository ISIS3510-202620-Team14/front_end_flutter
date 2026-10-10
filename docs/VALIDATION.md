# Validación y límites de Flutter

## Estructura

Cada capa agrupa las clases por funcionalidad: views, viewmodels, models, services y factories. Cada clase tiene su archivo. Los archivos part permiten separar State y widgets privados sin hacer pública la implementación. Las funciones usan cuerpo y las decisiones usan if/else. firebase_options.dart sigue siendo generado.

Se conserva MVVM con ChangeNotifier, Adapter para estudiantes, Repository para datos y Factory Method para crear actividades. ApiClient centraliza la configuración, el ID token vigente, los tiempos de espera y los errores HTTP. SafeNotifier protege los resultados asíncronos después de dispose.

## Funcionamiento

Registro selecciona instituciones y sedes. El perfil decide si la cuenta puede entrar; un administrador consulta reportes en Power BI. Mi lista importa códigos reales a /students/import y recarga IDs del servidor; nunca inventa identidades. Los nombres iguales con códigos diferentes pueden representar personas distintas. Clasificación usa los niveles reales del backend.

Grupos emplea instituciones autorizadas y el UID de sesión. Detalle permite renombrar, agregar/quitar estudiantes y eliminar el grupo. La recomendación conserva tolerancias de tamaño de clase de 3, 5 y 8 y mínimo de tres observaciones. La selección de método sigue siendo una recomendación, no un algoritmo nuevo de reparto.

Las actividades de biblioteca y propias se guardan en users/{uid}/actions como kind=flutter_activity, con fecha de Colombia. Guardado y evento activity_selected se confirman en una transacción con IDs estables para evitar doble conteo al reintentar. Nuevos repositorios y una nueva sesión recuperan el mismo plan. El reporte de uso y el ranking administrativo salen de la app.

Horas registra días reales mediante PUT /workedHours/:date. El backend compartido no ofrece lectura del historial propio del docente, solo un reporte administrativo. Flutter conserva comprobantes privados de los envíos confirmados bajo kind=flutter_hours_receipt. Estos comprobantes no sustituyen el historial canónico ni incluyen envíos desde Kotlin. No se modificó el backend para resolver ese límite.

## Analítica

Los eventos activity_selected y grouping_method_selected llevan platform=flutter. BQ #4 cuenta planes confirmados; BQ #11 cuenta frecuencia por título; BQ #14 describe las decisiones de agrupación por materia y tamaño de clase. No se infiere eficacia educativa. Los eventos históricos sin plataforma verificable quedan fuera.

La extracción de producción del 10 de octubre de 2026 encontró cero eventos verificables de Flutter y excluyó cuatro eventos de otras plataformas o sin plataforma. Los datos del emulador no se incluyen en el reporte. La creación web de modelos está deshabilitada por el tenant universitario. Se entrega un proyecto PBIP con tres páginas, medidas DAX y partición M portable. Sus definiciones se validan contra esquemas oficiales, pero su renderizado y publicación requieren Power BI Desktop o habilitación del tenant. No se configuraron servicios adicionales ni actualización automática.

Recarga: `node tools/export_metrics.cjs analytics-export`, después `python tools/build_powerbi.py analytics-export`. Requiere Firebase CLI autenticado con permiso de lectura; FIREBASE_TOOLS_ROOT permite indicar su instalación. Abrir analytics-export/ENAd_Flutter_PowerBI/ENAd.pbip, actualizar y publicar privadamente cuando exista acceso. No se guardan credenciales ni datos personales en Git.

## Comandos de validación

`flutter analyze --no-pub`

`flutter test --no-pub`

`flutter build apk --debug --no-pub`

Integración en Android: levantar una copia del backend existente con fixtures de escuela flutter-e2e-school y docente flutter-e2e-teacher. No ejecutar contra producción. El test requiere USE_EMULATORS=true y los puertos y URL indicados en la configuración del emulador.

`flutter test integration_test --no-pub --no-uninstall -d emulator-5554 --dart-define=USE_EMULATORS=true --dart-define=AUTH_EMULATOR_PORT=9199 --dart-define=FIRESTORE_EMULATOR_PORT=8180 --dart-define=API_BASE_URL=http://10.0.2.2:5101/enad-movil/us-central1`

Las 14 pruebas unitarias y de widgets pasan. Cubren token, importación, códigos incompletos/repetidos, errores HTTP, grupos, OCR y recomendaciones; los de widgets cubren sesión y las cinco entradas de navegación. La prueba integrada comprueba contratos reales, evaluación, importación idempotente, grupos, cierre/restauración de sesión, persistencia de actividades y comprobantes de horas. La cámara física y el renderizado en Power BI requieren validación adicional.


Los cuatro casos de cálculo de referencia pasan con totales conocidos, periodos vacíos, exclusión de Kotlin/origen desconocido y fuentes inválidas. Se validaron 32 definiciones PBIP/PBIR contra los esquemas JSON oficiales. Estas comprobaciones no ejecutan el motor DAX ni prueban el renderizado de Desktop.

El historial propio canónico de horas sigue bloqueado por contrato: functions/horas/index.js ofrece PUT /:date y GET /report restringido a administrador. Una respuesta stored=false no genera comprobante ni mensaje de éxito en Flutter. La cámara física requiere probarse en un teléfono; el parser se prueba sin cámara.

Para consultar la recarga y las pruebas de referencia: `python -m unittest discover -s tools -p test_metrics.py`.


Resultado Android: las dos pruebas integradas pasaron en emulator-5554 contra Auth 9199, Firestore 8180 y Functions 5101 aislados. La segunda inició un proceso nuevo y recuperó sesión, plan y comprobante sin volver a iniciar sesión. --no-uninstall conserva datos entre los dos ejecutables de prueba. No se realizaron escrituras de prueba en producción.

## Ejecutar desde Android Studio

Seleccionar el perfil compartido `Flutter Local Android` y el dispositivo Android. El perfil incluye USE_EMULATORS=true, AUTH_EMULATOR_PORT=9199, FIRESTORE_EMULATOR_PORT=8180 y API_BASE_URL=http://10.0.2.2:5101/enad-movil/us-central1. Pasar solamente USE_EMULATORS=true utiliza otros puertos y no conecta con este entorno.

Cuando la APK compila pero ADB se bloquea en force-stop, install o uninstall, revisar el emulador antes de cambiar el código. En Medium_Phone, restaurar el snapshot de Quick Boot volvió a mostrar el reloj del día anterior y el bloqueo de instalación. Arrancar en frío permitió instalar y ejecutar. Usar Cold Boot Now desde Device Manager o arrancar con -no-snapshot-load; no es necesario borrar los datos del dispositivo.
