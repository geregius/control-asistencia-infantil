import 'dart:convert';

import '../domain/dominio.dart';
import 'almacen_local.dart';
import 'datos_demo.dart';
import 'repositorio_asistencia.dart';
import 'repositorio_en_memoria.dart';

/// Repositorio que guarda los datos en el dispositivo para que no se
/// pierdan al recargar.
///
/// Es un *decorador*: implementa el mismo contrato que
/// [RepositorioEnMemoria], le delega las lecturas y las reglas, y solo
/// agrega una cosa: guardar después de cada movimiento. Las pantallas no
/// cambian; solo `main.dart` decide cuál usar.
class RepositorioPersistente implements RepositorioAsistencia {
  RepositorioPersistente._(this._base, this._almacen, this._reloj);

  static const clave = 'asistencia_infantil.datos';

  final RepositorioEnMemoria _base;
  final AlmacenLocal _almacen;
  final DateTime Function() _reloj;

  /// Carga lo guardado; si no hay nada, o es de otro día, empieza con los
  /// datos de demostración del día.
  ///
  /// Un día nuevo equivale al cierre automático de la jornada de la app
  /// real: nadie queda "presente" de un día para otro.
  static Future<RepositorioPersistente> abrir({
    required AlmacenLocal almacen,
    DateTime Function()? reloj,
  }) async {
    final ahora = reloj ?? DateTime.now;
    final guardado = _decodificar(await almacen.leer(clave), ahora());
    final datos = guardado ?? DatosDemo.generar(ahora());
    final repositorio = RepositorioPersistente._(
      RepositorioEnMemoria(ninos: datos.ninos, registros: datos.registros, reloj: ahora),
      almacen,
      ahora,
    );
    if (guardado == null) await repositorio._guardar();
    return repositorio;
  }

  /// Vuelve a los datos de demostración del día y borra lo guardado.
  Future<void> reiniciar() async {
    final datos = DatosDemo.generar(_reloj());
    _base.reemplazar(ninos: datos.ninos, registros: datos.registros);
    await _guardar();
  }

  @override
  Stream<List<Nino>> ninos() => _base.ninos();

  @override
  Stream<List<Registro>> registrosDelDia(DateTime dia) => _base.registrosDelDia(dia);

  @override
  Stream<List<Registro>> registrosDesde(DateTime desde) => _base.registrosDesde(desde);

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
    // Si la regla rechaza el movimiento, la excepción sube y no se guarda nada.
    final registro = await _base.registrarMovimiento(
      nino: nino,
      tipo: tipo,
      numeroManilla: numeroManilla,
      servicio: servicio,
      nombreAcudiente: nombreAcudiente,
      idVoluntario: idVoluntario,
      nombreVoluntario: nombreVoluntario,
    );
    await _guardar();
    return registro;
  }

  Future<void> _guardar() {
    final (:ninos, :registros) = _base.instantanea();
    return _almacen.guardar(
      clave,
      jsonEncode({
        'dia': escribirFecha(soloDia(_reloj())),
        'ninos': [for (final n in ninos) {'id': n.id, ...n.toMap()}],
        'registros': [for (final r in registros) {'id': r.id, ...r.toMap()}],
      }),
    );
  }

  /// Lo guardado, o `null` si no hay, está dañado o es de otro día.
  static DatosDemo? _decodificar(String? texto, DateTime hoy) {
    if (texto == null) return null;
    try {
      final json = jsonDecode(texto) as Map<String, dynamic>;
      if (leerFecha(json['dia']) != soloDia(hoy)) return null;
      List<Map<String, dynamic>> lista(String campo) =>
          (json[campo] as List).cast<Map<String, dynamic>>();
      return DatosDemo(
        [for (final m in lista('ninos')) Nino.fromMap(m['id'] as String, m)],
        [for (final m in lista('registros')) Registro.fromMap(m['id'] as String, m)],
      );
    } on Object {
      // Datos de una versión anterior o dañados: se empieza de nuevo.
      return null;
    }
  }

  Future<void> cerrar() => _base.cerrar();
}
