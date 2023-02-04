#!/bin/bash
nohup /usr/local/bin/enable-login.sh &

exec /usr/sbin/init
