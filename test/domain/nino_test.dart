import 'package:asistencia_infantil/domain/dominio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calcularEdad', () {
    test('resta un año si todavía no ha cumplido', () {
      final hoy = DateTime(2026, 3, 9);
      expect(calcularEdad(DateTime(2020, 3, 10), hoy: hoy), 5);
      expect(calcularEdad(DateTime(2020, 3, 9), hoy: hoy), 6);
    });
  });

  group('grupoParaEdad', () {
    test('asigna cada edad a su grupo', () {
      expect(grupoParaEdad(2), 'Semillas');
      expect(grupoParaEdad(4), 'Brotes');
      expect(grupoParaEdad(5), 'Exploradores');
      expect(grupoParaEdad(8), 'Aventureros');
      expect(grupoParaEdad(10), 'Líderes');
    });

    test('fuera del rango no hay grupo', () {
      expect(grupoParaEdad(1), isNull);
      expect(grupoParaEdad(11), isNull);
    });

    test('cada grupo tiene su rango de edad', () {
      expect(rangoEdadPorGrupo.keys, gruposEdad);
    });
  });

  group('cumpleaños', () {
    final hoy = DateTime(2026, 11, 3);

    test('diasDesdeCumpleanos cuenta hasta 6 días atrás', () {
      expect(diasDesdeCumpleanos(DateTime(2019, 11, 3), hoy: hoy), 0);
      expect(diasDesdeCumpleanos(DateTime(2019, 10, 28), hoy: hoy), 6);
      expect(diasDesdeCumpleanos(DateTime(2019, 10, 27), hoy: hoy), isNull);
    });

    test('diasHastaProximoCumpleanos pasa al año siguiente si ya cumplió', () {
      expect(diasHastaProximoCumpleanos(DateTime(2019, 11, 5), hoy: hoy), 2);
      expect(diasHastaProximoCumpleanos(DateTime(2019, 11, 2), hoy: hoy), 364);
    });

    test('mesDiaUltimaSemana usa el mismo criterio', () {
      final dias = mesDiaUltimaSemana(hoy: hoy);
      expect(dias, hasLength(7));
      expect(dias.first, '11-03');
      expect(dias.last, '10-28');
    });
  });

  test('generarLlaveInterna usa la fecha y la primera palabra', () {
    final llave = generarLlaveInterna(
      fechaNacimiento: DateTime(2021, 4, 7),
      nombres: ' maría josé ',
      apellidos: 'pérez gómez',
    );
    expect(llave, '20210407-MARÍA-PÉREZ');
  });

  test('la búsqueda ignora mayúsculas y tildes', () {
    final busqueda = NinoBusqueda(
      id: 'n1',
      nombres: 'José',
      apellidos: 'Muñoz',
      fechaNacimiento: DateTime(2020),
    );
    expect(busqueda.coincideBusqueda('jose munoz'), isTrue);
    expect(busqueda.coincideBusqueda('JOSÉ'), isTrue);
    expect(busqueda.coincideBusqueda('pedro'), isFalse);
  });

  group('Nino.toMap / fromMap', () {
    test('ida y vuelta conserva los datos', () {
      final original = Nino(
        id: 'n1',
        tipoIdentificacion: 'Registro Civil',
        identificacionMenor: '123',
        nombres: 'Ana',
        apellidos: 'Ruiz',
        fechaNacimiento: DateTime(2019, 5, 20),
        genero: 'Femenino',
        estadoRegistro: 'Activo',
        alertaMedica: true,
        condicionMedica: 'Alergia al maní',
        autorizoFoto: false,
        totalEntradas: 12,
        ultimaAsistencia: DateTime(2026, 10, 26, 9),
      );
      final copia = Nino.fromMap('n1', original.toMap());
      expect(copia.nombreCompleto, 'Ana Ruiz');
      expect(copia.fechaNacimiento, original.fechaNacimiento);
      expect(copia.condicionMedica, 'Alergia al maní');
      expect(copia.totalEntradas, 12);
      expect(copia.ultimaAsistencia, original.ultimaAsistencia);
      expect(original.toMap()['mesDiaNacimiento'], '05-20');
    });

    test('campos ausentes toman valores por defecto', () {
      final vacio = Nino.fromMap('x', {});
      expect(vacio.nombres, '');
      expect(vacio.presente, isFalse);
      expect(vacio.ultimaAsistencia, isNull);
    });
  });
}
