#!/bin/bash

# ============================================================================
# PostgreSQL 15 - Script de Backup Automático
# ============================================================================
# Uso: bash backup.sh
#
# Este script realiza backup de bases de datos PostgreSQL
# Puede ejecutarse manualmente o desde cron para backups automáticos
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

# Directorio donde guardar backups
BACKUP_DIR="/var/backups/postgresql"

# Usuario PostgreSQL
PG_USER="postgres"

# Nombre de la BD a respaldar (all para todas)
DATABASE="all"  # Cambiar a nombre específico si es necesario

# Retención de backups (días)
RETENTION_DAYS=30

# Compresión (gzip, bzip2, or none)
COMPRESSION="gzip"

# ============================================================================
# CREAR DIRECTORIO DE BACKUP
# ============================================================================

if [ ! -d "$BACKUP_DIR" ]; then
    print_info "Creando directorio de backup: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"
fi

# ============================================================================
# FUNCIÓN: BACKUP COMPLETO
# ============================================================================

backup_all_databases() {
    print_info "Iniciando backup de TODAS las bases de datos..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    case $COMPRESSION in
        gzip)
            BACKUP_FILE="$BACKUP_DIR/backup_all_$TIMESTAMP.sql.gz"
            sudo -u $PG_USER pg_dumpall | gzip > "$BACKUP_FILE"
            ;;
        bzip2)
            BACKUP_FILE="$BACKUP_DIR/backup_all_$TIMESTAMP.sql.bz2"
            sudo -u $PG_USER pg_dumpall | bzip2 > "$BACKUP_FILE"
            ;;
        none)
            BACKUP_FILE="$BACKUP_DIR/backup_all_$TIMESTAMP.sql"
            sudo -u $PG_USER pg_dumpall > "$BACKUP_FILE"
            ;;
    esac
    
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    print_info "✓ Backup completado: $BACKUP_FILE ($SIZE)"
}

# ============================================================================
# FUNCIÓN: BACKUP DE UNA BASE DE DATOS ESPECÍFICA
# ============================================================================

backup_specific_database() {
    local DB=$1
    print_info "Respaldando base de datos: $DB"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    case $COMPRESSION in
        gzip)
            BACKUP_FILE="$BACKUP_DIR/backup_${DB}_$TIMESTAMP.sql.gz"
            sudo -u $PG_USER pg_dump "$DB" | gzip > "$BACKUP_FILE"
            ;;
        bzip2)
            BACKUP_FILE="$BACKUP_DIR/backup_${DB}_$TIMESTAMP.sql.bz2"
            sudo -u $PG_USER pg_dump "$DB" | bzip2 > "$BACKUP_FILE"
            ;;
        none)
            BACKUP_FILE="$BACKUP_DIR/backup_${DB}_$TIMESTAMP.sql"
            sudo -u $PG_USER pg_dump "$DB" > "$BACKUP_FILE"
            ;;
    esac
    
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    print_info "✓ Backup completado: $BACKUP_FILE ($SIZE)"
}

# ============================================================================
# FUNCIÓN: BACKUP EN FORMATO PERSONALIZADO (más compresión)
# ============================================================================

backup_custom_format() {
    local DB=$1
    print_info "Respaldando $DB en formato personalizado (custom)..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/backup_${DB}_${TIMESTAMP}.dump"
    
    sudo -u $PG_USER pg_dump -Fc "$DB" > "$BACKUP_FILE"
    
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    print_info "✓ Backup personalizado completado: $BACKUP_FILE ($SIZE)"
}

# ============================================================================
# FUNCIÓN: LIMPIAR BACKUPS ANTIGUOS
# ============================================================================

cleanup_old_backups() {
    print_info "Limpiando backups más antiguos de $RETENTION_DAYS días..."
    
    DELETED_COUNT=$(find "$BACKUP_DIR" -name "backup_*.sql*" -o -name "backup_*.dump" | \
        xargs -I {} find {} -mtime +$RETENTION_DAYS -delete | wc -l)
    
    if [ $DELETED_COUNT -gt 0 ]; then
        print_info "✓ Se eliminaron $DELETED_COUNT backups antiguos"
    else
        print_info "✓ No hay backups que eliminar"
    fi
}

# ============================================================================
# FUNCIÓN: LISTAR BACKUPS
# ============================================================================

list_backups() {
    print_info "Backups disponibles:"
    echo ""
    ls -lh "$BACKUP_DIR" | tail -n +2
    echo ""
    
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
    TOTAL_FILES=$(ls -1 "$BACKUP_DIR" | wc -l)
    print_info "Total: $TOTAL_FILES archivos, $TOTAL_SIZE"
}

# ============================================================================
# FUNCIÓN: VERIFICAR INTEGRIDAD DE BACKUP
# ============================================================================

verify_backup() {
    local BACKUP_FILE=$1
    
    if [ ! -f "$BACKUP_FILE" ]; then
        print_error "Archivo no encontrado: $BACKUP_FILE"
        return 1
    fi
    
    print_info "Verificando integridad de: $BACKUP_FILE"
    
    # Detectar formato
    if [[ "$BACKUP_FILE" == *.gz ]]; then
        gunzip -t "$BACKUP_FILE" 2>/dev/null && \
            print_info "✓ Archivo gzip válido" || \
            { print_error "✗ Archivo gzip corrupto"; return 1; }
    elif [[ "$BACKUP_FILE" == *.bz2 ]]; then
        bzip2 -t "$BACKUP_FILE" 2>/dev/null && \
            print_info "✓ Archivo bzip2 válido" || \
            { print_error "✗ Archivo bzip2 corrupto"; return 1; }
    elif [[ "$BACKUP_FILE" == *.dump ]]; then
        pg_restore -l "$BACKUP_FILE" >/dev/null 2>&1 && \
            print_info "✓ Archivo dump válido" || \
            { print_error "✗ Archivo dump corrupto"; return 1; }
    else
        # Es SQL plano, solo verificamos que existe
        [ -s "$BACKUP_FILE" ] && \
            print_info "✓ Archivo SQL existe y no está vacío" || \
            { print_error "✗ Archivo SQL vacío o inválido"; return 1; }
    fi
}

# ============================================================================
# FUNCIÓN: RESTAURAR DESDE BACKUP
# ============================================================================

restore_backup() {
    local BACKUP_FILE=$1
    
    if [ ! -f "$BACKUP_FILE" ]; then
        print_error "Archivo no encontrado: $BACKUP_FILE"
        return 1
    fi
    
    print_info "Preparando restauración desde: $BACKUP_FILE"
    read -p "¿Continuar con la restauración? (s/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_info "Restauración cancelada"
        return 0
    fi
    
    print_info "Restaurando..."
    
    if [[ "$BACKUP_FILE" == *.dump ]]; then
        # Formato personalizado
        read -p "Ingresa nombre de base de datos destino: " TARGET_DB
        if [ -z "$TARGET_DB" ]; then
            print_error "Nombre de base de datos no especificado"
            return 1
        fi
        
        sudo -u $PG_USER pg_restore -d "$TARGET_DB" "$BACKUP_FILE"
    elif [[ "$BACKUP_FILE" == *.gz ]]; then
        # SQL comprimido
        gunzip -c "$BACKUP_FILE" | sudo -u $PG_USER psql
    elif [[ "$BACKUP_FILE" == *.bz2 ]]; then
        # SQL con bzip2
        bzip2 -dc "$BACKUP_FILE" | sudo -u $PG_USER psql
    else
        # SQL plano
        sudo -u $PG_USER psql < "$BACKUP_FILE"
    fi
    
    if [ $? -eq 0 ]; then
        print_info "✓ Restauración completada"
    else
        print_error "✗ Error durante la restauración"
        return 1
    fi
}

# ============================================================================
# MENÚ PRINCIPAL
# ============================================================================

if [ $# -eq 0 ]; then
    # Sin argumentos - hacer backup automático
    backup_all_databases
    cleanup_old_backups
    list_backups
else
    case "$1" in
        all)
            backup_all_databases
            ;;
        database)
            if [ -z "$2" ]; then
                print_error "Especifica nombre de base de datos"
                exit 1
            fi
            backup_specific_database "$2"
            ;;
        custom)
            if [ -z "$2" ]; then
                print_error "Especifica nombre de base de datos"
                exit 1
            fi
            backup_custom_format "$2"
            ;;
        list)
            list_backups
            ;;
        cleanup)
            cleanup_old_backups
            ;;
        verify)
            if [ -z "$2" ]; then
                print_error "Especifica archivo a verificar"
                exit 1
            fi
            verify_backup "$2"
            ;;
        restore)
            if [ -z "$2" ]; then
                print_error "Especifica archivo a restaurar"
                exit 1
            fi
            restore_backup "$2"
            ;;
        *)
            echo "PostgreSQL 15 - Script de Backup"
            echo ""
            echo "Uso: $0 [comando]"
            echo ""
            echo "Comandos:"
            echo "  (sin argumentos)  - Backup completo + limpieza"
            echo "  all               - Backup de todas las BDs"
            echo "  database <nombre> - Backup de una BD específica"
            echo "  custom <nombre>   - Backup en formato personalizado (dump)"
            echo "  list              - Listar backups disponibles"
            echo "  cleanup           - Limpiar backups antiguos"
            echo "  verify <archivo>  - Verificar integridad de backup"
            echo "  restore <archivo> - Restaurar desde backup"
            echo ""
            echo "Ejemplos:"
            echo "  $0 all"
            echo "  $0 database mi_app"
            echo "  $0 custom mi_app"
            echo "  $0 verify /var/backups/postgresql/backup_all_*.sql.gz"
            echo "  $0 restore /var/backups/postgresql/backup_all_*.sql.gz"
            ;;
    esac
fi
