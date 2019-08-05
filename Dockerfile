FROM php:7.1.8-apache

ENV DEBIAN_FRONTEND noninteractive
ENV DBUS_SESSION_BUS_ADDRESS /dev/null
MAINTAINER Paul Redmond

RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list

RUN docker-php-ext-install mbstring pdo pdo_mysql \
    && chown -R www-data:www-data /srv/app

## install manually all the missing libraries
RUN apt-get update -y

RUN a2enmod rewrite

#install some base extensions
RUN apt-get install -y libzip-dev zip wget \
  && docker-php-ext-configure zip --with-libzip \
  && docker-php-ext-install zip

# if there is a failure in apt-get below, try
#rm /etc/apt/preferences.d/no-debian-php

RUN apt-get update -y \
  && apt-get install -y \
    libxml2-dev \
    php-soap \
  && apt-get clean -y \
  && docker-php-ext-install soap

##setup composer
RUN curl -sS https://getcomposer.org/installer | php \
        && mv composer.phar /usr/local/bin/ \
        && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer

RUN composer global require phpunit/phpunit
RUN composer global require phpunit/dbunit
ENV PATH=~/.composer/vendor/bin:$PATH
