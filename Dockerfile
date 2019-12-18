# https://hub.docker.com/_/alpine
FROM alpine:edge as builder

#Based on base from Instrumentisto Team <developer@instrumentisto.com>


# Build and install Coturn
RUN apk update \
 && apk upgrade \
 && apk add --no-cache \
        ca-certificates \
        curl \
 && update-ca-certificates \
    \
 # Install Coturn dependencies
 && apk add --no-cache \
        libevent \
        libcrypto1.1 libssl1.1
 
 # Install Coturn build dependencies
 RUN apk add --no-cache --virtual .build-deps \
        linux-headers \
        libevent-dev \
        openssl-dev \
 # Install tools for building
 && apk add --no-cache --virtual .tool-deps \
        coreutils autoconf g++ libtool make \
        git \
        cmake 
 # Download and prepare Coturn sources
ADD https://api.github.com/repos/WaxieSDR/coturn/git/refs/heads/master version.json
RUN cd /tmp && git clone https://github.com/WaxieSDR/coturn.git \
 && cd /tmp/coturn \
 # Build Coturn from sources
 && ./configure --prefix=/usr \
        --turndbdir=/var/lib/coturn \
        --disable-rpath \
        --sysconfdir=/etc/coturn \
 && make \
 # Install and configure Coturn
 && make install \
  # Remove default config file
 && rm -f /etc/coturn/turnserver.conf.default \
    \
 # Cleanup unnecessary stuff
 && apk del .tool-deps .build-deps \
 && rm -rf /var/cache/apk/* \
           /tmp/*

FROM alpine:edge
#Install only dependencies
RUN apk update \
 && apk upgrade \
 && apk add --no-cache \
        ca-certificates \
        curl \
 && update-ca-certificates \
    \
 # Install Coturn dependencies
 && apk add --no-cache \
        libevent \
        libcrypto1.1 libssl1.1

#Install dumb-init
RUN wget -O /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 \
 && chmod +x /usr/bin/dumb-init

#Copy server binary
COPY --from=builder /usr/bin/turnserver /usr/bin/

#Copy extra files
COPY files/ /

ENTRYPOINT ["/usr/bin/dumb-init"]

CMD ["/usr/bin/run.sh"]
#CMD ["/usr/bin/turnserver", "-n", "--log-file=stdout"]
