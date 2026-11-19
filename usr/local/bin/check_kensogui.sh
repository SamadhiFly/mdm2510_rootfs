#!/bin/sh

HTTP_CODE=$(wget --spider -nv 'http://localhost/cgi-bin/index?health-check' 2>&1)
ERR_CODE=$?

if [ $ERR_CODE -ne 0 ]; then
    exit 1
fi

if [ "$HTTP_CODE" != "200 OK" ]; then
    exit 1
fi

exit 0
