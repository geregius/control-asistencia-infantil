// =============================================================================
// main.dart — Punto de entrada: arma las piezas y arranca la app.
//
// Es el único lugar que decide qué implementación del repositorio se usa.
// Las pantallas reciben el contrato y no saben cuál es.
// =============================================================================

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
  // Necesario antes de usar plugins (como shared_preferences) en main.
  WidgetsFlutterBinding.ensureInitialized();

  // Abre el repositorio: carga lo guardado en el navegador o crea los datos
  // de demostración del día.
  final repositorio = await RepositorioPersistente.abrir(
    almacen: AlmacenPreferencias(SharedPreferencesAsync()),
  );

  // Arranca la app y le pasa el repositorio y la función del botón ⟳.
  runApp(AsistenciaApp(repositorio: repositorio, alReiniciar: repositorio.reiniciar));
}
