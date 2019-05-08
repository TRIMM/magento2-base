FROM php:7.1-apache

# install the PHP extensions we need
RUN set -ex; \
	\
	if command -v a2enmod; then \
		a2enmod rewrite headers; \
	fi; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libfreetype6 \
        libfreetype6-dev \
        libicu-dev \
		libjpeg-dev \
        libmcrypt-dev \
		libpng-dev \
		libpq-dev \
        libxslt1-dev \
        unzip \
	; \
	\
    pecl install redis-4.2.0; \
	docker-php-ext-configure gd --with-png-dir=/usr --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr; \
	docker-php-ext-install -j "$(nproc)" \
        bcmath \
        dom \
		gd \
        hash \
        iconv \
        intl \
        mbstring \
        mcrypt \
		opcache \
		pdo_mysql \
        soap \
        xml \
		xsl \
		zip \
	; \
    docker-php-ext-enable redis; \
	\
    
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get install -y mysql-client sudo; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
        echo 'date.timezone="Europe/London"'; \
        echo 'memory_limit=756M'; \
        echo 'max_execution_time=600'; \
        echo 'upload_max_filesize=64M'; \
        echo 'post_max_size=64M'; \
        echo 'apc.enable_cli=1'; \
	echo 'default_socket_timeout=360'; \
    } > /usr/local/etc/php/conf.d/magento-recommended.ini

RUN { \
        echo 'SetEnvIf X-Forwarded-Proto https HTTPS=on'; \
    } > /etc/apache2/conf-enabled/magento.conf

# Change docroot structure
RUN rm -rf /var/www && \
    mkdir /var/www && \
    sed -i 's/\/var\/www\/html/\/var\/www\/html\/pub/g' /etc/apache2/sites-enabled/000-default.conf & \
	chsh -s /bin/bash www-data

# Install composer
RUN curl -sS https://getcomposer.org/installer | \
    php -- --install-dir=/usr/bin/ --filename=composer
