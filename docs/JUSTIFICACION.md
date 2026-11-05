# Justificación tecnológica

## El problema

Un programa infantil recibe a cientos de niños por jornada. En la puerta hay voluntarios con su propio celular (Android o iPhone) que deben, en segundos:

- encontrar al niño aunque escriban el nombre sin tilde,
- saber si tiene una alerta médica o alguien que no puede recogerlo,
- registrar la entrada con una manilla y, al final, la salida.

Además, el liderazgo necesita reportes y, en una evacuación, la lista exacta de quién está adentro. El presupuesto de infraestructura es **casi cero**: es una app donada.

## Flutter frente a las alternativas

| Criterio | **Flutter (Dart)** | Kotlin nativo | React Native | Web (React) |
|---|---|---|---|---|
| Android + iPhone + web con un solo código | **Sí** | Solo Android (Kotlin Multiplatform aún comparte poco de UI) | Sí, con más dependencias nativas | Sí, pero sin cámara/escáner tan integrados |
| Instalar sin tienda de apps | **Sí, como web (PWA) por un QR** | No | No | Sí |
| Rendimiento de la interfaz | Alto: motor de render propio | El más alto | Bueno; puente JS en algunos casos | Depende del navegador |
| Tipado y seguridad ante nulos | **Fuerte, null-safety obligatorio** | Fuerte | TypeScript opcional | TypeScript opcional |
| Curva para un equipo de una persona | Media | Alta si hay que hacer también iOS | Media | Baja |

**Decisión: Flutter.** (Las cifras medidas de rendimiento y tamaño están en [RENDIMIENTO.md](RENDIMIENTO.md).)

**Por qué Flutter:** Un solo código llega a los celulares de todos los voluntarios sin pasar por las tiendas. Los acudientes entran escaneando un QR. El null-safety de Dart evita una clase entera de errores (un niño sin fecha, un acudiente sin correo) que en esta app no son raros: hay datos migrados de un sistema anterior.

**Lo que se cede (trade-offs):**
- La web de Flutter pesa más al primer ingreso que una web hecha en React (se descarga el motor). Se mitiga con caché.
- Kotlin nativo daría mejor acceso al hardware. Aquí basta con cámara y escáner QR, que Flutter resuelve con paquetes.

## Firebase frente a las alternativas

| Criterio | **Firebase (Firestore)** | Supabase (Postgres) | Servidor propio (Node + SQL) |
|---|---|---|---|
| Costo con este volumen | **≈ US$0/mes** (capa gratuita) | Gratis, pero máximo 2 proyectos por cuenta y se pausa por inactividad | Hosting mensual fijo |
| Tiempo real (lista de presentes que se actualiza sola) | **Nativo** | Sí, con Realtime | Hay que programarlo (WebSockets) |
| Autenticación, archivos y funciones | Incluidos | Incluidos | Todo por aparte |
| Consultas relacionales y reportes complejos | Limitadas: hay que diseñar los datos para ellas | **Lo mejor: SQL completo** | SQL completo |
| Mantenimiento | Ninguno | Bajo | Alto |

**Decisión: Firebase.** El tiempo real es el corazón de la app (presentes y modo emergencia) y el costo tenía que ser cero. Supabase también se evaluó, pero la cuenta ya tenía ocupados sus dos proyectos gratuitos y su pausa por inactividad no sirve para una app que se usa solo ciertos días.

**Lo que se cede:** Firestore no hace `JOIN` ni sumas en el servidor. Se resolvió con:
- **Datos denormalizados**: el niño guarda `presente` y `tieneNoAutorizados` para no hacer una consulta extra por cada uno.
- **Resúmenes precalculados**: una Cloud Function mantiene un documento por mes con los totales, en vez de leer miles de registros para el Dashboard.
- **Campos derivados para consultar**: `mesDiaNacimiento` ("11-03") permite preguntar quién cumple esta semana sin traer toda la colección.

## Decisiones de costo y región

- **Firestore en São Paulo** (`southamerica-east1`), la región más cercana a Colombia: menor latencia en la puerta.
- **Archivos (fotos) en EE. UU.** (`us-east1`): Cloud Storage en São Paulo no tiene capa gratuita.
- Presupuesto con alertas de 5 USD/mes; el gasto real ha sido ≈ US$0.

## Por qué Dart para el dominio

Las reglas (edad, grupo, presentes, estadísticas) están en Dart puro, sin Flutter ni Firebase. Se pueden probar en segundos (`flutter test`) y se podrían reutilizar en un servidor Dart si algún día hiciera falta.
