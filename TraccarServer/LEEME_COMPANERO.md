# TraccarServer - paquete para compañero

Requisitos: Docker Desktop (Docker Compose), cloudflared opcional.

1. Extraer la carpeta TraccarServer en C:\TraccarServer (o adaptar las rutas del script).
2. Ejecutar en PowerShell desde esa carpeta: docker compose up -d
3. Verificar con docker ps y abrir http://localhost:8082
4. Registrar cuenta y dispositivo NUEVOS en Traccar. El ID 86730947 fue solo de pruebas y no se incluye su base de datos.
5. Para túnel web opcional: cloudflared tunnel --protocol http2 --url http://localhost:8082
6. El script start-tracking-server.ps1 depende de rutas locales y su ejecución automática quedó PENDIENTE DE VERIFICAR.

No se incluyen bases de datos, logs, URLs de túneles ni credenciales.
ATENCIÓN: el túnel HTTP para el puerto 5055 solo es apropiado para un protocolo GPS basado en HTTP; no sirve para protocolos TCP/UDP genéricos.
