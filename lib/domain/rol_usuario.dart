/// Roles de quienes usan la app.
///
/// Cada permiso es un getter con nombre propio, aunque hoy varios
/// coincidan: si un permiso delega en otro "porque son iguales", ampliar
/// uno amplía el otro sin querer. En la app real cada getter tiene su
/// regla equivalente en las reglas de seguridad de la base de datos, que
/// son las que de verdad bloquean; la interfaz solo oculta lo que no toca.
enum RolUsuario {
  administrador('administrador', 'Administrador'),
  coordinador('coordinador', 'Coordinador'),
  supervisor('supervisor', 'Supervisor'),
  maestroPrincipal('maestro_principal', 'Maestro principal'),
  maestroAuxiliar('maestro_auxiliar', 'Maestro auxiliar'),
  acudiente('acudiente', 'Acudiente'),
  pendiente('pendiente', 'Pendiente de aprobación'),
  desconocido('desconocido', 'Sin rol asignado');

  const RolUsuario(this.valorGuardado, this.etiqueta);

  /// Clave estable con que se guarda. No cambia aunque cambie la etiqueta.
  final String valorGuardado;
  final String etiqueta;

  static RolUsuario fromString(String? valor) {
    final limpio = valor?.trim().toLowerCase();
    return RolUsuario.values.firstWhere(
      (rol) => rol.valorGuardado == limpio,
      orElse: () => RolUsuario.desconocido,
    );
  }

  /// Roles que un administrador puede asignar (sin los estados transitorios).
  static List<RolUsuario> get asignables => RolUsuario.values
      .where((rol) => rol != RolUsuario.pendiente && rol != RolUsuario.desconocido)
      .toList();

  /// Voluntarios que operan el ingreso y la salida de niños.
  bool get esVoluntario =>
      this != acudiente && this != pendiente && this != desconocido;

  /// Liderazgo: ve información sensible y administrativa.
  bool get esLiderazgo =>
      this == administrador || this == coordinador || this == supervisor;

  /// Ver el panel de acudientes y niños: liderazgo más maestros principales.
  bool get puedeVerAcudientesYNinos => esLiderazgo || this == maestroPrincipal;

  /// Editar la ficha de un acudiente: solo liderazgo.
  bool get puedeEditarAcudientes => esLiderazgo;

  bool get puedeVerDashboard => esLiderazgo;

  bool get puedeActivarModoEmergencia => esLiderazgo;

  /// Cambiar roles, activar o eliminar voluntarios.
  bool get puedeGestionarVoluntarios => esLiderazgo;

  /// Armar la programación de turnos: más acotado que [puedeGestionarVoluntarios].
  bool get puedeGestionarProgramacion => this == administrador || this == coordinador;
}
