#!/usr/bin/env bash

# Configure Sendmail if required
if [ "$ENABLE_SENDMAIL" == "true" ]; then
    /etc/init.d/sendmail start
fi

if [ ! -f /var/www/html/app/etc/env.php ]; then
    sudo -E -u www-data cp /var/www/html/app/etc/env.example /var/www/html/app/etc/env.php
fi

if ! sudo -E -u www-data php /var/www/html/bin/magento store:list; then
    rm -rf /var/www/html/app/etc/env.php
    echo "Installing Magento 2"
    sudo -E -u www-data php /var/www/html/bin/magento setup:install \
        --base-url=$MAGENTO_URL \
        --backend-frontname=$MAGENTO_BACKEND_FRONTNAME \
        --language=$MAGENTO_LANGUAGE \
        --timezone=$MAGENTO_TIMEZONE \
        --currency=$MAGENTO_DEFAULT_CURRENCY \
        --db-host=$MAGENTO_DATABASE_HOST \
        --db-name=$MAGENTO_DATABASE_DB \
        --db-user=$MAGENTO_DATABASE_USER \
        --db-password=$MAGENTO_DATABASE_PASS \
        --use-secure=$MAGENTO_USE_SECURE \
        --base-url-secure=$MAGENTO_BASE_URL_SECURE \
        --use-secure-admin=$MAGENTO_USE_SECURE_ADMIN \
        --admin-firstname=$MAGENTO_ADMIN_FIRSTNAME \
        --admin-lastname=$MAGENTO_ADMIN_LASTNAME \
        --admin-email=$MAGENTO_ADMIN_EMAIL \
        --admin-user=$MAGENTO_ADMIN_USERNAME \
        --admin-password=$MAGENTO_ADMIN_PASSWORD
    echo "Installing Magento 2 [DONE]"
    rm -rf /var/www/html/app/etc/env.php
    cp /var/www/html/app/etc/env.example /var/www/html/app/etc/env.php
else
    echo "Magento 2 installed already"
fi

echo "Import Magento 2 configuration file"
sudo -E -u www-data php /var/www/html/bin/magento app:config:import

# Execute the supplied command
exec "$@"