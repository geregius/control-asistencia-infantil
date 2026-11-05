import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/almacen_local.dart';
import 'data/repositorio_persistente.dart';
import 'ui/app.dart';

/// Punto de entrada de la demo: datos ficticios que se guardan en el
/// navegador, así que sobreviven a una recarga. La versión en producción
/// inyecta aquí un repositorio sobre Firestore; el resto del código es el
/// mismo.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repositorio = await RepositorioPersistente.abrir(
    almacen: AlmacenPreferencias(SharedPreferencesAsync()),
  );
  runApp(AsistenciaApp(repositorio: repositorio, alReiniciar: repositorio.reiniciar));
}
