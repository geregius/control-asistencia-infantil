// =============================================================================
// app.dart — La app: tema, barra superior y navegación entre las 4 pantallas.
// =============================================================================

import 'package:flutter/material.dart';

import '../data/repositorio_asistencia.dart';
import 'pantalla_cumpleanos.dart';
import 'pantalla_dashboard.dart';
import 'pantalla_ingreso.dart';
import 'pantalla_presentes.dart';
import 'tema.dart';

/// El widget raíz. Recibe el repositorio desde main.dart (inyección de
/// dependencias): la app no sabe ni le importa de dónde vienen los datos.
class AsistenciaApp extends StatelessWidget {
  const AsistenciaApp({super.key, required this.repositorio, this.alReiniciar});

  final RepositorioAsistencia repositorio;

  /// Si se da, la barra superior muestra un botón para volver a los datos
  /// de demostración del día.
  final Future<void> Function()? alReiniciar;

  @override
  Widget build(BuildContext context) {
    // MaterialApp configura el tema, el título y la pantalla inicial.
    return MaterialApp(
      title: 'Asistencia Infantil',
      debugShowCheckedModeBanner: false,
      theme: temaApp(),
      home: _Inicio(repositorio: repositorio, alReiniciar: alReiniciar),
    );
  }
}

/// Estructura común: barra superior, contenido y barra de navegación inferior.
/// Es StatefulWidget porque recuerda qué pestaña está abierta.
class _Inicio extends StatefulWidget {
  const _Inicio({required this.repositorio, this.alReiniciar});

  final RepositorioAsistencia repositorio;
  final Future<void> Function()? alReiniciar;

  @override
  State<_Inicio> createState() => _InicioState();
}

class _InicioState extends State<_Inicio> {
  /// Pestaña abierta (0 = Ingreso, 1 = Presentes, 2 = Dashboard, 3 = Cumpleaños).
  var _indice = 0;

  /// Título e ícono de cada pestaña, como una lista de records.
  static const _secciones = [
    (titulo: 'Ingreso y salida', icono: Icons.how_to_reg),
    (titulo: 'Presentes', icono: Icons.groups),
    (titulo: 'Dashboard', icono: Icons.insights),
    (titulo: 'Cumpleaños', icono: Icons.cake),
  ];

  @override
  Widget build(BuildContext context) {
    final repo = widget.repositorio;
    // Las cuatro pantallas reciben el mismo repositorio.
    final pantallas = [
      PantallaIngreso(repositorio: repo),
      PantallaPresentes(repositorio: repo),
      PantallaDashboard(repositorio: repo),
      PantallaCumpleanos(repositorio: repo),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_secciones[_indice].titulo),
        actions: [
          const Center(child: Text('Datos de demostración', style: TextStyle(fontSize: 12))),
          // El botón ⟳ aparece solo si main.dart dio la función de reinicio.
          if (widget.alReiniciar != null)
            IconButton(
              tooltip: 'Reiniciar demo',
              icon: const Icon(Icons.restart_alt),
              onPressed: _confirmarReinicio,
            ),
          const SizedBox(width: 8),
        ],
      ),
      // IndexedStack muestra una pantalla a la vez pero mantiene vivas las
      // demás: al volver a una pestaña conserva lo que tenía (por ejemplo, el
      // texto del buscador).
      body: IndexedStack(index: _indice, children: pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: [
          for (final s in _secciones) NavigationDestination(icon: Icon(s.icono), label: s.titulo),
        ],
      ),
    );
  }

  /// Pide confirmación y, si el usuario acepta, reinicia la demo.
  Future<void> _confirmarReinicio() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar la demo?'),
        content: const Text('Se borran los movimientos que registraste y vuelven los datos ficticios del día.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reiniciar')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    await widget.alReiniciar!();
    mensajero.showSnackBar(const SnackBar(content: Text('Demo reiniciada.')));
  }
}
