#!/bin/sh

# Fix up redis configuration file
sed -i "s/^daemonize yes/daemonize no/g" /etc/redis/redis.conf
# Look for more consistancy. Since this is a mostly-read database,
# I don't expect a big performance impact.
sed -i "s/^appendonly no/appendonly yes/g" /etc/redis/redis.conf
# Be sure to bind on all interfaces
sed -i "s/^bind 127.0.0.1/bind 0.0.0.0/g" /etc/redis/redis.conf

# Merge configuration via environment variable into default.
config="/usr/local/lib/node_modules/hipache/config/config_generated.json"
echo $HIPACHE_CONFIG | cat /usr/local/lib/node_modules/hipache/config/config.json - | json --merge > $config

if [ -n "$SSL_KEY" ]; then
    file=$(cat $config | json server.https.key)
    echo "Writing SSL_KEY to $file"
    mkdir -p "$(dirname $file)"
    echo "$SSL_KEY" > $file
fi

if [ -n "$SSL_CERT" ]; then
    file=$(cat $config | json server.https.cert)
    echo "Writing SSL_CERT to $file"
    mkdir -p "$(dirname $file)"
    echo "$SSL_CERT" > $file
fi

if [ -z "$SSL_KEY" ]; then
    echo "Removing server.https section, SSL_KEY not defined"
    cfgcnt=$(cat $config)
    echo $cfgcnt | json -e "server.https=undefined" > $config
fi

# Start services as the base image does.
supervisord -n
