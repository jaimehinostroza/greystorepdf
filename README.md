# GreyStore PDF

Herramienta de escritorio para Windows para gestionar PDF: organizar páginas, convertir formatos y editar contenido. Funciona sin conexión y los documentos nunca salen del equipo.

## Origen y licencia

GreyStore PDF está basado en la parte de código abierto (licencia MIT) de
[Stirling-PDF](https://github.com/Stirling-Tools/Stirling-PDF), © 2025 Stirling PDF Inc.

Este repositorio **no incluye** ninguna de las carpetas que Stirling PDF publica bajo su licencia comercial
(`app/proprietary`, `app/saas`, `engine`, `frontend/src/editor/proprietary`, `frontend/src/editor/desktop`,
`frontend/src/editor/saas`, `frontend/src/editor/cloud`, `frontend/src/processor`). El build está fijado
en la versión "core" y no puede compilar esas partes.

"Stirling PDF" es una marca de su respectivo dueño; GreyStore PDF no está afiliado ni respaldado por Stirling PDF Inc.

- Versión base importada: Stirling-PDF `8652f45b276d4fd44222d2845b07a54ce417502b`
- Licencia: ver [LICENSE](LICENSE)

## Funciones incluidas

- **Organizar:** unir, dividir, rotar, recortar, reordenar, extraer y eliminar páginas; eliminar páginas en blanco;
  varias páginas por hoja, folletos, página única; ajustar escala, superponer PDF, portafolios; separar fotos escaneadas;
  auto-rotar y auto-renombrar.
- **Convertir:** Office, imágenes, HTML, web, Markdown, correos, SVG y ebooks a PDF; PDF a Office, Excel, imágenes,
  HTML, EPUB, video, vectores y CSV; PDF a PDF/A.
- **Editar:** texto, imágenes, sellos, marcas de agua, números de página, anotaciones, formularios, marcadores,
  metadatos, contraste, colores, aplanar.

## Compilar

El instalador de Windows se genera automáticamente con GitHub Actions (pestaña **Actions** del repositorio).
