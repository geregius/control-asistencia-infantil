// =============================================================================
// almacen_local.dart — Dónde se guarda texto en el dispositivo.
//
// Define un contrato pequeño (leer, guardar, borrar) y dos implementaciones:
// una real, que guarda en el navegador, y otra en memoria para las pruebas.
// =============================================================================

import 'package:shared_preferences/shared_preferences.dart';

/// Lugar donde guardar texto en el dispositivo.
///
/// Abstracto para que las pruebas usen [AlmacenEnMemoria] y la app el
/// almacenamiento del navegador, sin cambiar el repositorio.
abstract class AlmacenLocal {
  /// El texto guardado con esa clave, o null si no hay.
  Future<String?> leer(String clave);

  /// Guarda (o reemplaza) el texto de esa clave.
  Future<void> guardar(String clave, String valor);

  /// Borra lo guardado con esa clave.
  Future<void> borrar(String clave);
}

/// Guarda en el navegador (localStorage) o en el teléfono, según la plataforma.
///
/// Usa el paquete `shared_preferences`, que elige el mecanismo de cada
/// plataforma: localStorage en web, SharedPreferences en Android,
/// NSUserDefaults en iPhone.
class AlmacenPreferencias implements AlmacenLocal {
  AlmacenPreferencias(this._preferencias);

  final SharedPreferencesAsync _preferencias;

  @override
  Future<String?> leer(String clave) => _preferencias.getString(clave);

  @override
  Future<void> guardar(String clave, String valor) => _preferencias.setString(clave, valor);

  @override
  Future<void> borrar(String clave) => _preferencias.remove(clave);
}

/// Almacén que vive solo mientras corre el programa (pruebas).
///
/// Los métodos son `async`: aunque el trabajo es inmediato, devuelven un
/// Future para cumplir el mismo contrato que el almacén real.
class AlmacenEnMemoria implements AlmacenLocal {
  /// Público para que las pruebas puedan revisar qué se guardó.
  final datos = <String, String>{};

  @override
  Future<String?> leer(String clave) async => datos[clave];

  @override
  Future<void> guardar(String clave, String valor) async => datos[clave] = valor;

  @override
  Future<void> borrar(String clave) async => datos.remove(clave);
}
