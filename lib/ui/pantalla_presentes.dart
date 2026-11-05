import 'package:flutter/material.dart';

import '../data/repositorio_asistencia.dart';
import '../domain/dominio.dart';
import 'componentes.dart';
import 'tema.dart';

/// Quién está adentro ahora, agrupado por grupo de edad.
class PantallaPresentes extends StatelessWidget {
  const PantallaPresentes({super.key, required this.repositorio});

  final RepositorioAsistencia repositorio;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Registro>>(
      stream: repositorio.registrosDelDia(DateTime.now()),
      builder: (context, snapshot) {
        final presentes = calcularPresentes(snapshot.data ?? []);
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
              for (final MapEntry(key: grupo, value: lista) in porGrupo.entries) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(radius: 6, backgroundColor: Colores.grupos[gruposEdad.indexOf(grupo)]),
                    const SizedBox(width: 8),
                    Text('$grupo · ${rangoEdadPorGrupo[grupo]}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Etiqueta('${lista.length}'),
                  ],
                ),
                const SizedBox(height: 6),
                for (final r in lista)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
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

  String _hora(DateTime f) => '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
}
