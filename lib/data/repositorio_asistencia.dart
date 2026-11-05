import '../domain/dominio.dart';

/// Error de negocio al registrar un movimiento (lo que ve el voluntario).
class RegistroRechazado implements Exception {
  final String motivo;
  const RegistroRechazado(this.motivo);

  @override
  String toString() => motivo;
}

/// Contrato de acceso a los datos de asistencia.
///
/// Las pantallas solo conocen esta clase abstracta. La app real la
/// implementa sobre Firestore; este repositorio de muestra trae
/// [RepositorioEnMemoria] con datos ficticios. Cambiar de base de datos
/// es escribir otra implementación, sin tocar las pantallas.
abstract class RepositorioAsistencia {
  Stream<List<Nino>> ninos();

  Stream<List<Registro>> registrosDelDia(DateTime dia);

  /// Registra una entrada o salida aplicando las reglas del negocio.
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
