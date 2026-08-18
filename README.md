# Pivote Training App 🏋️

App Flutter para Julian Rivera — Pivot Selección Bogotá  
Preparación Clasificatorios Octubre 2026

---

## Qué hace la app

| Pantalla | Función |
|----------|---------|
| **Hoy** | Ejercicios del día con peso planificado (sem actual), marcar como hechos, registrar peso real |
| **Semana** | Vista de todos los días, expandible por día |
| **Nutrición** | Macros diarios, timing de comidas, suplementos |
| **Progreso** | Registrar peso, dolor (lumbar/hombro/rodilla), notas + gráfica histórica |
| **Ajustes** | Importar Excel, seleccionar semana (1-8), exportar PDF |

---

## Instalar en iPhone (desde Mac)

### 1. Instalar Flutter (si no lo tienes)

```bash
# Instalar con Homebrew
brew install --cask flutter

# Verificar instalación
flutter doctor
```

Asegúrate de que `flutter doctor` muestre ✓ en Xcode y en el dispositivo iOS.

### 2. Clonar el repo y crear el proyecto Flutter

```bash
# En tu Mac, clona el repo
git clone git@github.com:julianrivera35/training-app.git
cd training-app

# Crear la estructura Flutter (genera ios/, android/, etc.)
# Esto NO sobreescribe los archivos Dart que ya están en lib/
flutter create . \
  --org com.julianrivera35 \
  --project-name training_app \
  --platforms ios

# Instalar dependencias
flutter pub get
```

### 3. Abrir Xcode y configurar firma

```bash
# Abrir el proyecto iOS en Xcode
open ios/Runner.xcworkspace
```

En Xcode:
1. Click en **Runner** (en el panel izquierdo, la carpeta raíz)
2. Ir a la pestaña **Signing & Capabilities**
3. En **Team** seleccionar tu Apple ID (o tu cuenta de desarrollador)
4. El Bundle Identifier será `com.julianrivera35.training_app` (puedes dejarlo así)

> Si no tienes cuenta de Apple Developer ($99/año), puedes usar tu Apple ID gratuito pero la app expira en 7 días y necesitas reinstalarla.

### 4. Conectar iPhone y correr la app

```bash
# Conectar iPhone con cable USB
# En la primera conexión, confiar en el Mac desde el iPhone

# Verificar que el dispositivo se detecta
flutter devices

# Correr la app en el iPhone
flutter run
```

Si prefres desde Xcode: seleccionar tu iPhone en el dropdown de dispositivos → ▶️ Run.

### 5. Para instalaciones futuras (sin cable)

Una vez instalada por primera vez con cable, puedes activar **wireless debugging**:
- Xcode → Window → Devices and Simulators → tu iPhone → Enable network debugging

---

## Usar la app — flujo normal

### Primera vez
1. Abre la app → vas a la pantalla **Ajustes** (ícono de tuerca abajo a la derecha)
2. Tap en **Importar PIVOTES_FINAL.xlsx**
3. El selector de archivos de iOS se abre → navega a tu archivo → selecciónalo
4. La app parsea el Excel y carga todo → verás "✅ X días, Y ejercicios con cargas"
5. Selecciona la **Semana actual** (slider 1-8)

### Cada día
1. Abre la app → pantalla **Hoy**
2. Ves los ejercicios del día con el peso planeado para tu semana actual
3. Tap en un ejercicio para expandir → ver instrucciones → ingresar peso real
4. Marcar como hecho con el botón ✓

### Cada semana
1. **Ajustes** → mover el slider a la semana siguiente
2. Los pesos en "Hoy" se actualizan automáticamente

### Actualizaciones del Excel
Cuando cambien ejercicios, cargas, o llegue un nuevo mesociclo:
1. Descarga el nuevo Excel en tu iPhone (desde email, Drive, etc.)
2. App → **Ajustes** → **Importar PIVOTES_FINAL.xlsx**
3. La app re-carga todo con los nuevos datos
4. El historial de progreso **no se borra** (queda guardado localmente)

### Exportar PDF
1. **Ajustes** → **Exportar progreso en PDF**
2. iOS abre el menú compartir → puedes guardar en Archivos, enviar por email, WhatsApp, etc.

---

## Actualizar la app (cuando haya cambios en el código)

```bash
# En tu Mac, dentro de la carpeta training-app
git pull
flutter pub get
flutter run
```

---

## Estructura del proyecto

```
lib/
├── main.dart                    # Entrada de la app
├── theme/app_theme.dart         # Colores y estilos
├── models/
│   ├── exercise.dart            # Ejercicio + TrainingDay
│   ├── weekly_load.dart         # Cargas por semana
│   ├── progress_entry.dart      # Registro de progreso
│   └── nutrition_plan.dart      # Plan nutricional
├── services/
│   ├── excel_parser.dart        # Lee PIVOTES_FINAL.xlsx
│   ├── data_service.dart        # Guarda/carga datos locales
│   └── pdf_exporter.dart        # Genera PDF de progreso
├── providers/
│   └── app_provider.dart        # Estado global de la app
├── screens/
│   ├── main_scaffold.dart       # Navegación inferior
│   ├── today_screen.dart        # Pantalla Hoy
│   ├── week_screen.dart         # Pantalla Semana
│   ├── nutrition_screen.dart    # Pantalla Nutrición
│   ├── progress_screen.dart     # Pantalla Progreso
│   └── settings_screen.dart     # Pantalla Ajustes
└── widgets/
    └── exercise_card.dart       # Tarjeta de ejercicio
```

---

## Posibles problemas

| Problema | Solución |
|----------|---------|
| `flutter doctor` muestra errores de Xcode | `sudo xcode-select --switch /Applications/Xcode.app` |
| "No devices found" | Verifica que el iPhone confía en el Mac (aparece popup en el iPhone) |
| App no puede leer el Excel | Asegúrate de que el archivo se llama `PIVOTES_FINAL.xlsx` y tiene las hojas `PROGRAMA SEMANAL` y `CARGAS Y PROGRESIÓN` |
| Firma expirada (7 días, cuenta gratuita) | Vuelve a correr `flutter run` con el iPhone conectado |
| Pods error en iOS | `cd ios && pod install && cd ..` luego `flutter run` |

---

*Repo: git@github.com:julianrivera35/training-app.git*  
*Stack: Flutter 3.x · Dart 3.x · Excel parsing · PDF export · Local JSON storage*
