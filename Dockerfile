FROM alexcheng/magento2:2.2.2-integrator
MAINTAINER Mark Wienk <mark.wienk@trimm.nl>

ENV PHP_EXT_APCU_VERSION "5.1.7"
ENV PHP_EXT_REDIS_VERSION "4.0.2"

RUN apt-get update && apt-get install -y \
    libldap2-dev \
    libmemcached-dev \
    libpng-dev \
    libxml2-dev \
    sendmail \
    sendmail-bin \
    sudo \
    && yes "" | pecl install apcu-$PHP_EXT_APCU_VERSION && docker-php-ext-enable apcu \
    && docker-php-ext-install -j$(nproc) bcmath iconv exif \
    && docker-php-ext-install -j$(nproc) pcntl mysqli \
    && docker-php-ext-install -j$(nproc) gettext \
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

ENTRYPOINT ["docker-entrypoint.sh"]
