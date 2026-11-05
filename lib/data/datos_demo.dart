// =============================================================================
// datos_demo.dart — Genera los datos ficticios de la demo.
//
// Arma 24 niños y sus movimientos alrededor de la fecha de hoy, para que la
// demo siempre tenga cumpleaños de la semana, niños ausentes y movimientos
// del día. Las fórmulas con `%` (residuo de la división) solo sirven para
// repartir los casos entre los niños de forma variada pero repetible.
// =============================================================================

import '../domain/dominio.dart';

/// Datos 100 % ficticios para la demo y los pantallazos. Ningún nombre
/// corresponde a una persona real.
///
/// Cada elemento es un record `(nombre, género)`.
const _nombres = [
  ('Valentina', 'Femenino'), ('Samuel', 'Masculino'), ('Isabella', 'Femenino'),
  ('Matías', 'Masculino'), ('Salomé', 'Femenino'), ('Emiliano', 'Masculino'),
  ('Antonella', 'Femenino'), ('Jerónimo', 'Masculino'), ('Mariana', 'Femenino'),
  ('Tomás', 'Masculino'), ('Luciana', 'Femenino'), ('Martín', 'Masculino'),
  ('Gabriela', 'Femenino'), ('Santiago', 'Masculino'), ('Sara', 'Femenino'),
  ('Joaquín', 'Masculino'), ('Violeta', 'Femenino'), ('Emmanuel', 'Masculino'),
  ('Abril', 'Femenino'), ('Benjamín', 'Masculino'), ('Julieta', 'Femenino'),
  ('Simón', 'Masculino'), ('Amelia', 'Femenino'), ('Lorenzo', 'Masculino'),
];

const _apellidos = [
  'Ríos', 'Castaño', 'Morales', 'Quintero', 'Arango', 'Restrepo', 'Londoño', 'Ospina',
  'Giraldo', 'Valencia', 'Cardona', 'Montoya',
];

const _acudientes = [
  'Laura Ríos', 'Andrés Castaño', 'Paula Morales', 'Felipe Quintero', 'Diana Arango',
  'Carlos Restrepo', 'Natalia Londoño', 'Jorge Ospina',
];

const _voluntarios = ['Camila Herrera', 'Daniel Suárez', 'Manuela Pineda'];

/// Un juego de datos: la lista de niños y la de movimientos.
class DatosDemo {
  final List<Nino> ninos;
  final List<Registro> registros;

  const DatosDemo(this.ninos, this.registros);

  /// Arma los datos relativos a [hoy]: algunos niños cumplen esta semana,
  /// otros dejaron de venir, y hay entradas y salidas en el día y en las
  /// semanas anteriores para que el Dashboard tenga qué mostrar.
  factory DatosDemo.generar(DateTime hoy) {
    final dia = soloDia(hoy);

    // --- 1. Los niños ---------------------------------------------------------
    final ninos = <Nino>[];
    for (var i = 0; i < _nombres.length; i++) {
      // Desestructuración: saca los dos valores del record en dos variables.
      final (nombre, genero) = _nombres[i];
      final edad = 2 + i % 9; // 2 a 10 años
      // Cada cuarto niño cumple años en los últimos días; los demás, en una
      // fecha repartida a lo largo del año.
      final nacimiento = i % 4 == 0
          ? DateTime(dia.year - edad, dia.month, dia.day).subtract(Duration(days: i % 7))
          : DateTime(dia.year - edad, 1 + (i * 5) % 12, 1 + (i * 7) % 27);
      // Tres niños no vienen hace más de un mes (para el reporte de ausentes).
      final ausente = i % 8 == 3;
      ninos.add(Nino(
        id: 'n${i + 1}',
        tipoIdentificacion: edad >= 7 ? 'Tarjeta de Identidad' : 'Registro Civil',
        // Cada quinto niño no tiene documento.
        identificacionMenor: i % 5 == 0 ? '' : '10${(i * 7919) % 100000000}',
        nombres: nombre,
        apellidos: '${_apellidos[i % _apellidos.length]} ${_apellidos[(i + 5) % _apellidos.length]}',
        fechaNacimiento: nacimiento,
        genero: genero,
        estadoRegistro: 'Activo',
        // Algunos con alerta médica, para mostrar la etiqueta roja.
        alertaMedica: i % 6 == 2,
        condicionMedica: i % 6 == 2 ? 'Alergia alimentaria (ficticia)' : '',
        autorizoFoto: i % 3 != 0,
        // Un niño con personas que no pueden recogerlo.
        tieneNoAutorizados: i == 9,
        totalEntradas: ausente ? 6 : 20 + i,
        ultimaAsistencia: ausente ? dia.subtract(Duration(days: 35 + i)) : dia.subtract(const Duration(days: 7)),
      ));
    }

    // --- 2. Los movimientos ---------------------------------------------------
    final registros = <Registro>[];
    var manilla = 100; // las semanas anteriores usan manillas desde 100
    final servicioHoy = servicioSugerido(hoy) ?? 'Domingo mañana';

    // Función local que agrega un movimiento a la lista.
    void movimiento(Nino n, DateTime fecha, TipoMovimiento tipo, String servicio, String numero) {
      registros.add(Registro(
        id: 'demo-${registros.length + 1}',
        idNino: n.id,
        nombreNino: n.nombreCompleto,
        tipo: tipo,
        fecha: fecha,
        numeroManilla: numero,
        // Reparte los voluntarios y acudientes entre los movimientos.
        idVoluntario: 'v${registros.length % _voluntarios.length}',
        nombreVoluntario: _voluntarios[registros.length % _voluntarios.length],
        nombreAcudiente: _acudientes[int.parse(n.id.substring(1)) % _acudientes.length],
        servicio: servicio,
        grupoEdad: n.grupo(hoy: fecha) ?? '',
      ));
    }

    // Semanas anteriores: entradas y salidas en varias jornadas (para los
    // promedios del Dashboard). Cada tupla es (jornada, días atrás, cuántos).
    for (var semana = 1; semana <= 6; semana++) {
      for (final (servicio, diasAtras, cuantos) in [
        ('Domingo mañana', 7 * semana, 14 + semana % 3),
        ('Domingo mediodía', 7 * semana, 9 + semana % 2),
        ('Miércoles', 7 * semana - 3, 7 + semana % 4),
      ]) {
        final fecha = dia.subtract(Duration(days: diasAtras)).add(const Duration(hours: 9));
        // Solo niños que vienen con regularidad (no los ausentes).
        for (final n in ninos.where((n) => n.totalEntradas > 6).take(cuantos)) {
          final numero = '${manilla++}';
          movimiento(n, fecha, TipoMovimiento.entrada, servicio, numero);
          movimiento(n, fecha.add(const Duration(hours: 2)), TipoMovimiento.salida, servicio, numero);
        }
      }
    }

    // Hoy: 12 niños entraron (manillas 1 a 12) y 3 ya salieron.
    final entradaHoy = dia.add(const Duration(hours: 8, minutes: 40));
    final presentesHoy = <String>{}; // un Set: no admite repetidos
    final deHoy = ninos.where((n) => n.totalEntradas > 6).take(12).toList();
    for (var i = 0; i < deHoy.length; i++) {
      final numero = '${i + 1}';
      movimiento(deHoy[i], entradaHoy.add(Duration(minutes: i * 3)), TipoMovimiento.entrada, servicioHoy, numero);
      if (i % 4 == 1) {
        movimiento(deHoy[i], entradaHoy.add(const Duration(hours: 1)), TipoMovimiento.salida, servicioHoy, numero);
      } else {
        presentesHoy.add(deHoy[i].id);
      }
    }

    // --- 3. El estado de cada niño debe coincidir con sus movimientos ---------
    // Se marca `presente` a los que siguen adentro hoy (una prueba verifica
    // que esto coincide con calcularPresentes).
    final ninosConEstado = [
      for (final n in ninos)
        Nino.fromMap(n.id, {
          ...n.toMap(),
          'presente': presentesHoy.contains(n.id),
          if (deHoy.contains(n)) 'ultimaAsistencia': escribirFecha(entradaHoy),
        }),
    ];
    return DatosDemo(ninosConEstado, registros);
  }
}
