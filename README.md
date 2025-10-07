# yt-dlp Descargador

Este proyecto utiliza [yt-dlp](https://github.com/yt-dlp/yt-dlp) para descargar contenido multimedia.

## Acerca de

[yt-dlp](https://github.com/yt-dlp/yt-dlp) es un programa de línea de comandos para descargar videos de YouTube.com y otros sitios de video. Es un fork de youtube-dl con características adicionales y correcciones.

El script `descargar.ps1` es una interfaz gráfica para descargar videos y audios desde múltiples plataformas, incluyendo YouTube, Vimeo, Twitter, TikTok, Instagram, Facebook y Twitch.

## Características

- **Descarga automática de yt-dlp**: El script descarga automáticamente la última versión de yt-dlp si no está presente.
- **Soporte para múltiples plataformas**: Compatible con YouTube, Vimeo, Twitter, TikTok, Instagram, Facebook, Twitch y más.
- **Opciones de descarga**:
  - Video (calidad automática - recomendado)
  - Solo audio (MP3)
  - Video 1080p (si está disponible)
  - Video 720p
  - Personalizado (avanzado)
- **Soporte para FFmpeg**: Descarga e integración opcional de FFmpeg para funcionalidades avanzadas como metadatos y miniaturas incrustadas.
- **Manejo de errores**: Sistema robusto de reintentos y verificación de conexiones.
- **Interfaz amigable**: Menús interactivos con colores y mensajes de progreso.

## Requisitos

- Windows PowerShell 5.1 o superior
- Conexión a internet

## Uso

1. Ejecuta el archivo `descargar.ps1` en PowerShell.
2. Ingresa la URL del video que deseas descargar.
3. Selecciona la opción de descarga deseada (video, audio, calidad específica, etc.).
4. Especifica la carpeta de destino (deja vacío para usar la carpeta actual).
5. Confirma los detalles y comienza la descarga.

El script verificará automáticamente si yt-dlp está actualizado y te guiará a través del proceso de descarga con mensajes claros y opciones intuitivas.

## Funcionalidades avanzadas

- Integración con FFmpeg para incrustar metadatos y miniaturas
- Verificación de URLs de sitios conocidos
- Manejo de listas de reproducción
- Soporte para formatos personalizados

Para más información sobre yt-dlp, visita: https://github.com/yt-dlp/yt-dlp
