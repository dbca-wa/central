#!/usr/bin/env bash

echo "generating local service configuration.."

ENKETO_API_KEY=$(cat /etc/secrets/enketo-api-key) \
    envsubst '$DOMAIN $BASE_URL $SYSADMIN_EMAIL $SERVICE_EMAIL $ENKETO_API_KEY $HTTPS_PORT $DB_HOST $DB_USER $DB_PASSWORD $DB_NAME $DB_SSL $EMAIL_HOST $EMAIL_PORT $EMAIL_SECURE' \
    < /usr/share/odk/config.json.template \
    > /usr/odk/config/local.json

echo "running migrations.."
node -e 'const { withDatabase, migrate } = require("./lib/model/migrate"); withDatabase(require("config").get("default.database"))(migrate);'

echo "checking migration success.."
node -e 'const { withDatabase, checkMigrations } = require("./lib/model/migrate"); withDatabase(require("config").get("default.database"))(checkMigrations);'

if [ $? -eq 1 ]; then
  echo "*** Error starting ODK! ***"
  echo "After attempting to automatically migrate the database, we have detected unapplied migrations, which suggests a problem with the database migration step. Please look in the console above this message for any errors and post what you find in the forum: https://forum.getodk.org/"
  exit 1
fi

echo "starting cron.."
cron -f &

MEMTOT=$(vmstat -s | grep 'total memory' | awk '{ print $1 }')
if [ "$MEMTOT" -gt "1100000" ]
then
  WORKER_COUNT=4
else
  WORKER_COUNT=1
fi
echo "using $WORKER_COUNT worker(s) based on available memory ($MEMTOT).."

echo "starting server."
pm2-runtime ./pm2.config.js --instances $WORKER_COUNT

