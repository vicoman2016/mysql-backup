FROM alpine:3.18.4
ENV DBUSER="root" DBPASS="root" DBHOST="mysql" DBPORT="3306" SAVECOUNT=30 CRON="5 0,12 * * *"
COPY scripts /usr/local/sbin
ADD Shanghai   /etc/localtime
RUN echo 'https://mirrors.aliyun.com/alpine/v3.18/main/' > /etc/apk/repositories && \
    echo 'https://mirrors.aliyun.com/alpine/v3.18/community/' >> /etc/apk/repositories && \
    echo 'Asia/Shanghai' > /etc/timezone && \
    apk update && \
    apk add --no-cache mariadb-connector-c-dev mysql-client bash && \
    chmod +x /usr/local/sbin/*.sh
CMD /usr/local/sbin/init.sh