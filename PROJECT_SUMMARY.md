# PostgreSQL 15 - Guía de Instalación y Configuración Remota Segura

## 📂 Archivos del Proyecto

### 📄 README.md
**Guía completa y detallada** que incluye:
- Introducción y requisitos
- Instalación paso a paso (Ubuntu/Debian)
- Habilitación de acceso remoto con múltiples configuraciones
- Seguridad y buenas prácticas
- Gestión de bases de datos y usuarios
- Backup y restore
- Monitoreo
- FAQ extendido
- Troubleshooting

### 🔧 Scripts Automáticos

#### `install-postgres.sh`
- Instalación automática de PostgreSQL 15
- Configuración de repositorio oficial
- Activación automática del servicio
- Configuración de usuario postgres

**Uso:**
```bash
sudo bash install-postgres.sh
```

#### `configure-remote-access.sh`
- Menú interactivo para configuración remota
- 5 opciones predefinidas:
  1. Desarrollo local
  2. Red local
  3. Redes múltiples
  4. Acceso abierto
  5. Personalizado
- Backup automático de configuración
- Validación después de cambios

**Uso:**
```bash
sudo bash configure-remote-access.sh
```

#### `backup.sh`
- Backup completo o parcial
- Múltiples formatos (SQL, gzip, bzip2, dump)
- Limpieza automática de backups antiguos
- Verificación de integridad
- Restauración desde backup

**Uso:**
```bash
# Backup automático (todas las BDs + limpieza)
bash backup.sh

# Backup específico
bash backup.sh database nombre_bd

# Listar backups
bash backup.sh list

# Restaurar
bash backup.sh restore /path/to/backup.sql.gz
```

### 📋 Archivos de Configuración Ejemplo

#### `postgresql.conf.example`
Configuración de PostgreSQL con:
- Parámetros de red
- Configuración de memoria
- Logs
- SSL/TLS
- Performance tuning
- Replicación
- Ejemplos comentados

#### `pg_hba.conf.example`
Control de acceso con 6 configuraciones predefinidas:
1. Solo local
2. Red local privada
3. Múltiples redes con restricción por usuario
4. Acceso remoto abierto
5. Alta seguridad con SSL obligatorio
6. Múltiples aplicaciones con usuarios diferentes

## 🚀 Inicio Rápido

### 1. Instalación (5 minutos)
```bash
sudo bash install-postgres.sh
```

### 2. Configurar Acceso Remoto
```bash
sudo bash configure-remote-access.sh
# Selecciona la opción que necesites (1-5)
```

### 3. Crear Usuario y BD
```bash
sudo -u postgres psql

CREATE USER app_user WITH PASSWORD 'contraseña_fuerte';
CREATE DATABASE app_db OWNER app_user;
\q
```

### 4. Probar Conexión Remota
```bash
# Desde otra máquina
psql -h 192.168.1.10 -U app_user -d app_db
```

### 5. Configurar Backup Automático
```bash
# Editar crontab
sudo crontab -e

# Agregar línea (backup diario a las 2 AM)
0 2 * * * /path/to/backup.sh >> /var/log/postgres-backup.log 2>&1
```

## 🔒 Seguridad - Recomendaciones Principales

✅ **HACER:**
- Usar contraseñas fuertes (16+ caracteres)
- Crear usuarios específicos con permisos limitados
- Usar `scram-sha-256` en pg_hba.conf
- Mantener backups regulares
- Actualizar PostgreSQL regularmente
- Usar firewall y restringir IPs
- Monitorear logs regularmente

❌ **NO HACER:**
- Usar usuario `postgres` para aplicaciones
- Permitir acceso sin autenticación (trust)
- Exponer Puerto 5432 directamente a internet
- Usar contraseña del SO como contraseña DB
- Olvidar de hacer backups
- Ignorar updates de seguridad

## 📊 Contenido del README.md

El archivo README.md es una **guía profesional de 2000+ líneas** que cubre:

1. **Introducción** - ¿Qué es PostgreSQL? ¿Por qué usarlo?

2. **Instalación Rápida** - Comandos paso a paso para Ubuntu/Debian

3. **Acceso Remoto Detallado**
   - Editar postgresql.conf
   - Editar pg_hba.conf
   - Configurar firewall
   - Reiniciar servicios

4. **Seguridad**
   - Cambiar contraseñas
   - Crear usuarios con permisos limitados
   - Autenticación MD5 vs SCRAM-SHA-256
   - SSL/TLS

5. **Gestión de BD**
   - Crear bases de datos
   - Crear usuarios
   - Asignar permisos

6. **Conexiones Remotas**
   - Desde cliente Linux/Mac
   - Desde Windows con pgAdmin

7. **Backup y Restore**
   - Backup manual
   - Backup automático
   - Restauración

8. **Monitoreo**
   - Conexiones activas
   - Tamaño de BD/tablas
   - Logs en tiempo real

9. **FAQ** - 8 preguntas frecuentes respondidas

10. **Troubleshooting** - Solución de 5+ problemas comunes

11. **Conceptos Clave** - Explicaciones de términos técnicos

## 🎯 Casos de Uso

### Caso 1: Desarrollo Local
```bash
# Instalación
sudo bash install-postgres.sh

# Opción 1 en configure-remote-access.sh
# Solo localhost - no necesita contraseña
```

### Caso 2: Empresa Pequeña
```bash
# Instalación
sudo bash install-postgres.sh

# Opción 2 en configure-remote-access.sh
# Red local 192.168.1.0/24
# Todos los empleados pueden conectar

# Crear usuario para aplicación
sudo -u postgres psql
CREATE USER empresa_user WITH PASSWORD 'Str0ng!Pass123';
CREATE DATABASE empresa_db OWNER empresa_user;
```

### Caso 3: Producción Segura
```bash
# Instalación
sudo bash install-postgres.sh

# Opción 3 en configure-remote-access.sh
# Agregar red local + VPN + IP específica de app server

# Crear usuario limitado
sudo -u postgres psql
CREATE USER app_prod WITH PASSWORD 'Ver1Secure!Pass@2026';
CREATE DATABASE prod_db OWNER app_prod;
GRANT CONNECT ON DATABASE prod_db TO app_prod;
GRANT USAGE ON SCHEMA public TO app_prod;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_prod;

# Configurar SSL
# (Ver README.md sección "Usar SSL/TLS")

# Backup automático
sudo crontab -e
# Agregar línea de backup
```

### Caso 4: Múltiples Aplicaciones
```bash
# Instalación
sudo bash install-postgres.sh

# Opción 6 (personalizado) en configure-remote-access.sh

# Crear usuarios y BDs por aplicación
sudo -u postgres psql

CREATE USER app1_user WITH PASSWORD 'Pass1!@2026';
CREATE DATABASE app1_db OWNER app1_user;

CREATE USER app2_user WITH PASSWORD 'Pass2!@2026';
CREATE DATABASE app2_db OWNER app2_user;

# Editar pg_hba.conf para permitir cada app desde su IP
sudo nano /etc/postgresql/15/main/pg_hba.conf
# host app1_db app1_user 192.168.1.100/32 scram-sha-256
# host app2_db app2_user 192.168.1.101/32 scram-sha-256
```

## 📞 Soporte y Recursos

- **Documentación Oficial**: https://www.postgresql.org/docs/15/
- **Comunidad**: https://www.postgresql.org/community/
- **Herramientas Gráficas**: 
  - pgAdmin: https://www.pgadmin.org/
  - DBeaver: https://dbeaver.io/

## ✅ Checklist de Instalación

- [ ] Servidor Linux actualizado
- [ ] PostgreSQL 15 instalado
- [ ] Usuario postgres con contraseña segura
- [ ] postgresql.conf configurado (listen_addresses)
- [ ] pg_hba.conf configurado (acceso remoto)
- [ ] Firewall configurado
- [ ] Usuario/BD de aplicación creado
- [ ] Conexión remota probada
- [ ] Backup automático configurado
- [ ] Logs monitoreados
- [ ] Backups verificados

## 🎓 Próximos Pasos

Después de instalación básica:

1. **Optimizar Performance**
   - Editar postgresql.conf con valores ajustados a tu servidor
   - Crear índices en tablas grandes
   - Usar VACUUM ANALYZE regularmente

2. **Alta Disponibilidad**
   - Configurar replicación
   - Configurar failover automático

3. **Monitoreo Avanzado**
   - Instalar prometheus + grafana
   - Configurar alertas

4. **Seguridad Avanzada**
   - Implementar row-level security
   - Usar encryption columnar

---

**¡Tu PostgreSQL 15 está listo! Comienza con `sudo bash install-postgres.sh` 🎉**
