FROM alpine:3.18.4
ENV DBUSER="dbk" DBPASS="dbk" DBHOST="mysql" DBPORT="3306" SAVECOUNT=30 CRON="5 0,12 * * *"
ADD dumpdb.sh /usr/local/sbin/dumpdb.sh
ADD Shanghai /etc/localtime
ADD init.sh /usr/local/sbin/init.sh
RUN echo 'https://mirrors.aliyun.com/alpine/v3.18/main/' > /etc/apk/repositories ; \
    echo 'https://mirrors.aliyun.com/alpine/v3.18/community/' >> /etc/apk/repositories ; \
    echo 'Asia/Shanghai' > /etc/timezone ; \
    apk update ; \
    apk add --no-cache mariadb-connector-c-dev mysql-client ; \
    chmod +x /usr/local/sbin/*.sh
CMD init.sh
