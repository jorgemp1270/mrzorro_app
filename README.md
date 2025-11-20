# 🦊 Mr. Zorro - AI-Powered Emotional Wellness Journal

Una aplicación avanzada de bienestar emocional desarrollada en Flutter que integra inteligencia artificial para proporcionar apoyo emocional personalizado, análisis de imágenes y seguimiento emocional inteligente.

## ✨ Características Principales

### 🤖 Asistente de IA Emocional
- **Chat inteligente** con Mr. Zorro, tu compañero emocional personalizado
- **Respuestas contextuales** basadas en tu historial y estado emocional actual
- **Integración Gemini AI** para consejos personalizados y empáticos
- **Límite inteligente** de mensajes para mantener conversaciones focused (10 mensajes máx)
- **Soporte multiidioma** con respuestas naturales en español

### 🔐 Sistema de Autenticación Avanzado
- **Registro seguro** con validación en tiempo real
- **Login automático** con credenciales cifradas
- **Flutter Secure Storage** para protección máxima de datos
- **Validación robusta** de email, contraseña y nickname
- **Gestión de sesiones** persistente y segura

### 📖 Diario Emocional Inteligente
- **Entradas agrupadas por mes** con navegación intuitiva
- **12 emociones diferentes** con valores numéricos (1-10 escala)
- **Selección visual de emociones** con chips interactivos
- **Promedio emocional mensual** mostrado en barra dinámica
- **Sincronización automática** de datos al crear/editar entradas
- **Historial completo** con fechas y previsualización

### 📷 Análisis de Imágenes con IA
- **Captura inteligente** con análisis automático
- **ResNet-50** para clasificación de imágenes
- **Gemini AI** para descripciones contextuales detalladas
- **Recomendaciones personalizadas** basadas en análisis visual
- **Datos curiosos** relacionados con las imágenes
- **Integración fluida** con entradas de diario
- **Almacenamiento inteligente** por fecha en dispositivo

### 🎭 Gestión Emocional Completa
- **Registro rápido** con botones de emociones principales
- **Análisis de tendencias** con promedio mensual visual
- **Colores dinámicos** que reflejan el estado emocional
- **Feedback inmediato** del sistema de IA
- **Seguimiento de progreso** emocional a lo largo del tiempo

### 🏠 Experiencia de Usuario Premium
- **Bottom navigation** con tres secciones principales
- **Material Design 3** con colores personalizados
- **Animaciones fluidas** y transiciones suaves
- **Responsive design** adaptado a diferentes pantallas
- **Dark/Light theme support** automático del sistema

## 🏗️ Arquitectura Técnica

### Frontend (Flutter)
```yaml
- Framework: Flutter 3.7.2+
- Lenguaje: Dart
- UI Pattern: StatefulWidget + setState
- Storage: flutter_secure_storage (cifrado)
- HTTP: http package con manejo de errores
- Images: image_picker + path_provider
- Auth: local_auth (biométrica)
- Navegación: Material PageRoute
- Fonts: Google Fonts (Poppins)
- Internacionalización: intl package
```

### Backend Integration
```python
- Framework: FastAPI (Python)
- Base de Datos: TinyDB (JSON-based)
- IA: Google Gemini 2.5 Flash
- Análisis Visual: PyTorch + ResNet-50
- Validación: Pydantic
- CORS: Configurado para desarrollo
```

### Endpoints Implementados
```http
POST /login         # Autenticación de usuario
POST /signup        # Registro de nuevos usuarios
POST /diary         # Crear/editar entradas de diario
GET  /diary/{user}  # Obtener todas las entradas
POST /prompt        # Chat con IA (Gemini)
POST /predict-image # Análisis de imágenes con IA
```

## 🚀 Instalación y Configuración

### Prerrequisitos
- **Flutter SDK** >= 3.7.2
- **Dart SDK** (incluido con Flutter)
- **Android Studio** / VS Code con extensiones Flutter
- **Git** para clonación del repositorio
- **Emulador Android** o dispositivo físico

### Configuración del Proyecto

#### 1. Clonar Repositorio
```bash
git clone [repository-url]
cd mrzorro_app
```

#### 2. Instalación de Dependencias
```bash
# Limpiar cache si es necesario
flutter clean

# Instalar dependencias
flutter pub get

# Verificar configuración
flutter doctor
```

#### 3. Configuración de API
Actualizar `lib/config/api_config.dart` según tu entorno:

```dart
// Para emulador Android
static const String baseUrl = 'http://10.0.2.2:8000';

// Para dispositivo físico (usar IP de tu computadora)
static const String baseUrl = 'http://192.168.1.XXX:8000';
```

#### 4. Ejecutar Aplicación
```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en debug mode
flutter run

# Ejecutar en release mode
flutter run --release
```

## 📱 Guía de Uso

### Primera Experiencia
1. **Splash Screen** - Pantalla de bienvenida con logo Mr. Zorro
2. **Registro/Login** - Crear cuenta o iniciar sesión existente
3. **Main Menu** - Navegación por las tres secciones principales

### Funcionalidades Detalladas

#### 🏠 Home Tab - Chat con IA
- **Chat inteligente** con respuestas personalizadas
- **Registro de emociones** rápido con botones dedicados
- **Frases motivacionales** que cambian dinámicamente
- **Sistema de puntos** visible en tiempo real

#### 📚 Journal Tab - Diario Personal
- **Entradas agrupadas** por mes con año en contenedor
- **Estadísticas visuales** (entradas anuales, rachas)
- **Promedio emocional** con barra de colores dinámica
- **Autenticación biométrica** para entradas privadas
- **Prompts aleatorios** para inspirar escritura

#### 📸 Camera Tab - Análisis Visual
- **Captura inteligente** con guías visuales
- **Análisis automático** al tomar foto
- **Resultados detallados** con descripciones IA
- **Integración directa** a creación de entradas

### Creación de Entradas
1. **Selección de emoción** (obligatoria) - 12 opciones disponibles
2. **Título personalizado** (opcional)
3. **Contenido libre** con soporte multilínea
4. **Imagen opcional** con análisis automático
5. **Guardado seguro** con API y almacenamiento local

## 🔧 Configuración Avanzada

### Personalización de Colores
Modificar `lib/utils/colors.dart`:
```dart
class AppColors {
  static const Color lavender = Color(0xFF9B8EDB);
  static const Color lavenderLight = Color(0xFFE8E4F3);
  static const Color peach = Color(0xFFFFAB9D);
  // Personalizar según preferencias
}
```

### Configuración de Emociones
Actualizar `lib/utils/constants.dart`:
```dart
static final Map<String, String> emotionsSpanish = {
  'happy': 'Feliz',        // Valor: 8.5
  'sad': 'Triste',         // Valor: 2.5
  'excited': 'Emocionado', // Valor: 9.0
  // Agregar más emociones según necesidad
};
```

### Network Security (Android)
Para desarrollo con HTTP, agregar en `android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:usesCleartextTraffic="true">
```

## 📊 Sistema de Valores Emocionales

### Escala de Emociones (1-10)
```
😠 Angry      → 1.5  (Muy Negativo)
😰 Anxious    → 2.0  (Negativo)
😢 Sad        → 2.5  (Negativo)
😴 Tired      → 3.0  (Ligeramente Negativo)
😕 Confused   → 3.5  (Neutral-Negativo)
😌 Calm       → 7.0  (Positivo)
🙏 Grateful   → 9.5  (Muy Positivo)
😊 Happy      → 8.5  (Muy Positivo)
🤩 Excited    → 9.0  (Muy Positivo)
```

### Cálculo de Promedios
- **Mensual**: Entradas del mes actual
- **Fallback**: Promedio general si no hay entradas del mes
- **Visual**: Barra de gradiente con indicador posicional
- **Actualización**: Automática al crear/editar entradas

## 🔐 Seguridad y Privacidad

### Protección de Datos
```dart
// Credenciales cifradas
flutter_secure_storage: ^9.2.2

// Autenticación biométrica opcional
local_auth: ^2.1.7

// Headers de seguridad en API calls
'Content-Type': 'application/json'
```

### Validaciones Implementadas
- **Email**: Patrón RFC 5322 con regex robusto
- **Contraseña**: 8+ caracteres, letras + números
- **Nickname**: 2-20 caracteres, caracteres especiales permitidos
- **Sanitización**: Entrada de texto limpia en formularios

### Almacenamiento Local
- **Imágenes**: Carpeta interna por fecha (`/JournalImages/`)
- **Credenciales**: Flutter Secure Storage (cifrado)
- **Configuración**: SharedPreferences para settings

## 📦 Dependencias Completas

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0            # Tipografías personalizadas
  http: ^1.1.0                     # Cliente HTTP robusto
  intl: ^0.19.0                    # Internacionalización/fechas
  path_provider: ^2.1.1           # Acceso a directorios sistema
  flutter_secure_storage: ^9.2.2   # Almacenamiento cifrado
  shared_preferences: ^2.2.2       # Preferencias simples
  local_auth: ^2.1.7              # Autenticación biométrica
  image_picker: ^1.0.7            # Captura de imágenes
```

### Estructura de Archivos
```
lib/
├── config/
│   └── api_config.dart          # Configuración de endpoints
├── screens/
│   ├── splash_screen.dart       # Pantalla inicial
│   ├── login_screen.dart        # Autenticación
│   ├── signup_screen.dart       # Registro usuarios
│   ├── main_menu_screen.dart    # Navegación principal
│   ├── journal_screen.dart      # Lista de entradas
│   ├── journal_entry_screen.dart # Editor de entradas
│   └── camera_screen.dart       # Análisis de imágenes
├── services/
│   ├── api_service.dart         # Llamadas HTTP
│   └── auth_service.dart        # Gestión autenticación
├── utils/
│   ├── colors.dart              # Paleta de colores
│   ├── constants.dart           # Constantes app
│   ├── file_utils.dart          # Utilidades archivos
│   └── validation_utils.dart    # Validaciones
└── widgets/
    └── custom_widgets.dart      # Componentes reutilizables
```

## 🧪 Testing y Debugging

### Pruebas de Conectividad
```bash
# Verificar backend en localhost
curl http://localhost:8000

# Probar desde emulador Android
curl http://10.0.2.2:8000

# Test de registro
curl -X POST http://localhost:8000/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test1234","nickname":"TestUser"}'
```

### Debug en Flutter
```bash
# Ejecutar con logs detallados
flutter run --verbose

# Analizar rendimiento
flutter run --profile

# Verificar dependencias
flutter pub deps

# Limpiar build cache
flutter clean && flutter pub get
```

### Logging Implementado
- **API calls**: Print statements en servicios
- **Navigation**: Debug info en navegación
- **Emotion tracking**: Logs de cálculos emocionales
- **Image processing**: Feedback de análisis

## 🐛 Solución de Problemas

### Errores Comunes

#### ❌ "Connection refused"
```bash
# Verificar que el backend esté corriendo
# Para emulador, usar 10.0.2.2:8000
# Para dispositivo físico, usar IP real de la PC
```

#### ❌ "Secure storage error"
```bash
# Limpiar datos de la app
flutter clean
# Desinstalar y reinstalar app
```

#### ❌ "Image picker not working"
```bash
# Verificar permisos en AndroidManifest.xml
# Agregar permisos de cámara y storage
```

#### ❌ "Biometric auth fails"
```bash
# Configurar PIN/huella en emulador
# Verificar hardware compatible en dispositivo
```

### Logs Útiles
```dart
// En caso de problemas, buscar estos logs:
print('API Response: $response');
print('User ID: $_currentUserId');
print('Emotion average: ${_calculateCurrentMonthAverage()}');
print('Image analysis: $_aiAnalysis');
```

## 📈 Próximas Mejoras

### Características Planeadas
- 🌙 **Modo Oscuro** nativo
- 📊 **Dashboard** de analytics emocionales
- 🔔 **Notificaciones** de recordatorios
- 📱 **Widget** de pantalla principal
- 🌍 **Múltiples idiomas** (inglés, francés)
- 🎨 **Temas personalizables** por usuario
- 📈 **Gráficos avanzados** de tendencias emocionales

### Optimizaciones Técnicas
- ⚡ **State management** con Riverpod/Bloc
- 🗄️ **Database local** con SQLite
- 🔄 **Sincronización** offline-first
- 🎯 **Testing** automatizado completo
- 📦 **CI/CD** pipeline setup

---

## 👥 Contribuciones

### Como Contribuir
1. Fork del repositorio
2. Crear branch feature (`git checkout -b feature/nueva-caracteristica`)
3. Commit cambios (`git commit -m 'Agregar nueva característica'`)
4. Push al branch (`git push origin feature/nueva-caracteristica`)
5. Crear Pull Request

### Estándares de Código
- **Lint**: Seguir `analysis_options.yaml`
- **Formato**: Usar `flutter format .`
- **Documentación**: Comentarios en funciones complejas
- **Testing**: Agregar tests para nuevas funcionalidades

---

**Mr. Zorro - Tu compañero inteligente de bienestar emocional** 🦊✨

*Desarrollado con ❤️ usando Flutter y tecnologías de IA avanzadas*
