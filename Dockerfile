FROM php:7.1-apache
MAINTAINER Mark Wienk <mark.wienk@trimm.nl>

ENV PHP_EXT_APCU_VERSION "5.1.7"
ENV PHP_EXT_MEMCACHED_VERSION "3.0.3"
ENV PHP_EXT_REDIS_VERSION "4.0.2"
ENV MAGENTO_VERSION "2.2.0"

ENV COMPOSER_HOME "/root/.composer"

RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libgd-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libldap2-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libpng-dev \
    libxml2-dev \
    libxslt1-dev \
    sendmail \
    sendmail-bin \
    sudo \
    && yes "" | pecl install apcu-$PHP_EXT_APCU_VERSION && docker-php-ext-enable apcu \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) iconv gd exif mbstring mcrypt \
    && echo "no" | pecl install memcached-$PHP_EXT_MEMCACHED_VERSION && docker-php-ext-enable memcached \
    && docker-php-ext-install -j$(nproc) pcntl pdo_mysql mysqli soap \
    && yes | pecl install xdebug && docker-php-ext-enable xdebug \
    && docker-php-ext-install -j$(nproc) xsl zip intl gettext \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Composer
# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
	--install-dir=/usr/local/bin \
    --filename=composer

# REDIS client
RUN curl -fsSL https://github.com/phpredis/phpredis/archive/$PHP_EXT_REDIS_VERSION.tar.gz -o /tmp/redis.tar.gz \
    && mkdir -p /usr/src/php/ext/redis \
    && tar -xf /tmp/redis.tar.gz -C /usr/src/php/ext/redis --strip-components=1 \
    && rm /tmp/redis.tar.gz \
    && docker-php-ext-install redis

RUN a2enmod rewrite headers

COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY ./php.ini /usr/local/etc/php/conf.d/zz-magento.ini
COPY ./magento.conf /etc/apache2/conf-enabled/
COPY ./000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./wait-for-it.sh /usr/local/bin/wait-for-it.sh
COPY ./auth.json $COMPOSER_HOME

# Install Magento 2
RUN composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition $MAGENTO_VERSION

ENTRYPOINT ["docker-entrypoint.sh"]