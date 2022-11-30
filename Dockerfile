FROM composer:latest as build
WORKDIR /app
COPY . /app
RUN composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev

FROM tepcrohmiar.azurecr.io/php81:006302d754b132ac32d30e839659d6adee1a8b09
LABEL maintainer="Einar-Johan Hansen"
COPY --from=build /app /var/www/html/
WORKDIR /var/www/html
RUN cp .env.example .env \
    && touch /var/www/html/database/database.sqlite \
    && php artisan key:generate

# ssh
ENV SSH_PASSWD "root:Docker!"
RUN apk update \
    && apk add dialog  openssh-server \
    && echo "$SSH_PASSWD" | chpasswd

COPY sshd_config /etc/ssh/

EXPOSE 80 2222

CMD ["/usr/local/bin/php", "-d", "variables_order=EGPCS", "/var/www/html/artisan", "serve", "--host=0.0.0.0", "--port=80"]
