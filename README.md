# Appshine - Proyecto TFE 

- FP Desarrollo de Aplicaciones Multiplataforma
- Centro de estudios: IES Aguadulce
- Curso 2025 - 2026

Appshine es una aplicación móvil Android para registrar momentos culturales y eventos sociales. Permite al usuario evitar la desmemoria y crear estadísticas de su vida cultural y social.

- Desarrollada en Flutter 
- Autenticación y backend Firebase 

## 📋 Requisitos

### Para compilar desde código:
- Flutter 3.10.3 o superior
- Dart 3.10.3 o superior
- Android SDK (API 26+)
- Git (opcional, para clonar)

### Para instalar APK precompilado:
- Android 8.0+ (API 26+)

---

## 🖥️ Pasos previos: Instalación Inicial

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

### Paso 2: Instalar Extensiones en tu IDE

**Visual Studio Code:**
1. Ve a Extensions e instala:
   - **Flutter** (Dart Code)
   - **Dart** (Dart Code)

**Android Studio**
1. Ve a File > Settings > Plugins
2. Busca e instala:
   - **Dart**
   - **Flutter**
3. Reinicia el IDE

**Otros IDEs:**
Sigue los pasos necesarios para instalar Dart y Flutter

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

📝 **Nota**: si da error por command-line, consulta sección Troubleshooting

---

### Paso 4: Crear/Usar Emulador Android

**Opción A: Terminal**
```bash
# Crear emulador con API 26 (mínimo soportado, puede ser superior)
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
- Selecciona Pixel 4 o superior
- Elige API 26+ (Android 8.0+) o superior
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

## ⚡ Instalación Rápida (sin compilar)

Si tienes el **APK** de la carpeta `Instalable/` (entregado aparte):

1. Conecta tu móvil Android por USB (o copia el APK a una carpeta en el móvil)
2. Abre el explorador, tap en el APK, instala.

✅ **La app estará lista para usar en tu móvil.**

---

## 🚀 Descargando el proyecto de Appshine

### 1. Obtener el código fuente

**Opción A: Descarga desde Git**
```bash
git clone https://github.com/cdvallejo/appshine.git
cd appshine
```

**Opción B: Sin Git**
- Descarga el proyecto como ZIP desde GitHub
- Descomprime la carpeta
- Abre `appshine/` en tu terminal

### 2. **IMPORTANTE: Configurar Firebase y Variables de Entorno (REQUERIDO)**

Este proyecto necesita dos archivos de configuración (proporcionados aparte por motivos de seguridad, en la carpeta Instalable del entregable):

#### a) `google-services.json`
- Coloca en: `android/app/google-services.json`

#### b) `.env` 
- Coloca en: Raíz del proyecto (mismo nivel que `pubspec.yaml`)
- Contiene: API keys de TMDB

**Estructura esperada:**
```
appshine/
├── .env                           ← Aquí (proporcionado aparte)
├── pubspec.yaml
├── lib/
├── android/
│   └── app/
│       └── google-services.json   ← Aquí (proporcionado aparte)
└── ...
```

### 3. Instalar dependencias

```bash
flutter pub get
```

Si necesitas limpiar las dependencias, ejecuta:
```bash
flutter clean
flutter pub get
```

### 4. Ejecutar en emulador/móvil

**Emulador**
1. Desde Visual Studio Code: En la barra inferior, selecciona el emulador en el device selector
2. Abre `lib/main.dart` y haz clic en **Play** button
3. Se abrirá y compilará en el emulador elegido

**Desde Terminal**
```bash
# Lanza el emulador siguiendo el paso anterior
flutter emulators --launch <tu_nombre_emulador>

# Luego ejecuta:
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
| "Android sdkmanager not found" | En Android Studio, instala desde Settings - Languages & Frameworks - Android SDK - Pestaña SDK Tools: Marca Android SDK Command-line Tools (latest). Pulsa Apply y OK. |
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
Android API 26+ (Android 8.0+). Se recomienda superior
Flutter 3.10.3+
Emulador: Pixel 5 o similar con mínimo 2GB RAM disponible
```

---

### 🖼️ Capturas de Appshine

|                                                                                                          |                                                                                                          |
| -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| <img src="https://github.com/user-attachments/assets/aab0235b-bd57-4c5d-9bb6-b0d20df5f6ce" width="230"/> | <img src="https://github.com/user-attachments/assets/49f79fd3-c05d-4f59-be20-c8e462ee63ec" width="230"/> |
| <img src="https://github.com/user-attachments/assets/aa498e4c-d018-4f87-8e5c-15595703a841" width="230"/> | <img src="https://github.com/user-attachments/assets/866522ea-8d2b-4597-b4d5-2239a76785e7" width="230"/> |
| <img src="https://github.com/user-attachments/assets/258d0ffe-7f60-463d-8761-882ac902ee5f" width="230"/> | <img src="https://github.com/user-attachments/assets/1067119a-63d4-47db-944e-311aed17b1d6" width="230"/> |
                                                                                                         |
---

**Última actualización**: 18 de abril de 2026

