/// Capa de dominio: modelos y reglas de negocio en Dart puro, sin
/// dependencias de Flutter ni de la base de datos.
///
/// Este archivo no tiene código propio: reexporta los demás (`export`), así
/// el resto de la app importa todo el dominio con una sola línea:
/// `import '../domain/dominio.dart';`.
library;

export 'acudiente.dart';
export 'estadisticas.dart';
export 'fechas.dart';
export 'nino.dart';
export 'registro.dart';
export 'rol_usuario.dart';
