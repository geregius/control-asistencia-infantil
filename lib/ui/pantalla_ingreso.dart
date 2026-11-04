import 'package:flutter/material.dart';

import '../data/repositorio_asistencia.dart';
import '../domain/dominio.dart';
import 'componentes.dart';
import 'tema.dart';

/// Buscar un niño y registrar su entrada o su salida.
class PantallaIngreso extends StatefulWidget {
  const PantallaIngreso({super.key, required this.repositorio});

  final RepositorioAsistencia repositorio;

  @override
  State<PantallaIngreso> createState() => _PantallaIngresoState();
}

class _PantallaIngresoState extends State<PantallaIngreso> {
  var _consulta = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Nino>>(
      stream: widget.repositorio.ninos(),
      builder: (context, snapshot) {
        final ninos = (snapshot.data ?? [])
            .where((n) => NinoBusqueda.desde(n).coincideBusqueda(_consulta))
            .toList();
        return AnchoLimitado(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar niño por nombre (sin importar tildes)',
                ),
                onChanged: (texto) => setState(() => _consulta = texto),
              ),
              const SizedBox(height: 12),
              for (final nino in ninos) _FilaNino(nino: nino, alTocar: () => _registrar(nino)),
              if (ninos.isEmpty && snapshot.hasData)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Ningún niño coincide con la búsqueda.')),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _registrar(Nino nino) async {
    final tipo = nino.presente ? TipoMovimiento.salida : TipoMovimiento.entrada;
    final datos = await showDialog<({String manilla, String acudiente, String servicio})>(
      context: context,
      builder: (_) => _DialogoMovimiento(nino: nino, tipo: tipo),
    );
    if (datos == null || !mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    try {
      await widget.repositorio.registrarMovimiento(
        nino: nino,
        tipo: tipo,
        numeroManilla: datos.manilla,
        servicio: datos.servicio,
        nombreAcudiente: datos.acudiente,
        idVoluntario: 'demo',
        nombreVoluntario: 'Voluntario de demostración',
      );
      mensajero.showSnackBar(SnackBar(content: Text('${tipo.etiqueta} de ${nino.nombres} registrada.')));
    } on RegistroRechazado catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(e.motivo), backgroundColor: Colores.alerta));
    }
  }
}

class _FilaNino extends StatelessWidget {
  const _FilaNino({required this.nino, required this.alTocar});

  final Nino nino;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final grupo = nino.grupo();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: AvatarNino(nino: nino),
        title: Text(nino.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Etiqueta('${nino.edad()} años · ${grupo ?? 'Fuera de rango'}'),
              if (nino.alertaMedica)
                const Etiqueta('Alerta médica', color: Colores.alerta, icono: Icons.medical_services),
              if (nino.tieneNoAutorizados)
                const Etiqueta('Tiene personas no autorizadas', color: Colores.alerta, icono: Icons.block),
            ],
          ),
        ),
        trailing: FilledButton.tonal(
          onPressed: alTocar,
          child: Text(nino.presente ? 'Salida' : 'Entrada'),
        ),
      ),
    );
  }
}

class _DialogoMovimiento extends StatefulWidget {
  const _DialogoMovimiento({required this.nino, required this.tipo});

  final Nino nino;
  final TipoMovimiento tipo;

  @override
  State<_DialogoMovimiento> createState() => _DialogoMovimientoState();
}

class _DialogoMovimientoState extends State<_DialogoMovimiento> {
  final _manilla = TextEditingController();
  final _acudiente = TextEditingController();
  late var _servicio = servicioSugerido() ?? serviciosDisponibles.first;

  @override
  void dispose() {
    _manilla.dispose();
    _acudiente.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrando = widget.tipo == TipoMovimiento.entrada;
    return AlertDialog(
      title: Text('${widget.tipo.etiqueta} de ${widget.nino.nombres}'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.nino.alertaMedica)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Etiqueta(widget.nino.condicionMedica, color: Colores.alerta, icono: Icons.warning),
              ),
            if (entrando) ...[
              TextField(
                controller: _manilla,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Número de manilla'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _servicio,
                decoration: const InputDecoration(labelText: 'Jornada'),
                items: [for (final s in serviciosDisponibles) DropdownMenuItem(value: s, child: Text(s))],
                onChanged: (s) => setState(() => _servicio = s ?? _servicio),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _acudiente,
              decoration: InputDecoration(labelText: entrando ? 'Quién lo entrega' : 'Quién lo recoge'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            manilla: _manilla.text,
            acudiente: _acudiente.text.trim().isEmpty ? 'Sin especificar' : _acudiente.text.trim(),
            servicio: _servicio,
          )),
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
