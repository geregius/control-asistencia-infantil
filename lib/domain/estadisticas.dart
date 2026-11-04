import 'nino.dart';
import 'registro.dart';

/// Estadísticas del Dashboard, escritas como funciones puras: reciben
/// listas, no modifican nada y devuelven un valor nuevo. Por eso se
/// prueban sin pantalla ni base de datos.

/// Cuenta cuántos elementos caen en cada clave (un "group by" con [fold]).
Map<K, int> contarPor<T, K>(Iterable<T> elementos, K Function(T) clave) =>
    elementos.fold(<K, int>{}, (conteo, elemento) {
      final k = clave(elemento);
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
  return {for (final k in claves) k: conteo[k] ?? 0};
}

/// Resumen de un día de asistencia.
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

  int get yaSalieron => totalEntradas - presentes;
}

ResumenDelDia resumenDelDia(Iterable<Registro> registrosDelDia) {
  final entradas = registrosDelDia.where((r) => r.esEntrada).toList();
  return ResumenDelDia(
    totalEntradas: entradas.length,
    presentes: calcularPresentes(registrosDelDia).length,
    visitantes: entradas.where((r) => r.esVisitante).length,
    // Un niño inscrito sin grupo es porque ya pasó la edad máxima.
    fueraDeRangoDeEdad:
        entradas.where((r) => !r.esVisitante && r.grupoEdad.isEmpty).length,
    porGrupo: contarEnOrden(
      entradas.where((r) => gruposEdad.contains(r.grupoEdad)),
      gruposEdad,
      (r) => r.grupoEdad,
    ),
    porServicio: contarEnOrden(
      entradas.where((r) => serviciosDisponibles.contains(r.servicio)),
      serviciosDisponibles,
      (r) => r.servicio,
    ),
  );
}

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
  final entradasPorJornadaYDia = registros.where((r) => r.esEntrada).fold(
    <String, Map<int, int>>{},
    (acumulado, r) => acumulado
      ..putIfAbsent(r.servicio, () => {})
          .update(_claveDia(r.fecha), (n) => n + 1, ifAbsent: () => 1),
  );
  return {
    for (final servicio in serviciosDisponibles)
      servicio: promedio(entradasPorJornadaYDia[servicio]?.values ?? const <int>[]),
  };
}

int _claveDia(DateTime fecha) => fecha.year * 10000 + fecha.month * 100 + fecha.day;

/// La jornada con más entradas (con [reduce]), o `null` si no hay datos.
MapEntry<String, int>? jornadaConMasAsistencia(Map<String, int> porServicio) {
  final conDatos = porServicio.entries.where((e) => e.value > 0);
  if (conDatos.isEmpty) return null;
  return conDatos.reduce((a, b) => b.value > a.value ? b : a);
}

/// Niños activos que no vienen hace más de [semanas] semanas, del que
/// lleva más tiempo sin venir al que menos. Base del seguimiento.
List<Nino> ninosQueDejaronDeAsistir(
  Iterable<Nino> ninos, {
  int semanas = 4,
  DateTime? hoy,
}) {
  final limite = (hoy ?? DateTime.now()).subtract(Duration(days: semanas * 7));
  return ninos
      .where((n) => n.estadoRegistro == 'Activo' && n.ultimaAsistencia != null)
      .where((n) => n.ultimaAsistencia!.isBefore(limite))
      .toList()
    ..sort((a, b) => a.ultimaAsistencia!.compareTo(b.ultimaAsistencia!));
}

/// Quién cumplió años en la última semana, con cuántos días hace.
List<({Nino nino, int diasDesde})> cumpleanerosDeLaSemana(
  Iterable<Nino> ninos, {
  DateTime? hoy,
}) =>
    ninos
        .map((n) => (nino: n, diasDesde: diasDesdeCumpleanos(n.fechaNacimiento, hoy: hoy)))
        .where((c) => c.diasDesde != null)
        .map((c) => (nino: c.nino, diasDesde: c.diasDesde!))
        .toList()
      ..sort((a, b) => a.diasDesde.compareTo(b.diasDesde));
