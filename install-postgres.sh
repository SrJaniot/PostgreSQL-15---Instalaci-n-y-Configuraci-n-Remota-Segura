#!/bin/bash

# ============================================================================
# PostgreSQL 15 - Script de Instalación Automática
# ============================================================================
# Uso: sudo bash install-postgres.sh
# 
# Este script instala PostgreSQL 15 automáticamente en Ubuntu/Debian
# y realiza configuraciones básicas de seguridad.
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones auxiliares
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
    print_error "Este script debe ejecutarse como root (usa 'sudo')"
    exit 1
fi

print_info "=========================================="
print_info "Instalación de PostgreSQL 15"
print_info "=========================================="

# Paso 1: Actualizar sistema
print_info "Paso 1: Actualizando el sistema..."
apt update
apt upgrade -y

# Paso 2: Instalar dependencias
print_info "Paso 2: Instalando dependencias..."
apt install -y wget curl gnupg2 lsb-release

# Paso 3: Agregar repositorio oficial de PostgreSQL
print_info "Paso 3: Agregando repositorio oficial de PostgreSQL..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Paso 4: Importar clave GPG
print_info "Paso 4: Importando clave GPG..."
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Paso 5: Instalar PostgreSQL 15
print_info "Paso 5: Instalando PostgreSQL 15..."
apt update
apt install -y postgresql-15 postgresql-contrib-15

# Paso 6: Iniciar servicio
print_info "Paso 6: Iniciando PostgreSQL..."
systemctl start postgresql
systemctl enable postgresql

# Paso 7: Verificar instalación
print_info "Paso 7: Verificando instalación..."
PG_VERSION=$(sudo -u postgres psql --version 2>/dev/null)
if [ $? -eq 0 ]; then
    print_info "✓ PostgreSQL instalado: $PG_VERSION"
else
    print_error "La instalación falló"
    exit 1
fi

# Paso 8: Crear usuario postgres con contraseña
print_info "Paso 8: Configurando contraseña para usuario postgres..."
read -sp "Ingresa contraseña para usuario 'postgres': " POSTGRES_PASSWORD
echo ""
read -sp "Confirma contraseña: " POSTGRES_PASSWORD_CONFIRM
echo ""

if [ "$POSTGRES_PASSWORD" != "$POSTGRES_PASSWORD_CONFIRM" ]; then
    print_error "Las contraseñas no coinciden"
    exit 1
fi

sudo -u postgres psql <<EOF
\password postgres
EOF

# Paso 9: Verificar estado del servicio
print_info "Paso 9: Verificando estado del servicio..."
systemctl status postgresql --no-pager

# Resumen
echo ""
print_info "=========================================="
print_info "✓ Instalación completada"
print_info "=========================================="
echo ""
print_info "Próximos pasos:"
echo "1. Editar postgresql.conf:"
echo "   sudo nano /etc/postgresql/15/main/postgresql.conf"
echo ""
echo "2. Editar pg_hba.conf:"
echo "   sudo nano /etc/postgresql/15/main/pg_hba.conf"
echo ""
echo "3. Reiniciar PostgreSQL:"
echo "   sudo systemctl restart postgresql"
echo ""
echo "4. Conectar a PostgreSQL:"
echo "   sudo -u postgres psql"
echo ""
print_info "Documentación: https://www.postgresql.org/docs/15/"
