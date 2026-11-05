// =============================================================================
// repositorio_persistente.dart — Repositorio que guarda los datos en el
// dispositivo para que sobrevivan a una recarga de la página.
//
// Patrón Decorador: envuelve a RepositorioEnMemoria (que tiene las reglas),
// le pasa cada llamada y solo agrega "guardar después de cada cambio".
// =============================================================================

import 'dart:convert'; // jsonEncode / jsonDecode

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
///
/// Usa composición (lo *contiene*) y no herencia (no lo *extiende*): así las
/// reglas viven en un solo lugar y guardar es una capa aparte.
class RepositorioPersistente implements RepositorioAsistencia {
  /// Constructor privado (`._`): desde afuera solo se crea con [abrir], que
  /// primero carga lo guardado.
  RepositorioPersistente._(this._base, this._almacen, this._reloj);

  /// Nombre con que se guardan los datos en el navegador.
  static const clave = 'asistencia_infantil.datos';

  /// El repositorio decorado: tiene los datos y las reglas.
  final RepositorioEnMemoria _base;

  /// Dónde se guarda (navegador en la app, memoria en las pruebas).
  final AlmacenLocal _almacen;
  final DateTime Function() _reloj;

  /// Carga lo guardado; si no hay nada, o es de otro día, empieza con los
  /// datos de demostración del día.
  ///
  /// Un día nuevo equivale al cierre automático de la jornada de la app
  /// real: nadie queda "presente" de un día para otro.
  ///
  /// Es `static` y `async` porque leer el almacén tarda: no se puede hacer en
  /// un constructor normal.
  static Future<RepositorioPersistente> abrir({
    required AlmacenLocal almacen,
    DateTime Function()? reloj,
  }) async {
    final ahora = reloj ?? DateTime.now;
    // `await` espera a que termine la lectura.
    final guardado = _decodificar(await almacen.leer(clave), ahora());
    // Si no hay nada válido guardado, se generan los datos del día.
    final datos = guardado ?? DatosDemo.generar(ahora());
    final repositorio = RepositorioPersistente._(
      RepositorioEnMemoria(ninos: datos.ninos, registros: datos.registros, reloj: ahora),
      almacen,
      ahora,
    );
    // Si se generaron datos nuevos, se guardan de una vez.
    if (guardado == null) await repositorio._guardar();
    return repositorio;
  }

  /// Vuelve a los datos de demostración del día y borra lo guardado.
  Future<void> reiniciar() async {
    final datos = DatosDemo.generar(_reloj());
    _base.reemplazar(ninos: datos.ninos, registros: datos.registros);
    await _guardar();
  }

  // --- Lecturas: se delegan tal cual al repositorio en memoria --------------

  @override
  Stream<List<Nino>> ninos() => _base.ninos();

  @override
  Stream<List<Registro>> registrosDelDia(DateTime dia) => _base.registrosDelDia(dia);

  @override
  Stream<List<Registro>> registrosDesde(DateTime desde) => _base.registrosDesde(desde);

  // --- Escritura: se delega y luego se guarda --------------------------------

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

  /// Convierte todos los datos a JSON (texto) y los guarda en el almacén.
  Future<void> _guardar() {
    // Desestructura el record que devuelve instantanea().
    final (:ninos, :registros) = _base.instantanea();
    return _almacen.guardar(
      clave,
      jsonEncode({
        // El día en que se guardó, para descartarlo al día siguiente.
        'dia': escribirFecha(soloDia(_reloj())),
        // Cada objeto como Map, con su id (toMap no lo incluye).
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
      // Guardado otro día: se descarta (cierre de jornada).
      if (leerFecha(json['dia']) != soloDia(hoy)) return null;
      // Función local: lee una lista del JSON como lista de Maps.
      List<Map<String, dynamic>> lista(String campo) =>
          (json[campo] as List).cast<Map<String, dynamic>>();
      // Reconstruye los objetos con sus fábricas fromMap.
      return DatosDemo(
        [for (final m in lista('ninos')) Nino.fromMap(m['id'] as String, m)],
        [for (final m in lista('registros')) Registro.fromMap(m['id'] as String, m)],
      );
    } on Object {
      // Datos de una versión anterior o dañados: se empieza de nuevo.
      return null;
    }
  }

  /// Libera el repositorio decorado (pruebas).
  Future<void> cerrar() => _base.cerrar();
}
