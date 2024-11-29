#!/usr/bin/env bash
printf "> Preparing configuration file....."
MYF=/etc/mysql/conf.d/mysql.cnf
sed -i "s/^user=.*$/user=${DBUSER:-root}/g" $MYF
sed -i "s/^password=.*$/password=${DBPASS:-Hoyozero@2024..}/g" $MYF
sed -i "s/^host=.*$/host=${DBHOST:-service-mysql}/g" $MYF
sed -i "s/^port=.*$/port=${DBPORT:-3306}/g" $MYF
printf "done!\n> Starting main script....."
/usr/local/sbin/monitor.sh &
printf "done!\n> Starting cron....."
cron
printf "done!\n> Add cron job....."
CRONEXP=$(echo "${CRON:-5 0,12 * * *}" | sed 's/"//g' | sed 's/'"'"/'/g')
echo "${CRONEXP} /usr/local/sbin/dumpdb.sh" | crontab -
printf "done!\n\n"
echo "---------------------------------------------------------------"
printf "\tDatabaseUser: ${DBUSER:-root}\n"
printf "\tDatabasePassword: ************\n"
printf "\tDatabaseHost: ${DBHOST:-service-mysql}\n"
printf "\tDatabasePort: ${DBPORT:-3306}\n"
printf "\tCronExpression: ${CRONEXP}\n"
printf "\tFileKeepCounts: ${SAVECOUNT:-30}\n"
printf "\tSaveLogs: ${DEBUG:-false}\n"
echo "---------------------------------------------------------------"
echo "To start backup immediately, please run the following command:"
echo "docker exec -it <container_id> dumpdb.sh"
echo "==============================================================="
echo "Mysql backup job started successfully!"
tail -f /dev/null