# respaldoremoto.sh 
Automatizacion bases de datos backup.

Este script genera una copia de seguridad de nuestra base de datos mysql y posteriormente la envia a otro servidor remoto.
 A sido empleado exitosamente en dos servidores ubuntu 22.04 y 18.04 en distintas redes en el envio de respaldo de base de datos sql.

Antes de ejecutar realiza esto:

Accede a servidor de origen y completa:
 
Generar un par de claves SSH con el comando ssh-keygen.
Cargar la clave pública en el servidor Linux remoto.
Desactivar la autenticación basada en contraseña.
Transferir la clave al servidor usando ssh-copy-id.
Iniciar sesión en el VPS usando SSH.

Te pedira clave ssh una unica vez luego debes poder acceder sin contraseña.

Aquí tienes una explicación detallada de cómo funciona el script:

1️⃣ Configuración Inicial
El script define varias variables clave:

Credenciales de la base de datos:

bash
Copiar
Editar
USER_DB="root"
PASSWORD_DB="password"
HOST_DB="localhost"
DB_NAME="database"
Aquí se almacenan el usuario, la contraseña y el nombre de la base de datos que se va a respaldar.

Ubicaciones de los respaldos:

bash
Copiar
Editar
BACKUP_PATH="/backup"
REMOTE_USER="root"
REMOTE_HOST="IP REMOTE"
REMOTE_PORT="PUERTO REMOTE"
REMOTE_DIR="/root/backup"
BACKUP_PATH: Ruta local donde se guardará la copia de seguridad.

REMOTE_HOST y REMOTE_DIR: Servidor remoto y la carpeta donde se enviará el respaldo.

REMOTE_PORT: Puerto SSH para la conexión segura.

Formato de fecha y nombre del archivo de respaldo:

bash
Copiar
Editar
DATE=$(date +"%d-%b-%Y")
BACKUP_FILE="$BACKUP_PATH/$DB_NAME-$DATE.sql"
REMOTE_FILE="$REMOTE_DIR/$DB_NAME-$DATE.sql"
La fecha actual (dd-MMM-YYYY, ej. 02-Apr-2025) se usa para nombrar el archivo de respaldo.

2️⃣ Asegurar Permisos
bash
Copiar
Editar
umask 177
Evita que otros usuarios puedan leer el archivo del respaldo, asegurando privacidad.

3️⃣ Verificar si el respaldo ya existe
Antes de crear el respaldo, el script revisa si ya existe un archivo con el mismo nombre:

bash
Copiar
Editar
if [ -f "$BACKUP_FILE" ]; then
    echo "El respaldo $BACKUP_FILE ya existe. Saliendo..."
    exit 1
fi
Si el respaldo ya existe en la máquina local, se detiene la ejecución.

4️⃣ Crear la copia de seguridad de MySQL
bash
Copiar
Editar
mysqldump --user=$USER_DB --password="$PASSWORD_DB" --host=$HOST_DB $DB_NAME > "$BACKUP_FILE"
Usa mysqldump para extraer todos los datos de la base de datos y guardarlos en un archivo .sql.

5️⃣ Verificar si el respaldo ya existe en el servidor remoto
bash
Copiar
Editar
if ssh -p $REMOTE_PORT "$REMOTE_USER@$REMOTE_HOST" "[ -f '$REMOTE_FILE' ]"; then
    echo "El respaldo $REMOTE_FILE ya existe en el servidor remoto. Saliendo..."
    exit 1
fi
Se conecta al servidor remoto por SSH y verifica si el respaldo ya está en la otra máquina.

Si el archivo ya existe en el servidor remoto, se cancela la transferencia.

6️⃣ Transferir el respaldo al servidor remoto
bash
Copiar
Editar
rsync -avz -e "ssh -p $REMOTE_PORT" "$BACKUP_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/" --progress
rsync copia el archivo de respaldo al servidor remoto de forma segura.

-avz mantiene permisos, estructura y comprime los datos para una transferencia más rápida.

--progress muestra el progreso de la transferencia en la terminal.

7️⃣ Eliminar respaldos antiguos en la máquina local
bash
Copiar
Editar
find "$BACKUP_PATH" -type f -name "$DB_NAME-*.sql" -mtime +2 -exec rm {} \;
Busca archivos .sql en la carpeta de backups con más de 2 días de antigüedad y los elimina.

8️⃣ Eliminar respaldos antiguos en el servidor remoto
bash
Copiar
Editar
ssh -p $REMOTE_PORT "$REMOTE_USER@$REMOTE_HOST" "find \"$REMOTE_DIR\" -type f -name '$DB_NAME-*.sql' -mtime +2 -exec rm {} \;"
Ejecuta el mismo proceso anterior, pero directamente en el servidor remoto.

9️⃣ Finalización
bash
Copiar
Editar
echo "Proceso completado exitosamente."
Muestra un mensaje de confirmación cuando todo ha salido bien.

🛠️ Resumen del Flujo
Verifica si ya existe el respaldo localmente.

Crea el respaldo con mysqldump.

Verifica si el archivo ya existe en el servidor remoto.

Transfiere el respaldo con rsync.

Elimina respaldos antiguos tanto en el servidor local como en el remoto.

Muestra mensaje de éxito al finalizar.



🔹 Este script automatiza completamente la creación y transferencia de respaldos de la base de datos. 

programa un crontab para la ejecucion diaria del mismo.
