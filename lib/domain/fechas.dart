// =============================================================================
// fechas.dart — Conversión de fechas entre la base de datos y el dominio.
//
// El dominio solo trabaja con DateTime (el tipo de fecha de Dart). Este archivo
// traduce lo que venga de afuera (texto, Timestamp de Firestore...) a DateTime,
// para que el resto del código no dependa de ningún proveedor.
// =============================================================================

/// Convierte cualquier valor que represente una fecha en un [DateTime].
///
/// El dominio trabaja solo con [DateTime]. La base de datos puede
/// entregar la fecha como `DateTime`, como texto ISO-8601 o como un
/// objeto propio del proveedor (por ejemplo el `Timestamp` de Firestore,
/// que expone `toDate()`). Así los modelos no dependen de ningún SDK y
/// se pueden probar con `flutter test` sin servicios externos.
///
/// Devuelve `null` si el valor no se puede convertir.
DateTime? leerFecha(Object? valor) {
  // Sin valor: no hay fecha.
  if (valor == null) return null;

  // Ya es una fecha: se devuelve tal cual.
  if (valor is DateTime) return valor;

  // Texto ISO-8601 ("2026-11-03T08:40:00"): tryParse devuelve null si no es válido.
  if (valor is String) return DateTime.tryParse(valor);

  // Cualquier otro objeto: se intenta llamar a toDate(), como tiene el
  // Timestamp de Firestore. Se usa `dynamic` para no tener que importar su
  // paquete: si el método existe, se llama; si no, Dart lanza NoSuchMethodError.
  try {
    final convertido = (valor as dynamic).toDate();
    if (convertido is DateTime) return convertido;
  } on NoSuchMethodError {
    // El objeto no sabe convertirse: se trata como fecha ausente.
  }
  return null;
}

/// Fecha en el formato con que se guarda (texto ISO-8601).
String escribirFecha(DateTime fecha) => fecha.toIso8601String();

/// La fecha sin hora (medianoche del mismo día). Sirve para comparar si dos
/// momentos caen en el mismo día.
DateTime soloDia(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);
