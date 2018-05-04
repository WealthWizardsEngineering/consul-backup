#!/bin/bash -e

unset_vars() {
  unset GPG_PHRASE
  unset CONSUL_HTTP_TOKEN
  unset ACCESS_KEY
  unset SECRET_KEY
}

clean_environment(){
  rm -f consul-backup-*.snap
  rm -f /tmp/tmpfile-*
  unset_vars
}
trap clean_environment EXIT

echo "Backups will be set to run using cron schedule: ${CRON_SCHEDULE}"

BACKUP_FILE="consul-backup-$(date +"%H-%M-%S").snap"
S3_BACKUP_DIR="$(date +"%Y")/$(date +"%m")/$(date +"%d")"

# Define where and how to send events to influx
POST2INFLUX="curl -XPOST --data-binary @- ${INFLUXDB_URL}"

# Get CONSUL_HTTP_TOKEN, GPG_PHRASE, ACCESS_KEY and SECRET_KEY
source /environment.sh

# Backup consul
echo "Using CONSUL_HTTP_ADDR: ${CONSUL_HTTP_ADDR}"
echo "Running consul snapshot save"
echo -n "instance_backup_started,instance=consul value=true" | ${POST2INFLUX}
echo -n "database_backup_started,instance=consul,database=consul_kv value=true" | ${POST2INFLUX}
consul snapshot save ${BACKUP_FILE} || { echo "instance_snapshot_failed,instance=consul value=true" | ${POST2INFLUX} && exit 1; }
echo "database_backup_completed,instance=consul,database=consul_kv value=true" | ${POST2INFLUX}

# Inspect the backup
consul snapshot inspect ${BACKUP_FILE} || { echo "instance_inspect_failed,instance=consul value=true" | ${POST2INFLUX} && exit 1; }


# Push to S3
echo -n "database_s3-put_started,instance=consul,database=consul_kv value=true" | ${POST2INFLUX}
s3cmd put  ${BACKUP_FILE} s3://${S3_BUCKET}/${S3_BACKUP_DIR}/${BACKUP_FILE} || { echo "instance_s3-put_failed,instance=consul value=true" | ${POST2INFLUX} && exit 1; }
echo -n "database_s3-put_completed,instance=consul,database=consul_kv value=true" | ${POST2INFLUX}
echo -n "instance_backup_completed,instance=consul value=true" | ${POST2INFLUX}
