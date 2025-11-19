# Mr. Zorro - Flutter Emotional Wellness App

Una aplicación de bienestar emocional desarrollada en Flutter que conecta con un backend FastAPI y utiliza inteligencia artificial para proporcionar apoyo emocional personalizado.

## 🦊 Características Principales

### 💬 Chat Inteligente con IA
- Conversaciones en tiempo real con Foxito, tu compañero emocional
- Respuestas personalizadas basadas en tu historial de diario
- Integración con Gemini AI para consejos contextuales
- Soporte multiidioma (Español)

### 🔐 Sistema de Autenticación Completo
- Registro e inicio de sesión seguro
- Almacenamiento cifrado de credenciales con Flutter Secure Storage
- Auto-login inteligente al abrir la aplicación
- Opción "Guardar datos" para conveniencia del usuario

### 📖 Diario Emocional
- Registro diario de emociones y experiencias
- Análisis de imágenes con ResNet-50
- Recomendaciones personalizadas basadas en IA
- Historial de entradas por fecha

### 🎭 Gestión de Emociones
- Registro rápido de emociones con botones intuitivos
- Biblioteca extendida de 11 emociones diferentes
- Modal interactivo para selección de emociones adicionales
- Respuestas de IA personalizadas para cada estado emocional

### 📷 Análisis de Imágenes
- Captura y análisis automático de fotos
- Clasificación inteligente con modelos pre-entrenados
- Integración de imágenes en el contexto del diario

## 🏗️ Arquitectura Técnica

### Frontend (Flutter)
- **Lenguaje**: Dart
- **UI Framework**: Flutter con Material Design
- **Gestión de Estado**: StatefulWidget
- **Almacenamiento Seguro**: flutter_secure_storage
- **HTTP Client**: http package
- **Navegación**: Material PageRoute

### Backend (FastAPI)
- **Framework**: FastAPI (Python)
- **Base de Datos**: TinyDB (JSON)
- **IA**: Google Gemini AI
- **Análisis de Imágenes**: PyTorch + ResNet-50
- **Validación**: Pydantic

### Integración de IA
- **Gemini 2.5 Flash**: Para generación de respuestas contextuales
- **ResNet-50**: Para clasificación de imágenes
- **Prompts Estructurados**: Respuestas JSON validadas

## 🚀 Instalación y Configuración

### Prerrequisitos
- Flutter SDK (>=3.7.2)
- Python 3.8+
- Android Studio / VS Code
- Emulador Android o dispositivo físico

### Backend Setup
```bash
# Navegar al directorio del backend
cd backend

# Instalar dependencias
pip install -r requirements.txt

# Configurar variable de entorno para Gemini AI
# Crear archivo .env con tu API key
echo "GEMINI_API_KEY=tu_api_key_aqui" > .env

# Ejecutar el servidor
python -m uvicorn app.main:main --host 0.0.0.0 --port 8000
```

### Flutter Setup
```bash
# Instalar dependencias
flutter pub get

# Ejecutar en emulador Android
flutter run

# O ejecutar en dispositivo específico
flutter devices
flutter run -d [device_id]
```

## 📱 Uso de la Aplicación

### Primer Uso
1. **Splash Screen**: Bienvenida inicial con introducción a la app
2. **Registro**: Crear cuenta con email, contraseña y nickname
3. **Login**: Iniciar sesión con validación en tiempo real
4. **Auto-login**: La app recuerda tus credenciales si eliges "Guardar datos"

### Funcionalidades Principales

#### Chat con IA
- Abre la app y ve al tab "Home"
- Escribe tus pensamientos o preguntas en el chat
- Recibe respuestas personalizadas de Foxito
- El AI considera tu historial de diario para respuestas contextuales

#### Registro de Emociones
- Toca los botones de emociones rápidas (Ansioso, Feliz)
- Usa "Otro" para acceder a más emociones
- Recibe consejos automáticos basados en tu estado emocional

#### Diario Personal
- Ve al tab "Journal" para escribir entradas
- Agrega fotos que se analizan automáticamente
- Revisa tu historial y progreso emocional

## 🔧 Configuración de Red

### Para Emulador Android
La app está configurada para conectar con el backend en:
- **URL**: `http://10.0.2.2:8000` (mapea a localhost:8000)

### Para Dispositivo Físico
Actualiza `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://[IP_DE_TU_COMPUTADORA]:8000';
```

## 📦 Dependencias Principales

### Flutter
```yaml
dependencies:
  flutter_secure_storage: ^9.2.2  # Almacenamiento seguro
  http: ^1.1.0                     # Cliente HTTP
  google_fonts: ^6.1.0            # Fuentes personalizadas
  image_picker: ^1.0.7            # Captura de imágenes
  shared_preferences: ^2.2.2      # Preferencias locales
  local_auth: ^2.1.7              # Autenticación biométrica
```

### Python Backend
```text
fastapi                # Framework web
uvicorn               # Servidor ASGI
pydantic              # Validación de datos
tinydb                # Base de datos JSON
google-genai          # Cliente Gemini AI
torch                 # PyTorch para ML
torchvision          # Modelos pre-entrenados
pillow               # Procesamiento de imágenes
python-dotenv        # Variables de entorno
```

## 🔐 Seguridad

### Almacenamiento de Credenciales
- Las credenciales se almacenan cifradas usando Flutter Secure Storage
- Los tokens de usuario se guardan de forma segura
- Opción de limpieza completa de datos al cerrar sesión

### Validaciones
- **Email**: Formato RFC 5322 válido
- **Contraseña**: Mínimo 8 caracteres, letras y números
- **Nickname**: 2-20 caracteres, caracteres especiales permitidos

## 🌐 Endpoints de la API

### Autenticación
- `POST /login` - Iniciar sesión
- `POST /signup` - Registrar usuario

### Diario
- `GET /diary/{user}` - Obtener entradas del usuario
- `GET /diary/{user}/{date}` - Obtener entradas por fecha
- `POST /diary` - Crear nueva entrada

### IA y Análisis
- `POST /prompt` - Generar respuesta de IA
- `POST /predict-image` - Analizar imagen

## 🧪 Testing

### Backend Testing
```bash
# Probar conexión básica
curl http://localhost:8000

# Probar registro
curl -X POST http://localhost:8000/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","nickname":"Test"}'
```

### Flutter Testing
- Usa el botón "Test API Connection" en la pantalla de login
- Verifica conectividad de red antes de usar funciones principales

## 🐛 Solución de Problemas

### Error de Conexión
- Verificar que el backend esté ejecutándose en puerto 8000
- Confirmar que el emulador puede acceder a localhost (10.0.2.2:8000)
- Revisar configuración de firewall

### Problemas de Autenticación
- Verificar formato de email y contraseña
- Limpiar caché de la app si persisten problemas
- Revisar logs del backend para errores de validación

### Issues de Gemini AI
- Verificar que la API key de Gemini esté configurada
- Revisar límites de cuota de la API
- Verificar conectividad a internet

*Mr. Zorro - Tu compañero de bienestar emocional* 🦊✨
