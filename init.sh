#!/usr/bin/env sh
CRONEXP=$(echo "${CRON:-5 0,12 * * *}" | sed 's/"//g' | sed 's/'"'"/'/g')
echo -e "${CRONEXP} /usr/local/sbin/dumpdb.sh" | crontab -
crond
echo "Policy: $CRONEXP"
echo "Mysql backup job started!"
tail -f /dev/null
