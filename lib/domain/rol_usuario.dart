// =============================================================================
// rol_usuario.dart — Roles de quienes usan la app y qué puede hacer cada uno.
// =============================================================================

/// Roles de quienes usan la app.
///
/// Cada permiso es un getter con nombre propio, aunque hoy varios
/// coincidan: si un permiso delega en otro "porque son iguales", ampliar
/// uno amplía el otro sin querer. En la app real cada getter tiene su
/// regla equivalente en las reglas de seguridad de la base de datos, que
/// son las que de verdad bloquean; la interfaz solo oculta lo que no toca.
///
/// Es un "enum mejorado" de Dart: cada valor tiene campos propios
/// (`valorGuardado` y `etiqueta`) que se pasan en el constructor.
enum RolUsuario {
  administrador('administrador', 'Administrador'),
  coordinador('coordinador', 'Coordinador'),
  supervisor('supervisor', 'Supervisor'),
  maestroPrincipal('maestro_principal', 'Maestro principal'),
  maestroAuxiliar('maestro_auxiliar', 'Maestro auxiliar'),
  acudiente('acudiente', 'Acudiente'),
  pendiente('pendiente', 'Pendiente de aprobación'),
  desconocido('desconocido', 'Sin rol asignado');

  /// Constructor del enum: guarda los dos textos de cada rol.
  const RolUsuario(this.valorGuardado, this.etiqueta);

  /// Clave estable con que se guarda. No cambia aunque cambie la etiqueta.
  final String valorGuardado;

  /// Texto que ve el usuario.
  final String etiqueta;

  /// Del texto guardado al rol. Limpia espacios y mayúsculas, y busca el rol
  /// con ese valor; si no existe, devuelve `desconocido` en vez de fallar.
  static RolUsuario fromString(String? valor) {
    final limpio = valor?.trim().toLowerCase();
    return RolUsuario.values.firstWhere(
      (rol) => rol.valorGuardado == limpio,
      orElse: () => RolUsuario.desconocido,
    );
  }

  /// Roles que un administrador puede asignar (sin los estados transitorios).
  /// Filtra la lista de todos los roles con `where`.
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

  /// Ver el Dashboard con las estadísticas.
  bool get puedeVerDashboard => esLiderazgo;

  /// Activar el modo emergencia (evacuación).
  bool get puedeActivarModoEmergencia => esLiderazgo;

  /// Cambiar roles, activar o eliminar voluntarios.
  bool get puedeGestionarVoluntarios => esLiderazgo;

  /// Armar la programación de turnos: más acotado que [puedeGestionarVoluntarios]
  /// (el supervisor no puede).
  bool get puedeGestionarProgramacion => this == administrador || this == coordinador;
}
