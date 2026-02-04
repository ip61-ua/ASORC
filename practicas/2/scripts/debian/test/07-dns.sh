#!/bin/bash

# Desde el host

# Falla
nslookup debian.asorc.org
# Bien
nslookup debian.asorc.org 192.168.25.10
# Bien
nslookup truenas.debian.asorc.org 192.168.25.10
# Falla
nslookup truenas.debian.asorc.org

nslookup tabarca.cpd.ua.es 192.168.25.10
nslookup 193.145.233.5 192.168.25.10
