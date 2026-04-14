# Appshine - Proyecto TFE 

- FP Desarrollo de Aplicaciones Multiplataforma
- Centro de estudios: IES Aguadulce
- Curso 2025 - 2026

Appshine es una aplicación móvil para registrar momentos culturales y eventos sociales. Permite al usuario evitar la desmemoria y crear estadísticas de su vida cultural y social.

- Desarrollada en Flutter 
- Autenticación Firebase y Google Sign-In 

## 📋 Requisitos

- Flutter 3.10.3 o superior
- Dart 3.10.3 o superior
- Android SDK (API 26+)

---

## 🖥️ Instalación Inicial

### Paso 1: Instalar Flutter SDK (Windows)

1. **Descargar Flutter**:
   - Ir y seguir los pasos en [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
   - En el enlace podrás instalar el SDK de Flutter y agregar Flutter al PATH
     (Recomendamos instalar desde la opción con IDE Visual Studio)

2. **Verificar instalación**:
```bash
   flutter --version
```

   **Versión requerida de Flutter**:
   - Appshine requiere **Flutter 3.10.3 o superior**
   - Si tienes versión anterior a 3.10.3, actualiza: `flutter upgrade`

### Paso 2: Ejecutar IDE

1. Instalar extensiones en IDE:
   - **Flutter** (Dart Code)
   - **Dart** (Dart Code)

### Paso 3: Instalar Android SDK

```bash
flutter doctor
```

Este comando te mostrará qué falta:
- Si dice "Android SDK missing": Necesitas Android Studio o cmdline-tools
- Opción simple: Instalar [Android Studio](https://developer.android.com/studio)
  - Durante instalación, deja opción "Android SDK" marcada

Después:
```bash
flutter doctor --android-licenses
# Acepta todas las licencias escribiendo "y"
```

### Paso 4: Crear/Usar Emulador Android

**Opción A: Terminal (Rápido - Recomendado)**
```bash
# Crear emulador con API 26 (mínimo soportado)
flutter emulators --create --name=Pixel_API26

# Listar emuladores disponibles
flutter emulators

# Iniciar emulador
flutter emulators --launch Pixel_API26
```

**Opción B: Android Studio (Visual)**
- Abre Android Studio
- AVD Manager
- Create Virtual Device
- Selecciona Pixel 4 o 5
- Elige API 26+ (Android 8.0+)
- Finish

**Opción C: si prefieres simplemente conecta un móvil Android real por USB en modo debug** (sin necesidad de emulador).
- Activar modo desarrollador
- Permitir DEBUG por USB

### Paso 5: Verificación Final

```bash
flutter doctor
```

✅ Debería mostrar checkmarks verdes en todo excepto en aquellas plataformas no descargadas para emular.

---

## 🚀 Setup e Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/cdvallejo/appshine.git
cd appshine
```

### 2. **IMPORTANTE: Configurar Firebase (REQUERIDO)**

Este proyecto requiere el archivo `google-services.json` para funcionar. Por motivos de seguridad, **no está incluido en el repositorio**.
Revisar notas adjuntas a la entrega.

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Ejecutar en emulador/móvil

**Emulador**
Puedes ejecutarlo desde archivo main (en el botonado que aparece con Play, Hot restart y Cancel)
y seleccionando el emulador del listado.

También, seleccionando el emulador y, desde terminal:

```bash
# Si tienes emulador o móvil conectado:
flutter run
```

**Dispositivo Móvil**
```bash
# Conecta móvil por USB en modo Debug
flutter install
```

## 🆘 Troubleshooting

| Problema | Solución |
|----------|----------|
| "flutter: command not found" | Reinicia terminal o agrega Flutter a PATH (ver paso 1 de instalación inicial) |
| "No devices found" | Crea emulador: `flutter emulators --create --name=Pixel_API26` o conecta móvil USB |
| "No emulators found" | Lista disponibles: `flutter emulators` y lanza uno: `flutter emulators --launch Pixel_API26` |
| "google-services.json not found" | Verifica que esté en `android/app/google-services.json` |
| "Signing key error" | Normal en primera compilación, Dart genera key automática |
| "API key invalid" | Verifica current_key en google-services.json es correcta |
| "Build failed: ANDROID_SDK_ROOT" | Necesitas Android SDK instalado (ver instalación inicial paso 3) |



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

test/
└── unit_tests.dart    # 14 unit tests (modelos, localización, temas)

integration_test/
└── test_integracion.dart # E2E tests (login + creación de momentos)
```

## ✨ Características

- **Autenticación**: Email/Password y Google Sign-In
- **Firestore**: CRUD de momentos (películas, libros, eventos) en tiempo real
- **Búsquedas Externas**: Integración con TMDB (películas) y Open Library (libros)
- **Validación de Datos**: En modelos (factory constructors) y backend (Firebase)
- **Imágenes**: Descarga, caché local, generación de miniaturas
- **Localización**: Español e Inglés
- **Guía interactiva de primeros pasos**: Ejecutada en la primera ejecución de la app
- **Documentación**: DartDoc
- **Niveles de acceso**: Usuarios y Administradores
- **Temas**: Light/Dark mode con persistencia


## 📦 Build & Despliegue en Móvil

### Generar APK (Release)

```bash
# Limpiar build anterior
flutter clean

# Obtener dependencias
flutter pub get

# Generar APK optimizado para móvil
flutter build apk --release
```

**Resultado**: El APK se genera en:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Instalar en Móvil

**Opción 1: Automático (recomendado)**
```bash
# Conecta móvil por USB en modo Debug
flutter install
```

**Opción 2: Manual con ADB**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Opción 3: Transferencia manual**
- Copia el APK a una carpeta en tu móvil
- Abre el explorador de archivos
- Tap en el APK
- Instala (autoriza si pide permisos)

---

### Recomendación para Usar

**Mínimo recomendado**:
```
Android API 26+ (Android 8.0+)
Flutter 3.10.3+
Emulador: Pixel 5 o similar con mínimo 2GB RAM disponible
```

---

**Última actualización**: 14 de abril de 2026

