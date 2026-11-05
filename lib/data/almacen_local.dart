import 'package:shared_preferences/shared_preferences.dart';

/// Lugar donde guardar texto en el dispositivo.
///
/// Abstracto para que las pruebas usen [AlmacenEnMemoria] y la app el
/// almacenamiento del navegador, sin cambiar el repositorio.
abstract class AlmacenLocal {
  Future<String?> leer(String clave);
  Future<void> guardar(String clave, String valor);
  Future<void> borrar(String clave);
}

/// Guarda en el navegador (localStorage) o en el teléfono, según la plataforma.
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
class AlmacenEnMemoria implements AlmacenLocal {
  final datos = <String, String>{};

  @override
  Future<String?> leer(String clave) async => datos[clave];

  @override
  Future<void> guardar(String clave, String valor) async => datos[clave] = valor;

  @override
  Future<void> borrar(String clave) async => datos.remove(clave);
}
