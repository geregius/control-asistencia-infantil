import 'dart:async';

import '../domain/dominio.dart';
import 'repositorio_asistencia.dart';

/// Implementación en memoria de [RepositorioAsistencia], para la demo y
/// las pruebas. Aplica las mismas reglas que la app real.
class RepositorioEnMemoria implements RepositorioAsistencia {
  RepositorioEnMemoria({
    List<Nino> ninos = const [],
    List<Registro> registros = const [],
    DateTime Function()? reloj,
  })  : _ninos = {for (final n in ninos) n.id: n},
        _registros = [...registros],
        _reloj = reloj ?? DateTime.now,
        // Sigue la numeración de los registros que ya trae, para no repetir ids.
        _siguienteId = registros.length + 1;

  final Map<String, Nino> _ninos;
  final List<Registro> _registros;
  final DateTime Function() _reloj;
  final _cambios = StreamController<void>.broadcast();
  int _siguienteId;

  /// Copia de todos los datos, para guardarlos.
  ({List<Nino> ninos, List<Registro> registros}) instantanea() =>
      (ninos: _ninos.values.toList(), registros: [..._registros]);

  /// Cambia todos los datos de una vez y avisa a quien esté escuchando.
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

  @override
  Stream<List<Nino>> ninos() => _observar(() {
        final lista = _ninos.values.toList()
          ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));
        return lista;
      });

  @override
  Stream<List<Registro>> registrosDelDia(DateTime dia) => _observar(
        () => _registros.where((r) => soloDia(r.fecha) == soloDia(dia)).toList()
          ..sort((a, b) => a.fecha.compareTo(b.fecha)),
      );

  @override
  Stream<List<Registro>> registrosDesde(DateTime desde) => _observar(
        () => _registros.where((r) => !r.fecha.isBefore(desde)).toList()
          ..sort((a, b) => a.fecha.compareTo(b.fecha)),
      );

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
    final actual = _ninos[nino.id] ?? nino;
    final ahora = _reloj();
    final entrando = tipo == TipoMovimiento.entrada;

    if (entrando && actual.presente) {
      throw RegistroRechazado('${actual.nombres} ya está adentro.');
    }
    if (!entrando && !actual.presente) {
      throw RegistroRechazado('${actual.nombres} no tiene una entrada abierta.');
    }
    if (entrando && numeroManilla.trim().isEmpty) {
      throw const RegistroRechazado('La manilla es obligatoria para entrar.');
    }
    if (entrando && _manillaEnUsoHoy(numeroManilla, ahora)) {
      throw RegistroRechazado('La manilla $numeroManilla ya está en uso hoy.');
    }

    final registro = Registro(
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
    _ninos[actual.id] = Nino.fromMap(actual.id, {
      ...actual.toMap(),
      'presente': entrando,
      if (entrando) 'totalEntradas': actual.totalEntradas + 1,
      if (entrando) 'ultimaAsistencia': escribirFecha(ahora),
    });
    _cambios.add(null);
    return registro;
  }

  bool _manillaEnUsoHoy(String manilla, DateTime hoy) => calcularPresentes(
        _registros.where((r) => soloDia(r.fecha) == soloDia(hoy)),
      ).any((r) => r.numeroManilla == manilla.trim());

  /// Emite el valor actual y lo vuelve a emitir con cada cambio.
  ///
  /// Se suscribe a los cambios en el mismo momento en que alguien escucha
  /// (no después del primer valor), para no perder un cambio que ocurra
  /// entre la primera emisión y la siguiente.
  Stream<T> _observar<T>(T Function() leer) {
    StreamSubscription<void>? suscripcion;
    late final StreamController<T> salida;
    salida = StreamController<T>(
      onListen: () {
        salida.add(leer());
        suscripcion = _cambios.stream.listen((_) => salida.add(leer()));
      },
      onCancel: () => suscripcion?.cancel(),
    );
    return salida.stream;
  }

  Future<void> cerrar() => _cambios.close();
}
