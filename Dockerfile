FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

## Install php nginx mysql supervisor
RUN apt update && \
    apt install -y php-fpm php-cli php-gd php-mcrypt php-mysql php-curl php-pear php7.0-dev \
                       nginx \
                       curl \
                       build-essential \
                       g++ \
                       curl \
                       libssl-dev \
                       git \
                       libxml2-dev \
                       sshfs \
                       python-dev \
            supervisor && \
    echo "mysql-server mysql-server/root_password password" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password" | debconf-set-selections && \
    apt install -y mysql-server && \
    rm -rf /var/lib/apt/lists/*

## Install nodejs and cloud9 IDE
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - 
RUN apt-get install -y nodejs
#
RUN git clone https://github.com/c9/core.git /cloud9
WORKDIR /cloud9
RUN scripts/install-sdk.sh
# Tweak standlone.js conf
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js 
#
ADD files/pm2_cloud9.json /etc/pm2_cloud9.json
#
RUN npm install -g pm2

## Configuration
RUN sed -i 's/^listen\s*=.*$/listen = 127.0.0.1:9000/' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i 's/^\;error_log\s*=\s*syslog\s*$/error_log = \/var\/log\/php\/cgi.log/' /etc/php/7.0/fpm/php.ini && \
    sed -i 's/^\;error_log\s*=\s*syslog\s*$/error_log = \/var\/log\/php\/cli.log/' /etc/php/7.0/cli/php.ini && \
    sed -i 's/^key_buffer\s*=/key_buffer_size =/' /etc/mysql/my.cnf

COPY files/root /

WORKDIR /var/www/

VOLUME /var/www/

EXPOSE 80
EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
