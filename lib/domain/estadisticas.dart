// =============================================================================
// estadisticas.dart — Los cálculos del Dashboard, como funciones puras.
//
// Una función pura recibe datos, no modifica nada de afuera y devuelve un
// valor nuevo: con la misma entrada siempre da la misma salida. Por eso estas
// funciones se prueban con listas pequeñas, sin pantalla ni base de datos.
// Aquí está la parte funcional del proyecto: map, where, fold y reduce.
// =============================================================================

import 'nino.dart';
import 'registro.dart';

// --- Herramientas genéricas de conteo ---------------------------------------

/// Cuenta cuántos elementos caen en cada clave: un "group by" con [fold].
///
/// Es una función genérica (`<T, K>`: sirve para cualquier tipo de elemento T
/// y cualquier tipo de clave K) y de orden superior: recibe como parámetro la
/// función [clave] que dice en qué grupo cae cada elemento.
///
/// Ejemplo: `contarPor(['a', 'b', 'a'], (s) => s)` → `{'a': 2, 'b': 1}`.
Map<K, int> contarPor<T, K>(Iterable<T> elementos, K Function(T) clave) =>
    // fold arranca con un mapa vacío y lo va llenando elemento por elemento.
    elementos.fold(<K, int>{}, (conteo, elemento) {
      final k = clave(elemento);
      // update suma 1 si la clave ya existe; ifAbsent la crea en 1 si no.
      // `..` (cascada) aplica update y devuelve el mismo mapa.
      return conteo..update(k, (n) => n + 1, ifAbsent: () => 1);
    });

/// Igual que [contarPor], pero con todas las [claves] presentes aunque
/// tengan 0 (las gráficas muestran también los grupos vacíos) y en ese orden.
Map<K, int> contarEnOrden<T, K>(
  Iterable<T> elementos,
  List<K> claves,
  K Function(T) clave,
) {
  final conteo = contarPor(elementos, clave);
  // "Map for": arma un mapa nuevo recorriendo las claves en su orden.
  return {for (final k in claves) k: conteo[k] ?? 0};
}

// --- Resumen del día ---------------------------------------------------------

/// Resumen de un día de asistencia: lo que muestran las tarjetas y la
/// gráfica del Dashboard.
class ResumenDelDia {
  final int totalEntradas;
  final int presentes;
  final int visitantes;
  final int fueraDeRangoDeEdad;
  final Map<String, int> porGrupo;
  final Map<String, int> porServicio;

  const ResumenDelDia({
    required this.totalEntradas,
    required this.presentes,
    required this.visitantes,
    required this.fueraDeRangoDeEdad,
    required this.porGrupo,
    required this.porServicio,
  });

  /// Los que entraron menos los que siguen adentro.
  int get yaSalieron => totalEntradas - presentes;
}

/// Calcula el resumen de un día a partir de sus movimientos.
ResumenDelDia resumenDelDia(Iterable<Registro> registrosDelDia) {
  // Solo las entradas (where = filter).
  final entradas = registrosDelDia.where((r) => r.esEntrada).toList();
  return ResumenDelDia(
    totalEntradas: entradas.length,
    // Reutiliza la misma regla de presentes que usa toda la app.
    presentes: calcularPresentes(registrosDelDia).length,
    visitantes: entradas.where((r) => r.esVisitante).length,
    // Un niño inscrito sin grupo es porque ya pasó la edad máxima.
    fueraDeRangoDeEdad:
        entradas.where((r) => !r.esVisitante && r.grupoEdad.isEmpty).length,
    // Entradas por grupo de edad, con todos los grupos aunque estén en 0.
    porGrupo: contarEnOrden(
      entradas.where((r) => gruposEdad.contains(r.grupoEdad)),
      gruposEdad,
      (r) => r.grupoEdad,
    ),
    // Entradas por jornada, igual.
    porServicio: contarEnOrden(
      entradas.where((r) => serviciosDisponibles.contains(r.servicio)),
      serviciosDisponibles,
      (r) => r.servicio,
    ),
  );
}

// --- Promedios ---------------------------------------------------------------

/// Promedio de una serie, o `null` si está vacía. No se inventa un 0: se
/// leería como "no vino nadie" cuando en realidad es "no hubo jornada".
double? promedio(Iterable<num> valores) {
  if (valores.isEmpty) return null;
  // `fold` con tipo explícito y no `reduce`: si llega una lista de `int`,
  // `reduce` exige devolver `int` y la suma tipada como `num` falla.
  return valores.fold<num>(0, (suma, v) => suma + v) / valores.length;
}

/// Asistencia promedio por jornada, a partir de las entradas de varios días.
///
/// Divide por las OCASIONES en que hubo cada jornada (días distintos), no
/// por el número de semanas: así responde "cuántos niños llegan a un
/// miércoles típico".
///
/// Una sola pasada sobre los registros, agrupando por jornada y día. El
/// día se identifica con un entero (AAAAMMDD) y no con `soloDia()`: crear
/// un `DateTime` local por registro consulta la zona horaria y hacía esta
/// función ~170 veces más lenta (ver docs/RENDIMIENTO.md).
Map<String, double?> promedioPorJornada(Iterable<Registro> registros) {
  // Resultado del fold: jornada → (día → cuántas entradas ese día).
  // Ejemplo: {'Miércoles': {20261028: 3, 20261104: 1}}.
  final entradasPorJornadaYDia = registros.where((r) => r.esEntrada).fold(
    <String, Map<int, int>>{},
    (acumulado, r) => acumulado
      // Crea el mapa de la jornada si no existe y suma 1 al día del registro.
      ..putIfAbsent(r.servicio, () => {})
          .update(_claveDia(r.fecha), (n) => n + 1, ifAbsent: () => 1),
  );
  // Para cada jornada, promedia las entradas de sus días (si no hubo días,
  // promedio devuelve null).
  return {
    for (final servicio in serviciosDisponibles)
      servicio: promedio(entradasPorJornadaYDia[servicio]?.values ?? const <int>[]),
  };
}

/// El día como número AAAAMMDD (3 de noviembre de 2026 → 20261103). Es
/// mucho más barato que crear un DateTime y sirve igual como clave.
int _claveDia(DateTime fecha) => fecha.year * 10000 + fecha.month * 100 + fecha.day;

/// La jornada con más entradas (con [reduce]), o `null` si no hay datos.
MapEntry<String, int>? jornadaConMasAsistencia(Map<String, int> porServicio) {
  // Ignora las jornadas sin entradas.
  final conDatos = porServicio.entries.where((e) => e.value > 0);
  // reduce falla con una lista vacía, por eso se revisa antes.
  if (conDatos.isEmpty) return null;
  // reduce compara de dos en dos y se queda con el mayor.
  return conDatos.reduce((a, b) => b.value > a.value ? b : a);
}

// --- Listas para seguimiento -------------------------------------------------

/// Niños activos que no vienen hace más de [semanas] semanas, del que
/// lleva más tiempo sin venir al que menos. Base del seguimiento.
List<Nino> ninosQueDejaronDeAsistir(
  Iterable<Nino> ninos, {
  int semanas = 4,
  DateTime? hoy,
}) {
  // Fecha límite: hoy menos N semanas.
  final limite = (hoy ?? DateTime.now()).subtract(Duration(days: semanas * 7));
  return ninos
      // Activos y que alguna vez vinieron...
      .where((n) => n.estadoRegistro == 'Activo' && n.ultimaAsistencia != null)
      // ...cuya última visita es anterior al límite.
      .where((n) => n.ultimaAsistencia!.isBefore(limite))
      .toList()
    // Ordenados del que lleva más tiempo sin venir al que menos.
    ..sort((a, b) => a.ultimaAsistencia!.compareTo(b.ultimaAsistencia!));
}

/// Quién cumplió años en la última semana, con cuántos días hace.
///
/// Devuelve una lista de *records* `({Nino nino, int diasDesde})`: un record
/// es un grupo de valores con nombre, sin tener que crear una clase.
List<({Nino nino, int diasDesde})> cumpleanerosDeLaSemana(
  Iterable<Nino> ninos, {
  DateTime? hoy,
}) =>
    ninos
        // 1. A cada niño le asocia cuántos días hace que cumplió (o null).
        .map((n) => (nino: n, diasDesde: diasDesdeCumpleanos(n.fechaNacimiento, hoy: hoy)))
        // 2. Deja solo los que cumplieron esta semana.
        .where((c) => c.diasDesde != null)
        // 3. Cambia el tipo a int (ya sabemos que no es null).
        .map((c) => (nino: c.nino, diasDesde: c.diasDesde!))
        .toList()
      // 4. Del cumpleaños más reciente al más antiguo.
      ..sort((a, b) => a.diasDesde.compareTo(b.diasDesde));
