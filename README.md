# 📚 Guía Completa: PostgreSQL 15 - Instalación y Configuración Remota Segura

## 🎯 Introducción

Esta guía explica cómo instalar y configurar **PostgreSQL 15** en un servidor Linux para que puedas gestionar bases de datos desde cualquier lugar (o solo desde IPs que autorices).

### ¿Por qué PostgreSQL?
- Base de datos relacional robusta y confiable
- Excelente rendimiento con muchos datos
- Soporte para replicación y high availability
- Open source y gratuita
- Ideal para aplicaciones profesionales

### ¿Qué aprenderás?
- ✅ Instalación en Linux
- ✅ Configuración de acceso remoto seguro
- ✅ Restricción por IP (whitelist/blacklist)
- ✅ Autenticación robusta
- ✅ Firewall y networking
- ✅ Monitoreo y mantenimiento
- ✅ Backup y restore
- ✅ Solución de problemas comunes

---

## 📂 Estructura del Proyecto

```text
postgres-15-guide/
├── README.md                           # Esta guía completa
├── postgresql.conf.example             # Configuración de ejemplo
├── pg_hba.conf.example                 # Control de acceso de ejemplo
├── scripts/
│   ├── install-postgres.sh             # Script de instalación automática
│   ├── configure-remote-access.sh      # Configurar acceso remoto
│   └── backup.sh                       # Script de backup automático
└── docs/
    ├── NETWORKING.md                   # Detalles de networking
    ├── SECURITY.md                     # Guía de seguridad
    └── TROUBLESHOOTING.md              # Solución de problemas
```

---

## 🖥️ Requisitos Previos

### Hardware Mínimo Recomendado
- **CPU**: 2 cores
- **RAM**: 4GB (mínimo), 8GB+ (recomendado)
- **Almacenamiento**: 20GB (depende del tamaño de BD)
- **Red**: Conexión estable a internet

### Sistema Operativo
- ✅ Ubuntu 22.04 LTS
- ✅ Ubuntu 20.04 LTS
- ✅ Debian 11
- ✅ Debian 12
- ✅ CentOS 7/8
- ✅ Rocky Linux 8/9

### Conocimientos Necesarios
- Acceso SSH a servidor Linux
- Permisos de root o sudo
- Conceptos básicos de redes (IP, puertos)

---

## 🚀 Instalación Rápida (Ubuntu/Debian)

### Paso 1: Actualizar el Sistema

```bash
sudo apt update
sudo apt upgrade -y
```

### Paso 2: Instalar PostgreSQL 15

```bash
# Agregar repositorio oficial de PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Importar clave GPG
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Actualizar e instalar
sudo apt update
sudo apt install -y postgresql-15 postgresql-contrib-15
```

### Paso 3: Verificar la Instalación

```bash
sudo -u postgres psql --version
# Debe mostrar: psql (PostgreSQL) 15.X
```

### Paso 4: Iniciar el Servicio

```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verificar estado
sudo systemctl status postgresql
```

✅ **PostgreSQL está instalado y corriendo** 

---

## 🔓 Habilitar Acceso Remoto - Guía Detallada

Por defecto, PostgreSQL **solo acepta conexiones locales**. Vamos a cambiar eso de forma segura.

### Paso 1: Editar Configuración de Escucha

```bash
sudo nano /etc/postgresql/15/main/postgresql.conf
```

Busca la línea (alrededor de la línea 60):

```ini
#listen_addresses = 'localhost'
```

Descomenta y cambia a una de estas opciones:

**Opción A - Escuchar en todas las interfaces** (menos seguro):
```ini
listen_addresses = '*'
```

**Opción B - Escuchar en todas las interfaces IPv4 y IPv6** (más seguro):
```ini
listen_addresses = '0.0.0.0, ::'
```

**Opción C - Escuchar solo en una IP específica** (más seguro aún):
```ini
listen_addresses = '192.168.1.10'
```

Guarda con `Ctrl+O`, Enter, `Ctrl+X`.

---

### Paso 2: Editar Control de Acceso (pg_hba.conf)

Este archivo controla **quién puede conectarse** y **cómo**.

```bash
sudo nano /etc/postgresql/15/main/pg_hba.conf
```

**Estructura de cada línea:**
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             192.168.1.0/24          md5
```

Explicación:
- `host`: Conexión TCP/IP (remota)
- `all`: Todas las bases de datos
- `all`: Todos los usuarios
- `192.168.1.0/24`: Rango de IPs autorizadas
- `md5`: Método de autenticación (contraseña)

**Ejemplos de Configuración:**

**Ejemplo 1: Permitir desde red local específica**
```ini
# Local (siempre se permite)
local   all             all                                     trust

# TCP local
host    all             all             127.0.0.1/32            md5

# Desde red 192.168.1.x (local)
host    all             all             192.168.1.0/24          md5

# Desde servidor específico
host    all             all             203.0.113.50/32         md5

# RECHAZAR todas las demás
host    all             all             0.0.0.0/0               reject
```

**Ejemplo 2: Permitir desde cualquier lugar (menos seguro)**
```ini
# LOCAL
local   all             all                                     trust

# TCP desde cualquier lugar
host    all             all             0.0.0.0/0               md5
host    all             all             ::/0                    md5
```

**Ejemplo 3: Restricción por usuario y IP**
```ini
# LOCAL
local   all             all                                     trust

# Usuario 'app' solo desde 192.168.1.100
host    all             app             192.168.1.100/32        md5

# Usuario 'admin' desde red local
host    all             admin           192.168.1.0/24          md5

# Cualquier usuario de 203.0.113.0/24 (VPN)
host    all             all             203.0.113.0/24          md5

# RECHAZAR todo lo demás
host    all             all             0.0.0.0/0               reject
```

Guarda el archivo.

---

### Paso 3: Configurar Firewall (UFW)

⚠️ **IMPORTANTE**: Si PostgreSQL está en un servidor con firewall, necesitas abrir el puerto.

```bash
# Abrir puerto 5432 para un IP específico
sudo ufw allow from 192.168.1.100 to any port 5432

# Abrir para un rango de IPs
sudo ufw allow from 192.168.1.0/24 to any port 5432

# Ver reglas
sudo ufw status
```

**Si usas iptables:**
```bash
sudo iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 5432 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 5432 -j DROP

# Guardar (Debian/Ubuntu)
sudo iptables-save > /etc/iptables/rules.v4
```

---

### ⚠️ Observación Importante: Port Forwarding en Router/Módem

Si quieres acceder a PostgreSQL **desde internet** (no solo desde la red local), debes configurar **Port Forwarding** en tu router/módem:

**¿Por qué es necesario?**
- Tu servidor está en la red interna (ej: 192.168.1.10:5432)
- Los usuarios externos tienen tu IP pública (ej: 203.0.113.50)
- El router/módem necesita redirigir el tráfico externo hacia tu servidor interno

**Pasos para configurar Port Forwarding:**

1. **Ingresa al panel del router**
   ```
   Abre navegador → http://192.168.1.1 (o la IP de tu router)
   Usuario y contraseña: (por defecto en la etiqueta del router)
   ```

2. **Busca la sección "Port Forwarding" o "Reenvío de Puertos"**
   - Suele estar en: Configuración Avanzada → NAT → Port Forwarding
   - Puede variar según marca (TP-Link, Netgear, D-Link, Huawei, etc.)

3. **Configura la redirección:**
   - **Puerto Externo:** 5432 (o el que prefieras, ej: 15432)
   - **Puerto Interno:** 5432
   - **IP Destino Interna:** 192.168.1.10 (IP de tu servidor PostgreSQL)
   - **Protocolo:** TCP
   - **Guardar/Aplicar**

**Ejemplo de configuración:**
| Campo | Valor |
|-------|-------|
| Puerto Externo | 5432 |
| Puerto Interno | 5432 |
| IP Destino | 192.168.1.10 |
| Protocolo | TCP |
| Estado | Habilitado |

**Alternativa segura: Usar puerto diferente**
- Puerto Externo: 15432
- Puerto Interno: 5432
- De esta forma ocultas que usas PostgreSQL (seguridad por oscuridad)

**Verificar que funciona:**
```bash
# Desde fuera de tu red (en otra máquina con internet diferente):
psql -h tu_ip_publica -p 5432 -U usuario_app -d mi_app

# Si usaste puerto diferente:
psql -h tu_ip_publica -p 15432 -U usuario_app -d mi_app
```

**⚠️ ADVERTENCIA DE SEGURIDAD:**
- ❌ **NO expongas PostgreSQL directamente a internet sin SSL/TLS**
- ❌ **NO uses contraseñas débiles**
- ❌ **NO permitas acceso de usuario "postgres" desde internet**
- ✅ **USA SSL/TLS obligatorio** (ver sección de SSL más abajo)
- ✅ **USA contraseñas muy fuertes** (mínimo 16 caracteres)
- ✅ **Limita a IPs específicas si es posible**
- ✅ **Monitorea logs regularmente**

**Alternativa más segura: SSH Tunnel**
```bash
# Desde tu máquina local:
ssh -L 5432:localhost:5432 usuario@tu_ip_publica

# Luego conecta a localhost como si fuera local:
psql -h localhost -U usuario_app -d mi_app
```

---

### Paso 4: Reiniciar PostgreSQL

Después de cambios en configuración:

```bash
sudo systemctl restart postgresql

# Verificar que se reinició correctamente
sudo systemctl status postgresql

# Ver logs en caso de error
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

---

### Paso 5: Verificar que Escucha en Puerto 5432

```bash
sudo netstat -tlnp | grep 5432
# o si usas ss:
sudo ss -tlnp | grep 5432
```

Deberías ver algo como:
```
tcp        0      0 0.0.0.0:5432           0.0.0.0:*               LISTEN      1234/postgres
tcp6       0      0 :::5432                :::*                    LISTEN      1234/postgres
```

✅ **PostgreSQL está aceptando conexiones remotas**

---

## 🔐 Seguridad - Buenas Prácticas

### 1. Cambiar Contraseña del Usuario postgres

```bash
sudo -u postgres psql

# Dentro de psql:
\password postgres
# Ingresa una contraseña fuerte

# Salir
\q
```

**Contraseña fuerte debe tener:**
- ✅ Mínimo 16 caracteres
- ✅ Mayúsculas y minúsculas
- ✅ Números y símbolos
- ✅ Evitar palabras comunes

Ejemplo: `P0st9r€s_2@26!Secure#`

---

### 2. Crear Usuario Específico para tu Aplicación

En lugar de usar `postgres` (superusuario), crea un usuario con permisos limitados:

```bash
sudo -u postgres psql

# Crear usuario
CREATE USER app_user WITH PASSWORD 'password_fuerte_123';

# Crear base de datos
CREATE DATABASE app_db OWNER app_user;

# Asignar permisos solo a esa BD
GRANT CONNECT ON DATABASE app_db TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT CREATE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

\q
```

---

### 3. Usar Autenticación MD5 (mínimo) o SCRAM-SHA-256 (mejor)

En `pg_hba.conf`, cambia:
```ini
host    all             all             0.0.0.0/0               md5
```

A:
```ini
host    all             all             0.0.0.0/0               scram-sha-256
```

Luego reinicia:
```bash
sudo systemctl restart postgresql
```

---

### 4. Deshabilitar Acceso a Usuario postgres desde Red Remota

En `pg_hba.conf`:
```ini
# LOCAL - postgres puede conectar localmente
local   postgres        postgres                                trust

# REMOTO - postgres RECHAZADO desde red
host    postgres        postgres        0.0.0.0/0               reject
host    postgres        postgres        ::/0                    reject

# Otros usuarios desde IP autorizada
host    all             all             192.168.1.0/24          md5
```

---

### 5. Usar SSL/TLS para Conexiones Remotas (Producción)

Para máxima seguridad, encripta la conexión:

```bash
# Generar certificado auto-firmado
sudo openssl req -new -x509 -days 365 -nodes \
  -out /etc/postgresql/15/main/server.crt \
  -keyout /etc/postgresql/15/main/server.key

# Asignar permisos correctos
sudo chmod 600 /etc/postgresql/15/main/server.key
sudo chown postgres:postgres /etc/postgresql/15/main/server.* 

# Editar postgresql.conf
sudo nano /etc/postgresql/15/main/postgresql.conf

# Busca y descomenta:
ssl = on
ssl_cert_file = '/etc/postgresql/15/main/server.crt'
ssl_key_file = '/etc/postgresql/15/main/server.key'

# Guardar y reiniciar
sudo systemctl restart postgresql
```

---

## 📊 Gestión de Bases de Datos

### Crear Base de Datos

```bash
sudo -u postgres psql

CREATE DATABASE mi_app;
CREATE DATABASE otra_app;

# Listar bases de datos
\l

# Salir
\q
```

---

### Crear Usuario y Asignar Permisos

```bash
sudo -u postgres psql

# Crear usuario
CREATE USER usuario_app WITH PASSWORD 'contraseña_segura';

# Dar permisos sobre base de datos
ALTER DATABASE mi_app OWNER TO usuario_app;

# O darle permisos específicos
GRANT CONNECT ON DATABASE mi_app TO usuario_app;
GRANT USAGE, CREATE ON SCHEMA public TO usuario_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO usuario_app;

\q
```

---

### Conectar desde Otra Máquina

**Desde cliente Linux/Mac:**
```bash
psql -h 192.168.1.10 -U usuario_app -d mi_app
# Ingresa contraseña cuando lo pida
```

**Desde cliente Windows (con pgAdmin):**
1. Descarga pgAdmin desde https://www.pgadmin.org
2. Instala
3. File → New Server
4. Connection:
   - Host: 192.168.1.10
   - Port: 5432
   - Username: usuario_app
   - Password: tu_contraseña
   - Database: mi_app
5. Save y conecta

---

## 🔄 Backup y Restore

### Backup Completo

```bash
# Backup de una base de datos
sudo -u postgres pg_dump mi_app > backup_mi_app.sql

# Backup de todas las bases de datos
sudo -u postgres pg_dumpall > backup_completo.sql

# Backup en formato comprimido (más rápido)
sudo -u postgres pg_dump -Fc mi_app > backup_mi_app.dump
```

---

### Restore de Backup

```bash
# Restaurar desde SQL
sudo -u postgres psql mi_app < backup_mi_app.sql

# Restaurar desde formato comprimido
sudo -u postgres pg_restore -d mi_app backup_mi_app.dump
```

---

### Automatizar Backups Diarios

```bash
sudo nano /usr/local/bin/postgres-backup.sh
```

```bash
#!/bin/bash

BACKUP_DIR="/var/backups/postgres"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup completo
sudo -u postgres pg_dumpall | gzip > $BACKUP_DIR/backup_$DATE.sql.gz

# Limpiar backups más antiguos de 30 días
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete

echo "Backup completado: $BACKUP_DIR/backup_$DATE.sql.gz"
```

Hazlo ejecutable y agrega a crontab:
```bash
sudo chmod +x /usr/local/bin/postgres-backup.sh

# Editar crontab
sudo crontab -e

# Agregar línea para ejecutar diariamente a las 2 AM
0 2 * * * /usr/local/bin/postgres-backup.sh >> /var/log/postgres-backup.log 2>&1
```

---

## 📊 Monitoreo

### Ver Conexiones Activas

```bash
sudo -u postgres psql

SELECT datname, usename, application_name, state FROM pg_stat_activity;

\q
```

---

### Ver Tamaño de Bases de Datos

```bash
sudo -u postgres psql

SELECT datname, pg_size_pretty(pg_database_size(datname)) as size 
FROM pg_database 
ORDER BY pg_database_size(datname) DESC;

\q
```

---

### Ver Tamaño de Tablas

```bash
sudo -u postgres psql

\connect mi_app

SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

\q
```

---

### Monitorear Logs en Tiempo Real

```bash
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

---

## ❓ Preguntas Frecuentes (FAQ)

### P1: ¿Por qué no puedo conectar desde otra máquina?

**Causas comunes:**
1. PostgreSQL no escucha en la red (listen_addresses)
2. Firewall bloqueando puerto 5432
3. pg_hba.conf no permite la IP
4. Contraseña incorrecta

**Solución:**
```bash
# Verificar escucha
sudo ss -tlnp | grep 5432

# Verificar firewall
sudo ufw status

# Verificar configuración
sudo grep "listen_addresses" /etc/postgresql/15/main/postgresql.conf
sudo tail -20 /etc/postgresql/15/main/pg_hba.conf

# Verificar logs
sudo tail -50 /var/log/postgresql/postgresql-15-main.log
```

---

### P2: ¿Cómo cambio el puerto 5432 a otro?

```bash
sudo nano /etc/postgresql/15/main/postgresql.conf

# Busca y cambia:
port = 5433

# Guarda y reinicia
sudo systemctl restart postgresql

# Actualiza firewall
sudo ufw allow 5433/tcp

# Conectar con cliente:
psql -h 192.168.1.10 -p 5433 -U usuario_app -d mi_app
```

---

### P3: ¿Cómo mejoro el rendimiento?

Para producción, edita `postgresql.conf`:

```ini
# Memoria
shared_buffers = 256MB          # 25% de RAM disponible
effective_cache_size = 1GB      # 50-75% de RAM

# Conexiones
max_connections = 200

# Escritura
wal_buffers = 16MB

# Logs
log_min_duration_statement = 1000  # Log queries > 1 segundo
```

Luego:
```bash
sudo systemctl restart postgresql
```

---

### P4: ¿Es seguro exponer PostgreSQL a internet?

❌ **NO es recomendable**, pero si debes hacerlo:

✅ Usa estas precauciones:
1. **SSL/TLS obligatorio**
2. **Firewall restringido** a IPs conocidas
3. **Contraseñas muy fuertes**
4. **Límites de conexión**
5. **Monitoreo constante**
6. **VPN o SSH tunnel** es mejor

**Alternativa segura - SSH Tunnel:**
```bash
# En tu máquina local:
ssh -L 5432:localhost:5432 usuario@servidor.com

# Luego conectas a localhost:5432
psql -h localhost -U usuario_app -d mi_app
```

---

### P5: ¿Cómo reseteo la contraseña olvidada?

```bash
sudo nano /etc/postgresql/15/main/pg_hba.conf

# Cambia la línea local a:
local   all             all                                     trust

# Guarda y reinicia
sudo systemctl restart postgresql

# Conecta sin contraseña
sudo -u postgres psql

# Cambia contraseña
\password postgres

# Luego vuelve a cambiar pg_hba.conf a md5 o scram-sha-256
```

---

### P6: ¿Cómo deshabilito conexiones remotas rápidamente?

```bash
# Opción 1: Parar el servicio
sudo systemctl stop postgresql

# Opción 2: Editar pg_hba.conf
sudo nano /etc/postgresql/15/main/pg_hba.conf

# Comenta todo lo remoto, deja solo local
local   all             all                                     trust

# Reinicia
sudo systemctl restart postgresql
```

---

### P7: ¿Cuánta RAM necesito?

- **Desarrollo pequeño**: 2GB RAM
- **Producción pequeña**: 8GB RAM
- **Producción mediana**: 16GB+ RAM
- **Producción grande**: 64GB+ RAM

Regla general: `shared_buffers = 25% de RAM`

---

### P8: ¿Puedo tener múltiples versiones de PostgreSQL?

✅ **Sí**, pero en puertos diferentes:

```bash
# PostgreSQL 14 en puerto 5432
# PostgreSQL 15 en puerto 5433

sudo nano /etc/postgresql/15/main/postgresql.conf
# port = 5433

sudo systemctl restart postgresql
```

---

## 🚨 Troubleshooting - Problemas Comunes

### Error: "connect: Connection refused"

**Causa:** PostgreSQL no está corriendo o no escucha

```bash
sudo systemctl status postgresql
sudo systemctl restart postgresql

# Ver logs
sudo tail -20 /var/log/postgresql/postgresql-15-main.log
```

---

### Error: "FATAL: Ident authentication failed"

**Causa:** pg_hba.conf usa "ident" pero no está configurado

**Solución:**
```bash
sudo nano /etc/postgresql/15/main/pg_hba.conf

# Cambia de:
host    all             all             192.168.1.0/24          ident

# A:
host    all             all             192.168.1.0/24          md5
# o
host    all             all             192.168.1.0/24          scram-sha-256

sudo systemctl restart postgresql
```

---

### Error: "FATAL: role does not exist"

**Causa:** El usuario no existe o está mal escrito

```bash
# Listar usuarios
sudo -u postgres psql

\du

# Crear si no existe
CREATE USER usuario_app WITH PASSWORD 'contraseña';

\q
```

---

### Error: "database does not exist"

```bash
# Listar bases de datos
sudo -u postgres psql

\l

# Crear si no existe
CREATE DATABASE mi_app;

\q
```

---

### PostgreSQL consume mucha memoria

```bash
# Ver procesos
sudo ps aux | grep postgres

# Ver memoria por tabla
sudo -u postgres psql

SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) 
FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;

\q
```

**Soluciones:**
- Aumentar RAM del servidor
- Optimizar queries
- Usar índices
- Hacer vacuum: `VACUUM ANALYZE;`

---

## 🎓 Conceptos Clave

### ¿Qué es pg_hba.conf?
"PostgreSQL Host-Based Authentication" - archivo que controla quién puede conectarse, desde dónde y cómo.

### ¿Qué es listen_addresses?
Direcciones IP en las que PostgreSQL "escucha" conexiones entrantes.

### ¿Qué es un Role/Usuario?
Cuenta en PostgreSQL para acceder. Puede tener permisos específicos.

### ¿Qué es una Base de Datos?
Contenedor de datos. Un servidor PostgreSQL puede tener múltiples BDs.

### ¿Qué es un Schema?
Namespace dentro de una BD. Por defecto es "public".

---

## 📞 Próximos Pasos

1. ✅ Instalar PostgreSQL 15
2. ✅ Configurar acceso remoto
3. ✅ Crear usuarios y bases de datos
4. ✅ Configurar backups automáticos
5. ✅ Monitorear y mantener

---

## 📚 Recursos Adicionales

- [Documentación oficial PostgreSQL 15](https://www.postgresql.org/docs/15/)
- [Configuración de seguridad](https://www.postgresql.org/docs/15/runtime-config-connection.html)
- [pgAdmin - Herramienta gráfica](https://www.pgadmin.org/)
- [DBeaver - Cliente SQL universal](https://dbeaver.io/)

---

**¡Tu PostgreSQL 15 está listo para producción! 🎉**
