// =============================================================================
// nino.dart — El niño y las reglas que dependen de su fecha de nacimiento.
//
// Contiene: las listas fijas del formulario (documentos, géneros, grupos), las
// funciones de edad, grupo y cumpleaños, la clase Nino (el modelo) y la clase
// NinoBusqueda (copia mínima, sin datos sensibles, para buscar por nombre).
// =============================================================================

import 'fechas.dart';

// --- Listas fijas que usan los formularios -----------------------------------

/// Tipos de documento que puede tener un menor en Colombia.
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

/// Rango de edad de cada grupo, para mostrarlo en pantalla. Es un Map
/// (diccionario): la clave es el grupo y el valor su rango. Debe quedar
/// sincronizado con [grupoParaEdad].
const rangoEdadPorGrupo = {
  'Semillas': '2 años',
  'Brotes': '3-4 años',
  'Exploradores': '5-6 años',
  'Aventureros': '7-8 años',
  'Líderes': '9-10 años',
};

/// Relación del adulto con el niño.
const parentescos = ['Padre', 'Madre', 'Tío/a', 'Abuelo/a', 'Acudiente Autorizado'];

/// Rango de edad que recibe el programa.
const edadMinimaRegistro = 2;
const edadMaximaRegistro = 10;

// --- Edad y grupo ------------------------------------------------------------

/// Edad en años cumplidos a partir de la fecha de nacimiento.
///
/// [hoy] es opcional: en la app se usa la fecha actual; en las pruebas se
/// pasa una fecha fija para que el resultado no cambie con el tiempo.
int calcularEdad(DateTime fechaNacimiento, {DateTime? hoy}) {
  // `??` significa "si es null, usa lo de la derecha".
  final ahora = hoy ?? DateTime.now();

  // Primero, la diferencia de años.
  var edad = ahora.year - fechaNacimiento.year;

  // Si este año todavía no llega el cumpleaños, aún no cumple: se resta uno.
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
///
/// Devuelve `null` si la edad está fuera del rango del programa. El `?` en
/// `String?` indica que el resultado puede ser null (null-safety de Dart).
String? grupoParaEdad(int edad) {
  if (edad == 2) return 'Semillas';
  if (edad >= 3 && edad <= 4) return 'Brotes';
  if (edad >= 5 && edad <= 6) return 'Exploradores';
  if (edad >= 7 && edad <= 8) return 'Aventureros';
  if (edad >= 9 && edad <= 10) return 'Líderes';
  return null;
}

// --- Cumpleaños --------------------------------------------------------------

/// Cuántos días atrás cayó el cumpleaños de este año (0 = hoy), o `null`
/// si no cayó en los últimos 7 días. Sirve para "Cumple hoy" /
/// "Cumplió hace N días".
int? diasDesdeCumpleanos(DateTime fechaNacimiento, {DateTime? hoy}) {
  final ahora = hoy ?? DateTime.now();
  // Revisa hoy y los 6 días anteriores, comparando solo mes y día (el año no
  // importa: es el cumpleaños, no la fecha de nacimiento).
  for (var i = 0; i < 7; i++) {
    final dia = ahora.subtract(Duration(days: i));
    if (dia.month == fechaNacimiento.month && dia.day == fechaNacimiento.day) {
      return i;
    }
  }
  return null;
}

/// true si el cumpleaños (solo mes y día) cayó en los últimos 7 días.
/// Reutiliza [diasDesdeCumpleanos] para que las dos reglas no se separen.
bool cumpleEnUltimaSemana(DateTime fechaNacimiento, {DateTime? hoy}) =>
    diasDesdeCumpleanos(fechaNacimiento, hoy: hoy) != null;

/// Días que faltan para el próximo cumpleaños (0 = hoy).
int diasHastaProximoCumpleanos(DateTime fechaNacimiento, {DateTime? hoy}) {
  final ahora = soloDia(hoy ?? DateTime.now());
  // El cumpleaños de este año...
  var proximo = DateTime(ahora.year, fechaNacimiento.month, fechaNacimiento.day);
  // ...y si ya pasó, el del año siguiente.
  if (proximo.isBefore(ahora)) {
    proximo = DateTime(ahora.year + 1, fechaNacimiento.month, fechaNacimiento.day);
  }
  return proximo.difference(ahora).inDays;
}

/// "MM-DD" de una fecha, sin año (por ejemplo "11-03").
///
/// Se guarda junto a la fecha de nacimiento para consultar "quién cumple
/// esta semana" con un filtro acotado en la base de datos, en vez de
/// traer la colección completa y filtrar en el teléfono.
/// `padLeft(2, '0')` agrega un cero a la izquierda: 3 → "03".
String mesDiaDe(DateTime fecha) =>
    '${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

/// Los 7 "MM-DD" que cuentan como "esta semana" (hoy y los 6 días
/// anteriores), con el mismo criterio de [diasDesdeCumpleanos].
List<String> mesDiaUltimaSemana({DateTime? hoy}) {
  final ahora = hoy ?? DateTime.now();
  // "Collection for": arma la lista con un ciclo dentro de los corchetes.
  return [for (var i = 0; i < 7; i++) mesDiaDe(ahora.subtract(Duration(days: i)))];
}

// --- Identificación ----------------------------------------------------------

/// Llave interna para un menor sin número de documento:
/// AAAAMMDD-PRIMERNOMBRE-PRIMERAPELLIDO (por ejemplo 20210407-MARÍA-PÉREZ).
String generarLlaveInterna({
  required DateTime fechaNacimiento,
  required String nombres,
  required String apellidos,
}) {
  // La fecha como AAAAMMDD.
  final fecha = '${fechaNacimiento.year.toString().padLeft(4, '0')}'
      '${fechaNacimiento.month.toString().padLeft(2, '0')}'
      '${fechaNacimiento.day.toString().padLeft(2, '0')}';

  // Función local: quita espacios de los extremos, parte por espacios
  // (RegExp(r'\s+') = uno o más espacios) y toma la primera palabra en mayúsculas.
  String primeraPalabra(String texto) =>
      texto.trim().split(RegExp(r'\s+')).first.toUpperCase();

  return '$fecha-${primeraPalabra(nombres)}-${primeraPalabra(apellidos)}';
}

// --- El modelo Nino ----------------------------------------------------------

/// Un niño inscrito en el programa.
///
/// Todos los campos son `final`: el objeto es inmutable, no cambia después
/// de creado. Para "cambiar" un niño se crea uno nuevo con los datos nuevos.
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

  /// Constructor `const`: permite crear el objeto en tiempo de compilación.
  /// `required` obliga a pasar ese dato; los que tienen `=` toman ese valor
  /// por defecto si no se pasan.
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

  /// Propiedad calculada (getter): se usa como un campo, pero se calcula.
  String get nombreCompleto => '$nombres $apellidos';

  /// Edad de hoy (o de la fecha que se pase).
  int edad({DateTime? hoy}) => calcularEdad(fechaNacimiento, hoy: hoy);

  /// Grupo de hoy, calculado con la edad (nunca guardado).
  String? grupo({DateTime? hoy}) => grupoParaEdad(edad(hoy: hoy));

  /// Convierte el objeto en un Map para guardarlo en la base de datos.
  Map<String, dynamic> toMap() => {
        'tipoIdentificacion': tipoIdentificacion,
        'identificacionMenor': identificacionMenor,
        'nombres': nombres,
        'apellidos': apellidos,
        'fechaNacimiento': escribirFecha(fechaNacimiento),
        // Campo derivado para consultar cumpleaños sin traer a todos.
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
        // `!` le dice a Dart "aquí ya sé que no es null" (se comprobó antes).
        'ultimaAsistencia':
            ultimaAsistencia == null ? null : escribirFecha(ultimaAsistencia!),
      };

  /// Constructor de fábrica: crea un Nino a partir de lo que llega de la
  /// base de datos. Cada `as String? ?? ''` significa: "léelo como texto que
  /// puede faltar; si falta, usa texto vacío". Así un dato incompleto no
  /// rompe la app.
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
        // `num` acepta int o double (JSON puede traer cualquiera de los dos).
        totalEntradas: (data['totalEntradas'] as num?)?.toInt() ?? 0,
        ultimaAsistencia: leerFecha(data['ultimaAsistencia']),
      );
}

// --- Búsqueda sin datos sensibles --------------------------------------------

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

  /// Arma la copia mínima a partir del niño completo.
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

/// Tabla de reemplazo: cada letra con tilde → la misma letra sin tilde.
/// El guion bajo inicial (`_sinTilde`) la hace privada a este archivo.
const _sinTilde = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};

/// Minúsculas y sin tildes, para búsquedas.
///
/// Estilo funcional: parte el texto en letras (`split('')`), transforma cada
/// una con `map` (si está en la tabla la reemplaza, si no la deja igual) y
/// vuelve a unirlas con `join()`.
String normalizarTexto(String texto) =>
    texto.toLowerCase().split('').map((letra) => _sinTilde[letra] ?? letra).join();
