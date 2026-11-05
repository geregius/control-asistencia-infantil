// =============================================================================
// pantalla_cumpleanos.dart — Niños que cumplieron años en la última semana.
// =============================================================================

import 'package:flutter/material.dart';

import '../data/repositorio_asistencia.dart';
import '../domain/dominio.dart';
import 'componentes.dart';
import 'tema.dart';

/// Niños que cumplieron años en la última semana.
class PantallaCumpleanos extends StatelessWidget {
  const PantallaCumpleanos({super.key, required this.repositorio});

  final RepositorioAsistencia repositorio;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Nino>>(
      stream: repositorio.ninos(),
      builder: (context, snapshot) {
        // La lógica está en el dominio; aquí solo se pinta el resultado.
        final cumpleaneros = cumpleanerosDeLaSemana(snapshot.data ?? []);
        return AnchoLimitado(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text('Cumpleaños de la semana',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (cumpleaneros.isEmpty) const Text('Nadie cumplió años esta semana.'),
              // Desestructura cada record: `(:nino, :diasDesde)` crea dos
              // variables con los campos del mismo nombre.
              for (final (:nino, :diasDesde) in cumpleaneros)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: AvatarNino(nino: nino),
                    title: Text(nino.nombreCompleto),
                    subtitle: Text('Cumplió ${nino.edad()} años · ${nino.grupo() ?? ''}'),
                    // "¡Hoy!", "Hace 1 día" o "Hace N días".
                    trailing: Etiqueta(
                      diasDesde == 0 ? '¡Hoy!' : 'Hace $diasDesde ${diasDesde == 1 ? 'día' : 'días'}',
                      color: diasDesde == 0 ? Colores.acento : Colores.primario,
                      icono: Icons.cake,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
