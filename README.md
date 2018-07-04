# magento2-base
Magento 2 Base image

## Adding your project
Add a Dockerfile to your project, containing something like

```
FROM trimm/magento2-base AS build
WORKDIR /var/www/html
COPY composer.json composer.lock /var/www/html/
RUN composer install --no-interaction --prefer-dist --no-progress

FROM trimm/magento2-base
MAINTAINER Mark Wienk <mark.wienk@trimm.nl>
# Copy vendor dependencies
COPY --from=build /var/www/html /var/www/html
# Copy custom code
COPY app generated pub /var/www/html/
RUN chown -R www-data:www-data /var/www/html
CMD ["apache2-foreground"]
```
