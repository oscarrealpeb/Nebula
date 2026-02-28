# Nebula Flutter App

Base funcional para Android en Flutter, alineada al flujo descrito (welcome, auth, home, torre de planetas, configuracion y perfil).

## Estado actual

- Flujo de onboarding con slides y dots.
- Registro y login con unicidad de correo/username.
- sesión persistente local (no pide login al reabrir).
- Home con juegos, minijuegos y escalera de planetas.
- Configuracion: Perfil, Preferencias y Personalizacion.
- Cooldowns:
  - Login -> "Olvide mi contraseña": 2 minutos.
  - Perfil -> reset de contraseña: 5 minutos.
- Base offline/local con `shared_preferences`.

## Pendiente de integrar

- Firebase Auth + Firestore + Storage.
- Sincronizacion real online/offline.
- Google ML Kit / Vision API para clasificacion de objetos reales.
- Assets finales (astronauta, ilustraciones, audio de narradores).

## Ejecutar

1. Instala Flutter SDK.
2. En esta carpeta:
   - `flutter pub get`
   - `flutter run -d android`
