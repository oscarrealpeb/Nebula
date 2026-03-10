# Nebula - Implementacion Flutter (Fase Base)

## Decisiones aplicadas

- Se creo un modulo nuevo en `flutter_app/` para no romper el prototipo web existente.
- Estado global con `AppController` (`ChangeNotifier`) y persistencia local con `shared_preferences`.
- Flujo de sesión persistente: si el usuario ya inicio sesión, abre directo en Home.
- Registro/Login locales:
  - correo y username unicos,
  - login por correo o username.
- Cooldowns:
  - reset desde login: 2 min,
  - reset desde perfil: 5 min.

## Pantallas implementadas

- Welcome con 4 slides, dots e ingresos a login/registro.
- Login y Registro.
- Home:
  - saludo,
  - avatar circular,
  - tarjeta de planeta/estrellas,
  - juegos y minijuegos,
  - acceso a configuracion.
- Escalera de planetas con progreso y estados bloqueado/actual.
- Configuracion:
  - Perfil,
  - Preferencias,
  - Personalizacion.
- Explora y aprende (categorias + dialog "Sabias que...?").
- Placeholder de juego con selector por estrellas (1, 2, 3).

## Mejora visual aplicada

- Fondo espacial reutilizable con gradientes y detalles.
- Botones primarios con estilo mas fuerte (degradado y sombra suave).
- Home y Settings con cards de mayor jerarquia visual.
- Unificacion visual en auth, home, torre de planetas y configuraciones.

## Requisitos cubiertos de tu descripcion

- Bordes redondeados y estilo uniforme.
- Persistencia de sesión.
- Unicidad de correo/apodo.
- Mensajes de recuperacion de cuenta con anti-spam temporal.
- Sistema de planetas con rangos y progreso.
- Dificultad mostrada como estrellas, sin etiquetas directas de "facil/medio/dificil".

## Integraciones pendientes (siguiente fase)

- Firebase Auth (registro/login reales, reset por correo real, borrado seguro).
- Cloud Firestore (usuarios, progreso, preferencias, planetas).
- Firebase Storage (imagenes personalizadas).
- Sincronizacion offline/online y resolucion de conflictos.
- Google ML Kit / Vision API para clasificar imagenes en personalizacion.
- Catalogo final de contenidos por planeta (animales/objetos/juegos reales).
