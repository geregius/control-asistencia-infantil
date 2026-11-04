// ignore_for_file: avoid_print -- herramienta de consola: imprime la tabla de resultados.
// Mide las funciones del dominio con volúmenes crecientes.
//
//   dart run tool/benchmark.dart
//
// No es una prueba (los tiempos varían según el equipo): es una medición
// para justificar decisiones con números. Resultados en docs/RENDIMIENTO.md.
import 'package:asistencia_infantil/domain/dominio.dart';

void main() {
  final hoy = DateTime(2026, 11, 1, 8);
  print('Función | Datos | Mediana | Por elemento');
  print('---|---|---|---');

  for (final cantidad in [500, 5000, 50000]) {
    final registros = _registrosDelDia(hoy, cantidad);
    _medir('calcularPresentes', cantidad, () => calcularPresentes(registros));
    _medir('resumenDelDia', cantidad, () => resumenDelDia(registros));
  }

  // Ocho semanas de historial: 3 jornadas por semana, 400 niños por jornada.
  final historial = [
    for (var semana = 0; semana < 8; semana++)
      for (final (servicio, dias) in [('Domingo mañana', 0), ('Domingo mediodía', 0), ('Miércoles', 4)])
        ..._registrosDelDia(hoy.subtract(Duration(days: semana * 7 + dias)), 400, servicio: servicio),
  ];
  _medir('promedioPorJornada', historial.length, () => promedioPorJornada(historial));

  final ninos = [for (var i = 0; i < 5000; i++) _nino(i)];
  _medir('búsqueda sin tildes', ninos.length,
      () => ninos.where((n) => NinoBusqueda.desde(n).coincideBusqueda('jose')).length);
  _medir('ninosQueDejaronDeAsistir', ninos.length, () => ninosQueDejaronDeAsistir(ninos, hoy: hoy));
}

/// Corre [funcion] varias veces y reporta la mediana (descarta las
/// primeras corridas, mientras el compilador optimiza).
void _medir(String nombre, int datos, Object? Function() funcion) {
  for (var i = 0; i < 5; i++) {
    funcion();
  }
  final tiempos = <int>[];
  for (var i = 0; i < 21; i++) {
    final reloj = Stopwatch()..start();
    funcion();
    tiempos.add(reloj.elapsedMicroseconds);
  }
  tiempos.sort();
  final mediana = tiempos[tiempos.length ~/ 2];
  final ms = (mediana / 1000).toStringAsFixed(2);
  final porElemento = (mediana * 1000 / datos).toStringAsFixed(0);
  print('$nombre | $datos | $ms ms | $porElemento ns');
}

/// [cantidad] movimientos de un día: entradas de niños y salidas de la mitad.
List<Registro> _registrosDelDia(DateTime dia, int cantidad, {String servicio = 'Domingo mañana'}) {
  final ninos = cantidad * 2 ~/ 3;
  return [
    for (var i = 0; i < cantidad; i++)
      Registro(
        id: '${dia.millisecondsSinceEpoch}-$i',
        idNino: 'n${i % ninos}',
        nombreNino: 'Niño $i',
        tipo: i < ninos ? TipoMovimiento.entrada : TipoMovimiento.salida,
        fecha: dia.add(Duration(seconds: i)),
        numeroManilla: '${i % ninos}',
        idVoluntario: 'v',
        nombreVoluntario: 'V',
        nombreAcudiente: 'A',
        servicio: servicio,
        grupoEdad: gruposEdad[i % gruposEdad.length],
      ),
  ];
}

Nino _nino(int i) => Nino(
      id: 'n$i',
      tipoIdentificacion: 'Registro Civil',
      identificacionMenor: '$i',
      nombres: i % 50 == 0 ? 'José' : 'Niño$i',
      apellidos: 'Muñoz',
      fechaNacimiento: DateTime(2019, 1 + i % 12, 1 + i % 28),
      genero: 'Masculino',
      estadoRegistro: 'Activo',
      alertaMedica: false,
      condicionMedica: '',
      autorizoFoto: true,
      ultimaAsistencia: DateTime(2026, 1 + i % 10, 1),
    );
