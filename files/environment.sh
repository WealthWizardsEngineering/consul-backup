#!/bin/bash
set -eo pipefail

# Define where and how to send events to influx
POST2INFLUX="curl -XPOST --data-binary @- ${INFLUXDB_URL}"

# Allow me to pass a KUBE_SA_TOKEN so I can test this without having to run it on Kube
if [[ -z $KUBE_SA_TOKEN ]]; then
  KUBE_SA_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
fi

#########################################################################

echo "Getting secrets from Vault server: ${VAULT_ADDR}"

# Login to Vault and so I can get an approle token
VAULT_LOGIN_TOKEN=$(curl -sS --request POST \
  ${VAULT_ADDR}/v1/auth/${KUBERNETES_AUTH_PATH}/login \
  -H "Content-Type: application/json" \
  -d '{"role":"'"${VAULT_LOGIN_ROLE}"'","jwt":"'"${KUBE_SA_TOKEN}"'"}' | \
  jq -r 'if .errors then . else .auth.client_token end')

ROLE_ID=$(curl -sS --header "X-Vault-Token: ${VAULT_LOGIN_TOKEN}" \
  ${VAULT_ADDR}/v1/auth/approle/role/${VAULT_LOGIN_ROLE}/role-id | \
  jq -r 'if .errors then . else .data.role_id end')

SECRET_ID=$(curl -sS --header "X-Vault-Token: ${VAULT_LOGIN_TOKEN}" \
  --request POST \
  ${VAULT_ADDR}/v1/auth/approle/role/${VAULT_LOGIN_ROLE}/secret-id | \
  jq -r 'if .errors then . else .data.secret_id end')

APPROLE_TOKEN=$(curl -sS --request POST \
  --data '{"role_id":"'"$ROLE_ID"'","secret_id":"'"$SECRET_ID"'"}' \
  ${VAULT_ADDR}/v1/auth/approle/login | \
  jq -r 'if .errors then . else .auth.client_token end')

#########################################################################

# $APPROLE_TOKEN allows me to get the secrets that I actually need to do my stuff
AWS_KEYS=$(curl -sS --header "X-Vault-Token: ${APPROLE_TOKEN}" \
    ${VAULT_ADDR}/v1/${VAULT_AWS_AUTH_PATH}/creds/${AWS_IAM_POLICY})
export ACCESS_KEY=$(echo $AWS_KEYS | jq -r '.data.access_key')
export SECRET_KEY=$(echo $AWS_KEYS | jq -r '.data.secret_key')

export GPG_PHRASE=$(curl -sS --header "X-Vault-Token: ${APPROLE_TOKEN}" \
    ${VAULT_ADDR}/v1/secret/infrastructure/${VAULT_LOGIN_ROLE} | \
    jq -r 'if .errors then . else .data.gpg_phrase end')

export CONSUL_HTTP_TOKEN=$(curl -sS --header "X-Vault-Token: ${APPROLE_TOKEN}" \
    ${VAULT_ADDR}/v1/consul/creds/management | \
    jq -r 'if .errors then . else .data.token end')

#########################################################################
# If Vault response contains '.errors' key then something went wrong; this should be logged
# For example:
#   - {{ "errors": [ "invalid role name \"non_existent_role\"" ] }
#   - {"errors":["permission denied"]}
for i in "$VAULT_LOGIN_TOKEN" "$ROLE_ID" "$SECRET_ID" \
          "$APPROLE_TOKEN" "$AWS_KEYS" "$GPG_PHRASE" "$CONSUL_HTTP_TOKEN"; do
  if [[ $(echo $i | grep errors) ]]; then
    echo $i
    exit 1
  fi
done

#########################################################################

# IAM is eventualy consistent; need to wait a bit... or use STS Assume Role :)
echo "Need to wait for IAM consistency, sleep 10..."
sleep 10

#########################################################################
