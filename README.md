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

# Abrir para cualquier IP (menos seguro)
sudo ufw allow 5432/tcp

# eliminar reglas anteriores si es necesario
sudo ufw delete allow 5432/tcp

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

Para máxima seguridad, encripta la conexión. **¿Son gratis? ✅ SÍ**

#### Opción A: Certificado Auto-Firmado (GRATIS - Para desarrollo/testing)

Válido por 365 días, genera advertencias en clientes pero **encripta la conexión**:

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

**Renovación manual:**
- El certificado expira cada **365 días**
- Necesitas regenerarlo antes de que expire
- Muy tedioso renovar manualmente

---

#### Opción B: Let's Encrypt (GRATIS - Recomendado para Producción)

Certificados **válidos, confiables y gratis**. Durabilidad: **90 días** pero se renuevan automáticamente.

**Requisitos:**
- Servidor con dominio (ej: postgres.tudominio.com)
- Acceso a internet desde el servidor
- Puerto 80 o 443 accesible

---

#### 📋 GUÍA COMPLETA: Cloudflare + Certbot + Let's Encrypt + PostgreSQL SSL

Esta sección explica en detalle cómo configurar SSL/TLS correctamente, incluyendo todos los errores que cometimos y sus soluciones.

---

##### **PASO 1: Configurar Dominio en Cloudflare (DNS)**

**¿Por qué Cloudflare?**
- DNS gratuito y rápido
- Permite actualizar dinámicamente la IP cuando cambia
- Gestión centralizada de dominios
- Compatible con Let's Encrypt

**Requisitos:**
- Tu dominio registrado (ej: `ejaniot.com`)
- Cuenta de Cloudflare (gratuita en https://www.cloudflare.com)

**Paso 1.1: Agregar dominio a Cloudflare**

```
1. Ve a https://dash.cloudflare.com
2. Click en "Add a site"
3. Escribe tu dominio: ejaniot.com
4. Selecciona plan "Free" (gratuito)
5. Cloudflare te mostrará sus nameservers (NS)
```

**Paso 1.2: Actualizar nameservers en tu registrador**

Cloudflare te dirá algo como:
```
Usa estos nameservers:
- alice.ns.cloudflare.com
- bob.ns.cloudflare.com
```

Ve a tu registrador (GoDaddy, Namecheap, etc.) y cambia los nameservers a los de Cloudflare.

**Paso 1.3: Crear registro A para subdominio postgres**

En Cloudflare Dashboard:
```
1. Ve a tu dominio (ejaniot.com)
2. Click en "DNS" en el menú izquierdo
3. Click en "Add record"
4. Rellena:
   - Type: A
   - Name: postgres (esto crea postgres.ejaniot.com)
   - IPv4 address: TU_IP_PUBLICA (ej: 186.115.81.13)
   - TTL: Auto
   - Proxied: OFF ⚠️ (CRÍTICO: Debe ser "DNS only" - nube gris)
5. Click en "Save"
```

**NOTA: Alternativa con CNAME (para IPs Dinámicas)**

Si tu ISP te cambia la IP frecuentemente y prefieres **NO actualizar postgres.ejaniot.com constantemente**, puedes usar CNAME:

```
1. Crea un registro A para ejaniot.com apuntando a tu IP (este sí se actualiza automáticamente)
2. Crea un registro CNAME para postgres.ejaniot.com apuntando a ejaniot.com
   - Type: CNAME
   - Name: postgres
   - Target: ejaniot.com
   - TTL: Auto
   - Proxied: OFF ⚠️ (Debe ser "DNS only")

Ventaja: El script solo actualiza ejaniot.com, y postgres.ejaniot.com se resuelve automáticamente
Desventaja: Una actualización más en la cadena DNS, pero imperceptible en latencia
```

**⚠️ IMPORTANTE: Proxied vs DNS Only**

```
✅ CORRECTO (DNS only - nube gris):
postgres.ejaniot.com → [gray cloud] → apunta directamente a 186.115.81.13
Let's Encrypt puede validar: ✅

❌ INCORRECTO (Proxied - nube naranja):
postgres.ejaniot.com → [orange cloud] → intermediario Cloudflare
Let's Encrypt NO puede validar: ❌ FALLA
```

**¿Por qué DNS only?**
- Let's Encrypt necesita verificar que el dominio apunta a TU servidor
- Si Cloudflare está entre medio (proxied), Let's Encrypt ve a Cloudflare, no a ti
- Para PostgreSQL, no necesitamos proxy de Cloudflare (no es HTTP)

**Paso 1.4: Verificar que el DNS apunta correctamente**

```bash
# Desde tu máquina local (no en el servidor):
nslookup postgres.ejaniot.com
# Debe mostrar tu IP pública: 186.115.81.13

# O:
dig postgres.ejaniot.com
# Busca la línea "ANSWER SECTION" y verifica tu IP
```

Si ves tu IP pública correctamente, ✅ el DNS está bien configurado.

---

##### **PASO 2: Preparar tu IP Dinámica (Cloudflare API)**

**¿Por qué esto?**
Tu ISP (Movistar) puede cambiar tu IP pública en cualquier momento. Necesitas actualizar automáticamente el registro DNS en Cloudflare.

**Paso 2.1: Obtener API Token de Cloudflare**

```
1. Ve a https://dash.cloudflare.com/profile/api-tokens
2. Click en "Create Token"
3. Selecciona "Edit zone DNS" (permiso limitado, más seguro)
4. En "Zone Resources" selecciona tu dominio (ejaniot.com)
5. Click en "Continue to summary"
6. Click en "Create Token"
7. Copia el token (algo como: `cfut_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)
```

**⚠️ IMPORTANTE:** Guarda este token en un lugar seguro (ej: `/home/ejaniot/cloudflare-token.txt`)

**⚠️ NUNCA expongas este token en público (Git, documentación pública, etc.)**

```bash
# En tu servidor (reemplaza TU_TOKEN_AQUI con tu token real):
echo "TU_TOKEN_CLOUDFLARE_AQUI" > ~/.cloudflare-token
chmod 600 ~/.cloudflare-token
```

**Paso 2.2: Crear script para actualizar IP automáticamente**

```bash
sudo nano /usr/local/bin/update-cloudflare-dns.sh
```

Copia este script (reemplaza tu dominio y email):

```bash
#!/bin/bash

# Cloudflare API
CLOUDFLARE_TOKEN="TU_TOKEN_CLOUDFLARE_AQUI"  # Reemplazar con tu token real
ZONE_ID="tu_zone_id"  # Lo obtienes de Cloudflare Dashboard
RECORD_NAME="postgres.ejaniot.com"
RECORD_ID="tu_record_id"  # Lo obtienes de Cloudflare Dashboard

# Obtener IP pública actual
CURRENT_IP=$(curl -s https://api.ipify.org)

# Actualizar en Cloudflare
curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\": \"A\",
    \"name\": \"$RECORD_NAME\",
    \"content\": \"$CURRENT_IP\",
    \"ttl\": 3600,
    \"proxied\": false
  }" | grep -q '"success":true'

if [ $? -eq 0 ]; then
  echo "[$(date)] DNS actualizado a $CURRENT_IP"
else
  echo "[$(date)] ERROR: Fallo al actualizar DNS"
fi
```

**Nota:** Para obtener ZONE_ID y RECORD_ID:
```bash
# ZONE_ID (ID de tu dominio):
curl -s -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  https://api.cloudflare.com/client/v4/zones | jq '.result[] | select(.name=="ejaniot.com") | .id'

# RECORD_ID (ID del registro postgres):
curl -s -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records | jq '.result[] | select(.name=="postgres.ejaniot.com") | .id'
```

**Paso 2.3: Automatizar actualización de DNS cada hora**

```bash
sudo chmod +x /usr/local/bin/update-cloudflare-dns.sh

# Agregar a crontab
sudo crontab -e

# Agregar esta línea (ejecuta cada hora):
0 * * * * /usr/local/bin/update-cloudflare-dns.sh >> /var/log/cloudflare-dns-update.log 2>&1
```

---

##### **PASO 3: Instalar Certbot y Generar Certificado Let's Encrypt**

**Paso 3.1: Instalar Certbot**

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y certbot python3-certbot

# CentOS/Rocky
sudo dnf install -y certbot
```

**Paso 3.2: Generar certificado para tu dominio**

```bash
# Solicitar certificado para postgres.ejaniot.com
sudo certbot certonly --standalone \
  -d postgres.ejaniot.com \
  --email tu_email@gmail.com \
  --agree-tos \
  --non-interactive

# Certbot genera:
# /etc/letsencrypt/live/postgres.ejaniot.com/fullchain.pem
# /etc/letsencrypt/live/postgres.ejaniot.com/privkey.pem
# /etc/letsencrypt/live/postgres.ejaniot.com/cert.pem
# /etc/letsencrypt/live/postgres.ejaniot.com/chain.pem
```

**¿Qué archivo usar en PostgreSQL?**
- `fullchain.pem`: Certificado + cadena (esto es lo que usamos) ✅
- `privkey.pem`: Clave privada (esto es lo que usamos) ✅
- `cert.pem`: Solo certificado (sin cadena, puede causar problemas)
- `chain.pem`: Solo cadena (sin certificado, incompleto)

---

##### **PASO 4: Configurar PostgreSQL con SSL (MÉTODO CORRECTO)**

⚠️ **ERRORES QUE COMETIMOS (y las soluciones):**

**ERROR 1: "could not load server certificate file"**
```
❌ INCORRECTO: Crear symlinks en /etc/postgresql/15/main/
PostgreSQL busca archivos en /var/lib/postgresql/15/main/

✅ CORRECTO: Crear symlinks en /var/lib/postgresql/15/main/
```

**ERROR 2: "Permission denied" al acceder a certificados**
```
❌ INCORRECTO: /etc/letsencrypt/ tiene permisos 700 (solo root)
Usuario postgres no puede acceder

✅ CORRECTO: Cambiar /etc/letsencrypt/live/ y archive/ a 755
```

**ERROR 3: Certificado no se actualiza después de renovación de Certbot**
```
❌ INCORRECTO: Copiar certificados a /etc/postgresql/15/main/
Certbot renueva en /etc/letsencrypt/live/ pero copia quedan obsoletas

✅ CORRECTO: Usar symlinks a /etc/letsencrypt/live/
Certbot actualiza /etc/letsencrypt/live/ automáticamente
Symlinks siempre apuntan a la versión actual
```

**Paso 4.1: Crear symlinks en el directorio de datos de PostgreSQL**

```bash
# CREAR SYMLINKS en /var/lib/postgresql/15/main/ (NO en /etc/postgresql/)
sudo ln -sf /etc/letsencrypt/live/postgres.ejaniot.com/fullchain.pem \
  /var/lib/postgresql/15/main/server.crt

sudo ln -sf /etc/letsencrypt/live/postgres.ejaniot.com/privkey.pem \
  /var/lib/postgresql/15/main/server.key
```

**Verificar que se crearon correctamente:**

```bash
# Ver symlinks
ls -la /var/lib/postgresql/15/main/server.*
# Debe mostrar:
# lrwxrwxrwx 1 root root 56 May 21 00:43 server.crt -> /etc/letsencrypt/live/postgres.ejaniot.com/fullchain.pem
# lrwxrwxrwx 1 root root 54 May 21 00:43 server.key -> /etc/letsencrypt/live/postgres.ejaniot.com/privkey.pem

# Verificar que apuntan a archivos válidos
sudo ls -la /etc/letsencrypt/live/postgres.ejaniot.com/
# Debe mostrar fullchain.pem y privkey.pem
```

**Paso 4.2: Arreglar permisos en directorios de Let's Encrypt**

```bash
# Let's Encrypt está protegido, pero postgres necesita acceso
# Permitir que postgres pueda LEER (no escribir) los certificados
sudo chmod 755 /etc/letsencrypt/live
sudo chmod 755 /etc/letsencrypt/archive

# Permitir que postgres sea dueño de los symlinks
sudo chown postgres:postgres /var/lib/postgresql/15/main/server.crt
sudo chown postgres:postgres /var/lib/postgresql/15/main/server.key
```

**Paso 4.3: Configurar PostgreSQL para usar SSL**

```bash
# Editar archivo de configuración
sudo nano /etc/postgresql/15/main/postgresql.conf
```

Busca estas líneas (alrededor de la línea 105) y descomenta:

```ini
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
```

**¿Por qué rutas relativas, no absolutas?**

PostgreSQL busca archivos **relativamente** al directorio de datos:
- `server.crt` → busca en `/var/lib/postgresql/15/main/server.crt` ✅
- `/etc/postgresql/15/main/server.crt` → NO funcionaría ❌
- `/etc/letsencrypt/live/.../fullchain.pem` → NO funcionaría sin permisos ❌

**Paso 4.4: Reiniciar PostgreSQL y verificar**

```bash
# Reiniciar servicio
sudo systemctl restart postgresql

# Verificar estado
sudo pg_lsclusters
# Debe mostrar: 15  main  5432  online

# Si está "down", ver el error:
sudo tail -50 /var/log/postgresql/postgresql-15-main.log
```

**Paso 4.5: Probar conexión SSL**

```bash
# Conexión LOCAL con SSL obligatorio
PGSSLMODE=require psql -h localhost -U vanessaapp -d vanessaapp_db

# Deberías ver:
# SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
# vanessaapp_db=>
```

Si ves eso, ✅ SSL está funcionando correctamente con TLS 1.3 (excelente).

---

##### **PASO 5: Configurar Renovación Automática de Certificados**

**¿Por qué es importante?**
- Let's Encrypt certificados duran 90 días
- Necesitas renovarlos automáticamente
- Con symlinks, la renovación es automática (el symlink siempre apunta a la versión actual)

**Paso 5.1: Verificar que Certbot timer esté habilitado**

```bash
# Verificar auto-renovación
sudo systemctl status certbot.timer
# Debe mostrar "active (enabled)"

# Ver cuándo se ejecutó por última vez
sudo systemctl list-timers certbot.timer
```

Si no está habilitado:
```bash
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

**Paso 5.2: Probar renovación manualmente (OPCIONAL)**

```bash
# Hacer una prueba de renovación (sin aplicar cambios)
sudo certbot renew --dry-run

# Debe mostrar: "Congratulations, all renewals succeeded"
```

**Paso 5.3: ¿Y PostgreSQL? ¿Necesito reiniciarlo después de renovar?**

```
NO ES NECESARIO por estos motivos:

1. Usamos symlinks a /etc/letsencrypt/live/postgres.ejaniot.com/
2. Certbot actualiza los archivos en /etc/letsencrypt/live/ automáticamente
3. Los symlinks SIEMPRE apuntan a la versión actual
4. PostgreSQL sigue funcionando sin reiniciar

Ejemplo:
  /var/lib/postgresql/15/main/server.crt
  └─> /etc/letsencrypt/live/postgres.ejaniot.com/fullchain.pem
      └─> /etc/letsencrypt/archive/postgres.ejaniot.com/fullchain100.pem (vieja)
      
Cuando Certbot renueva:
  /var/lib/postgresql/15/main/server.crt
  └─> /etc/letsencrypt/live/postgres.ejaniot.com/fullchain.pem
      └─> /etc/letsencrypt/archive/postgres.ejaniot.com/fullchain101.pem (nueva)
      
El symlink automáticamente apunta a la nueva versión ✅
```

---

##### **RESUMEN: Estructura Final Correcta**

```
/etc/letsencrypt/
├── live/
│   └── postgres.ejaniot.com/
│       ├── fullchain.pem → ../../archive/postgres.ejaniot.com/fullchain1.pem
│       ├── privkey.pem → ../../archive/postgres.ejaniot.com/privkey1.pem
│       ├── cert.pem → ../../archive/postgres.ejaniot.com/cert1.pem
│       └── chain.pem → ../../archive/postgres.ejaniot.com/chain1.pem
└── archive/
    └── postgres.ejaniot.com/
        ├── fullchain1.pem (certificado actual)
        ├── privkey1.pem (clave privada actual)
        ├── cert1.pem
        └── chain1.pem

/var/lib/postgresql/15/main/
├── server.crt → /etc/letsencrypt/live/postgres.ejaniot.com/fullchain.pem
├── server.key → /etc/letsencrypt/live/postgres.ejaniot.com/privkey.pem
└── ... (otros archivos de PostgreSQL)

postgresql.conf:
  ssl = on
  ssl_cert_file = 'server.crt'
  ssl_key_file = 'server.key'
```

**Flujo de Renovación Automática:**

```
[90 días después]
  ↓
Certbot Timer se ejecuta
  ↓
Descarga nuevo certificado
  ↓
Actualiza /etc/letsencrypt/archive/postgres.ejaniot.com/fullchain2.pem
  ↓
Actualiza symlink /etc/letsencrypt/live/postgres.ejaniot.com/fullchain.pem
  ↓
PostgreSQL lee del symlink (que ahora apunta a fullchain2.pem)
  ↓
✅ SSL sigue funcionando sin intervención manual
```

---

##### **Tabla de Comparación: Métodos SSL**

| Aspecto | Auto-Firmado | Let's Encrypt | Let's Encrypt + Symlinks |
|---|---|---|---|
| **Costo** | Gratis | Gratis | Gratis |
| **Validez** | 365 días | 90 días | 90 días |
| **Renovación** | Manual ❌ | Automática ✅ | Automática ✅ |
| **Certificado válido** | ⚠️ Advertencias | ✅ Válido | ✅ Válido |
| **Requiere dominio** | No | Sí | Sí |
| **Recomendado para** | Testing | Producción | Producción ✅ |
| **Complejidad** | Baja | Media | Media |
| **Mantenimiento** | Alto | Bajo | Mínimo ✅ |
| **Confianza** | Baja | Alta | Alta |



---

#### ⚙️ Renovación Automática de Certificados

**Certificados Let's Encrypt duran 90 días**, pero se renuevan automáticamente:

```bash
# Certbot crea automáticamente un timer/cron
# Verifica que esté habilitado:
sudo systemctl status certbot.timer

# O si usas crontab directamente:
sudo crontab -e

# Agrega esta línea para renovar automáticamente cada mes
0 3 1 * * certbot renew --quiet
```

---

#### ⚡ Troubleshooting: Errores Comunes y Soluciones

**ERROR 1: "could not load server certificate file \"server.crt\": No such file or directory"**

**Síntoma:**
```
FATAL: could not load server certificate file "server.crt": No such file or directory
```

**Causa:** Los symlinks están en el lugar incorrecto.

❌ INCORRECTO:
```bash
/etc/postgresql/15/main/server.crt → /etc/letsencrypt/live/.../fullchain.pem
```

PostgreSQL ejecuta como usuario `postgres` desde `/var/lib/postgresql/15/main/` y busca los archivos AHÍ, no en `/etc/postgresql/`.

✅ CORRECTO:
```bash
/var/lib/postgresql/15/main/server.crt → /etc/letsencrypt/live/.../fullchain.pem
```

**Solución:**
```bash
# Eliminar symlinks incorrectos
sudo rm /etc/postgresql/15/main/server.crt
sudo rm /etc/postgresql/15/main/server.key

# Crear en el lugar correcto
sudo ln -sf /etc/letsencrypt/live/postgres.ejaniot.com/fullchain.pem \
  /var/lib/postgresql/15/main/server.crt

sudo ln -sf /etc/letsencrypt/live/postgres.ejaniot.com/privkey.pem \
  /var/lib/postgresql/15/main/server.key

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

---

**ERROR 2: "Permission denied" al acceder a certificados de Let's Encrypt**

**Síntoma:**
```
FATAL: could not open file "/etc/letsencrypt/live/...: Permission denied
```

**Causa:** El usuario `postgres` no puede leer los directorios `/etc/letsencrypt/live/` o `/etc/letsencrypt/archive/` porque tienen permisos 700 (solo root).

**Solución:**
```bash
# Permitir lectura en directorios de letsencrypt
sudo chmod 755 /etc/letsencrypt/live
sudo chmod 755 /etc/letsencrypt/archive

# Asegurarse que postgres es dueño de los symlinks
sudo chown postgres:postgres /var/lib/postgresql/15/main/server.crt
sudo chown postgres:postgres /var/lib/postgresql/15/main/server.key

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

---

**ERROR 3: Conexión exitosa SIN SSL (no estás usando SSL aunque esté habilitado)**

**Síntoma:**
```
$ psql -h localhost -U vanessaapp -d vanessaapp_db
(conecta pero sin SSL)
```

**Causa:** PostgreSQL permite conexión sin SSL. Para OBLIGAR SSL:

**Solución (en pg_hba.conf):**

```bash
sudo nano /etc/postgresql/15/main/pg_hba.conf
```

```ini
# Para OBLIGAR SSL, usa "hostssl" en lugar de "host":
hostssl    all             vanessaapp      0.0.0.0/0               scram-sha-256
hostssl    all             vanessaapp      ::/0                    scram-sha-256

# Rechazar conexiones NO-SSL
host       all             vanessaapp      0.0.0.0/0               reject
host       all             vanessaapp      ::/0                    reject
```

Luego:
```bash
sudo systemctl restart postgresql

# Probar: debe fallar sin --sslmode=require
psql -h localhost -U vanessaapp -d vanessaapp_db
# Connection refused (porque no usamos SSL)

# Probar: debe conectar CON SSL
PGSSLMODE=require psql -h localhost -U vanessaapp -d vanessaapp_db
# Conecta exitosamente
```

---

**ERROR 4: Certificado no se actualiza después de renovación de Certbot**

**Síntoma:**
```
- Certbot renovó el certificado exitosamente
- Pero pgAdmin/clientes siguen mostrando certificado viejo
- O ves error "certificate signature expired"
```

**Causa:** Copiaste certificados a `/etc/postgresql/15/main/` en lugar de usar symlinks.

❌ INCORRECTO (los certificados quedan obsoletos):
```bash
sudo cp /etc/letsencrypt/live/.../fullchain.pem /etc/postgresql/15/main/server.crt
# Certbot renueva en /etc/letsencrypt/live/
# Pero la copia en /etc/postgresql/ no se actualiza ❌
```

✅ CORRECTO (siempre apunta al certificado actual):
```bash
sudo ln -sf /etc/letsencrypt/live/.../fullchain.pem \
  /var/lib/postgresql/15/main/server.crt
# Certbot actualiza /etc/letsencrypt/live/
# El symlink automáticamente apunta a la versión nueva ✅
```

**Solución:**
1. Eliminar los certificados copiados (si existen)
2. Crear symlinks (ver ERROR 1)
3. NO necesitas hacer nada cuando Certbot renueva

---

**ERROR 5: "pg_lsclusters" muestra "down" después de cambiar SSL**

**Síntoma:**
```
$ sudo pg_lsclusters
Ver Cluster Port Status Owner Data directory
15  main    5432 down   postgres /var/lib/postgresql/15/main
```

**Causa:** PostgreSQL no puede arrancar debido a error en SSL.

**Diagnóstico:**
```bash
# Ver el error exacto:
sudo tail -100 /var/log/postgresql/postgresql-15-main.log

# O iniciar manualmente para ver error en terminal:
sudo -u postgres /usr/lib/postgresql/15/bin/postgres \
  -D /var/lib/postgresql/15/main \
  -c config_file=/etc/postgresql/15/main/postgresql.conf
```

**Soluciones comunes según el error:**

Si dice "No such file or directory":
```bash
# Ver ERROR 1
```

Si dice "Permission denied":
```bash
# Ver ERROR 2
```

Si dice "invalid certificate" o "signature expired":
```bash
# Certbot renovó pero PostgreSQL lee certificado viejo
# Solución: Usar symlinks (ERROR 4)
# O reiniciar PostgreSQL después de renovar:
sudo systemctl restart postgresql
```

---

**ERROR 6: Certbot falla con "Could not start standalone TLS server"**

**Síntoma:**
```
Error starting standalone mode server
Could not start standalone TLS server at (0.0.0.0, 443)
```

**Causa:** 
- Puerto 443 ya está en uso
- O algo está escuchando en el puerto
- O PostgreSQL no está escuchando en 5432

**Solución:**
```bash
# Ver qué está usando el puerto 443
sudo ss -tlnp | grep 443
sudo ss -tlnp | grep 80

# Si Apache/Nginx está usando:
sudo systemctl stop apache2
sudo systemctl stop nginx

# O usar DNS validation en lugar de standalone (más complejo)

# O detener PostgreSQL temporalmente:
sudo systemctl stop postgresql

# Luego generar certificado
sudo certbot certonly --standalone -d postgres.ejaniot.com

# Reiniciar PostgreSQL
sudo systemctl start postgresql
```



---

#### Comparativa: Certificados Auto-firmados vs Let's Encrypt

| Característica | Auto-firmado | Let's Encrypt |
|---|---|---|
| **Costo** | Gratis ✅ | Gratis ✅ |
| **Validez** | 365 días (por defecto) | 90 días |
| **Automatización** | ❌ Manual | ✅ Automática |
| **Confianza** | ⚠️ Advertencias | ✅ Confiable |
| **Requiere dominio** | ❌ No | ✅ Sí |
| **Recomendado para** | Testing/Dev | Producción |
| **Renovación** | Tediosa | Automática |

---

#### Testear Conexión SSL

```bash
# Desde cliente Linux/Mac:
psql -h postgres.tudominio.com -U usuario_app -d mi_app --set=sslmode=require

# Debería conectar sin advertencias si usas Let's Encrypt
# Con certificado auto-firmado mostrará advertencia (normal)
```

---

#### ⚠️ Especial: Acceso con pgAdmin desde Casa y desde Internet

Si vas a usar **pgAdmin desde tu casa (red local) Y desde internet**, necesitas SSL **obligatoriamente**:

**En casa (red local):**
- ✅ No es crítico, red privada
- pgAdmin → PostgreSQL (192.168.1.10:5432)

**Desde internet (fuera de casa):**
- ❌ **CRÍTICO SIN SSL**: Tu contraseña viaja en texto plano
- ✅ **CON SSL**: Tu contraseña viaja encriptada

**Recomendación (la más segura):**

1. **Instala Let's Encrypt** (como se explicó arriba)
2. **En pgAdmin, configura así:**
   - **Host:** postgres.tudominio.com (tu dominio)
   - **Port:** 5432
   - **Username:** usuario_app
   - **Password:** tu_contraseña_fuerte
   - **SSL Mode:** require (obligatorio)

**Configuración en pgAdmin:**
```
Server → Properties → Connection
- Host name: postgres.tudominio.com
- Port: 5432
- Maintenance DB: postgres
- Username: usuario_app
- Password: [tu_contraseña]
- SSL Mode: require
```

**Desde casa también funcionará SSL:**
```
Server → Properties → Connection
- Host name: 192.168.1.10 (O usar el dominio también funciona)
- Port: 5432
- SSL Mode: require
```

**Alternativa aún más segura: SSH Tunnel en pgAdmin**

Si quieres máxima seguridad, usa SSH Tunnel:

1. **En pgAdmin → Connection → SSH Tunnel:**
   - Enable SSH tunneling: ✅
   - Tunnel host: tu_ip_publica
   - Tunnel port: 22 (SSH)
   - Username: usuario_ssh
   - Password: contraseña_ssh
   - Auth type: Password

2. **Connection:**
   - Host name: localhost (por el túnel)
   - Port: 5432
   - Username: usuario_app
   - Password: contraseña_bd

Así tu conexión va:
```
Tu máquina → SSH Tunnel (encriptado) → Servidor SSH → PostgreSQL
```

---

### SSH vs SSL/TLS - ¿Cuál es más fácil?

**Resumen rápido:**

| Aspecto | SSH Tunnel | SSL/TLS (Certificado) |
|---|---|---|
| **Facilidad inicial** | ⭐⭐⭐ Fácil | ⭐ Complicado |
| **Configuración** | Mínima | Media (Let's Encrypt) |
| **Automatización** | Manual cada vez | Automática (Let's Encrypt) |
| **Seguridad** | ✅ Excelente | ✅ Excelente |
| **Rendimiento** | Bueno (overhead mínimo) | Mejor (sin overhead) |
| **Mantenimiento** | Bajo | Bajo (con Let's Encrypt) |
| **Ideal para** | Dev/Admin remoto | Producción/Múltiples usuarios |
| **Curva de aprendizaje** | Baja | Media |

---

**¿Cuál elegir?**

#### 🔧 **SSH Tunnel - MÁS FÁCIL para ti como Admin**

**Ventajas:**
- ✅ Muy fácil de configurar
- ✅ No necesitas certificados
- ✅ Perfecto para acceso administrativo remoto
- ✅ Funciona en cualquier lugar sin configuración extra
- ✅ SSH ya está en tu servidor (seguro por defecto)

**Desventajas:**
- ❌ Solo para una o pocas personas
- ❌ Necesitas crear túnel manualmente cada vez
- ❌ No es práctico para aplicaciones/múltiples usuarios

**Cuándo usarlo:**
- Eres el único admin accediendo remotamente
- Trabajas desde diferentes lugares
- Quieres máxima seguridad sin complicaciones

**Cómo configurar (30 segundos):**
```bash
# Terminal en tu máquina local:
ssh -L 5432:localhost:5432 usuario@tu_ip_publica

# En otra terminal, conectas normalmente:
psql -h localhost -U usuario_app -d mi_app
```

---

#### 🔐 **SSL/TLS - MÁS CONVENIENTE para uso continuo**

**Ventajas:**
- ✅ Una sola configuración, funciona siempre
- ✅ Mejor para múltiples usuarios/aplicaciones
- ✅ pgAdmin se conecta automáticamente
- ✅ Let's Encrypt es gratis y automático
- ✅ Mejor rendimiento (sin overhead de túnel)

**Desventajas:**
- ❌ Requiere dominio
- ❌ Configuración inicial más compleja
- ❌ Necesitas renovar certificados (aunque Let's Encrypt lo hace automático)

**Cuándo usarlo:**
- Tu aplicación se conecta remotamente
- Múltiples personas acceden a PostgreSQL
- Es producción y quieres estabilidad
- Quieres pgAdmin funcionando sin trucos

**Cómo configurar (5-10 minutos con Let's Encrypt):**
```bash
# Instalar Certbot
sudo apt install -y certbot

# Generar certificado (una sola vez)
sudo certbot certonly --standalone -d postgres.tudominio.com

# Copiar a PostgreSQL y configurar
# (una sola vez, luego se renueva automático)
```

---

#### 📋 **MI RECOMENDACIÓN PARA TI**

**Como eres un ADMIN remoto (tu caso):**

1. **Fase 1 (Rápido - ahora):** Usa **SSH Tunnel**
   ```bash
   ssh -L 5432:localhost:5432 usuario@tu_ip_publica
   ```
   - Es lo más fácil
   - No necesitas nada extra
   - Funciona desde casa o desde la calle
   - Seguridad garantizada

2. **Fase 2 (Producción - después):** Agrega **SSL/TLS con Let's Encrypt**
   - Cuando tengas aplicaciones conectándose
   - Cuando haya múltiples usuarios
   - Cuando quieras pgAdmin funcionando siempre

---

#### ⚡ **Configurar SSH Tunnel en 2 pasos**

**Paso 1: Desde tu máquina (macOS/Linux/WSL):**
```bash
ssh -L 5432:localhost:5432 usuario@tu_ip_publica
# Ingresa contraseña SSH (está encriptada ✅)
```

**Paso 2: En otra terminal, conecta normalmente:**
```bash
# pgAdmin GUI
# Host: localhost
# Port: 5432
# Username: usuario_app
# Password: tu_contraseña_bd

# O desde línea de comandos:
psql -h localhost -U usuario_app -d mi_app
```

**¿Y desde Windows?**

Opción A - WSL (Windows Subsystem for Linux):
```bash
# En WSL terminal:
ssh -L 5432:localhost:5432 usuario@tu_ip_publica
```

Opción B - PuTTY (cliente SSH gráfico):
1. Abre PuTTY
2. Connection → SSH → Tunnels
3. Source port: 5432
4. Destination: localhost:5432
5. Add
6. Open (conecta por SSH)
7. En pgAdmin: localhost:5432

---

#### 🎯 **Resumen final**

**Para tu caso (admin remoto desde casa/calle):**

| Tarea | Recomendación |
|---|---|
| **Conectar desde casa** | SSH Tunnel ✅ |
| **Conectar desde calle** | SSH Tunnel ✅ |
| **pgAdmin ocasional** | SSH Tunnel ✅ |
| **Aplicación conectada 24/7** | SSL/TLS ✅ |
| **Múltiples aplicaciones** | SSL/TLS ✅ |
| **Máxima facilidad ahora** | SSH Tunnel ✅ |

**Lo ideal:** Empieza con SSH Tunnel (es lo más fácil), y cuando tengas aplicaciones en producción, agrega SSL/TLS.

---

## 📊 Gestión de Bases de Datos

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

#### ⚠️ Observación Importante: Casos de Letra en PostgreSQL

**PostgreSQL convierte automáticamente los nombres de usuario y BD a minúsculas:**

- `CREATE USER VanessaAPP` se crea como `vanessaapp`
- `CREATE DATABASE VanessaAPP_DB` se crea como `vanessaapp_db`
- **Las contraseñas SÍ preservan mayúsculas/minúsculas**

Para forzar mayúsculas, usa comillas dobles: `CREATE USER "VanessaAPP"`

**Recomendación:** Usa minúsculas directamente para evitar confusiones. Es la convención estándar en PostgreSQL.

---

#### Paso 1: Crear el Usuario en PostgreSQL

```bash
sudo -u postgres psql

# Crear usuario con contraseña segura (se crea como "vanessaapp")
CREATE USER vanessaapp WITH PASSWORD 'contraseña segura';

# Listar usuarios
\du

\q
```

---

#### Paso 2: Crear Base de Datos y Asignar Permisos

```bash
sudo -u postgres psql

# Crear bases de datos (se crean en minúsculas automáticamente)
CREATE DATABASE seguridadvanessaapp_db OWNER vanessaapp;
CREATE DATABASE vanessaapp_db OWNER vanessaapp;

# Asignar permisos específicos
GRANT CONNECT ON DATABASE seguridadvanessaapp_db TO vanessaapp;
GRANT CONNECT ON DATABASE vanessaapp_db TO vanessaapp;
GRANT USAGE, CREATE ON SCHEMA public TO vanessaapp;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO vanessaapp;

# Listar bases de datos
\l

\q
```

---

#### Paso 3: Permitir Conexión Remota en pg_hba.conf

**Edita el archivo de control de acceso:**

```bash
sudo nano /etc/postgresql/15/main/pg_hba.conf
```

**Agrega estas líneas ANTES de las líneas genéricas (si existen):**

```ini
# ⚠️ SECURITY: Rechazar usuario postgres desde internet
host    postgres        postgres        0.0.0.0/0               reject
host    postgres        postgres        ::/0                    reject

# ✅ REMOTE: Permitir usuario vanessaapp desde cualquier IP
host    all             vanessaapp      0.0.0.0/0               scram-sha-256
host    all             vanessaapp      ::/0                    scram-sha-256

# ⛔ DEFENSA FINAL: Rechazar todo lo demás
host    all             all             0.0.0.0/0               reject
host    all             all             ::/0                    reject
```

**Explicación de cada línea:**
| Parámetro | Significa |
|---|---|
| `host` | Conexión TCP/IP remota |
| `postgres` / `VanessaAPP` | Usuario específico |
| `0.0.0.0/0` | Cualquier IPv4 |
| `::/0` | Cualquier IPv6 |
| `scram-sha-256` | Autenticación con contraseña (segura) |
| `reject` | Rechazar conexión |

**Guarda:** `Ctrl+O`, Enter, `Ctrl+X`

---

#### Paso 4: Reiniciar PostgreSQL y Verificar

```bash
# Reiniciar servicio
sudo systemctl restart postgresql

# Verificar estado
sudo systemctl status postgresql

# Ver que escucha en puerto 5432
sudo ss -tlnp | grep 5432
```

---

#### Paso 5: Probar Conexión Remota

**Desde otra máquina en la red local:**

```bash
# Conectar con el usuario vanessaapp (minúsculas)
psql -h 192.168.1.X -U vanessaapp -d vanessaapp_db
# Ingresa contraseña: contraseña segura
```

**Desde pgAdmin (GUI):**
1. File → Add New Server
2. Connection:
   - Host name: `192.168.1.X` (IP del servidor)
   - Port: `5432`
   - Username: `vanessaapp` (minúsculas)
   - Password: `contraseña segura`
   - Database: `vanessaapp_db` (minúsculas)
3. Save

---

#### Resumen del Flujo Completo

```bash
# 1. Crear usuario (se crea como "vanessaapp")
CREATE USER vanessaapp WITH PASSWORD 'contraseña segura';

# 2. Crear bases de datos (se crean como "seguridadvanessaapp_db" y "vanessaapp_db")
CREATE DATABASE seguridadvanessaapp_db OWNER vanessaapp;
CREATE DATABASE vanessaapp_db OWNER vanessaapp;

# 3. Asignar permisos
GRANT CONNECT ON DATABASE seguridadvanessaapp_db TO vanessaapp;
GRANT CONNECT ON DATABASE vanessaapp_db TO vanessaapp;
GRANT USAGE, CREATE ON SCHEMA public TO vanessaapp;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO vanessaapp;

# 4. Agregar en pg_hba.conf (permitir conexión remota)
# host    all    vanessaapp    0.0.0.0/0    scram-sha-256

# 5. Reiniciar PostgreSQL
sudo systemctl restart postgresql

# 6. ¡Listo! Conectar desde otra máquina
psql -h tu_ip_servidor -U vanessaapp -d vanessaapp_db
```

---

## 📋 INFORME FINAL: Configuración Segura PostgreSQL 15

### ✅ Arquitectura Implementada

**Componentes:**
1. **Servidor PostgreSQL:** 192.168.1.102:5432 (red local)
2. **Usuarios:** postgres (admin local), vanessaapp (app remota)
3. **Bases de datos:** vanessaapp_db, seguridadvanessaapp_db
4. **Port Forwarding:** Movistar (15432 → 5432)
5. **Firewall:** UFW habilitado

---

### ✅ Orden Correcto de pg_hba.conf (CRÍTICO)

**Regla: PostgreSQL evalúa de arriba a abajo. La primera que coincide se aplica.**

**Configuración correcta:**

```ini
# 1️⃣ PRIMERO: Permitir postgres SOLO desde red local
host    all             postgres        192.168.1.0/24          scram-sha-256

# 2️⃣ SEGUNDO: Rechazar postgres desde internet
host    postgres        postgres        0.0.0.0/0               reject
host    postgres        postgres        ::/0                    reject

# 3️⃣ TERCERO: Permitir vanessaapp desde cualquier IP
host    all             vanessaapp      0.0.0.0/0               scram-sha-256
host    all             vanessaapp      ::/0                    scram-sha-256

# 4️⃣ CUARTO: Rechazar todo lo demás
host    all             all             0.0.0.0/0               reject
host    all             all             ::/0                    reject
```

**¿Por qué este orden?**
- Si primero está el rechazo de postgres, rechaza ANTES de permitir desde local
- Las líneas más específicas deben ir ANTES que las genéricas
- Ejemplo: permitir desde 192.168.1.0/24 ANTES que rechazar desde 0.0.0.0/0

---

### ✅ Convención: Todo en Minúsculas

PostgreSQL convierte automáticamente los nombres a minúsculas:

```sql
CREATE USER VanessaAPP → Se crea como vanessaapp
CREATE DATABASE VanessaAPP_DB → Se crea como vanessaapp_db
```

**Conexiones siempre con minúsculas:**
```bash
psql -h 192.168.1.102 -U vanessaapp -d vanessaapp_db
# NO: psql -h 192.168.1.102 -U VanessaAPP -d VanessaAPP_DB ❌
```

---

### ✅ Matriz de Acceso

| Usuario | Origen | Método | Acceso |
|---|---|---|---|
| `postgres` | Red local (192.168.1.0/24) | scram-sha-256 | ✅ PERMITIDO |
| `postgres` | Internet (0.0.0.0/0) | - | ❌ BLOQUEADO |
| `vanessaapp` | Red local (192.168.1.0/24) | scram-sha-256 | ✅ PERMITIDO |
| `vanessaapp` | Internet (0.0.0.0/0) | scram-sha-256 | ✅ PERMITIDO |
| Otros usuarios | Cualquier lugar | - | ❌ BLOQUEADO |

---

### ✅ Flujos de Conexión

#### Escenario 1: Admin desde Casa
```
Tu PC (192.168.1.100)
  ↓
pgAdmin (GUI)
  ↓
Servidor PostgreSQL (192.168.1.102:5432)
  ↓
Usuario: postgres
Base de datos: postgres
SSL Mode: disable
Resultado: ✅ CONECTA
```

#### Escenario 2: Aplicación desde Internet
```
Servidor/App Externa (IP pública)
  ↓
Internet
  ↓
Modem Movistar (Port Forwarding 15432 → 5432)
  ↓
Servidor PostgreSQL (192.168.1.102:5432)
  ↓
Usuario: vanessaapp
Base de datos: vanessaapp_db
SSL Mode: disable
Resultado: ✅ CONECTA
```

#### Escenario 3: Intento de Ataque
```
Atacante (IP pública)
  ↓
Internet
  ↓
Modem Movistar (15432)
  ↓
Servidor PostgreSQL
  ↓
Usuario: postgres (INTENTADO)
Base de datos: postgres
Resultado: ❌ BLOQUEADO por pg_hba.conf
```

---

### ✅ Seguridad Implementada

| Componente | Medida |
|---|---|
| **Usuario postgres** | Restringido solo a red local |
| **Usuario vanessaapp** | Autenticación scram-sha-256 |
| **Bases de datos** | Propiedad asignada por usuario |
| **Firewall** | UFW abierto solo para 5432 |
| **Port Forwarding** | Movistar (puerto no-estándar 15432) |
| **Contraseñas** | Mínimo 16 caracteres |
| **Defensa final** | Rechazo explícito de todas las demás conexiones |

---

### ✅ Testing Realizado

**Prueba 1: postgres desde local (esperado: conecta)**
```bash
psql -h 192.168.1.102 -U postgres -d postgres
Resultado: ✅ FUNCIONA
```

**Prueba 2: vanessaapp desde local (esperado: conecta)**
```bash
psql -h 192.168.1.102 -U vanessaapp -d vanessaapp_db
Resultado: ✅ FUNCIONA
```

**Prueba 3: postgres desde internet (esperado: rechazado)**
```bash
psql -h tu_ip_publica -p 15432 -U postgres -d postgres
Resultado: ❌ pg_hba.conf rejects connection (ESPERADO)
```

**Prueba 4: vanessaapp desde internet (esperado: conecta)**
```bash
psql -h tu_ip_publica -p 15432 -U vanessaapp -d vanessaapp_db
Resultado: ✅ FUNCIONA (una vez que port forwarding está activo)
```

---

### ✅ Errores Comunes y Soluciones

**Error: "pg_hba.conf rejects connection"**
- Causa: Orden incorrecto de líneas en pg_hba.conf
- Solución: Verificar que líneas de PERMISO están ANTES que de RECHAZO

**Error: "database does not exist"**
- Causa: Nombres en mayúsculas (VanessaAPP_DB en lugar de vanessaapp_db)
- Solución: Usar siempre minúsculas en conexiones

**Error: "SSL encryption required"** (en pgAdmin)
- Causa: pgAdmin intenta SSL pero servidor no lo requiere
- Solución: Cambiar "SSL Mode" a "disable" en pgAdmin

**Error: "could not load server certificate file"**
- Causa: Certificados en lugar incorrecto (`/etc/postgresql/15/main/` en lugar de `/var/lib/postgresql/15/main/`)
- Solución: Crear symlinks en `/var/lib/postgresql/15/main/` como se explicó en sección SSL

**Error: "permission denied" en certificados de Let's Encrypt**
- Causa: Usuario `postgres` no puede acceder a `/etc/letsencrypt/`
- Solución: Usar symlinks y dar permisos 755 a directorios `/etc/letsencrypt/`

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

---

## 🔐 SSL/TLS - Configuración Completa y Verificación

### ✅ Verificar que SSL está Habilitado en PostgreSQL

```bash
# Conectar localmente
sudo -u postgres psql -c "SHOW ssl;"
# Debe mostrar: on

# Ver detalles de protocolo SSL
PGSSLMODE=require psql -h localhost -U vanessaapp -d vanessaapp_db -c "SELECT version();"
```

Si conectas y ves algo como:
```
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
```

✅ **SSL está funcionando correctamente**

---

### ✅ Actualizar pgAdmin para Usar SSL

**Desde casa (red local):**

Si pgAdmin está en la red local (192.168.1.X):

1. En pgAdmin → Server → Properties
2. Connection:
   - Host name: `192.168.1.10` (IP local)
   - Port: `5432`
   - SSL Mode: `disable` o `prefer`
   - Username: `postgres` o `vanessaapp`
3. Save

---

**Desde internet (IP pública):**

Si accedes desde fuera de la red:

1. En pgAdmin → Server → Properties
2. Connection:
   - Host name: `postgres.tudominio.com` (Tu dominio)
   - Port: `15432` (tu puerto forwarded)
   - SSL Mode: `require` ✅ (OBLIGATORIO)
   - Username: `vanessaapp`
   - Password: `tu_contraseña`
3. Save

**⚠️ IMPORTANTE:** Con SSL obligatorio (`require`), pgAdmin rechazará cualquier conexión sin encriptación. Esto es lo que queremos para internet.

---

### ✅ Estructura Final de Certificados (Correcto)

```
/etc/letsencrypt/
├── live/
│   └── postgres.tudominio.com/
│       ├── fullchain.pem (certificado + chain)
│       └── privkey.pem (clave privada)
└── archive/
    └── postgres.tudominio.com/
        ├── cert1.pem
        ├── chain1.pem
        ├── fullchain1.pem
        └── privkey1.pem

/var/lib/postgresql/15/main/
├── server.crt → /etc/letsencrypt/live/postgres.tudominio.com/fullchain.pem
├── server.key → /etc/letsencrypt/live/postgres.tudominio.com/privkey.pem
└── ... (otros archivos de PostgreSQL)
```

**Nunca coloques certificados en `/etc/postgresql/15/main/`**
- PostgreSQL ejecuta como usuario `postgres`
- Los directorios en `/etc/postgresql/` tienen permisos muy restrictivos
- Los symlinks en `/var/lib/postgresql/15/main/` **siempre funcionan correctamente**

---

### ✅ Checklist SSL/TLS Final

- [ ] Let's Encrypt certificado generado: `certbot certonly --standalone -d postgres.tudominio.com`
- [ ] Symlinks creados en `/var/lib/postgresql/15/main/server.{crt,key}`
- [ ] Permisos en `/etc/letsencrypt/{live,archive}` son 755
- [ ] PostgreSQL configurado: `ssl = on` en `postgresql.conf`
- [ ] PostgreSQL reiniciado: `sudo systemctl restart postgresql`
- [ ] Prueba local funciona: `PGSSLMODE=require psql -h localhost ...`
- [ ] Prueba remota funciona: `PGSSLMODE=require psql -h postgres.tudominio.com ...`
- [ ] pgAdmin SSL Mode actualizado a `require` para conexiones remotas
- [ ] Renovación automática configurada en Certbot
- [ ] Logs de PostgreSQL sin errores de certificado

---



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

**¡Tu PostgreSQL 15 está listo para producción! By:SrJaniot  🎉**
