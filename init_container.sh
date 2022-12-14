#!/bin/bash
cat >/etc/motd <<EOL
  _____
  /  _  \ __________ _________   ____
 /  /_\  \\___   /  |  \_  __ \_/ __ \
/    |    \/    /|  |  /|  | \/\  ___/
\____|__  /_____ \____/ |__|    \___  >
        \/      \/                  \/
A P P   S E R V I C E   O N   L I N U X
Documentation: http://aka.ms/webapp-linux
PHP quickstart: https://aka.ms/php-qs
PHP version : `php -v | head -n 1 | cut -d ' ' -f 2`
EOL
cat /etc/motd

# Get environment variables to show up in SSH session
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

# starting sshd process
sed -i "s/SSH_PORT/$SSH_PORT/g" /etc/ssh/sshd_config
/usr/sbin/sshd

# Migrations
/usr/local/bin/php artisan migrate --force

# Clear caches
/usr/local/bin/php artisan cache:clear

# Clear and cache routes
/usr/local/bin/php artisan route:cache

# Clear and cache config
/usr/local/bin/php artisan config:cache

# Clear and cache config
/usr/local/bin/php artisan view:cache

userStartupCommand="$@"
if [ -z "$userStartupCommand" ]
then
  userStartupCommand="/usr/bin/supervisord -c /etc/supervisor/conf.d/php-app.conf";
else
  userStartupCommand="$userStartupCommand; /usr/bin/supervisord -c /etc/supervisor/conf.d/php-app.conf;"
fi

$userStartupCommand
