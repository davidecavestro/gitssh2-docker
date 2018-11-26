#!/bin/sh
# init script, should be kept idempotent, as it is executed at every restart

function errcho { (>&2 echo "$name: $1") }
{
cd /var/www/html/git-web-client
errcho "waiting for $SYMFONY__APP__DB__HOST:$SYMFONY__APP__DB__PORT"
# waits for db
/wait-for $SYMFONY__APP__DB__HOST:$SYMFONY__APP__DB__PORT
errcho "init db structures"
php app/console version:install
errcho "create admin"
php app/console version:admin:create $APP_ADMIN_USER $APP_ADMIN_EMAIL $APP_ADMIN_PASSWORD admin

tail -f /dev/null

} 2>&1 | tee -a /var/log/init/init.log 2>&1
