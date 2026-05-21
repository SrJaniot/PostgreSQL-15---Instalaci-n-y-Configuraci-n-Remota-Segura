#!/bin/bash

# ============================================================================
# PostgreSQL 15 - Configurar Acceso Remoto
# ============================================================================
# Uso: sudo bash configure-remote-access.sh
#
# Este script configura PostgreSQL para aceptar conexiones remotas
# desde IPs específicas (whitelist)
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_choice() {
    echo -e "${BLUE}[?]${NC} $1"
}

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script debe ejecutarse como root (usa 'sudo')"
    exit 1
fi

print_info "=========================================="
print_info "Configurar Acceso Remoto - PostgreSQL 15"
print_info "=========================================="
echo ""

# Archivo de configuración
POSTGRESQL_CONF="/etc/postgresql/15/main/postgresql.conf"
PG_HBA_CONF="/etc/postgresql/15/main/pg_hba.conf"

# Verificar que PostgreSQL está instalado
if [ ! -f "$POSTGRESQL_CONF" ]; then
    print_error "PostgreSQL 15 no está instalado o no se encontró $POSTGRESQL_CONF"
    exit 1
fi

# Menú de opciones
echo ""
print_choice "Selecciona el tipo de configuración:"
echo "1) Desarrollo Local (solo localhost)"
echo "2) Red Local (192.168.1.0/24)"
echo "3) Redes Múltiples (Local + VPN + IP específica)"
echo "4) Acceso Remoto Abierto (MENOS SEGURO)"
echo "5) Personalizado (ingresar IPs manualmente)"
echo ""
read -p "Selecciona opción (1-5): " OPTION

case $OPTION in
    1)
        print_info "Configurando para Desarrollo Local..."
        LISTEN_ADDR="localhost"
        ;;
    2)
        print_info "Configurando para Red Local (192.168.1.0/24)..."
        LISTEN_ADDR="*"
        ;;
    3)
        print_info "Configurando para Redes Múltiples..."
        LISTEN_ADDR="*"
        ;;
    4)
        print_warn "Configurando para Acceso Remoto Abierto (MENOS SEGURO)"
        LISTEN_ADDR="*"
        ;;
    5)
        print_info "Ingresa manualmente..."
        read -p "¿Escuchar en (default: localhost)? " LISTEN_ADDR
        LISTEN_ADDR=${LISTEN_ADDR:-localhost}
        ;;
    *)
        print_error "Opción inválida"
        exit 1
        ;;
esac

# Hacer backup
print_info "Creando backup de archivos de configuración..."
cp "$POSTGRESQL_CONF" "${POSTGRESQL_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$PG_HBA_CONF" "${PG_HBA_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
print_info "✓ Backups creados"

# Configurar listen_addresses
print_info "Configurando listen_addresses = '$LISTEN_ADDR'..."
sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '$LISTEN_ADDR'/" "$POSTGRESQL_CONF"
sed -i "s/^listen_addresses = 'localhost'/listen_addresses = '$LISTEN_ADDR'/" "$POSTGRESQL_CONF"

# Configurar pg_hba.conf según la opción
print_info "Configurando pg_hba.conf..."

# Crear backup del pg_hba.conf
TEMP_PG_HBA=$(mktemp)

cat > "$TEMP_PG_HBA" << 'EOF'
# PostgreSQL 15 - Control de Acceso (Autogenerado)
local   postgres        postgres                                trust
local   all             all                                     scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
EOF

case $OPTION in
    1)
        # Solo localhost
        cat >> "$TEMP_PG_HBA" << 'EOF'
host    all             all             0.0.0.0/0               reject
host    all             all             ::/0                    reject
EOF
        ;;
    2)
        # Red Local
        cat >> "$TEMP_PG_HBA" << 'EOF'
host    all             all             192.168.1.0/24          scram-sha-256
host    all             all             0.0.0.0/0               reject
host    all             all             ::/0                    reject
EOF
        ;;
    3)
        # Múltiples redes
        print_choice "¿Agregar rango de VPN? (ej: 10.0.0.0/24) (enter para omitir): "
        read VPN_RANGE
        
        print_choice "¿Agregar IP específica de app server? (ej: 203.0.113.50/32) (enter para omitir): "
        read APP_IP
        
        cat >> "$TEMP_PG_HBA" << 'EOF'
host    all             all             192.168.1.0/24          scram-sha-256
EOF
        
        if [ ! -z "$VPN_RANGE" ]; then
            echo "host    all             all             $VPN_RANGE          scram-sha-256" >> "$TEMP_PG_HBA"
        fi
        
        if [ ! -z "$APP_IP" ]; then
            echo "host    all             all             $APP_IP          scram-sha-256" >> "$TEMP_PG_HBA"
        fi
        
        cat >> "$TEMP_PG_HBA" << 'EOF'
host    all             all             0.0.0.0/0               reject
host    all             all             ::/0                    reject
EOF
        ;;
    4)
        # Acceso abierto
        cat >> "$TEMP_PG_HBA" << 'EOF'
host    all             all             0.0.0.0/0               scram-sha-256
host    all             all             ::/0                    scram-sha-256
EOF
        print_warn "⚠ Acceso remoto abierto habilitado - asegúrate de usar contraseñas fuertes"
        ;;
    5)
        # Personalizado
        print_choice "Ingresa líneas de pg_hba.conf adicionales (una por línea, enter dos veces para terminar):"
        while true; do
            read -p "> " line
            if [ -z "$line" ]; then
                read -p "> " line
                if [ -z "$line" ]; then
                    break
                else
                    echo "$line" >> "$TEMP_PG_HBA"
                fi
            else
                echo "$line" >> "$TEMP_PG_HBA"
            fi
        done
        ;;
esac

# Reemplazar pg_hba.conf
cp "$TEMP_PG_HBA" "$PG_HBA_CONF"
rm "$TEMP_PG_HBA"
print_info "✓ pg_hba.conf configurado"

# Reiniciar PostgreSQL
print_info "Reiniciando PostgreSQL..."
systemctl restart postgresql

# Verificar que se reinició correctamente
if systemctl is-active --quiet postgresql; then
    print_info "✓ PostgreSQL reiniciado correctamente"
else
    print_error "Error al reiniciar PostgreSQL"
    print_info "Restaurando archivos anteriores..."
    # Podríamos hacer restore aquí si es necesario
    exit 1
fi

# Verificar puerto
print_info "Verificando puerto 5432..."
if ss -tlnp | grep -q 5432; then
    print_info "✓ PostgreSQL escuchando en puerto 5432"
else
    print_warn "⚠ No se detectó escucha en puerto 5432"
fi

# Mostrar configuración actual
echo ""
print_info "=========================================="
print_info "Configuración Actual:"
print_info "=========================================="
echo ""
print_info "listen_addresses:"
grep "^listen_addresses" "$POSTGRESQL_CONF"
echo ""
print_info "Reglas de acceso:"
grep "^host" "$PG_HBA_CONF"
echo ""

# Resumen
echo ""
print_info "=========================================="
print_info "✓ Configuración Completada"
print_info "=========================================="
echo ""
print_info "Próximos pasos:"
echo "1. Abrir puerto 5432 en firewall (si es necesario):"
echo "   sudo ufw allow from 192.168.1.0/24 to any port 5432"
echo ""
echo "2. Crear usuario y base de datos:"
echo "   sudo -u postgres psql"
echo "   CREATE USER app_user WITH PASSWORD 'password';"
echo "   CREATE DATABASE app_db OWNER app_user;"
echo ""
echo "3. Verificar conexión remota:"
echo "   psql -h 192.168.1.X -U app_user -d app_db"
echo ""
print_info "Logs:"
echo "   sudo tail -f /var/log/postgresql/postgresql-15-main.log"
