# Appshine

Una aplicación Flutter con autenticación Firebase, Firestore y Google Sign-In para gestionar momentos (películas, libros y eventos sociales).

## 📋 Requisitos

- Flutter 3.10.3 o superior
- Dart 3.10.3 o superior
- Android SDK (API 26+)
- Una cuenta de Google Cloud con Firebase configurado

## 🚀 Setup e Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/cdvallejo/appshine.git
cd appshine
```

### 2. **IMPORTANTE: Configurar Firebase (REQUERIDO)**

Este proyecto requiere el archivo `google-services.json` para funcionar. Por motivos de seguridad, **no está incluido en el repositorio**.

**Pasos:**

1. Crea tu propio proyecto en [Firebase Console](https://console.firebase.google.com)
   - Project ID: `appshine`
   - Añade una app Android con package name: `com.carlosvallejo.appshine`

2. Descarga `google-services.json` desde Firebase Console

3. Copia el archivo a:
   ```
   android/app/google-services.json
   ```

4. **Alternativa**: Si no tienes Firebase, puedes usar el template de ejemplo como referencia:
   - Copia `android/app/google-services.example.json` a `android/app/google-services.json`
   - Reemplaza el valor de `current_key` con tu clave API real de Google Cloud

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Ejecutar la app

```bash
flutter run
```

## 🔐 Seguridad

- El archivo `google-services.json` está protegido en `.gitignore` por razones de seguridad
- Nunca commits este archivo a repositorios públicos
- Las claves de API están restringidas a Android en Google Cloud Console

## 📁 Estructura de Carpetas

```
lib/
├── screens/           # Pantallas de la app
├── data/              # Lógica de datos (AuthRepository, DatabaseService)
├── models/            # Modelos de datos
├── repositories/      # Repositorios
├── widgets_extra/     # Widgets customizados
├── theme/             # Configuración de tema
└── l10n/              # Localización (Español/Inglés)
```

## ✨ Características

- ✅ **Autenticación**: Email/Password y Google Sign-In
- ✅ **Firestore**: CRUD de momentos (películas, libros, eventos)
- ✅ **Firebase Storage**: Almacenamiento de imágenes
- ✅ **Localización**: Español e Inglés
- ✅ **Google OAuth 2.0**: Integración completa
- ✅ **Documentación**: DartDoc en todo el código

## 📱 Devices/Emulators

Desarrollado y probado en:
- Android Emulator (SDK 26+)
- Dispositivos Android reales

## 📞 Contacto

Desarrollador: Carlos Vallejo
TFE: Appshine - Aplicación de gestión de momentos

---

**Última actualización**: 24 de marzo de 2026

