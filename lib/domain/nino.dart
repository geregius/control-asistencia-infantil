import 'fechas.dart';

const tiposIdentificacionMenor = [
  'Registro Civil',
  'Tarjeta de Identidad',
  'Cédula de Extranjería',
  'Pasaporte',
  'No tiene documento',
];

const generos = ['Masculino', 'Femenino'];

/// Estados que se pueden alternar desde un seguimiento: un niño que dejó
/// de venir pasa a "Inactivo" sin borrarlo ni perder su historial.
const estadosRegistroGestionables = ['Activo', 'Inactivo'];

/// Los grupos del programa, en orden de edad.
const gruposEdad = ['Semillas', 'Brotes', 'Exploradores', 'Aventureros', 'Líderes'];

/// Rango de edad de cada grupo. Debe quedar sincronizado con [grupoParaEdad].
const rangoEdadPorGrupo = {
  'Semillas': '2 años',
  'Brotes': '3-4 años',
  'Exploradores': '5-6 años',
  'Aventureros': '7-8 años',
  'Líderes': '9-10 años',
};

const parentescos = ['Padre', 'Madre', 'Tío/a', 'Abuelo/a', 'Acudiente Autorizado'];

/// Rango de edad que recibe el programa.
const edadMinimaRegistro = 2;
const edadMaximaRegistro = 10;

/// Edad en años cumplidos a partir de la fecha de nacimiento.
int calcularEdad(DateTime fechaNacimiento, {DateTime? hoy}) {
  final ahora = hoy ?? DateTime.now();
  var edad = ahora.year - fechaNacimiento.year;
  final aunNoCumple = ahora.month < fechaNacimiento.month ||
      (ahora.month == fechaNacimiento.month && ahora.day < fechaNacimiento.day);
  if (aunNoCumple) edad--;
  return edad;
}

/// Grupo al que pertenece un niño HOY según su edad.
///
/// A propósito no se guarda en el registro del menor: la edad cambia con
/// el tiempo, así que el grupo se recalcula cada vez que hace falta (por
/// ejemplo al registrar el ingreso) en vez de quedar fijado al inscribirlo.
String? grupoParaEdad(int edad) {
  if (edad == 2) return 'Semillas';
  if (edad >= 3 && edad <= 4) return 'Brotes';
  if (edad >= 5 && edad <= 6) return 'Exploradores';
  if (edad >= 7 && edad <= 8) return 'Aventureros';
  if (edad >= 9 && edad <= 10) return 'Líderes';
  return null;
}

/// Cuántos días atrás cayó el cumpleaños de este año (0 = hoy), o `null`
/// si no cayó en los últimos 7 días. Sirve para "Cumple hoy" /
/// "Cumplió hace N días".
int? diasDesdeCumpleanos(DateTime fechaNacimiento, {DateTime? hoy}) {
  final ahora = hoy ?? DateTime.now();
  for (var i = 0; i < 7; i++) {
    final dia = ahora.subtract(Duration(days: i));
    if (dia.month == fechaNacimiento.month && dia.day == fechaNacimiento.day) {
      return i;
    }
  }
  return null;
}

/// true si el cumpleaños (solo mes y día) cayó en los últimos 7 días.
bool cumpleEnUltimaSemana(DateTime fechaNacimiento, {DateTime? hoy}) =>
    diasDesdeCumpleanos(fechaNacimiento, hoy: hoy) != null;

/// Días que faltan para el próximo cumpleaños (0 = hoy).
int diasHastaProximoCumpleanos(DateTime fechaNacimiento, {DateTime? hoy}) {
  final ahora = soloDia(hoy ?? DateTime.now());
  var proximo = DateTime(ahora.year, fechaNacimiento.month, fechaNacimiento.day);
  if (proximo.isBefore(ahora)) {
    proximo = DateTime(ahora.year + 1, fechaNacimiento.month, fechaNacimiento.day);
  }
  return proximo.difference(ahora).inDays;
}

/// "MM-DD" de una fecha, sin año.
///
/// Se guarda junto a la fecha de nacimiento para consultar "quién cumple
/// esta semana" con un filtro acotado en la base de datos, en vez de
/// traer la colección completa y filtrar en el teléfono.
String mesDiaDe(DateTime fecha) =>
    '${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

/// Los 7 "MM-DD" que cuentan como "esta semana" (hoy y los 6 días
/// anteriores), con el mismo criterio de [diasDesdeCumpleanos].
List<String> mesDiaUltimaSemana({DateTime? hoy}) {
  final ahora = hoy ?? DateTime.now();
  return [for (var i = 0; i < 7; i++) mesDiaDe(ahora.subtract(Duration(days: i)))];
}

/// Llave interna para un menor sin número de documento:
/// AAAAMMDD-PRIMERNOMBRE-PRIMERAPELLIDO.
String generarLlaveInterna({
  required DateTime fechaNacimiento,
  required String nombres,
  required String apellidos,
}) {
  final fecha = '${fechaNacimiento.year.toString().padLeft(4, '0')}'
      '${fechaNacimiento.month.toString().padLeft(2, '0')}'
      '${fechaNacimiento.day.toString().padLeft(2, '0')}';
  String primeraPalabra(String texto) =>
      texto.trim().split(RegExp(r'\s+')).first.toUpperCase();
  return '$fecha-${primeraPalabra(nombres)}-${primeraPalabra(apellidos)}';
}

class Nino {
  final String id;
  final String tipoIdentificacion;
  final String identificacionMenor;
  final String nombres;
  final String apellidos;
  final DateTime fechaNacimiento;
  final String genero;
  final String estadoRegistro;
  final bool alertaMedica;
  final String condicionMedica;
  final bool autorizoFoto;
  final String fotoUrl;

  /// Si el niño está adentro ahora mismo (última Entrada sin Salida).
  /// Se actualiza en la misma operación atómica que crea cada registro,
  /// así que es la fuente de verdad de "¿ya entró hoy?".
  final bool presente;

  /// Denormalizado para avisar en el ingreso, sin una consulta extra por
  /// niño, si hay personas que NO pueden recogerlo.
  final bool tieneNoAutorizados;

  /// Total histórico de Entradas y fecha de la más reciente. Alimentan el
  /// reporte "Niños que dejaron de asistir".
  final int totalEntradas;
  final DateTime? ultimaAsistencia;

  const Nino({
    required this.id,
    required this.tipoIdentificacion,
    required this.identificacionMenor,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.genero,
    required this.estadoRegistro,
    required this.alertaMedica,
    required this.condicionMedica,
    required this.autorizoFoto,
    this.fotoUrl = '',
    this.presente = false,
    this.tieneNoAutorizados = false,
    this.totalEntradas = 0,
    this.ultimaAsistencia,
  });

  String get nombreCompleto => '$nombres $apellidos';

  int edad({DateTime? hoy}) => calcularEdad(fechaNacimiento, hoy: hoy);

  String? grupo({DateTime? hoy}) => grupoParaEdad(edad(hoy: hoy));

  Map<String, dynamic> toMap() => {
        'tipoIdentificacion': tipoIdentificacion,
        'identificacionMenor': identificacionMenor,
        'nombres': nombres,
        'apellidos': apellidos,
        'fechaNacimiento': escribirFecha(fechaNacimiento),
        'mesDiaNacimiento': mesDiaDe(fechaNacimiento),
        'genero': genero,
        'estadoRegistro': estadoRegistro,
        'alertaMedica': alertaMedica,
        'condicionMedica': condicionMedica,
        'autorizoFoto': autorizoFoto,
        'fotoUrl': fotoUrl,
        'presente': presente,
        'tieneNoAutorizados': tieneNoAutorizados,
        'totalEntradas': totalEntradas,
        'ultimaAsistencia':
            ultimaAsistencia == null ? null : escribirFecha(ultimaAsistencia!),
      };

  factory Nino.fromMap(String id, Map<String, dynamic> data) => Nino(
        id: id,
        tipoIdentificacion: data['tipoIdentificacion'] as String? ?? '',
        identificacionMenor: data['identificacionMenor'] as String? ?? '',
        nombres: data['nombres'] as String? ?? '',
        apellidos: data['apellidos'] as String? ?? '',
        fechaNacimiento: leerFecha(data['fechaNacimiento']) ?? DateTime.now(),
        genero: data['genero'] as String? ?? '',
        estadoRegistro: data['estadoRegistro'] as String? ?? '',
        alertaMedica: data['alertaMedica'] as bool? ?? false,
        condicionMedica: data['condicionMedica'] as String? ?? '',
        autorizoFoto: data['autorizoFoto'] as bool? ?? false,
        fotoUrl: data['fotoUrl'] as String? ?? '',
        presente: data['presente'] as bool? ?? false,
        tieneNoAutorizados: data['tieneNoAutorizados'] as bool? ?? false,
        totalEntradas: (data['totalEntradas'] as num?)?.toInt() ?? 0,
        ultimaAsistencia: leerFecha(data['ultimaAsistencia']),
      );
}

/// Copia mínima de un niño (nombre y fecha de nacimiento) que cualquier
/// cuenta puede consultar para buscarlo al vincularlo. A propósito NO
/// incluye foto, documento ni información médica: quien no tiene vínculo
/// con el niño no puede ver esos datos solo con saber su nombre.
class NinoBusqueda {
  final String id;
  final String nombres;
  final String apellidos;
  final DateTime fechaNacimiento;

  const NinoBusqueda({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
  });

  factory NinoBusqueda.desde(Nino nino) => NinoBusqueda(
        id: nino.id,
        nombres: nino.nombres,
        apellidos: nino.apellidos,
        fechaNacimiento: nino.fechaNacimiento,
      );

  String get nombreCompleto => '$nombres $apellidos';

  /// Compara sin distinguir mayúsculas ni tildes: "jose" encuentra a "José".
  bool coincideBusqueda(String consulta) =>
      normalizarTexto(nombreCompleto).contains(normalizarTexto(consulta));
}

const _sinTilde = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};

/// Minúsculas y sin tildes, para búsquedas.
String normalizarTexto(String texto) =>
    texto.toLowerCase().split('').map((letra) => _sinTilde[letra] ?? letra).join();
