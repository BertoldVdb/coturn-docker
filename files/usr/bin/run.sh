#!/bin/sh


FILE=/tmp/turnserver.conf
REALM=`hexdump -n 8 -e '2/4 "%08x"' /dev/urandom`.turn.bertold.org

echo "listening-port=3478
min-port=49152
max-port=65535
verbose
fingerprint
log-file=stdout
lt-cred-mech
realm=$REALM
stale-nonce=600
dh-file=/etc/dh2048.pem
no-multicast-peers
no-tlsv1" > $FILE

#Add secret if needed
if [ "x$TURN_SECRET" != "x" ]; then
    echo "static-auth-secret=$TURN_SECRET" >> $FILE
    echo "use-auth-secret" >> $FILE
fi

if [ "x$SSL" != "x" ]; then
    while [ ! -f $SSL ]; do
        echo "$SSL does not exist"
        sleep 1
    done
    echo "cert=$SSL" >> $FILE
    echo "pkey=$SSL" >> $FILE
else
    echo "no-tls" >> $FILE
    echo "no-dtls" >> $FILE
fi

#Lookup our external IP
SERVICE='https://api-public.bertold.org/ip?app=coturn_docker'
IP4=`curl -4 $SERVICE`

if [ "x$IP4" != "x" ]; then
    DEV=`ip route list match 0/0 | awk  '{print $5}'`
    IP4L=`ip -f inet addr show $DEV | sed -En -e 's/.*inet ([0-9.]+).*/\1/p'`

    echo "Found IPv4 address: $IP4 (local $IP4L)"
    echo "external-ip=$IP4/$IP4L" >> $FILE
    echo "relay-ip=$IP4L" >> $FILE
    echo "listening-ip=$IP4L" >> $FILE
else
    echo "Could not find IPv4 address"
    exit
fi

IP6=`curl -6 $SERVICE`

if [ "x$IP6" != "x" ]; then
    #Warning this not compatible with IPv6 privacy addresses
    echo "Found IPv6 address: $IP6 (Assuming no NAT)"
    echo "external-ip=$IP6/$IP6" >> $FILE
    echo "relay-ip=$IP6" >> $FILE
    echo "listening-ip=$IP6" >> $FILE
fi

exec /usr/bin/turnserver -c $FILE
