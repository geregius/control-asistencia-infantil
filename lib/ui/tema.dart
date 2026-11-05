// =============================================================================
// tema.dart — Colores y estilo visual de toda la app (Material 3).
// =============================================================================

import 'package:flutter/material.dart';

/// Paleta de la app. El constructor privado `Colores._()` impide crear
/// objetos de esta clase: solo se usan sus constantes (`Colores.primario`).
class Colores {
  Colores._();

  static const primario = Color(0xFF2E6B5E); // verde azulado
  static const primarioClaro = Color(0xFF4F9A88);
  static const acento = Color(0xFFF2A541); // ámbar
  static const alerta = Color(0xFFD64545); // rojo para alertas y errores
  static const fondo = Color(0xFFF6F7F5);
  static const texto = Color(0xFF1C2421);

  /// Un color por grupo de edad, en el mismo orden de `gruposEdad`.
  static const grupos = [
    Color(0xFF7BB661),
    Color(0xFF4F9A88),
    Color(0xFF3C7DC4),
    Color(0xFF8A5CC2),
    Color(0xFFE0773C),
  ];
}

/// El tema de Material 3: Flutter deriva la mayoría de los colores a partir
/// del color semilla y aquí se ajustan la barra superior, las tarjetas y los
/// campos de texto.
ThemeData temaApp() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Colores.primario,
    primary: Colores.primario,
    secondary: Colores.acento,
    error: Colores.alerta,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Colores.fondo,
    // Barra superior verde con texto blanco.
    appBarTheme: const AppBarTheme(
      backgroundColor: Colores.primario,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    // Tarjetas planas con un borde suave y esquinas redondeadas.
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
    ),
    // Campos de texto con fondo blanco y borde redondeado.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
