import 'package:asistencia_infantil/domain/dominio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromString ignora mayúsculas y espacios', () {
    expect(RolUsuario.fromString('  Administrador '), RolUsuario.administrador);
    expect(RolUsuario.fromString('maestro_principal'), RolUsuario.maestroPrincipal);
  });

  test('valores desconocidos o nulos caen en desconocido', () {
    expect(RolUsuario.fromString(null), RolUsuario.desconocido);
    expect(RolUsuario.fromString('lo-que-sea'), RolUsuario.desconocido);
  });

  test('los estados transitorios no se pueden asignar', () {
    expect(RolUsuario.asignables, isNot(contains(RolUsuario.pendiente)));
    expect(RolUsuario.asignables, isNot(contains(RolUsuario.desconocido)));
  });

  test('el maestro principal ve niños pero no edita acudientes', () {
    const rol = RolUsuario.maestroPrincipal;
    expect(rol.puedeVerAcudientesYNinos, isTrue);
    expect(rol.puedeEditarAcudientes, isFalse);
    expect(rol.esLiderazgo, isFalse);
  });

  test('la programación es más acotada que la gestión de voluntarios', () {
    expect(RolUsuario.supervisor.puedeGestionarVoluntarios, isTrue);
    expect(RolUsuario.supervisor.puedeGestionarProgramacion, isFalse);
  });

  test('un acudiente no es voluntario', () {
    expect(RolUsuario.acudiente.esVoluntario, isFalse);
    expect(RolUsuario.maestroAuxiliar.esVoluntario, isTrue);
  });
}
