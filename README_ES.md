# JDI LPM027M128C Driver Mejorado - Edición N@Xs

**DRIVER COMPLETAMENTE OPTIMIZADO PARA LPM027M128C BASADO EN ESPECIFICACIONES PDF OFICIALES**

## 📋 Especificaciones Técnicas LPM027M128C

Basado en especificaciones PDF oficiales:

- **Pantalla**: 2.7" TFT LCD Reflectiva
- **Tecnología**: Memory in Pixel (MIP) - Ultra bajo consumo
- **Interfaz**: SPI (Serial Peripheral Interface)
- **Colores**: 8 colores (modo de datos 3-bit)
- **Resolución**: 400×240 píxeles
- **Tecnología**: IGZO (Óxido de Indio Galio Zinc)
- **Tipo**: LCD reflectiva con contraste avanzado
- **Consumo**: Ultra-bajo consumo con tecnología MIP

## 🚀 Instalación Rápida

### 1. Descargar y Extraer
```bash
tar -xzf jdi-drm-enhanced64-COMPLETE.tar.gz
cd jdi-drm-enhanced64
```

### 2. Ejecutar Instalador Mejorado
```bash
chmod +x JDI_INSTALLER_FINAL.sh
./JDI_INSTALLER_FINAL.sh
```

### 3. Reiniciar y Disfrutar
```bash
sudo reboot
```

**¡Después del reinicio, todas las optimizaciones LPM027M128C estarán activas automáticamente!**

## ✨ Lo Que Se Instala Automáticamente

### 🔧 Servicios SystemD
- **jdi-backlight-button.service** - Botón GPIO 17 para control de brillo
- **jdi-auto-optimize.service** - Optimización automática LPM027M128C
- **jdi-powersave.service** - Ahorro inteligente de energía de 5 minutos

### ⚙️ Configuración del Sistema
- **Device Tree Overlay**: dtoverlay=jdi-drm-enhanced en /boot/firmware/config.txt
- **Interfaz SPI**: Habilitada automáticamente
- **Permisos GPIO**: Usuario pi añadido a grupos gpio, spi, i2c
- **Carga Automática**: El driver se carga al arranque

### 🎯 Conjunto Completo de Comandos
- **25+ aliases optimizados** para LPM027M128C
- **Configuraciones preestablecidas** para diferentes casos de uso
- **Sistema de ayuda avanzado** con especificaciones técnicas

## 📱 Referencia de Comandos LPM027M128C

### 📊 Estado del Sistema y Control
```bash
jdi-status              # Monitor completo del estado del sistema
brightness              # Mostrar brillo PWM actual (0-3)
brightness-set N        # Establecer brillo PWM (0-3)
```

### 🖥️ Comandos Específicos LPM027M128C
Basado en especificaciones PDF oficiales:

```bash
lpm027-status           # Estado color/mono LPM027M128C
lpm027-8colors          # Habilitar modo 8 colores (datos 3-bit)
lpm027-mono             # Habilitar modo monocromo
lpm027-reflective       # Optimizar para LCD reflectiva
lpm027-mip              # Optimizar tecnología Memory in Pixel
lpm027-lowpower         # Modo bajo consumo MIP
lpm027-optimize         # Optimizador avanzado de pantalla
```

### 🎛️ Configuraciones Preestablecidas Rápidas
```bash
preset-indoor           # Optimizado para uso interior
preset-outdoor          # Optimizado para uso exterior
preset-battery          # Máxima duración de batería
preset-performance      # Máximo rendimiento
preset-reading          # Optimizado para lectura
```

### ⚡ Gestión de Energía (Tecnología MIP)
```bash
powersave               # Gestión avanzada de energía
power-status            # Estado de gestión de energía
power-performance       # Modo de energía rendimiento
power-eco               # Modo de energía ecológico
```

## 🔧 Configuración Avanzada

### Modos de Pantalla Basados en Especificaciones LPM027M128C

#### Modo 8 Colores (Recomendado)
```bash
lpm027-8colors
```
- Habilita el modo completo de 8 colores (datos 3-bit)
- Mejor para uso general
- Cortes de color optimizados (110-140)
- Beneficios completos de la tecnología MIP

#### Modo Reflectivo (Uso Exterior)
```bash  
lpm027-reflective
```
- Optimizado para uso reflectivo exterior
- Contraste mejorado para visibilidad bajo luz solar
- Mejor con brillo máximo

#### Modo Bajo Consumo (Ahorro de Batería)
```bash
lpm027-lowpower  
```
- Activa características MIP de ultra-bajo consumo
- Timeout automático de 60 segundos a mono
- Protección de memoria habilitada
- Consumo mínimo de energía

## 📖 Ayuda y Documentación

### Ayuda Rápida
```bash
jdi-help                # Referencia completa de comandos
```

### Comandos de Diagnóstico
```bash
jdi-test                # Suite completa de pruebas del driver
jdi-logs                # Ver logs del driver
jdi-modules             # Mostrar módulos cargados
```

## 🎯 Ejemplos de Uso

### Escenarios de Uso Diario

#### Configuración de Trabajo Interior
```bash
preset-indoor           # Modo 8 colores + brillo 4
```

#### Lectura Exterior
```bash  
preset-outdoor          # Modo reflectivo + brillo máximo
```

#### Conservación de Batería
```bash
preset-battery          # Bajo consumo + brillo mínimo
```

## 💝 Créditos y Licencia

**Autor**: N@Xs - Edición Mejorada 2025  
**Pantalla**: Implementación basada en especificaciones LPM027M128C  
**Tecnología**: Optimización Memory in Pixel (MIP) + IGZO  

Basado en especificaciones PDF oficiales LPM027M128C.

---

*Este driver está específicamente optimizado para la pantalla LPM027M128C basado en documentación técnica oficial. Todas las características están diseñadas para maximizar el potencial de la tecnología Memory in Pixel mientras se mantiene un consumo de energía ultra-bajo.*
