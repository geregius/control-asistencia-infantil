// =============================================================================
// pantalla_ingreso.dart — Buscar un niño y registrar su entrada o su salida.
//
// La pantalla principal de la puerta. Tiene tres piezas: la pantalla con el
// buscador y la lista, la fila de cada niño y el diálogo que pide la manilla.
// =============================================================================

import 'package:flutter/material.dart';

import '../data/repositorio_asistencia.dart';
import '../domain/dominio.dart';
import 'componentes.dart';
import 'tema.dart';

/// Buscar un niño y registrar su entrada o su salida.
///
/// Es un StatefulWidget porque guarda un estado propio: el texto que el
/// voluntario va escribiendo en el buscador.
class PantallaIngreso extends StatefulWidget {
  const PantallaIngreso({super.key, required this.repositorio});

  /// El contrato, no una implementación concreta (polimorfismo).
  final RepositorioAsistencia repositorio;

  @override
  State<PantallaIngreso> createState() => _PantallaIngresoState();
}

class _PantallaIngresoState extends State<PantallaIngreso> {
  /// Lo que está escrito en el buscador.
  var _consulta = '';

  @override
  Widget build(BuildContext context) {
    // StreamBuilder escucha el Stream de niños y vuelve a dibujar la lista
    // cada vez que llega un valor nuevo (por ejemplo, al registrar una entrada).
    return StreamBuilder<List<Nino>>(
      stream: widget.repositorio.ninos(),
      builder: (context, snapshot) {
        // snapshot.data es la última lista recibida (null mientras carga).
        // Se filtra con la búsqueda sin tildes.
        final ninos = (snapshot.data ?? [])
            .where((n) => NinoBusqueda.desde(n).coincideBusqueda(_consulta))
            .toList();
        return AnchoLimitado(
          child: ListView(
            // Margen inferior de 96 para que la última fila no quede debajo
            // de la barra de navegación.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar niño por nombre (sin importar tildes)',
                ),
                // setState avisa a Flutter que el estado cambió y que redibuje.
                onChanged: (texto) => setState(() => _consulta = texto),
              ),
              const SizedBox(height: 12),
              for (final nino in ninos) _FilaNino(nino: nino, alTocar: () => _registrar(nino)),
              // Mensaje si la búsqueda no encuentra a nadie.
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

  /// Abre el diálogo y registra el movimiento con lo que el voluntario escriba.
  Future<void> _registrar(Nino nino) async {
    // Si está adentro, el botón registra la salida; si no, la entrada.
    final tipo = nino.presente ? TipoMovimiento.salida : TipoMovimiento.entrada;

    // showDialog espera a que el diálogo se cierre y devuelve lo que este
    // mande con Navigator.pop: un record con los tres datos, o null si se canceló.
    final datos = await showDialog<({String manilla, String acudiente, String servicio})>(
      context: context,
      builder: (_) => _DialogoMovimiento(nino: nino, tipo: tipo),
    );
    // Cancelado, o la pantalla ya no existe (`mounted` = sigue en pantalla).
    if (datos == null || !mounted) return;

    // Se guarda antes del `await` porque después el context podría no ser válido.
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
      // Mensaje de éxito abajo (SnackBar).
      mensajero.showSnackBar(SnackBar(content: Text('${tipo.etiqueta} de ${nino.nombres} registrada.')));
    } on RegistroRechazado catch (e) {
      // Una regla no se cumplió: se muestra el motivo en rojo.
      mensajero.showSnackBar(SnackBar(content: Text(e.motivo), backgroundColor: Colores.alerta));
    }
  }
}

/// Una fila de la lista: avatar, nombre, etiquetas y botón Entrada/Salida.
class _FilaNino extends StatelessWidget {
  const _FilaNino({required this.nino, required this.alTocar});

  final Nino nino;

  /// Qué hacer al tocar el botón (lo decide la pantalla, no la fila).
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
          // Wrap: si las etiquetas no caben en una línea, pasan a la siguiente.
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

/// Diálogo que pide la manilla, la jornada y quién entrega o recoge.
class _DialogoMovimiento extends StatefulWidget {
  const _DialogoMovimiento({required this.nino, required this.tipo});

  final Nino nino;
  final TipoMovimiento tipo;

  @override
  State<_DialogoMovimiento> createState() => _DialogoMovimientoState();
}

class _DialogoMovimientoState extends State<_DialogoMovimiento> {
  // Controladores: guardan el texto de cada campo.
  final _manilla = TextEditingController();
  final _acudiente = TextEditingController();

  // Jornada preseleccionada según el día y la hora. `late` la calcula la
  // primera vez que se usa.
  late var _servicio = servicioSugerido() ?? serviciosDisponibles.first;

  /// Libera los controladores al cerrar el diálogo (evita fugas de memoria).
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
            // Si tiene alerta médica, se muestra arriba en rojo.
            if (widget.nino.alertaMedica)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Etiqueta(widget.nino.condicionMedica, color: Colores.alerta, icono: Icons.warning),
              ),
            // Manilla y jornada solo se piden al entrar.
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
        // Cancelar cierra sin devolver nada (null).
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        // Registrar cierra y devuelve un record con los datos escritos. La
        // validación de la manilla la hace el repositorio, no el diálogo.
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
