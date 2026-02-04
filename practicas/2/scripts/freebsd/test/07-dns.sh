#!/bin/bash

# Desde el host

# Falla
nslookup bsd.asorc.org
# Bien
nslookup bsd.asorc.org 192.168.25.11
# Bien
nslookup truenas.bsd.asorc.org 192.168.25.11
# Falla
nslookup truenas.bsd.asorc.org

nslookup tabarca.cpd.ua.es 192.168.25.11
nslookup 193.145.233.5 192.168.25.11
