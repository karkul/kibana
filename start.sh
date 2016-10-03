#!/bin/bash
#
# /usr/local/bin/start.sh
# Start Kibana service
#
# spujadas 2015-10-09; added initial pidfile removal and graceful termination

# WARNING - This script assumes that the ELK services are not running, and is
#   only expected to be run once, when the container is started.<<
#   Do not attempt to run this script if the ELK services are running (or be
#   prepared to reap zombie processes).

set -e 

## handle termination gracefully

_term() {
  echo "Terminating ELK"
  service kibana stop
  exit 0
}

trap _term SIGTERM

## Oddly, crond needs to be started while the container is running
# so lets do that now
service cron start


## remove pidfiles in case previous graceful termination failed
# NOTE - This is the reason for the WARNING at the top - it's a bit hackish, 
#   but if it's good enough for Fedora (https://goo.gl/88eyXJ), it's good
#   enough for me :)

rm -f /var/run/kibana4.pid

## initialise list of log files to stream in console (initially empty)
OUTPUT_LOGFILES=""

## Validate variables
#if [ -z "$1" ]; then
#  echo "elasticsearch.url: 'http://localhost:9200'" >> /opt/kibana/config/kibana.yml
#else 
#  echo "elasticsearch.url: "${ELASTICSEARCH_HOST} >> /opt/kibana/config/kibana.yml


## start services as needed

# Kibana
if [ -z "$KIBANA_START" ]; then
  KIBANA_START=1
fi
if [ "$KIBANA_START" -ne "1" ]; then
  echo "KIBANA_START is set to something different from 1, not starting..."
else
  service kibana start
  OUTPUT_LOGFILES+="/var/log/kibana/kibana4.log "
fi

# Exit if nothing has been started
if [ "$ELASTICSEARCH_START" -ne "1" ] && [ "$LOGSTASH_START" -ne "1" ] \
  && [ "$KIBANA_START" -ne "1" ]; then
  >&2 echo "No services started. Exiting."
  exit 1
fi

tail -f $OUTPUT_LOGFILES &
wait
