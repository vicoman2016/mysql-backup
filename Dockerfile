FROM alpine:3.18.4
ENV DBUSER="dbk" DBPASS="dbk" DBHOST="mysql" DBPORT="3306" SAVECOUNT=30
ADD dumpdb.sh /usr/local/sbin/dumpdb.sh
ADD cleanup.sh /usr/local/sbin/cleanup.sh
ADD Shanghai /etc/localtime
RUN echo 'https://mirrors.aliyun.com/alpine/v3.18/main/' > /etc/apk/repositories
RUN echo 'https://mirrors.aliyun.com/alpine/v3.18/community/' >> /etc/apk/repositories
RUN echo 'Asia/Shanghai' > /etc/timezone 
RUN apk update
RUN apk add --no-cache mariadb-connector-c-dev mysql-client 
RUN echo -e "5 0,12 * * * sh /usr/local/sbin/dumpdb.sh\n30 0,12 * * * sh /usr/local/sbin/cleanup.sh" | crontab -
CMD crond && tail -f /dev/null