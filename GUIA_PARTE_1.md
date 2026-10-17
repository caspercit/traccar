# CafeSoft + Traccar — Parte 1

## Estado de la entrega

La rama `feature/traccar-parte-1` ya contiene la configuración base de Docker/Traccar. **El backend Java completo y el script PowerShell del ZIP limpio aún no están publicados** y deben agregarse desde la computadora del autor.

## Requisitos
- Docker Desktop y Docker Compose
- Java 17, Maven y PostgreSQL
- cloudflared para túneles temporales opcionales

## Arranque del servidor GPS

```powershell
cd TraccarServer
docker compose up -d
docker ps
```

Abrir http://localhost:8082

Los túneles Quick Tunnel de Cloudflare generan URLs temporales; no publicar credenciales ni usar un túnel HTTP para protocolos TCP/UDP arbitrarios.

## Vinculación con CafeSoft

El backend debe contener la columna `usuarios.traccar_device_id` y soportar las operaciones:

- `POST /api/usuarios/login`
- `GET /api/usuarios/{id}` — ADMIN
- `PUT /api/usuarios/{id}/traccar-device` — ADMIN

Ejemplo de cuerpo PUT: `{"traccarDeviceId":"86730947"}`.

Se comprobó login JWT, consulta GET y PUT de vinculación en el equipo de prueba. La obtención de coordenadas GPS desde Spring Boot no forma parte de la implementación probada.

## Pendientes
- Subir el contenido de `CafeSoft_Backend_Parte1_LIMPIO.zip` a `Backend-Java/`.
- Completar `TraccarServer/start-tracking-server.ps1` desde `TraccarServer_Parte1_LIMPIO.zip`.
- Configurar PostgreSQL con variables de entorno sin compartir contraseñas.
- Verificar el arranque automático de Windows; estaba pendiente.

## Seguridad
No subir `.env`, tokens, bases de datos locales, archivos `*.mv.db`, logs ni datos privados.
