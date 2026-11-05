import 'package:asistencia_infantil/domain/dominio.dart';

/// Fábricas para armar datos de prueba con lo mínimo.
Nino nino(
  String id, {
  DateTime? nacimiento,
  String estado = 'Activo',
  DateTime? ultimaAsistencia,
  bool presente = false,
}) =>
    Nino(
      id: id,
      tipoIdentificacion: 'Registro Civil',
      identificacionMenor: '',
      nombres: 'Niño $id',
      apellidos: 'Prueba',
      fechaNacimiento: nacimiento ?? DateTime(2020, 1, 1),
      genero: 'Masculino',
      estadoRegistro: estado,
      alertaMedica: false,
      condicionMedica: '',
      autorizoFoto: true,
      presente: presente,
      ultimaAsistencia: ultimaAsistencia,
    );

Registro registro({
  String idNino = '',
  String manilla = '1',
  TipoMovimiento tipo = TipoMovimiento.entrada,
  required DateTime fecha,
  String servicio = 'Domingo mañana',
  String grupo = 'Brotes',
}) =>
    Registro(
      id: '$idNino-$manilla-${fecha.millisecondsSinceEpoch}-${tipo.name}',
      idNino: idNino,
      nombreNino: idNino.isEmpty ? 'Visitante $manilla' : 'Niño $idNino',
      tipo: tipo,
      fecha: fecha,
      numeroManilla: manilla,
      idVoluntario: 'v1',
      nombreVoluntario: 'Voluntario',
      nombreAcudiente: 'Acudiente',
      servicio: servicio,
      grupoEdad: grupo,
    );
