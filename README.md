# Asistencia Infantil

App en **Flutter** para controlar la entrada y salida de niños en programas infantiles: búsqueda rápida en la puerta, manillas, alertas médicas, lista de presentes en tiempo real, Dashboard y cumpleaños.

[![CI](../../actions/workflows/ci.yml/badge.svg)](../../actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart)
![Pruebas](https://img.shields.io/badge/pruebas-42-brightgreen)

> **Repositorio de muestra.** La app completa está en producción (Flutter + Firebase, más de 60 archivos y unas 23.000 líneas de Dart, desde agosto de 2026) y su código es privado porque maneja datos de menores. Aquí se publica una parte representativa: el dominio, la capa de datos y una app de demostración que corre con **datos 100 % ficticios**. Ningún nombre corresponde a una persona real.

## Capturas

| Ingreso y salida | Registrar entrada | Presentes | Dashboard | Cumpleaños |
|---|---|---|---|---|
| ![Ingreso](docs/capturas/01-ingreso.jpg) | ![Entrada](docs/capturas/02-registrar-entrada.jpg) | ![Presentes](docs/capturas/03-presentes.jpg) | ![Dashboard](docs/capturas/04-dashboard.jpg) | ![Cumpleaños](docs/capturas/05-cumpleanos.jpg) |

## Qué hace

- **Ingreso y salida:** busca al niño sin importar tildes ni mayúsculas ("jose" encuentra a "José"), muestra su grupo, alertas médicas y si hay personas que no pueden recogerlo, y registra la entrada con número de manilla.
- **Reglas en la puerta:** no deja entrar dos veces al mismo niño, ni salir a quien no ha entrado, ni repetir una manilla que ya está en uso ese día.
- **Grupo por edad automático:** se calcula con la edad del día, no se guarda fijo.
- **Presentes en tiempo real**, agrupados por grupo de edad. Es el mismo cálculo que usa el modo emergencia de la app completa.
- **Dashboard:** entradas del día, presentes, los que ya salieron, distribución por grupo, promedio por jornada y niños que dejaron de asistir.
- **Cumpleaños de la semana.**

## Probarlo

Requisitos: [Flutter](https://docs.flutter.dev/get-started/install) 3.44 o superior.

```bash
git clone <url-de-este-repositorio>
cd control-asistencia-infantil
flutter pub get
flutter run -d chrome     # abre la demo en el navegador
flutter test              # 42 pruebas
flutter analyze           # análisis estático
```

Cada cambio a `main` corre el análisis y las pruebas en GitHub Actions y publica la demo en GitHub Pages.

## Estructura

```
lib/
├── domain/            Dart puro: modelos y reglas de negocio
│   ├── nino.dart          Nino, edad, grupo, cumpleaños, búsqueda
│   ├── acudiente.dart     Acudiente y vínculo niño-acudiente
│   ├── registro.dart      Entradas/salidas y cálculo de presentes
│   ├── rol_usuario.dart   Roles y permisos
│   ├── estadisticas.dart  Funciones puras del Dashboard
│   └── fechas.dart        Conversión de fechas sin depender de Firebase
├── data/              Acceso a datos
│   ├── repositorio_asistencia.dart   Contrato (clase abstracta)
│   ├── repositorio_en_memoria.dart   Implementación para demo y pruebas
│   └── datos_demo.dart               Datos ficticios
├── ui/                Pantallas, tema y componentes
└── main.dart
test/                  Pruebas de dominio, datos y widgets
docs/                  Arquitectura, paradigmas, justificación y capturas
```

## Documentación

- [Arquitectura](docs/ARQUITECTURA.md): capas, diagramas y flujo de un ingreso.
- [Paradigmas](docs/PARADIGMAS.md): POO, funcional (`map`, `where`, `fold`, `reduce`) y procedimental, con ejemplos del código.
- [Justificación tecnológica](docs/JUSTIFICACION.md): Flutter frente a Kotlin, React Native y web; Firebase frente a Supabase y servidor propio; trade-offs.

## Tecnologías

| | |
|---|---|
| Lenguaje | Dart 3 (null-safety, records, patterns, enums con campos) |
| Interfaz | Flutter, Material 3 |
| App en producción | Firebase: Auth, Firestore, Storage, Cloud Functions, Hosting, Cloud Messaging |
| Calidad | `flutter_lints`, pruebas unitarias y de widgets, GitHub Actions |

## Autor

Rafael Balaguera. El código de la app es de su autoría, y la app se donó para el uso de un programa infantil.
