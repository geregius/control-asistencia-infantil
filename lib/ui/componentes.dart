import 'package:flutter/material.dart';

import '../domain/dominio.dart';
import 'tema.dart';

/// Círculo con las iniciales del niño, del color de su grupo.
class AvatarNino extends StatelessWidget {
  const AvatarNino({super.key, required this.nino, this.radio = 22});

  final Nino nino;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final indice = gruposEdad.indexOf(nino.grupo() ?? '');
    final color = indice >= 0 ? Colores.grupos[indice] : Colors.grey;
    return CircleAvatar(
      radius: radio,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Text(
        '${nino.nombres[0]}${nino.apellidos[0]}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Etiqueta pequeña de color (grupo, alerta médica, visitante...).
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, this.color = Colores.primario, this.icono});

  final String texto;
  final Color color;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[Icon(icono, size: 13, color: color), const SizedBox(width: 4)],
          Text(texto, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Tarjeta con un número grande y su descripción.
class TarjetaDato extends StatelessWidget {
  const TarjetaDato({
    super.key,
    required this.valor,
    required this.titulo,
    required this.icono,
    this.color = Colores.primario,
  });

  final String valor;
  final String titulo;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
                  Text(titulo, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfica de barras horizontales sencilla, sin paquetes externos.
class BarrasHorizontales extends StatelessWidget {
  const BarrasHorizontales({super.key, required this.datos, this.colores});

  final Map<String, num> datos;
  final List<Color>? colores;

  @override
  Widget build(BuildContext context) {
    final maximo = datos.values.fold<num>(0, (a, b) => b > a ? b : a);
    final entradas = datos.entries.toList();
    return Column(
      children: [
        for (var i = 0; i < entradas.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 130, child: Text(entradas[i].key, style: const TextStyle(fontSize: 13))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: maximo == 0 ? 0 : entradas[i].value / maximo,
                      minHeight: 14,
                      backgroundColor: Colors.black.withValues(alpha: 0.05),
                      color: colores != null ? colores![i % colores!.length] : Colores.primarioClaro,
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    _formato(entradas[i].value),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formato(num valor) => valor is int ? '$valor' : valor.toStringAsFixed(1);
}

/// Centra el contenido y limita su ancho en pantallas grandes.
class AnchoLimitado extends StatelessWidget {
  const AnchoLimitado({super.key, required this.child, this.ancho = 900});

  final Widget child;
  final double ancho;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: ancho), child: child),
      );
}
