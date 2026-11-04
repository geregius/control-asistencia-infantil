# Rendimiento

Mediciones hechas con [`tool/benchmark.dart`](../tool/benchmark.dart) en un computador de escritorio (AMD Ryzen 5 3600, 12 hilos, Windows 11, Dart 3.12 en la VM). Cada valor es la **mediana de 21 corridas**, después de 5 corridas de calentamiento.

```bash
dart run tool/benchmark.dart
```

## Funciones del dominio

| Función | Datos | Mediana | Por elemento |
|---|---|---|---|
| `calcularPresentes` | 500 registros | 0,48 ms | 958 ns |
| `calcularPresentes` | 5.000 registros | 0,84 ms | 167 ns |
| `calcularPresentes` | 50.000 registros | 18,08 ms | 362 ns |
| `resumenDelDia` | 5.000 registros | 1,68 ms | 336 ns |
| `resumenDelDia` | 50.000 registros | 26,78 ms | 536 ns |
| `promedioPorJornada` | 9.600 registros (8 semanas) | 0,82 ms | 85 ns |
| Búsqueda sin tildes | 5.000 niños | 5,16 ms | 1.032 ns |
| `ninosQueDejaronDeAsistir` | 5.000 niños | 0,49 ms | 99 ns |

**Cómo leerlo:** una jornada real tiene unos pocos cientos de movimientos. Con 100 veces ese volumen (50.000), el resumen del día tarda menos de 30 ms: menos de dos cuadros de pantalla a 60 fps. El cálculo crece de forma lineal (O(n)) porque cada función recorre la lista una vez y usa mapas (`Map`) para agrupar, que encuentran cada clave en tiempo constante.

`calcularPresentes` ordena la lista antes de recorrerla (O(n log n)). Así no depende del orden en que la base de datos entregue los registros, y aun así se mantiene por debajo de 20 ms con 50.000.

## Un caso real: 170 veces más rápido

La primera versión de `promedioPorJornada` tardaba **137,64 ms** con 9.600 registros, unos 14 µs por registro. Es demasiado para algo tan simple.

```dart
// Antes: 5 pasadas (una por jornada) y un DateTime nuevo por registro
for (final servicio in serviciosDisponibles)
  servicio: promedio(contarPor(
    entradas.where((r) => r.servicio == servicio),
    (r) => soloDia(r.fecha),            // DateTime(año, mes, día) en hora local
  ).values),
```

**La causa** estaba en `soloDia()`: crear un `DateTime` en hora local obliga a consultar la zona horaria del sistema operativo, y eso se hacía una vez por cada registro.

```dart
// Después: una sola pasada con fold y el día como entero AAAAMMDD
final entradasPorJornadaYDia = registros.where((r) => r.esEntrada).fold(
  <String, Map<int, int>>{},
  (acumulado, r) => acumulado
    ..putIfAbsent(r.servicio, () => {})
        .update(_claveDia(r.fecha), (n) => n + 1, ifAbsent: () => 1),
);
```

| Versión | Mediana | Por registro |
|---|---|---|
| Antes | 137,64 ms | 14.338 ns |
| Después | **0,82 ms** | **85 ns** |

Las 42 pruebas siguieron pasando sin cambios, y eso es lo que da confianza para optimizar: el comportamiento está fijado por las pruebas.

**Lección:** medir antes de optimizar. La sospecha natural habría sido "son cinco pasadas en vez de una", pero ese costo era pequeño. El costo real estaba en una función de apariencia inocente que se llamaba miles de veces.

## Tamaño de la app web

Compilación `flutter build web --release`:

| Archivo | Tamaño | Transferido (comprimido) |
|---|---|---|
| `main.dart.js` (el código de la app) | 2,5 MB | 752 KB |
| Íconos (con *tree shaking*) | 10 KB | 6 KB |
| **Primera visita, total** | | **≈ 765 KB** más el motor de render |

El motor de render de Flutter (`canvaskit.wasm`, unos 7 MB) se descarga del CDN de Google y el navegador lo guarda en caché. Ese es el *trade-off* de Flutter web frente a una página hecha en React o HTML: la primera carga pesa más. A cambio, el mismo código corre igual en Android, iPhone y escritorio. *Tree shaking* redujo las fuentes de íconos un 99 % (de 1,6 MB a 9 KB), porque solo incluye los íconos que la app usa.

## En la app en producción

Con datos reales, el cuello de botella no es la CPU sino **cuántos documentos se leen de Firestore**, que es lo que se cobra. Por eso la app completa:

- guarda resúmenes mensuales precalculados en vez de leer miles de registros para el Dashboard;
- guarda `mesDiaNacimiento` para consultar solo los cumpleaños de la semana;
- denormaliza `presente` en el niño para no recalcularlo en cada pantalla.
