import 'package:flutter/material.dart';

import 'data/datos_demo.dart';
import 'data/repositorio_en_memoria.dart';
import 'ui/app.dart';

/// Punto de entrada de la demo: la app corre con datos ficticios en
/// memoria. La versión en producción inyecta aquí un repositorio sobre
/// Firestore; el resto del código es el mismo.
void main() {
  final datos = DatosDemo.generar(DateTime.now());
  runApp(AsistenciaApp(
    repositorio: RepositorioEnMemoria(ninos: datos.ninos, registros: datos.registros),
  ));
}
