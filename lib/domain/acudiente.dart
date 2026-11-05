// =============================================================================
// acudiente.dart — El adulto que entrega o recoge a un niño.
//
// Contiene: el estado de autorización (enum), la clase Acudiente y la clase
// NinoAcudiente, que une niños y acudientes (relación muchos a muchos).
// =============================================================================

/// Tipos de documento de un adulto.
const tiposDocumentoAcudiente = [
  'Cédula de Ciudadanía',
  'Cédula de Extranjería',
  'Pasaporte',
];

/// Estado de un acudiente. Solo un administrador lo cambia a restringido.
///
/// Es un enum (un tipo con valores fijos) y no un texto suelto: así el
/// compilador no deja escribir un estado que no existe, como "Autorisado".
enum EstadoAutorizacion {
  autorizado,
  restringido;

  /// Convierte el texto guardado en el valor del enum. Cualquier cosa que
  /// no sea "Restringido" se toma como autorizado.
  static EstadoAutorizacion fromString(String? valor) =>
      valor == 'Restringido' ? restringido : autorizado;

  /// Texto que se guarda y se muestra.
  String get etiqueta => this == autorizado ? 'Autorizado' : 'Restringido';
}

/// Adulto que puede entregar y recoger niños.
class Acudiente {
  final String id;
  final String tipoDocumento;
  final String numeroDocumento;
  final String nombres;
  final String apellidos;
  final String telefonoCelular;
  final String correoElectronico;
  final String fotoSeguridadUrl;
  final EstadoAutorizacion estadoAutorizacion;
  final String observacionesRestriccion;

  const Acudiente({
    required this.id,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.nombres,
    required this.apellidos,
    required this.telefonoCelular,
    required this.correoElectronico,
    this.fotoSeguridadUrl = '',
    this.estadoAutorizacion = EstadoAutorizacion.autorizado,
    this.observacionesRestriccion = '',
  });

  String get nombreCompleto => '$nombres $apellidos';

  /// Si puede recoger niños (no está restringido).
  bool get puedeRecoger => estadoAutorizacion == EstadoAutorizacion.autorizado;

  /// Sin correo no puede recuperar su cuenta: se avisa en la ficha y en el
  /// ingreso hasta que alguien lo corrija. `trim()` quita espacios, para que
  /// un correo de solo espacios también cuente como vacío.
  bool get correoPendienteDeCorregir => correoElectronico.trim().isEmpty;

  /// Convierte el objeto en un Map para guardarlo.
  Map<String, dynamic> toMap() => {
        'tipoDocumento': tipoDocumento,
        'numeroDocumento': numeroDocumento,
        'nombres': nombres,
        'apellidos': apellidos,
        'telefonoCelular': telefonoCelular,
        'correoElectronico': correoElectronico,
        'fotoSeguridadUrl': fotoSeguridadUrl,
        // El enum se guarda como texto legible.
        'estadoAutorizacion': estadoAutorizacion.etiqueta,
        'observacionesRestriccion': observacionesRestriccion,
      };

  /// Crea un Acudiente a partir de lo guardado; los datos faltantes toman
  /// un valor por defecto en vez de romper la app.
  factory Acudiente.fromMap(String id, Map<String, dynamic> data) => Acudiente(
        id: id,
        tipoDocumento: data['tipoDocumento'] as String? ?? '',
        numeroDocumento: data['numeroDocumento'] as String? ?? '',
        nombres: data['nombres'] as String? ?? '',
        apellidos: data['apellidos'] as String? ?? '',
        telefonoCelular: data['telefonoCelular'] as String? ?? '',
        correoElectronico: data['correoElectronico'] as String? ?? '',
        fotoSeguridadUrl: data['fotoSeguridadUrl'] as String? ?? '',
        estadoAutorizacion:
            EstadoAutorizacion.fromString(data['estadoAutorizacion'] as String?),
        observacionesRestriccion: data['observacionesRestriccion'] as String? ?? '',
      );
}

/// Vínculo entre un niño y un acudiente (relación muchos a muchos).
///
/// Un niño tiene varios acudientes (mamá, papá, abuela) y un acudiente
/// puede tener varios niños (hermanos). Esta clase es la "tabla intermedia":
/// cada objeto dice "este acudiente está ligado a este niño, con este
/// parentesco".
class NinoAcudiente {
  final String id;
  final String idNino;
  final String idAcudiente;
  final String parentesco;
  final bool esRepresentanteLegal;

  const NinoAcudiente({
    required this.id,
    required this.idNino,
    required this.idAcudiente,
    required this.parentesco,
    required this.esRepresentanteLegal,
  });

  Map<String, dynamic> toMap() => {
        'idNino': idNino,
        'idAcudiente': idAcudiente,
        'parentesco': parentesco,
        'esRepresentanteLegal': esRepresentanteLegal,
      };

  factory NinoAcudiente.fromMap(String id, Map<String, dynamic> data) => NinoAcudiente(
        id: id,
        idNino: data['idNino'] as String? ?? '',
        idAcudiente: data['idAcudiente'] as String? ?? '',
        parentesco: data['parentesco'] as String? ?? '',
        esRepresentanteLegal: data['esRepresentanteLegal'] as bool? ?? false,
      );
}
