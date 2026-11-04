import 'package:flutter/material.dart';

import '../data/repositorio_asistencia.dart';
import 'pantalla_cumpleanos.dart';
import 'pantalla_dashboard.dart';
import 'pantalla_ingreso.dart';
import 'pantalla_presentes.dart';
import 'tema.dart';

class AsistenciaApp extends StatelessWidget {
  const AsistenciaApp({super.key, required this.repositorio});

  final RepositorioAsistencia repositorio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistencia Infantil',
      debugShowCheckedModeBanner: false,
      theme: temaApp(),
      home: _Inicio(repositorio: repositorio),
    );
  }
}

class _Inicio extends StatefulWidget {
  const _Inicio({required this.repositorio});

  final RepositorioAsistencia repositorio;

  @override
  State<_Inicio> createState() => _InicioState();
}

class _InicioState extends State<_Inicio> {
  var _indice = 0;

  static const _secciones = [
    (titulo: 'Ingreso y salida', icono: Icons.how_to_reg),
    (titulo: 'Presentes', icono: Icons.groups),
    (titulo: 'Dashboard', icono: Icons.insights),
    (titulo: 'Cumpleaños', icono: Icons.cake),
  ];

  @override
  Widget build(BuildContext context) {
    final repo = widget.repositorio;
    final pantallas = [
      PantallaIngreso(repositorio: repo),
      PantallaPresentes(repositorio: repo),
      PantallaDashboard(repositorio: repo),
      PantallaCumpleanos(repositorio: repo),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_secciones[_indice].titulo),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: Text('Datos de demostración', style: TextStyle(fontSize: 12))),
          ),
        ],
      ),
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
}
