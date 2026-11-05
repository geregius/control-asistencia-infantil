// =============================================================================
// widget_test.dart — Pruebas de la interfaz y de los datos de demostración.
//
// `testWidgets` dibuja la app en memoria (sin navegador). `tester.tap` toca
// un botón, `enterText` escribe y `pumpAndSettle` espera a que terminen las
// animaciones. `find.text(...)` busca un texto en pantalla.
// =============================================================================

import 'package:asistencia_infantil/data/datos_demo.dart';
import 'package:asistencia_infantil/data/repositorio_en_memoria.dart';
import 'package:asistencia_infantil/domain/dominio.dart';
import 'package:asistencia_infantil/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los datos de demostración son coherentes', () {
    final hoy = DateTime(2026, 11, 1, 10);
    final datos = DatosDemo.generar(hoy);
    final presentesSegunRegistros = calcularPresentes(
      datos.registros.where((r) => soloDia(r.fecha) == soloDia(hoy)),
    ).map((r) => r.idNino).toSet();
    final presentesSegunNinos = datos.ninos.where((n) => n.presente).map((n) => n.id).toSet();
    expect(presentesSegunNinos, presentesSegunRegistros);
    expect(datos.ninos.every((n) => n.grupo(hoy: hoy) != null), isTrue);
  });

  testWidgets('la app abre y navega entre secciones', (tester) async {
    final datos = DatosDemo.generar(DateTime.now());
    final repo = RepositorioEnMemoria(ninos: datos.ninos, registros: datos.registros);
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(AsistenciaApp(repositorio: repo));
    await tester.pumpAndSettle();

    expect(find.text('Ingreso y salida'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'valentina');
    await tester.pumpAndSettle();
    expect(find.textContaining('Valentina'), findsOneWidget);

    await tester.tap(find.text('Presentes').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('niños presentes'), findsOneWidget);

    await tester.tap(find.text('Dashboard').last);
    await tester.pumpAndSettle();
    expect(find.text('Entradas hoy'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('avisa si la manilla ya está en uso', (tester) async {
    final hoy = DateTime.now();
    final presente = nino('a', presente: true);
    final libre = nino('b');
    final repo = RepositorioEnMemoria(ninos: [presente, libre], registros: [
      Registro(
        id: 'r1',
        idNino: 'a',
        nombreNino: presente.nombreCompleto,
        tipo: TipoMovimiento.entrada,
        fecha: hoy,
        numeroManilla: '7',
        idVoluntario: 'v',
        nombreVoluntario: 'V',
        nombreAcudiente: 'A',
        servicio: 'Miércoles',
      ),
    ]);
    await tester.pumpWidget(AsistenciaApp(repositorio: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrada').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Número de manilla'), '7');
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(find.text('La manilla 7 ya está en uso hoy.'), findsOneWidget);
  });
}

Nino nino(String id, {bool presente = false}) => Nino(
      id: id,
      tipoIdentificacion: 'Registro Civil',
      identificacionMenor: '',
      nombres: 'Niño $id',
      apellidos: 'Prueba',
      fechaNacimiento: DateTime(DateTime.now().year - 5, 1, 1),
      genero: 'Masculino',
      estadoRegistro: 'Activo',
      alertaMedica: false,
      condicionMedica: '',
      autorizoFoto: true,
      presente: presente,
    );
