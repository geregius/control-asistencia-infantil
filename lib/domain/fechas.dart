/// Conversión de fechas entre la capa de datos y el dominio.
///
/// El dominio trabaja solo con [DateTime]. La base de datos puede
/// entregar la fecha como `DateTime`, como texto ISO-8601 o como un
/// objeto propio del proveedor (por ejemplo el `Timestamp` de Firestore,
/// que expone `toDate()`). Así los modelos no dependen de ningún SDK y
/// se pueden probar con `flutter test` sin servicios externos.
DateTime? leerFecha(Object? valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor;
  if (valor is String) return DateTime.tryParse(valor);
  try {
    final convertido = (valor as dynamic).toDate();
    if (convertido is DateTime) return convertido;
  } on NoSuchMethodError {
    // El objeto no sabe convertirse: se trata como fecha ausente.
  }
  return null;
}

/// Fecha en el formato con que se guarda (ISO-8601).
String escribirFecha(DateTime fecha) => fecha.toIso8601String();

/// La fecha sin hora (medianoche del mismo día).
DateTime soloDia(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);
