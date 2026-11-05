import 'package:asistencia_infantil/domain/dominio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final domingo = DateTime(2026, 11, 1, 8);

  test('contarPor agrupa y cuenta', () {
    expect(contarPor(['a', 'b', 'a'], (s) => s), {'a': 2, 'b': 1});
    expect(contarPor(<String>[], (s) => s), isEmpty);
  });

  test('contarEnOrden incluye las claves en 0 y respeta el orden', () {
    final conteo = contarEnOrden([3, 3, 1], [1, 2, 3], (n) => n);
    expect(conteo, {1: 1, 2: 0, 3: 2});
    expect(conteo.keys, [1, 2, 3]);
  });

  group('resumenDelDia', () {
    final registros = [
      registro(idNino: 'a', fecha: domingo, grupo: 'Brotes'),
      registro(idNino: 'b', manilla: '2', fecha: domingo, grupo: 'Líderes'),
      registro(manilla: '3', fecha: domingo, grupo: 'Brotes'), // visitante
      registro(idNino: 'c', manilla: '4', fecha: domingo, grupo: ''), // mayor de 10
      registro(
        idNino: 'a',
        tipo: TipoMovimiento.salida,
        fecha: domingo.add(const Duration(hours: 2)),
      ),
    ];
    final resumen = resumenDelDia(registros);

    test('cuenta entradas, presentes y los que ya salieron', () {
      expect(resumen.totalEntradas, 4);
      expect(resumen.presentes, 3);
      expect(resumen.yaSalieron, 1);
    });

    test('separa visitantes y niños fuera del rango de edad', () {
      expect(resumen.visitantes, 1);
      expect(resumen.fueraDeRangoDeEdad, 1);
    });

    test('reparte por grupo con todos los grupos presentes', () {
      expect(resumen.porGrupo.keys, gruposEdad);
      expect(resumen.porGrupo['Brotes'], 2);
      expect(resumen.porGrupo['Semillas'], 0);
    });
  });

  test('promedio devuelve null sin datos en vez de 0', () {
    expect(promedio([2, 4, 6]), 4);
    expect(promedio([]), isNull);
  });

  test('promedioPorJornada divide por los días en que hubo jornada', () {
    final miercoles1 = DateTime(2026, 10, 28, 18);
    final miercoles2 = DateTime(2026, 11, 4, 18);
    final promedios = promedioPorJornada([
      registro(idNino: 'a', fecha: miercoles1, servicio: 'Miércoles'),
      registro(idNino: 'b', fecha: miercoles1, servicio: 'Miércoles'),
      registro(idNino: 'c', fecha: miercoles1, servicio: 'Miércoles'),
      registro(idNino: 'a', fecha: miercoles2, servicio: 'Miércoles'),
    ]);
    expect(promedios['Miércoles'], 2);
    expect(promedios['Sábado'], isNull);
  });

  test('jornadaConMasAsistencia elige el mayor e ignora las vacías', () {
    expect(jornadaConMasAsistencia({'A': 3, 'B': 9, 'C': 1})?.key, 'B');
    expect(jornadaConMasAsistencia({'A': 0}), isNull);
  });

  test('ninosQueDejaronDeAsistir filtra activos y ordena por antigüedad', () {
    final hoy = DateTime(2026, 11, 3);
    final lista = ninosQueDejaronDeAsistir([
      nino('reciente', ultimaAsistencia: DateTime(2026, 10, 30)),
      nino('hace2meses', ultimaAsistencia: DateTime(2026, 9, 1)),
      nino('hace6semanas', ultimaAsistencia: DateTime(2026, 9, 20)),
      nino('inactivo', estado: 'Inactivo', ultimaAsistencia: DateTime(2026, 1, 1)),
      nino('nunca'),
    ], hoy: hoy);
    expect(lista.map((n) => n.id), ['hace2meses', 'hace6semanas']);
  });

  test('cumpleanerosDeLaSemana ordena del más reciente al más antiguo', () {
    final hoy = DateTime(2026, 11, 3);
    final lista = cumpleanerosDeLaSemana([
      nino('hace3', nacimiento: DateTime(2020, 10, 31)),
      nino('hoy', nacimiento: DateTime(2021, 11, 3)),
      nino('lejos', nacimiento: DateTime(2021, 6, 1)),
    ], hoy: hoy);
    expect(lista.map((c) => c.nino.id), ['hoy', 'hace3']);
    expect(lista.first.diasDesde, 0);
  });
}
