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
# https://github.com/Azure-Samples/docker-django-webapp-linux/blob/master/Dockerfile
# https://learn.microsoft.com/en-us/answers/questions/470087/unable-to-ssh-into-web-app.html
ENV SSH_PASSWD "root:Docker!"
ENV SSH_PORT 2222
RUN apk update \
    && apk add dialog openssh-server \
    && echo "$SSH_PASSWD" | chpasswd

# configure startup
COPY sshd_config /etc/ssh/
COPY ssh_setup.sh /tmp
RUN chmod -R +x /tmp/ssh_setup.sh \
   && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null) \
   && rm -rf /tmp/*

ENV PORT 8080
ENV SSH_PORT 2222
EXPOSE 2222 8080
COPY sshd_config /etc/ssh/

CMD ["/usr/local/bin/php", "-d", "variables_order=EGPCS", "/var/www/html/artisan", "serve", "--host=0.0.0.0", "--port=8080"]
