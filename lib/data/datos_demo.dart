import '../domain/dominio.dart';

/// Datos 100 % ficticios para la demo y los pantallazos. Ningún nombre
/// corresponde a una persona real.
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

class DatosDemo {
  final List<Nino> ninos;
  final List<Registro> registros;

  const DatosDemo(this.ninos, this.registros);

  /// Arma los datos relativos a [hoy]: algunos niños cumplen esta semana,
  /// otros dejaron de venir, y hay entradas y salidas en el día y en las
  /// semanas anteriores para que el Dashboard tenga qué mostrar.
  factory DatosDemo.generar(DateTime hoy) {
    final dia = soloDia(hoy);
    final ninos = <Nino>[];
    for (var i = 0; i < _nombres.length; i++) {
      final (nombre, genero) = _nombres[i];
      final edad = 2 + i % 9; // 2 a 10 años
      // Cada cuarto niño cumple años en los últimos días.
      final nacimiento = i % 4 == 0
          ? DateTime(dia.year - edad, dia.month, dia.day).subtract(Duration(days: i % 7))
          : DateTime(dia.year - edad, 1 + (i * 5) % 12, 1 + (i * 7) % 27);
      // Tres niños no vienen hace más de un mes.
      final ausente = i % 8 == 3;
      ninos.add(Nino(
        id: 'n${i + 1}',
        tipoIdentificacion: edad >= 7 ? 'Tarjeta de Identidad' : 'Registro Civil',
        identificacionMenor: i % 5 == 0 ? '' : '10${(i * 7919) % 100000000}',
        nombres: nombre,
        apellidos: '${_apellidos[i % _apellidos.length]} ${_apellidos[(i + 5) % _apellidos.length]}',
        fechaNacimiento: nacimiento,
        genero: genero,
        estadoRegistro: 'Activo',
        alertaMedica: i % 6 == 2,
        condicionMedica: i % 6 == 2 ? 'Alergia alimentaria (ficticia)' : '',
        autorizoFoto: i % 3 != 0,
        tieneNoAutorizados: i == 9,
        totalEntradas: ausente ? 6 : 20 + i,
        ultimaAsistencia: ausente ? dia.subtract(Duration(days: 35 + i)) : dia.subtract(const Duration(days: 7)),
      ));
    }

    final registros = <Registro>[];
    var manilla = 100;
    final servicioHoy = servicioSugerido(hoy) ?? 'Domingo mañana';

    void movimiento(Nino n, DateTime fecha, TipoMovimiento tipo, String servicio, String numero) {
      registros.add(Registro(
        id: 'demo-${registros.length + 1}',
        idNino: n.id,
        nombreNino: n.nombreCompleto,
        tipo: tipo,
        fecha: fecha,
        numeroManilla: numero,
        idVoluntario: 'v${registros.length % _voluntarios.length}',
        nombreVoluntario: _voluntarios[registros.length % _voluntarios.length],
        nombreAcudiente: _acudientes[int.parse(n.id.substring(1)) % _acudientes.length],
        servicio: servicio,
        grupoEdad: n.grupo(hoy: fecha) ?? '',
      ));
    }

    // Semanas anteriores: entradas y salidas en varias jornadas.
    for (var semana = 1; semana <= 6; semana++) {
      for (final (servicio, diasAtras, cuantos) in [
        ('Domingo mañana', 7 * semana, 14 + semana % 3),
        ('Domingo mediodía', 7 * semana, 9 + semana % 2),
        ('Miércoles', 7 * semana - 3, 7 + semana % 4),
      ]) {
        final fecha = dia.subtract(Duration(days: diasAtras)).add(const Duration(hours: 9));
        for (final n in ninos.where((n) => n.totalEntradas > 6).take(cuantos)) {
          final numero = '${manilla++}';
          movimiento(n, fecha, TipoMovimiento.entrada, servicio, numero);
          movimiento(n, fecha.add(const Duration(hours: 2)), TipoMovimiento.salida, servicio, numero);
        }
      }
    }

    // Hoy: 12 niños entraron y 3 ya salieron.
    final entradaHoy = dia.add(const Duration(hours: 8, minutes: 40));
    final presentesHoy = <String>{};
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
