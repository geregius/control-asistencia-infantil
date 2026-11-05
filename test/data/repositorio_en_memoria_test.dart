import 'package:asistencia_infantil/data/repositorio_asistencia.dart';
import 'package:asistencia_infantil/data/repositorio_en_memoria.dart';
import 'package:asistencia_infantil/domain/dominio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final ahora = DateTime(2026, 11, 1, 8);
  late RepositorioEnMemoria repo;

  setUp(() {
    repo = RepositorioEnMemoria(
      ninos: [nino('a', nacimiento: DateTime(2022, 5, 1)), nino('b')],
      reloj: () => ahora,
    );
  });

  tearDown(() => repo.cerrar());

  Future<Registro> mover(
    String id, {
    TipoMovimiento tipo = TipoMovimiento.entrada,
    String manilla = '10',
  }) async {
    final actual = (await repo.ninos().first).firstWhere((n) => n.id == id);
    return repo.registrarMovimiento(
      nino: actual,
      tipo: tipo,
      numeroManilla: manilla,
      servicio: 'Domingo mañana',
      nombreAcudiente: 'Acudiente',
      idVoluntario: 'v1',
      nombreVoluntario: 'Voluntario',
    );
  }

  test('la entrada calcula el grupo por la edad de hoy y marca presente', () async {
    final registro = await mover('a');
    expect(registro.grupoEdad, 'Brotes'); // 4 años
    final a = (await repo.ninos().first).firstWhere((n) => n.id == 'a');
    expect(a.presente, isTrue);
    expect(a.totalEntradas, 1);
  });

  test('no deja entrar dos veces al mismo niño', () async {
    await mover('a');
    expect(() => mover('a', manilla: '11'), throwsA(isA<RegistroRechazado>()));
  });

  test('no deja salir a quien no ha entrado', () async {
    expect(() => mover('a', tipo: TipoMovimiento.salida), throwsA(isA<RegistroRechazado>()));
  });

  test('una manilla en uso no se puede repetir el mismo día', () async {
    await mover('a', manilla: '10');
    expect(() => mover('b', manilla: '10'), throwsA(isA<RegistroRechazado>()));
  });

  test('al salir, la manilla queda libre', () async {
    await mover('a', manilla: '10');
    await mover('a', tipo: TipoMovimiento.salida);
    await expectLater(mover('b', manilla: '10'), completes);
  });

  test('el stream del día emite cada cambio', () async {
    final emisiones = repo.registrosDelDia(ahora).map((l) => l.length);
    final esperado = expectLater(emisiones, emitsInOrder([0, 1]));
    await mover('a');
    await esperado;
  });
}
