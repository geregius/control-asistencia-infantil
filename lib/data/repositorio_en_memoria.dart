// =============================================================================
// repositorio_en_memoria.dart — Una implementación del contrato que guarda
// los datos en la memoria del programa y aplica las reglas de la puerta.
//
// La usan las pruebas directamente y la demo a través del repositorio
// persistente, que le delega todo.
// =============================================================================

import 'dart:async';

import '../domain/dominio.dart';
import 'repositorio_asistencia.dart';

/// Implementación en memoria de [RepositorioAsistencia], para la demo y
/// las pruebas. Aplica las mismas reglas que la app real.
///
/// `implements` significa que esta clase cumple el contrato: está obligada a
/// escribir todos los métodos de [RepositorioAsistencia].
class RepositorioEnMemoria implements RepositorioAsistencia {
  /// Constructor. Lo que va después de `:` es la "lista de inicialización":
  /// prepara los campos privados antes de que el objeto exista.
  RepositorioEnMemoria({
    List<Nino> ninos = const [],
    List<Registro> registros = const [],
    DateTime Function()? reloj,
  })  : _ninos = {for (final n in ninos) n.id: n},
        _registros = [...registros],
        // El reloj se inyecta: en la app es DateTime.now; en las pruebas, una
        // función que siempre devuelve la misma hora.
        _reloj = reloj ?? DateTime.now,
        // Sigue la numeración de los registros que ya trae, para no repetir ids.
        _siguienteId = registros.length + 1;

  // Campos privados (empiezan con `_`): nadie de afuera puede tocarlos. Es el
  // encapsulamiento: la única forma de cambiar los datos es por los métodos.

  /// Niños indexados por id, para encontrarlos sin recorrer la lista.
  final Map<String, Nino> _ninos;

  /// Todos los movimientos.
  final List<Registro> _registros;

  final DateTime Function() _reloj;

  /// Canal interno de avisos: cada vez que algo cambia, se emite un evento.
  /// `broadcast` permite que lo escuchen varias pantallas a la vez.
  final _cambios = StreamController<void>.broadcast();

  int _siguienteId;

  /// Copia de todos los datos, para guardarlos. Devuelve un record con dos
  /// listas nuevas, así quien la reciba no puede modificar los originales.
  ({List<Nino> ninos, List<Registro> registros}) instantanea() =>
      (ninos: _ninos.values.toList(), registros: [..._registros]);

  /// Cambia todos los datos de una vez y avisa a quien esté escuchando.
  /// Lo usa el botón "Reiniciar demo".
  void reemplazar({required List<Nino> ninos, required List<Registro> registros}) {
    _ninos
      ..clear()
      ..addAll({for (final n in ninos) n.id: n});
    _registros
      ..clear()
      ..addAll(registros);
    _siguienteId = registros.length + 1;
    _cambios.add(null);
  }

  // `@override` indica que el método cumple uno del contrato.

  /// Los niños ordenados por nombre.
  @override
  Stream<List<Nino>> ninos() => _observar(() {
        final lista = _ninos.values.toList()
          ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
        return lista;
      });

  /// Los movimientos cuyo día coincide con [dia], ordenados por hora.
  @override
  Stream<List<Registro>> registrosDelDia(DateTime dia) => _observar(
        () => _registros.where((r) => soloDia(r.fecha) == soloDia(dia)).toList()
          ..sort((a, b) => a.fecha.compareTo(b.fecha)),
      );

  /// Los movimientos desde [desde] en adelante.
  @override
  Stream<List<Registro>> registrosDesde(DateTime desde) => _observar(
        () => _registros.where((r) => !r.fecha.isBefore(desde)).toList()
          ..sort((a, b) => a.fecha.compareTo(b.fecha)),
      );

  /// Registra una entrada o una salida. Primero valida las reglas, paso a
  /// paso; si alguna falla, lanza [RegistroRechazado] y no cambia nada.
  @override
  Future<Registro> registrarMovimiento({
    required Nino nino,
    required TipoMovimiento tipo,
    required String numeroManilla,
    required String servicio,
    required String nombreAcudiente,
    required String idVoluntario,
    required String nombreVoluntario,
  }) async {
    // Se trabaja con la versión guardada del niño (la de la pantalla podría
    // estar desactualizada).
    final actual = _ninos[nino.id] ?? nino;
    final ahora = _reloj();
    final entrando = tipo == TipoMovimiento.entrada;

    // Regla 1: no puede entrar quien ya está adentro.
    if (entrando && actual.presente) {
      throw RegistroRechazado('${actual.nombres} ya está adentro.');
    }
    // Regla 2: no puede salir quien no ha entrado.
    if (!entrando && !actual.presente) {
      throw RegistroRechazado('${actual.nombres} no tiene una entrada abierta.');
    }
    // Regla 3: para entrar hace falta una manilla.
    if (entrando && numeroManilla.trim().isEmpty) {
      throw const RegistroRechazado('La manilla es obligatoria para entrar.');
    }
    // Regla 4: la manilla no puede estar en uso por otro niño hoy.
    if (entrando && _manillaEnUsoHoy(numeroManilla, ahora)) {
      throw RegistroRechazado('La manilla $numeroManilla ya está en uso hoy.');
    }

    // Todo bien: se arma el registro. El grupo se calcula con la edad de hoy.
    final registro = Registro(
      // `_siguienteId++` usa el valor actual y luego le suma 1.
      id: 'reg-${_siguienteId++}',
      idNino: actual.id,
      nombreNino: actual.nombreCompleto,
      tipo: tipo,
      fecha: ahora,
      numeroManilla: numeroManilla.trim(),
      idVoluntario: idVoluntario,
      nombreVoluntario: nombreVoluntario,
      nombreAcudiente: nombreAcudiente,
      servicio: servicio,
      grupoEdad: actual.grupo(hoy: ahora) ?? '',
    );

    // El registro y el estado del niño cambian juntos, como en el batch
    // atómico de la app real: nunca queda uno sin el otro.
    _registros.add(registro);
    // Como Nino es inmutable, se crea uno nuevo: se copian sus datos
    // (`...actual.toMap()`, el operador spread) y se cambian los necesarios.
    _ninos[actual.id] = Nino.fromMap(actual.id, {
      ...actual.toMap(),
      'presente': entrando,
      if (entrando) 'totalEntradas': actual.totalEntradas + 1,
      if (entrando) 'ultimaAsistencia': escribirFecha(ahora),
    });
    // Avisa a las pantallas que algo cambió.
    _cambios.add(null);
    return registro;
  }

  /// true si [manilla] la tiene puesta alguien que sigue adentro hoy. Usa la
  /// misma regla de presentes que el resto de la app.
  bool _manillaEnUsoHoy(String manilla, DateTime hoy) => calcularPresentes(
        _registros.where((r) => soloDia(r.fecha) == soloDia(hoy)),
      ).any((r) => r.numeroManilla == manilla.trim());

  /// Emite el valor actual y lo vuelve a emitir con cada cambio.
  ///
  /// [leer] es la función que calcula el valor (por ejemplo, la lista de
  /// niños ordenada). Se suscribe a los cambios en el mismo momento en que
  /// alguien escucha (no después del primer valor), para no perder un cambio
  /// que ocurra entre la primera emisión y la siguiente.
  Stream<T> _observar<T>(T Function() leer) {
    StreamSubscription<void>? suscripcion;
    // `late` permite declarar la variable ahora y asignarla en la línea
    // siguiente, aunque el propio controlador la mencione adentro.
    late final StreamController<T> salida;
    salida = StreamController<T>(
      // Cuando una pantalla empieza a escuchar: le manda el valor actual y se
      // suscribe a los cambios para mandarle los siguientes.
      onListen: () {
        salida.add(leer());
        suscripcion = _cambios.stream.listen((_) => salida.add(leer()));
      },
      // Cuando deja de escuchar (la pantalla se cierra): se desuscribe.
      onCancel: () => suscripcion?.cancel(),
    );
    return salida.stream;
  }

  /// Libera el canal de avisos (se usa al terminar las pruebas).
  Future<void> cerrar() => _cambios.close();
}
