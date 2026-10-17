# CafeSoft Backend - paquete para compañero

Requisitos: Java 17, Maven, PostgreSQL.

1. Crear base PostgreSQL local llamada Cafesoft (o configurar PG_DATABASE).
2. Configurar variables de entorno: PG_HOST (localhost), PG_PORT (5432), PG_DATABASE (Cafesoft), PG_USER (postgres), PG_PASSWORD (tu contraseña local).
3. Ejecutar: mvn spring-boot:run
4. Autenticarse como ADMIN con una cuenta propia de su base de datos.
5. Probar GET /api/usuarios/{id} y PUT /api/usuarios/{id}/traccar-device.

IMPORTANTE: Este ZIP no contiene datos de PostgreSQL ni cuentas de usuario. No se incluye .env, .git ni target. La configuración de producción usa variables RDS_* y NO incluye secretos.
No se ha probado la compilación ni el despliegue de esta copia saneada.
