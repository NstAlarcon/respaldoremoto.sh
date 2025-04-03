Backup database automation.

This script generates a backup of our MySQL database and then sends it to another remote server. It has been successfully used on two Ubuntu servers, 22.04 and 18.04, on different networks to send SQL database backups.

Before running do this:

Access the source server and complete:

Generate an SSH key pair using the ssh-keygen command. Upload the public key to the remote Linux server. Disable password-based authentication. Transfer the key to the server using ssh-copy-id. Log in to the VPS using SSH.

It will ask you for an SSH key only once, then you should be able to access without a password.

Here's a detailed explanation of how the script works:

1️⃣ Initial Configuration The script defines several key variables:

Database Credentials:

bash Copy Edit USER_DB="root" PASSWORD_DB="password" HOST_DB="localhost" DB_NAME="database" The user, password, and name of the database to be backed up are stored here.

Backrest locations:

bash Copy Edit BACKUP_PATH="/backup" REMOTE_USER="root" REMOTE_HOST="REMOTE IP" REMOTE_PORT="REMOTE PORT" REMOTE_DIR="/root/backup" BACKUP_PATH: Local path where the backup will be saved.

REMOTE_HOST and REMOTE_DIR: Remote server and the folder where the backup will be sent.

REMOTE_PORT: SSH port for secure connection.

Backup file name and date format:

bash Copy Edit DATE=$(date +"%d-%b-%Y") BACKUP_FILE="$BACKUP_PATH/$DB_NAME-$DATE.sql" REMOTE_FILE="$REMOTE_DIR/$DB_NAME-$DATE.sql" The current date (dd-MMM-YYYY, e.g. 02-Apr-2025) is used to name the backup file.

2️⃣ Ensure bash Permissions Copy Edit umask 177 Prevents other users from reading the backup file, ensuring privacy.

3️⃣ Check if the backup already exists Before creating the backup, the script checks if a file with the same name already exists:

bash Copy Edit if [ -f "$BACKUP_FILE" ]; then echo "Backup $BACKUP_FILE already exists. Exiting..." exit 1 fi If the backup already exists on the local machine, execution stops.

4️⃣ Create the MySQL backup bash Copy Edit mysqldump --user=$USER_DB --password="$PASSWORD_DB" --host=$HOST_DB $DB_NAME > "$BACKUP_FILE" Use mysqldump to extract all the data from the database and save it to a .sql file.

5️⃣ Check if the backup already exists on the remote server bash Copy Edit if ssh -p $REMOTE_PORT "$REMOTE_USER@$REMOTE_HOST" "[ -f '$REMOTE_FILE' ]"; then echo "Backup $REMOTE_FILE already exists on the remote server. Exiting..." exit 1 fi Connect to the remote server via SSH and check if the backup is already on the other machine.

If the file already exists on the remote server, the transfer is canceled.

6️⃣ Transfer the backup to the remote server bash Copy Edit rsync -avz -e "ssh -p $REMOTE_PORT" "$BACKUP_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/" --progress rsync copies the backup file to the remote server securely.

-avz maintains permissions, structure, and compresses data for faster transfer.

--progress shows the transfer progress in the terminal.

7️⃣ Delete old backups on the local machine bash Copy Edit find "$BACKUP_PATH" -type f -name "$DB_NAME-*.sql" -mtime +2 -exec rm {} ; Looks for .sql files in the backups folder that are older than 2 days and deletes them.

8️⃣ Delete old backups on the remote server bash Copy Edit ssh -p $REMOTE_PORT "$REMOTE_USER@$REMOTE_HOST" "find "$REMOTE_DIR" -type f -name '$DB_NAME-*.sql' -mtime +2 -exec rm {} ;" Run the same process above, but directly on the remote server.

9️⃣ Bash Completion Copy Edit echo "Process completed successfully." Displays a confirmation message when everything went well.

🛠️ Flow Summary Check if the backup already exists locally.

Create the backup with mysqldump.

Check if the file already exists on the remote server.

Transfer the backup with rsync.

Delete old backups on both the local and remote servers.

Displays success message upon completion.

🔹 This script completely automates the creation and transfer of database backups.

schedule a crontab for its daily execution.
