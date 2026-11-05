// =============================================================================
// repositorio_persistente_test.dart — Pruebas del decorador que guarda:
// sobrevive a reabrir, no repite ids, no guarda movimientos rechazados,
// descarta lo de otro día, tolera datos dañados y se reinicia.
//
// Usa AlmacenEnMemoria en vez del navegador: el mismo contrato, sin plugins.
// =============================================================================

import 'dart:convert';

import 'package:asistencia_infantil/data/almacen_local.dart';
import 'package:asistencia_infantil/data/repositorio_asistencia.dart';
import 'package:asistencia_infantil/data/repositorio_persistente.dart';
import 'package:asistencia_infantil/domain/dominio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hoy = DateTime(2026, 11, 1, 10);

  Future<Nino> primeroAfuera(RepositorioPersistente repo) async =>
      (await repo.ninos().first).firstWhere((n) => !n.presente);

  Future<Registro> entrar(RepositorioPersistente repo, Nino nino, String manilla) =>
      repo.registrarMovimiento(
        nino: nino,
        tipo: TipoMovimiento.entrada,
        numeroManilla: manilla,
        servicio: 'Domingo mañana',
        nombreAcudiente: 'Acudiente',
        idVoluntario: 'v',
        nombreVoluntario: 'Voluntario',
      );

  test('lo registrado sigue ahí al volver a abrir', () async {
    final almacen = AlmacenEnMemoria();
    final primero = await RepositorioPersistente.abrir(almacen: almacen, reloj: () => hoy);
    final nino = await primeroAfuera(primero);
    final registro = await entrar(primero, nino, '500');

    final segundo = await RepositorioPersistente.abrir(almacen: almacen, reloj: () => hoy);
    final registros = await segundo.registrosDelDia(hoy).first;
    expect(registros.map((r) => r.id), contains(registro.id));
    final recargado = (await segundo.ninos().first).firstWhere((n) => n.id == nino.id);
    expect(recargado.presente, isTrue);
  });

  test('los ids nuevos no chocan con los guardados', () async {
    final almacen = AlmacenEnMemoria();
    final primero = await RepositorioPersistente.abrir(almacen: almacen, reloj: () => hoy);
    final a = await entrar(primero, await primeroAfuera(primero), '500');
    final segundo = await RepositorioPersistente.abrir(almacen: almacen, reloj: () => hoy);
    final b = await entrar(segundo, await primeroAfuera(segundo), '501');
    expect(b.id, isNot(a.id));
  });

  test('un movimiento rechazado no se guarda', () async {
    final almacen = AlmacenEnMemoria();
    final repo = await RepositorioPersistente.abrir(almacen: almacen, reloj: () => hoy);
    final antes = almacen.datos[RepositorioPersistente.clave];
    // La manilla 1 ya está en uso en los datos de demostración del día.
    await expectLater(entrar(repo, await primeroAfuera(repo), '1'), throwsA(isA<RegistroRechazado>()));
    expect(almacen.datos[RepositorioPersistente.clave], antes);
  });

  test('lo guardado de otro día se descarta (cierre de jornada)', () async {
    final almacen = AlmacenEnMemoria();
    final ayer = await RepositorioPersistente.abrir(almacen: almacen, reloj: () => hoy);
    await entrar(ayer, await primeroAfuera(ayer), '500');

    final manana = hoy.add(const Duration(days: 1));
    final repo = await RepositorioPersistente.abrir(almacen: almacen, reloj: () => manana);
    final guardado = jsonDecode(almacen.datos[RepositorioPersistente.clave]!) as Map<String, dynamic>;
    expect(leerFecha(guardado['dia']), soloDia(manana));
    expect((await repo.registrosDelDia(hoy).first).where((r) => r.numeroManilla == '500'), isEmpty);
  });

  test('datos dañados no rompen la app', () async {
    final almacen = AlmacenEnMemoria()..datos[RepositorioPersistente.clave] = '{no es json';
    final repo = await RepositorioPersistente.abrir(almacen: almacen, reloj: () => hoy);
    expect(await repo.ninos().first, isNotEmpty);
  });

  test('reiniciar vuelve a los datos de demostración', () async {
    final almacen = AlmacenEnMemoria();
    final repo = await RepositorioPersistente.abrir(almacen: almacen, reloj: () => hoy);
    final inicial = (await repo.registrosDelDia(hoy).first).length;
    await entrar(repo, await primeroAfuera(repo), '500');
    await repo.reiniciar();
    expect((await repo.registrosDelDia(hoy).first).length, inicial);
  });
}
