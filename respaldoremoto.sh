#!/bin/bash

set -e  # Detener la ejecución si ocurre un error

# Configuración
USER_DB="root"
PASSWORD_DB="password"
HOST_DB="localhost"
DB_NAME="databasename"
BACKUP_PATH="/backup"
REMOTE_USER="root"
REMOTE_HOST="REMOTE IP"
REMOTE_PORT="REMOTE PORT"
REMOTE_DIR="/root/backup"
DATE=$(date +"%d-%b-%Y")
BACKUP_FILE="$BACKUP_PATH/$DB_NAME-$DATE.sql"
REMOTE_FILE="$REMOTE_DIR/$DB_NAME-$DATE.sql"

# Asegurar permisos
umask 177

# Verificar si el respaldo ya existe en el origen
if [ -f "$BACKUP_FILE" ]; then
    echo "El respaldo $BACKUP_FILE ya existe. Saliendo..."
    exit 1
fi

# Mensaje de inicio
echo "Iniciando el respaldo de la base de datos $DB_NAME..."

# Dump de la base de datos
mysqldump --user=$USER_DB --password="$PASSWORD_DB" --host=$HOST_DB $DB_NAME > "$BACKUP_FILE"
echo "Respaldo completado: $BACKUP_FILE"

# Verificar si el respaldo ya existe en el destino
if ssh -p $REMOTE_PORT "$REMOTE_USER@$REMOTE_HOST" "[ -f '$REMOTE_FILE' ]"; then
    echo "El respaldo $REMOTE_FILE ya existe en el servidor remoto. Saliendo..."
    exit 1
fi

# Transferencia segura al servidor remoto
echo "Iniciando la transferencia del respaldo al servidor remoto..."
rsync -avz -e "ssh -p $REMOTE_PORT" "$BACKUP_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/" --progress
echo "Transferencia completada."

# Eliminar respaldos antiguos en el origen (mantener últimos 3)
echo "Eliminando respaldos antiguos en el origen..."
find "$BACKUP_PATH" -type f -name "$DB_NAME-*.sql" -mtime +2 -exec rm {} \;
echo "Respaldos antiguos eliminados en el origen."

# Eliminar respaldos antiguos en el destino
echo "Eliminando respaldos antiguos en el destino..."
ssh -p $REMOTE_PORT "$REMOTE_USER@$REMOTE_HOST" "find \"$REMOTE_DIR\" -type f -name '$DB_NAME-*.sql' -mtime +2 -exec rm {} \;"
echo "Respaldos antiguos eliminados en el destino."

echo "Proceso completado exitosamente."
