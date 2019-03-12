# Magento 2 - Base image

This image can be used for a custom Magento 2 environment.

It does not contain any application code, add a Dockerfile to your project with:

```
FROM trimm/magento2-base

# Add application dependencies
COPY --chown=www-data:www-data . /var/www
RUN composer install --no-autoloader --no-progress --no-dev
RUN composer dump-autoload --optimize
```