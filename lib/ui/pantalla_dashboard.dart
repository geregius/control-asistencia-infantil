// =============================================================================
// pantalla_dashboard.dart — Resumen del día, promedios y niños ausentes.
//
// Esta pantalla no calcula nada: llama a las funciones puras de
// domain/estadisticas.dart y solo dibuja lo que devuelven.
// =============================================================================

import 'package:flutter/material.dart';

import '../data/repositorio_asistencia.dart';
import '../domain/dominio.dart';
import 'componentes.dart';
import 'tema.dart';

/// Resumen del día, promedios por jornada y niños que dejaron de venir.
/// Toda la lógica vive en `domain/estadisticas.dart`; aquí solo se pinta.
class PantallaDashboard extends StatelessWidget {
  const PantallaDashboard({super.key, required this.repositorio});

  final RepositorioAsistencia repositorio;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    return AnchoLimitado(
      ancho: 1000,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // Bloque 1: tarjetas y gráfica del día. Escucha los movimientos de hoy.
          StreamBuilder<List<Registro>>(
            stream: repositorio.registrosDelDia(hoy),
            builder: (context, snapshot) => _ResumenHoy(resumen: resumenDelDia(snapshot.data ?? [])),
          ),
          const SizedBox(height: 16),

          // Bloque 2: promedio por jornada de las últimas 8 semanas (56 días).
          StreamBuilder<List<Registro>>(
            stream: repositorio.registrosDesde(hoy.subtract(const Duration(days: 56))),
            builder: (context, snapshot) {
              // Quita las jornadas sin datos (promedio null).
              final promedios = promedioPorJornada(snapshot.data ?? [])
                ..removeWhere((_, valor) => valor == null);
              return _Seccion(
                titulo: 'Promedio de niños por jornada (últimas 8 semanas)',
                child: promedios.isEmpty
                    ? const Text('Sin datos todavía.')
                    // map convierte cada valor double? en double (ya sin nulos).
                    : BarrasHorizontales(datos: promedios.map((k, v) => MapEntry(k, v!))),
              );
            },
          ),
          const SizedBox(height: 16),

          // Bloque 3: niños que dejaron de venir, para hacerles seguimiento.
          StreamBuilder<List<Nino>>(
            stream: repositorio.ninos(),
            builder: (context, snapshot) {
              final ausentes = ninosQueDejaronDeAsistir(snapshot.data ?? []);
              return _Seccion(
                titulo: 'Dejaron de asistir (más de 4 semanas)',
                child: Column(
                  children: [
                    if (ausentes.isEmpty) const Text('Nadie, todos vienen con regularidad.'),
                    for (final n in ausentes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: AvatarNino(nino: n, radio: 18),
                        title: Text(n.nombreCompleto),
                        subtitle: Text('Última vez hace ${hoy.difference(n.ultimaAsistencia!).inDays} días'),
                        trailing: const Etiqueta('Hacer seguimiento', color: Colores.acento),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Las cuatro tarjetas del día, la gráfica por grupo y la jornada más concurrida.
class _ResumenHoy extends StatelessWidget {
  const _ResumenHoy({required this.resumen});

  final ResumenDelDia resumen;

  @override
  Widget build(BuildContext context) {
    final tarjetas = [
      TarjetaDato(valor: '${resumen.totalEntradas}', titulo: 'Entradas hoy', icono: Icons.login),
      TarjetaDato(valor: '${resumen.presentes}', titulo: 'Presentes ahora', icono: Icons.groups, color: Colores.primarioClaro),
      TarjetaDato(valor: '${resumen.yaSalieron}', titulo: 'Ya salieron', icono: Icons.logout, color: Colores.acento),
      TarjetaDato(valor: '${resumen.visitantes}', titulo: 'Visitantes', icono: Icons.person_add_alt, color: Colors.indigo),
    ];
    final masConcurrida = jornadaConMasAsistencia(resumen.porServicio);

    // LayoutBuilder entrega el ancho disponible: 4 tarjetas por fila en
    // pantallas anchas y 2 en el celular.
    return LayoutBuilder(
      builder: (context, restricciones) {
        final columnas = restricciones.maxWidth > 700 ? 4 : 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filas de [columnas] tarjetas con su alto natural (una
            // cuadrícula de proporción fija recortaba el texto).
            for (var i = 0; i < tarjetas.length; i += columnas)
              Row(
                children: [
                  // skip + take: las tarjetas de esta fila.
                  for (final tarjeta in tarjetas.skip(i).take(columnas)) Expanded(child: tarjeta),
                ],
              ),
            const SizedBox(height: 16),
            _Seccion(
              titulo: 'Hoy por grupo de edad',
              child: BarrasHorizontales(datos: resumen.porGrupo, colores: Colores.grupos),
            ),
            if (masConcurrida != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Jornada con más asistencia hoy: ${masConcurrida.key} (${masConcurrida.value}).',
                    style: const TextStyle(color: Colors.black54)),
              ),
          ],
        );
      },
    );
  }
}

/// Tarjeta con título que envuelve cada bloque del Dashboard.
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
