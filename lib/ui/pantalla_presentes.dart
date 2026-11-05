// =============================================================================
// pantalla_presentes.dart — Quién está adentro ahora, agrupado por edad.
// =============================================================================

import 'package:flutter/material.dart';

import '../data/repositorio_asistencia.dart';
import '../domain/dominio.dart';
import 'componentes.dart';
import 'tema.dart';

/// Quién está adentro ahora, agrupado por grupo de edad.
///
/// StatelessWidget: no guarda estado propio; los datos llegan por el Stream.
class PantallaPresentes extends StatelessWidget {
  const PantallaPresentes({super.key, required this.repositorio});

  final RepositorioAsistencia repositorio;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Registro>>(
      stream: repositorio.registrosDelDia(DateTime.now()),
      builder: (context, snapshot) {
        // La misma regla del modo emergencia: quién terminó en Entrada.
        final presentes = calcularPresentes(snapshot.data ?? []);

        // Grupo → lista de presentes de ese grupo. `..removeWhere` quita los
        // grupos vacíos para no mostrar títulos sin niños.
        final porGrupo = {
          for (final grupo in gruposEdad)
            grupo: presentes.where((r) => r.grupoEdad == grupo).toList(),
        }..removeWhere((_, lista) => lista.isEmpty);

        return AnchoLimitado(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text(
                '${presentes.length} niños presentes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mismo cálculo que usa el modo emergencia: el último movimiento de cada niño es una entrada.',
                style: TextStyle(color: Colors.black54),
              ),
              // Por cada grupo: un título y las tarjetas de sus niños. El
              // patrón `MapEntry(key: grupo, value: lista)` saca la clave y el
              // valor de cada entrada del mapa en dos variables.
              for (final MapEntry(key: grupo, value: lista) in porGrupo.entries) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: Colores.grupos[gruposEdad.indexOf(grupo)]),
                    const SizedBox(width: 8),
                    Text('$grupo · ${rangoEdadPorGrupo[grupo]}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(), // empuja el contador a la derecha
                    Etiqueta('${lista.length}'),
                  ],
                ),
                const SizedBox(height: 6),
                for (final r in lista)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      // El número de manilla en un círculo.
                      leading: CircleAvatar(
                        backgroundColor: Colores.acento.withValues(alpha: 0.2),
                        child: Text(r.numeroManilla, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      title: Text(r.nombreNino),
                      subtitle: Text('Entregó: ${r.nombreAcudiente} · ${_hora(r.fecha)}'),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// La hora como "08:40".
  String _hora(DateTime f) => '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
}
