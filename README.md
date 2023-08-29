# consul-backup
Backup a Consul cluster used as Vault storage backend and running on Kubernetes

## Run it on Kubernetes:
Edit `k8s-cronjob.yaml` as needed and then run:
`kubectl apply -f k8s-cronjob.yaml`

## Take a one time backup:
Update `env.list` accordingly and run:
`make backup`

## Perform a restore:
Update `env.list` accordingly and run:
`make restore`
##
#### Needed for 'run once' backup
- `KUBE_SA_TOKEN`: JWT generated by the Kubernetes cluster for 'my' service account
- `VAULT_ADDR`: Vault URL, i.e.  https://vault.domain
- `VAULT_LOGIN_ROLE`: Vault role that I can use to login
- `VAULT_AWS_AUTH_PATH`: Vault path that I can use to get my AWS keys
- `AWS_IAM_POLICY`: AWS IAM policy name that allows me to put/get backups to S3 bucket
- `KUBERNETES_AUTH_PATH`: Vault path to use for Kubernetes auth backend
- `INFLUXDB_URL`: InfluxDB URL, i.e. https://influx.domain/write?db=backups so we can send events to it
##
#### Required for both backup and restore operations
- `CONSUL_HTTP_ADDR`: Consul URL, i.e. https://consul.domain
- `S3_BUCKET`: S3 bucket name for storing backups
##
#### Set only for restore
- `REMOTE_FILE_PATH`: 2018/02/16/consul-backup-11-03-17.snap
- `CONSUL_BOOTSTRAP_TOKEN`: what it says on the tin; generated during a new Consul cluster setup
- `ACCESS_KEY`: AWS access key
- `SECRET_KEY`: AWS secret key
