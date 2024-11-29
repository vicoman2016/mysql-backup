#!/usr/bin/env bash

# Set the root directory for export. If BKPATH is not set, default to /opt/data
EXPORT_DIR_ROOT="${BKPATH:-/opt/data}"

# Set the number of backup files to keep. If SAVECOUNT is not set, default to 30
SAVE_COUNT="${SAVECOUNT:-30}"

# Set the path for log files. It will be under the EXPORT_DIR_ROOT in a directory named 'logs'
LOGPATH=${EXPORT_DIR_ROOT}/logs

### Function to print log messages ###
log(){
    echo "[$(date +'%Y-%m-%d %H:%M:%S')][$$] $*" | tee -a $LOGF
}

# This function prints the given warning message along with the current date and time and the process ID (PID) to the standard error.
warn(){
    echo "[$(date +'%Y-%m-%d %H:%M:%S')][$$] $*" >&2
}

# Function to execute a query in MySQL
# This function takes a query as input, removes spaces from it, and then executes it using the mysql command.
# If the query is not empty, it runs the query and prints a warning message with the executed command and its return code.
query(){
    # Escape single quotes in the input SQL statement, replacing single quotes with '\''
    local PARAM=$(echo "$*" | sed 's/\s//g')
    if [ ${#PARAM} -gt 0 ]; then
        warn "execute: [mysql --skip-column-names -B -e \"$*\"]"
        echo "$*" | mysql --skip-column-names -B | tee -a $LOGF
    fi
}

# Function to dump database schema and data
# This function first retrieves all the databases to be exported by excluding some system databases.
# Then it constructs a mysqldump command to export the database schema and data to a specific file.
# It logs the progress and the result of the export operation.
dump_schema_and_data(){
    # Get all the databases that need to be exported, excluding some system databases like information_schema, performance_schema, mysql, and sys.
    DATABASES=$( query "SHOW DATABASES;" | grep -Ev "(\binformation_schema\b|\bperformance_schema\b|\bmysql\b|\bsys\b)" | awk '{printf("%s ", $1);}' )
    if [ -z "${DATABASES// /}" ]; then
        log "no database to dump"
        return
    fi
    log "prepare to dump databases: ${DATABASES}"
    CMD="mysqldump --single-transaction --routines --compact --databases ${DATABASES} --result-file=${EXPORT_DIR}/schemas-and-data.sql"
    warn "execute: [${CMD}]"
    mysqldump --single-transaction --routines --compact --databases ${DATABASES} --result-file=${EXPORT_DIR}/schemas-and-data.sql
    log "export of table structures and data completed, execution result: $?"
}

# Function to dump user and grants information
# This function first logs that it's starting to export user and grants information.
# Then it creates an empty grants.sql file and loops through each user (excluding some specific ones) to construct SQL statements for creating the user and showing their grants.
# These statements are then written to the grants.sql file. Finally, it logs that the export is completed.
dump_user_and_grants(){
    log "exporting users and permissions..."
    log "  ** excluding: root, mysql.infoschema, mysql.session, mysql.sys, mysql.%"
    touch ${EXPORT_DIR}/grants.sql
    query "select concat_ws('@', concat_ws(user, '''', ''''), concat_ws(host, '''', '''')) from mysql.user where user != 'root' and user not like 'mysql.%';" | while read USER_WITH_HOST ; do
        ( echo "CREATE USER IF NOT EXISTS ${USER_WITH_HOST} IDENTIFIED BY '${DBPASS}';"
        query "SHOW GRANTS FOR ${USER_WITH_HOST};" | while read GRANT_LINE ; do
            echo "${GRANT_LINE};"
        done
        ) >> ${EXPORT_DIR}/grants.sql
    done
    log "export of users and permissions completed"
}

# Main function for the backup process
# This function first prints a separator line for logging purposes.
# Then it tests the database connection by executing a simple query. If the connection fails, it logs an error message and returns.
# If the connection is successful, it starts the backup process which includes creating an export directory, exporting database schema and data, exporting user and grants information, compressing the export directory, and cleaning up old compressed backup files.
# Finally, it logs the completion of the backup and the path of the backup file.
dump_main(){
    echo
    log "====================  Starting backup process  ===================="
    # Test the database connection by running a simple query to get the database version
    query "select version();" >/dev/null
    if [ $? -ne 0 ]; then
        log "database connection failed. Please check the database connection parameters."
        return 1
    fi

    # Create the export directory with a timestamp in its name
    TS="$(date +%Y%m%d-%H%M%S)"
    EXPORT_DIR=${EXPORT_DIR_ROOT}/${TS}
    mkdir -p ${EXPORT_DIR}

    # Export database structure and data
    dump_schema_and_data

    # Export user and grants information
    dump_user_and_grants

    # Compress the export directory
    log "compressing backup files..."
    cd ${EXPORT_DIR_ROOT}
    tar -zcf ${TS}.tgz ${TS}
    rm -rf ${TS}/

    # Clean up old compressed backup files, keeping only the most recent ${SAVE_COUNT} ones
    log "cleaning up expired compressed packages..."
    if [  0 -lt $SAVE_COUNT ]; then
        ls -t *.tgz | tail -n +$(($SAVE_COUNT + 1)) | xargs -I {} rm -f {}
    fi
    log "backup file saved to: ${EXPORT_DIR_ROOT}/${TS}.tgz"
    log "====================  Backup process completed  ===================="
    echo
}

deel_signal() {
    # Disable SIGUSR1 signal to avoid triggering the backup operation again during the backup process
    trap '' SIGUSR1
    # Set the specific log file name with the current date format as YYYYMMDD.log under the LOGPATH
    if [ "${DEBUG}" == "true" ]; then
        LOGF=$LOGPATH/$(date +"%Y%m%d").log
        # Create the LOGPATH directory if it doesn't exist
        mkdir -p ${LOGPATH}
        # Create an empty log file or update its access time if it already exists
        touch $LOGF
    else
        LOGF=/dev/null
    fi
    # Redirect standard error to the log file
    exec 3>&2
    exec 2>>$LOGF
    # Execute the dump_main function to perform the backup operation
    dump_main
    # Restore standard error output
    exec 2>&3
    exec 3>&-
    # Enable SIGUSR1 signal to allow triggering the backup operation again
    trap 'deel_signal' SIGUSR1    
}

# Set a trap to execute the dump_main function when the SIGUSR1 signal is received
trap 'deel_signal' SIGUSR1

# Infinite loop to keep the script running and waiting for signals
while true; do
    sleep 1
done
