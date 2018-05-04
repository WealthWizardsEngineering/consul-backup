#!/bin/bash -e

clean_environment(){
  rm -f $LOCAL_FILE
}
trap clean_environment EXIT

export CONSUL_HTTP_TOKEN=$CONSUL_BOOTSTRAP_TOKEN
LOCAL_FILE="backup.snap"

echo ""
echo "Restoring consul snapshot using server $CONSUL_HTTP_ADDR"
echo "Restore using backup file: s3://$S3_BUCKET/$REMOTE_FILE_PATH"
echo ""
echo "  This restore involve a potentially dangerous low-level Raft operation that is not
  designed to handle server failures during a restore. This command is primarily
  intended to be used when recovering from a disaster, restoring into a fresh
  cluster of Consul servers."
echo ""
echo "Do you wish to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes )
          s3cmd get s3://$S3_BUCKET/$REMOTE_FILE_PATH $LOCAL_FILE

          echo "" && echo "Inspecting the backup"
          consul snapshot inspect $LOCAL_FILE

          echo "Performing the restore"
          consul snapshot restore $LOCAL_FILE

          break
          ;;

        No )
          break
          ;;
    esac
done
