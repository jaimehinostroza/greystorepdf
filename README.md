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

## Soporte

GreyStoreChile — WhatsApp +56 9 5069 0280 — info@greystorechile.cl — [greystorechile.cl](https://greystorechile.cl)

## Compilar

El instalador de Windows se genera automáticamente con GitHub Actions (pestaña **Actions** del repositorio)
en cada cambio a `main`. Al publicar una etiqueta `vX.Y.Z` se crea además una versión en **Releases**.

## Firma digital

El instalador y el lanzador se firman con un certificado propio de GreyStoreChile (no emitido por una
autoridad pública), pensado para equipos que GreyStoreChile instala y mantiene.

1. En un PC propio, ejecutar una sola vez `packaging/windows/crear-certificado.ps1`.
2. En GitHub, **Settings → Secrets and variables → Actions**, crear `WINDOWS_SIGNING_PFX_BASE64` y
   `WINDOWS_SIGNING_PFX_PASSWORD` con los archivos que genera el script.
3. Guardar `GreyStoreChile.pfx` y su contraseña en un lugar seguro y borrar `pfx-base64.txt`.

Al instalar "para todos los usuarios" (como administrador), el instalador ofrece registrar el certificado
como confiable en ese equipo. Sin los secretos, el instalador se genera igual pero sin firma.

## Marca

Los logos e íconos salen de `packaging/branding/generate.py` (colores #1C4E38 y #B3D335).
