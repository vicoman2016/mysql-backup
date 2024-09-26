#!/usr/bin/env bash
### 需要的变量 ###################################
DB_USERNAME=${DBUSER:-root}
DB_PASSWORD=${DBPASS:-}
DB_HOST=${DBHOST:-localhost}
DB_PORT=${DBPORT:-3306}
#SSL_MODE=${SSL_MODE:-DISABLED}
EXPORT_DIR_ROOT=${EXPORT_DIR_ROOT:-/opt/data}
SAVECOUNT=${SAVECOUNT:-0} # 保留多少个备份, 0表示全部保留
##################################################
# 设置认证信息
#DBAUTH="--ssl-mode=${SSL_MODE} -h${DB_HOST} -P${DB_PORT} -u${DB_USERNAME}"
DBAUTH=" -h${DB_HOST} -P${DB_PORT} -u${DB_USERNAME} "
if [ "${#DB_PASSWORD}" -gt 0 ]; then
    DBAUTH="${DBAUTH} -p${DB_PASSWORD}"
fi

### 打印日志 ###
log(){
    LOGPATH=${EXPORT_DIR_ROOT}/logs
    mkdir -p ${LOGPATH}
    LOGF=${LOGPATH}/$(date +"%Y-%m-%d").log
    touch ${LOGF}
    if [ "$1" = "-q" ]; then
        shift
        echo "[$(date +'%Y-%m-%d %H:%M:%S')][$$] $*" >> $LOGF
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')][$$] $*" >> $LOGF
        echo "[$(date +'%Y-%m-%d %H:%M:%S')][$$] $*"
    fi
}

#查询命令
query(){
    CMD="mysql ${DBAUTH} --skip-column-names -B -e '$*'"
    log -q "执行SQL: [$CMD]"
    mysql ${DBAUTH} --skip-column-names -B -e "$*" 2>/tmp/query.log
    if [ $? -ne 0 ]; then
        log -q "查询失败，执行命令: ${CMD}, 错误信息: $(cat /tmp/query.log)"
    fi
}

#导出表结构和数据
dump_schema_and_data(){
    # 获取需要导出的所有数据库
    DBS=$( query "SHOW DATABASES;" | grep -Ev "(information_schema|performance_schema|mysql|sys)" )
    if [ "${#DBS}" -eq 0 ]; then
        log "没有需要导出的数据库"
        return 1
    fi
    #IFS=' ' read -ra DATABASES <<< "$DBS"
    DATABASES=$(echo "$DBS" | awk 'ORS=" " {print}')
    CMD="mysqldump ${DBAUTH} --single-transaction --routines --compact --databases ${DATABASES} --result-file=$EXPORT_DIR/schemas-and-data-${TIME}.sql"
    log -q "执行SQL: ${CMD}"
    $CMD 2>/tmp/query.log
    RET=$?
    if [ $RET -ne 0 ]; then
        log "[ERROR($RET)]: $(cat /tmp/query.log)"
        return 1
    fi
    log "导出数据库:[ ${DATABASES}], 执行成功。"
}

#导出用户和权限
dump_user_and_grants(){
    query "select concat('''', user, '''@''', host, '''') from mysql.user where user not in ('mysql.infoschema', 'mysql.session', 'mysql.sys', 'root')" | while read USER_WITH_HOST ; do
        echo "CREATE USER IF NOT EXISTS ${USER_WITH_HOST} IDENTIFIED BY '${DB_PASSWORD}';"
        query "SHOW GRANTS for ${USER_WITH_HOST};" | while read GRANT_LINE ; do
            echo "${GRANT_LINE};"
        done
    done > ${EXPORT_DIR}/users_and_grants-${TIME}.sql
}
# 检查数据库连接
if [ ! query "SHOW DATABASES;" 2>/dev/null ]; then
    log "[ERROR]无法连接数据库，请检查参数。"
    exit 1
fi

log "==================== 备份开始, 执行时间: $(date '+%Y-%m-%d %H:%M:%S') ===================="
# 设置导出目录
DATE=$(date +%Y%m%d)
TIME=$(date +%H%M%S)
mkdir -p ${EXPORT_DIR_ROOT}
cd ${EXPORT_DIR_ROOT}
EXPORT_DIR="${DATE}"
mkdir -p ${EXPORT_DIR}
# 导出数据库结构和数据
dump_schema_and_data && \
dump_user_and_grants
#压缩文件
TARGET_FILE=${EXPORT_DIR_ROOT}/${DATE}-${TIME}-$$.tgz
#此版本的tar不支持--remove-files参数
tar -zcf ${TARGET_FILE} ${EXPORT_DIR} #--remove-files
rm -rf ${EXPORT_DIR}

#清除历史文件，保留${SAVECOUNT}个
if [ $SAVECOUNT -gt 0 ] ; then
    ls -1t ${EXPORT_DIR_ROOT}/*.tgz | awk "NR>${SAVECOUNT}" | xargs rm -rf
fi

log "数据库备份完成，备份文件为:${TARGET_FILE}!"
echo