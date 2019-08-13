FROM php:7.1.8-apache
MAINTAINER Paul Redmond

ENV DEBIAN_FRONTEND noninteractive
ENV DBUS_SESSION_BUS_ADDRESS /dev/null

RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list

# Install GD and opcache
# opcache is configured by default for development
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install opcache

RUN docker-php-ext-install mbstring pdo pdo_mysql

## install manually all the missing libraries
RUN apt-get update -y

RUN a2enmod rewrite

#install some base extensions
RUN apt-get install -y libzip-dev zip wget \
  && docker-php-ext-configure zip --with-libzip \
  && docker-php-ext-install zip

# Install needed php extensions: ldap
RUN apt-get update && \
    apt-get install libldap2-dev -y && \
    rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install ldap

COPY opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Install various PHP extensions
RUN docker-php-ext-configure bcmath --enable-bcmath && docker-php-ext-install bcmath

# if there is a failure in apt-get below, try
#rm /etc/apt/preferences.d/no-debian-php

RUN apt-get update -y \
  && apt-get install -y \
    libxml2-dev \
    php-soap \
  && apt-get clean -y \
  && docker-php-ext-install soap
#
##setup composer
RUN curl -sS https://getcomposer.org/installer | php \
        && mv composer.phar /usr/local/bin/ \
        && ln -s /usr/local/bin/composer.phar /usr/local/bin/composer

RUN apt-get install -y gconf-service libasound2 libatk1.0-0 libcairo2 libcups2 libfontconfig1 libgdk-pixbuf2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libxss1 fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils

## install chrome
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN dpkg -i google-chrome-stable_current_amd64.deb; apt-get -fy install

RUN apt-get update && apt-get install -y git

##I havent tested this
RUN apt-get update -yq \
    && apt-get install curl gnupg -yq \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash \
    && apt-get install nodejs -yq
    
RUN apt-get upgrade curl -y

# makes sure all your repos are up to date
RUN apt-get update -yqq

# laravel dusk dependencies
RUN apt-get -y install libxpm4 libxrender1 libgtk2.0-0 libnss3 \
    libgconf-2-4 libnss3-dev libxi6 libgconf-2-4 xvfb gtk2-engines-pixbuf \
    xfonts-cyrillic xfonts-100dpi xfonts-75dpi xfonts-base xfonts-scalable \
    imagemagick x11-apps

WORKDIR /srv/app