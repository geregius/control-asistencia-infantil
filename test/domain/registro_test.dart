// =============================================================================
// registro_test.dart — Pruebas de la jornada sugerida, calcularPresentes
// (incluido el caso de registros desordenados y visitantes por manilla) y
// de leerFecha con un Timestamp falso.
// =============================================================================

import 'package:asistencia_infantil/domain/dominio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('servicioSugerido', () {
    test('elige la jornada según el día y la hora', () {
      expect(servicioSugerido(DateTime(2026, 11, 1, 8)), 'Domingo mañana');
      expect(servicioSugerido(DateTime(2026, 11, 1, 11)), 'Domingo mediodía');
      expect(servicioSugerido(DateTime(2026, 11, 4, 19)), 'Miércoles');
      expect(servicioSugerido(DateTime(2026, 11, 3, 19)), isNull); // martes
    });
  });

  group('calcularPresentes', () {
    final hoy = DateTime(2026, 11, 1, 8);

    test('quien entró y salió ya no está presente', () {
      final presentes = calcularPresentes([
        registro(idNino: 'a', fecha: hoy),
        registro(idNino: 'b', manilla: '2', fecha: hoy),
        registro(idNino: 'a', tipo: TipoMovimiento.salida, fecha: hoy.add(const Duration(hours: 2))),
      ]);
      expect(presentes.map((r) => r.idNino), ['b']);
    });

    test('al visitante se le identifica por la manilla', () {
      final presentes = calcularPresentes([
        registro(manilla: '7', fecha: hoy),
        registro(manilla: '8', fecha: hoy),
        registro(manilla: '7', tipo: TipoMovimiento.salida, fecha: hoy.add(const Duration(hours: 1))),
      ]);
      expect(presentes.map((r) => r.numeroManilla), ['8']);
    });

    test('no depende del orden en que lleguen los registros', () {
      final salida = registro(idNino: 'a', tipo: TipoMovimiento.salida, fecha: hoy.add(const Duration(hours: 2)));
      final entrada = registro(idNino: 'a', fecha: hoy);
      expect(calcularPresentes([salida, entrada]), isEmpty);
    });
  });

  test('Registro.toMap / fromMap ida y vuelta', () {
    final original = registro(idNino: 'a', fecha: DateTime(2026, 11, 1, 8, 30));
    final copia = Registro.fromMap(original.id, original.toMap());
    expect(copia.tipo, TipoMovimiento.entrada);
    expect(copia.fecha, original.fecha);
    expect(copia.claveDelDia, 'nino:a');
  });

  group('leerFecha', () {
    test('acepta DateTime, texto ISO y objetos con toDate()', () {
      final fecha = DateTime(2026, 1, 2, 3, 4);
      expect(leerFecha(fecha), fecha);
      expect(leerFecha(fecha.toIso8601String()), fecha);
      expect(leerFecha(_TimestampFalso(fecha)), fecha);
      expect(leerFecha(42), isNull);
      expect(leerFecha(null), isNull);
    });
  });
}

/// Imita al Timestamp de Firestore sin depender de su SDK.
class _TimestampFalso {
  _TimestampFalso(this._fecha);
  final DateTime _fecha;
  DateTime toDate() => _fecha;
}
