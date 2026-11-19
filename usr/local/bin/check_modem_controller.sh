#!/bin/sh
[ $(/usr/local/bin/cliclient -g RequestResult.Success GetAirMACAddress) == "true" ]

