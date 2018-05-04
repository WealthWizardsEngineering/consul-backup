FROM alpine:latest

ENV CONSUL_VERSION=1.0.6
RUN apk add --no-cache bash py-pip py-setuptools curl gnupg jq
RUN rm -rf /var/cache/apk/*

RUN pip install --no-cache-dir s3cmd

RUN curl -LO https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
RUN unzip consul_${CONSUL_VERSION}_linux_amd64.zip && \
    mv consul /usr/local/bin/ && \
    rm consul_${CONSUL_VERSION}_linux_amd64.zip

ADD files/backup.sh backup.sh
ADD files/environment.sh environment.sh
ADD files/restore.sh restore.sh
ADD files/s3cfg /root/.s3cfg

CMD ["/backup.sh"]
