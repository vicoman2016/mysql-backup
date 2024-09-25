FROM ubuntu:24.04
ADD Shanghai /etc/localtime
#ADD ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources

RUN apt update && \
    apt install  -y wget curl net-tools vim && \
    apt-get autoremove -y && \
    apt-get clean
