# Arquitectura

La app está dividida en tres capas. Cada una solo conoce a la de abajo.

```mermaid
flowchart TD
    UI["ui/ — Pantallas Flutter<br/>(StatelessWidget / StatefulWidget)"]
    DATA["data/ — RepositorioAsistencia (clase abstracta)"]
    MEM["RepositorioEnMemoria<br/>(demo y pruebas)"]
    FS["Repositorio sobre Firestore<br/>(app en producción, no incluido)"]
    DOM["domain/ — Modelos y reglas en Dart puro<br/>Nino, Acudiente, Registro, RolUsuario, estadísticas"]

    UI -->|"escucha Streams y llama métodos"| DATA
    DATA --> MEM
    DATA -.-> FS
    UI --> DOM
    MEM --> DOM
    FS -.-> DOM
```

| Capa | Carpeta | Qué contiene | Depende de |
|---|---|---|---|
| Dominio | `lib/domain/` | Modelos (`Nino`, `Acudiente`, `Registro`), roles y permisos (`RolUsuario`), reglas de negocio (`calcularPresentes`, `grupoParaEdad`) y estadísticas | Nada: solo Dart |
| Datos | `lib/data/` | El contrato `RepositorioAsistencia`, la implementación en memoria y los datos ficticios de la demo | Dominio |
| Interfaz | `lib/ui/` | Pantallas, tema y componentes visuales | Dominio y el contrato de datos |

## Por qué así

- **El dominio no importa Flutter ni Firebase.** Por eso las 42 pruebas corren en segundos, sin emulador ni internet. La conversión de fechas (`fechas.dart`) acepta el `Timestamp` de Firestore sin depender de su SDK.
- **Las pantallas dependen de una clase abstracta**, no de una base de datos concreta (inversión de dependencias). La demo inyecta `RepositorioEnMemoria`; la app real, uno sobre Firestore. Cambiar de proveedor es escribir otra implementación.
- **Una sola regla para "quién está presente".** `calcularPresentes()` la usan la lista de presentes, el Dashboard y, en la app real, el modo emergencia (evacuación). Si cada pantalla tuviera su propio cálculo, la lista de una evacuación podría no coincidir con la real.
- **Los datos se reciben como `Stream`.** Las pantallas usan `StreamBuilder`, así que cuando un voluntario registra una entrada, la lista de presentes y el Dashboard se actualizan solos.

## Flujo de un ingreso

```mermaid
sequenceDiagram
    actor V as Voluntario
    participant P as PantallaIngreso
    participant R as RepositorioAsistencia
    participant D as Dominio

    V->>P: Busca "jose" y toca Entrada
    P->>V: Pide manilla, jornada y acudiente
    V->>P: Registrar
    P->>R: registrarMovimiento(...)
    R->>D: ¿ya está adentro? ¿manilla en uso? (calcularPresentes)
    alt Regla incumplida
        R-->>P: RegistroRechazado("La manilla 7 ya está en uso hoy.")
        P-->>V: Aviso en rojo
    else Todo bien
        R->>D: grupoParaEdad(edad de hoy)
        R->>R: Guarda registro y marca presente (juntos)
        R-->>P: Stream emite la lista nueva
        P-->>V: "Entrada registrada"
    end
```

## Qué hay en la app completa y no está aquí

Este repositorio es una muestra. La app en producción además tiene:

- Autenticación con Firebase Auth, aprobación de cuentas y recuperación de contraseña.
- Reglas de seguridad de Firestore y Storage por rol.
- Cloud Functions: cierre automático de jornadas, resúmenes mensuales, correos y notificaciones push.
- Fotos con compresión, firma digital en pantalla, escáner QR de manillas, reportes PDF y modo emergencia.
- Programación de turnos de voluntarios, manual de usuario y videotutoriales.

Se dejaron fuera para no exponer la configuración del servidor, las reglas de seguridad ni datos de personas reales.
