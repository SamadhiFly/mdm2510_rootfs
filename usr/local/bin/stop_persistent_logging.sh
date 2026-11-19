#!/bin/sh

# kill process if exists if not ignore the outcome
killall -15 rotator || true

# change monitoring state if possible if not ignore the outcome
clish -u newtec -c debug monitoring status set off || true