import 'fechas.dart';

/// Jornadas en las que se registra asistencia.
const serviciosDisponibles = [
  'Domingo mañana',
  'Domingo mediodía',
  'Miércoles',
  'Viernes',
  'Sábado',
];

enum TipoMovimiento {
  entrada,
  salida;

  static TipoMovimiento fromString(String? valor) =>
      valor == 'Salida' ? salida : entrada;

  String get etiqueta => this == entrada ? 'Entrada' : 'Salida';
}

/// La jornada que corresponde AHORA según el día y la hora, para
/// preseleccionarla en el formulario. `null` si hoy no hay jornada.
String? servicioSugerido([DateTime? ahora]) {
  final hoy = ahora ?? DateTime.now();
  return switch (hoy.weekday) {
    DateTime.wednesday => 'Miércoles',
    DateTime.friday => 'Viernes',
    DateTime.saturday => 'Sábado',
    DateTime.sunday => hoy.hour < 10 ? 'Domingo mañana' : 'Domingo mediodía',
    _ => null,
  };
}

/// Un movimiento de entrada o salida de un niño.
///
/// Puede ser de un niño ya inscrito (`idNino` con valor) o de un
/// VISITANTE que llega por primera vez sin cuenta (`idNino` vacío): así
/// nunca se rechaza a nadie en la puerta.
class Registro {
  final String id;
  final String idNino; // vacío si es visitante
  final String nombreNino;
  final TipoMovimiento tipo;
  final DateTime fecha;

  /// Manilla física que se le pone al niño. Es única por día y es la que
  /// identifica a un visitante.
  final String numeroManilla;
  final String idVoluntario;
  final String nombreVoluntario;
  final String nombreAcudiente;
  final String servicio;
  final String grupoEdad;
  final bool esEmergencia;
  final String observacion;

  const Registro({
    required this.id,
    this.idNino = '',
    required this.nombreNino,
    required this.tipo,
    required this.fecha,
    required this.numeroManilla,
    required this.idVoluntario,
    required this.nombreVoluntario,
    required this.nombreAcudiente,
    required this.servicio,
    this.grupoEdad = '',
    this.esEmergencia = false,
    this.observacion = '',
  });

  bool get esVisitante => idNino.isEmpty;
  bool get esEntrada => tipo == TipoMovimiento.entrada;

  /// Con qué se identifica a la persona en el día: el niño inscrito por su
  /// id, el visitante por su manilla.
  String get claveDelDia => esVisitante ? 'manilla:$numeroManilla' : 'nino:$idNino';

  Map<String, dynamic> toMap() => {
        'idNino': idNino,
        'nombreNino': nombreNino,
        'tipo': tipo.etiqueta,
        'fecha': escribirFecha(fecha),
        'numeroManilla': numeroManilla,
        'idVoluntario': idVoluntario,
        'nombreVoluntario': nombreVoluntario,
        'nombreAcudiente': nombreAcudiente,
        'servicio': servicio,
        'grupoEdad': grupoEdad,
        'esEmergencia': esEmergencia,
        'observacion': observacion,
      };

  factory Registro.fromMap(String id, Map<String, dynamic> data) => Registro(
        id: id,
        idNino: data['idNino'] as String? ?? '',
        nombreNino: data['nombreNino'] as String? ?? '',
        tipo: TipoMovimiento.fromString(data['tipo'] as String?),
        fecha: leerFecha(data['fecha']) ?? DateTime.now(),
        numeroManilla: data['numeroManilla'] as String? ?? '',
        idVoluntario: data['idVoluntario'] as String? ?? '',
        nombreVoluntario: data['nombreVoluntario'] as String? ?? '',
        nombreAcudiente: data['nombreAcudiente'] as String? ?? '',
        servicio: data['servicio'] as String? ?? '',
        grupoEdad: data['grupoEdad'] as String? ?? '',
        esEmergencia: data['esEmergencia'] as bool? ?? false,
        observacion: data['observacion'] as String? ?? '',
      );
}

/// De todos los movimientos de un día, deja solo a quien está presente
/// AHORA: aquellos cuyo movimiento más reciente es una Entrada.
///
/// Lo usan la lista de "Niños presentes" y el modo emergencia, así que
/// las dos pantallas comparten exactamente el mismo criterio: el listado
/// de una evacuación no puede quedar distinto del real.
List<Registro> calcularPresentes(Iterable<Registro> registrosDelDia) {
  final ordenados = [...registrosDelDia]..sort((a, b) => a.fecha.compareTo(b.fecha));
  // Al recorrer en orden, el último que queda por cada clave es el más reciente.
  final ultimoPorPersona = {for (final r in ordenados) r.claveDelDia: r};
  return ultimoPorPersona.values.where((r) => r.esEntrada).toList();
}
