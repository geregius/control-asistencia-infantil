# Paradigmas de programación

Dart es un lenguaje **multiparadigma**. Este proyecto usa los tres paradigmas clásicos, cada uno donde encaja mejor:

| Paradigma | Dónde | Por qué ahí |
|---|---|---|
| Orientado a objetos | Modelos, repositorio, widgets | Agrupar datos con su comportamiento y poder cambiar implementaciones |
| Funcional | Estadísticas y filtros | Cálculos sin efectos secundarios, fáciles de probar |
| Procedimental | Reglas paso a paso (edad, llave interna, validaciones) | Secuencias cortas de pasos con condiciones |

## 1. Programación orientada a objetos

**Clases y objetos.** Cada entidad del negocio es una clase con sus datos y su comportamiento:

```dart
// lib/domain/nino.dart
class Nino {
  final String nombres;
  final DateTime fechaNacimiento;
  ...
  String get nombreCompleto => '$nombres $apellidos';     // propiedad calculada
  int edad({DateTime? hoy}) => calcularEdad(fechaNacimiento, hoy: hoy);
  String? grupo({DateTime? hoy}) => grupoParaEdad(edad(hoy: hoy));
}
```

**Encapsulamiento.** `RepositorioEnMemoria` guarda sus datos en campos privados (`_ninos`, `_registros`). La única forma de cambiarlos es `registrarMovimiento()`, que valida las reglas antes de escribir.

**Abstracción y polimorfismo.** Las pantallas reciben un `RepositorioAsistencia` (clase abstracta) y no saben qué implementación tienen detrás:

```dart
// lib/data/repositorio_asistencia.dart
abstract class RepositorioAsistencia {
  Stream<List<Nino>> ninos();
  Future<Registro> registrarMovimiento({...});
}

// lib/data/repositorio_en_memoria.dart
class RepositorioEnMemoria implements RepositorioAsistencia { ... }

// lib/data/repositorio_persistente.dart
class RepositorioPersistente implements RepositorioAsistencia {
  final RepositorioEnMemoria _base;   // le delega las reglas
  final AlmacenLocal _almacen;        // dónde guardar
  ...
}
```

**Composición y patrón Decorador.** `RepositorioPersistente` no hereda de `RepositorioEnMemoria`: lo *contiene* y le delega cada llamada, y solo agrega guardar en el navegador. `main.dart` usa el persistente; las pruebas, el de memoria; ninguna pantalla cambió. Lo mismo pasa con `AlmacenLocal`: la app guarda con `AlmacenPreferencias` (localStorage) y las pruebas con `AlmacenEnMemoria`.

**Herencia.** Cada pantalla hereda de `StatelessWidget` o `StatefulWidget` y sobrescribe `build()`. `RegistroRechazado` implementa `Exception`.

**Enums con comportamiento.** `RolUsuario` no es solo una lista de valores: cada rol tiene campos y métodos (`esLiderazgo`, `puedeVerDashboard`...):

```dart
// lib/domain/rol_usuario.dart
enum RolUsuario {
  administrador('administrador', 'Administrador'),
  ...
  bool get esLiderazgo => this == administrador || this == coordinador || this == supervisor;
}
```

**Constructores de fábrica.** `Nino.fromMap()` construye el objeto a partir de lo que llega de la base de datos.

## 2. Programación funcional

Las estadísticas (`lib/domain/estadisticas.dart`) son **funciones puras**: reciben una lista, no modifican nada y devuelven un valor nuevo.

**`where` (filter) y `map`**: niños que cumplieron años esta semana.

```dart
ninos
    .map((n) => (nino: n, diasDesde: diasDesdeCumpleanos(n.fechaNacimiento, hoy: hoy)))
    .where((c) => c.diasDesde != null)
    .map((c) => (nino: c.nino, diasDesde: c.diasDesde!))
    .toList()
```

**`fold`**: un "group by" genérico que cuenta cuántos elementos caen en cada clave. Recibe la función que calcula la clave (**función de orden superior**):

```dart
Map<K, int> contarPor<T, K>(Iterable<T> elementos, K Function(T) clave) =>
    elementos.fold(<K, int>{}, (conteo, elemento) {
      final k = clave(elemento);
      return conteo..update(k, (n) => n + 1, ifAbsent: () => 1);
    });
```

**`reduce`**: la jornada con más asistencia.

```dart
return conDatos.reduce((a, b) => b.value > a.value ? b : a);
```

**Composición**: `promedioPorJornada()` encadena `where` → `contarPor` (agrupa por día) → `promedio` (suma con `fold`), sin variables intermedias que cambien.

**Inmutabilidad**: todos los modelos tienen campos `final` y constructor `const`. Para "cambiar" un niño se crea uno nuevo (`Nino.fromMap(id, {...actual.toMap(), 'presente': true})`).

> Un hallazgo real al escribir las pruebas: `promedio()` usaba `reduce((a, b) => a + b)` sobre una lista de `int` tipada como `num`, y fallaba en tiempo de ejecución porque `reduce` exige devolver el mismo tipo que los elementos. Se cambió por `fold<num>(0, ...)`. Ver el comentario en el código.

## 3. Programación procedimental

Algunas reglas se leen mejor como una secuencia de pasos con condiciones:

```dart
// lib/domain/nino.dart
int calcularEdad(DateTime fechaNacimiento, {DateTime? hoy}) {
  final ahora = hoy ?? DateTime.now();
  var edad = ahora.year - fechaNacimiento.year;
  final aunNoCumple = ahora.month < fechaNacimiento.month ||
      (ahora.month == fechaNacimiento.month && ahora.day < fechaNacimiento.day);
  if (aunNoCumple) edad--;
  return edad;
}
```

También `registrarMovimiento()` valida paso a paso (¿ya está adentro? ¿tiene manilla? ¿la manilla está libre?) antes de guardar.

## 4. Programación reactiva (extra)

Los datos llegan como `Stream` y las pantallas los pintan con `StreamBuilder`. Cuando se registra una entrada, el repositorio emite la lista nueva y todas las pantallas que la escuchan se actualizan solas.
