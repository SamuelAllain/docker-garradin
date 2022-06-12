ARG ALPINE_VERSION=3.16
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Samuel Allain"
LABEL Description="Garradin on Alpine Linux with Docker"

# Setup document root
WORKDIR /var/www/

# Change the version here
ENV GARRADIN_VERSION 1.1.25

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php81 \
  php81-ctype \
  php81-curl \
  php81-dom \
  php81-fpm \
  php81-gd \
  php81-intl \
  php81-mbstring \
  php81-mysqli \
  php81-opcache \
  php81-openssl \
  php81-phar \
  php81-session \
  php81-sqlite3 \
  php81-pdo_sqlite \
  php81-fileinfo \
  php81-json \
  php81-openssl \
  php81-xml \
  php81-xmlreader \
  php81-zlib \
  supervisor \
  gettext

# Downloading and installing Garradin
RUN curl -L -O https://fossil.kd2.org/garradin/uv/garradin-$GARRADIN_VERSION.tar.gz # download
RUN tar xzvf garradin-$GARRADIN_VERSION.tar.gz # extract
RUN mv garradin-$GARRADIN_VERSION /var/www/garradin # root of the website
RUN rm -r garradin-$GARRADIN_VERSION.tar.gz # cleaning

# Create symlink so programs depending on `php` still function
RUN ln -s /usr/bin/php81 /usr/bin/php

# Configure nginx
RUN rm /etc/nginx/http.d/default.conf # remove this file because it listens on port 80 and it blocks other vhost
COPY config/nginx-garradin.conf /etc/nginx/http.d

# Configure PHP (seems useless)
# to have the function finfo_open (uncomment ;extension=fileinfo)
#COPY config/php.ini /etc/php81/php.ini

# Configure PHP-FPM
COPY config/fpm-garradin.conf /etc/php81/php-fpm.d/

# Configure timezone
COPY config/php-custom.ini /etc/php81/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisord.conf
#COPY supervisord.conf /etc/supervisord.conf

## Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody:  /run /var/lib/nginx /var/log/nginx /var/www/garradin

# Switch to use a non-root user from here on
USER nobody

# Expose the port nginx is reachable on (documentation purposes only)
EXPOSE 80

## Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
#CMD ["/usr/bin/supervisord"] # should work too
#CMD ["nginx", "-g", "daemon off;"] # to start nginx only

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
# when curl fails to get an anwser, `docker ps` shows an "unhealthy" status
