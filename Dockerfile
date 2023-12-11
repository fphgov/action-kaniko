FROM alpine as builder

RUN apk --update add ca-certificates

RUN mkdir /kaniko && \
    wget -O /kaniko/jq \
    https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x /kaniko/jq && \
    wget -O /kaniko/reg \
    https://github.com/genuinetools/reg/releases/download/v0.16.1/reg-linux-386 && \
    chmod +x /kaniko/reg && \
    wget -O /crane.tar.gz \ 
    https://github.com/google/go-containerregistry/releases/download/v0.8.0/go-containerregistry_Linux_x86_64.tar.gz && \
    tar -xvzf /crane.tar.gz crane -C /kaniko && \
    rm /crane.tar.gz

FROM busybox:musl AS busybox

FROM  gcr.io/kaniko-project/executor:latest 

COPY --from=busybox /bin /busybox
VOLUME /busybox

RUN ["/busybox/mkdir", "-p", "/bin"]
RUN ["/busybox/ln", "-s", "/busybox/sh", "/bin/sh"]
RUN ["/busybox/ln", "-s", "/busybox/cat", "/bin/cat"]
RUN ["/busybox/ln", "-s", "/busybox/sed", "/bin/sed"]

COPY entrypoint.sh /
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /kaniko /kaniko

ENTRYPOINT ["/entrypoint.sh"]

LABEL repository="https://github.com/aevea/action-kaniko" \
    maintainer="Alex Viscreanu <alexviscreanu@gmail.com>"
