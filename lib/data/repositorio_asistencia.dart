// =============================================================================
// repositorio_asistencia.dart — El contrato de acceso a los datos.
//
// Define QUÉ se puede pedir o guardar, sin decir CÓMO. Las pantallas solo
// conocen este contrato; las implementaciones (en memoria, persistente,
// Firestore) deciden el cómo. Es la base del polimorfismo del proyecto.
// =============================================================================

import '../domain/dominio.dart';

/// Error de negocio al registrar un movimiento (lo que ve el voluntario).
///
/// `implements Exception` la marca como una excepción de Dart, para poder
/// lanzarla con `throw` y atraparla con `on RegistroRechazado catch`.
class RegistroRechazado implements Exception {
  /// El mensaje que se muestra en pantalla, por ejemplo
  /// "La manilla 7 ya está en uso hoy."
  final String motivo;
  const RegistroRechazado(this.motivo);

  @override
  String toString() => motivo;
}

/// Contrato de acceso a los datos de asistencia.
///
/// Es una clase abstracta: declara los métodos pero no los implementa, y no
/// se puede crear un objeto de ella directamente. Las pantallas solo conocen
/// esta clase. La app real la implementa sobre Firestore; este repositorio
/// de muestra trae [RepositorioEnMemoria] y [RepositorioPersistente] con
/// datos ficticios. Cambiar de base de datos es escribir otra
/// implementación, sin tocar las pantallas.
abstract class RepositorioAsistencia {
  /// Todos los niños. Un `Stream` es un flujo de valores en el tiempo: emite
  /// la lista actual y una nueva cada vez que cambia.
  Stream<List<Nino>> ninos();

  /// Los movimientos de un día, en orden de hora.
  Stream<List<Registro>> registrosDelDia(DateTime dia);

  /// Movimientos desde [desde] hasta hoy, para los promedios del Dashboard.
  Stream<List<Registro>> registrosDesde(DateTime desde);

  /// Registra una entrada o salida aplicando las reglas del negocio.
  ///
  /// Devuelve un `Future` (un valor que llega después, cuando termina la
  /// operación). Si una regla no se cumple, lanza [RegistroRechazado].
  Future<Registro> registrarMovimiento({
    required Nino nino,
    required TipoMovimiento tipo,
    required String numeroManilla,
    required String servicio,
    required String nombreAcudiente,
    required String idVoluntario,
    required String nombreVoluntario,
  });
}
