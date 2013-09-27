#!/bin/sh

grep -a signature= /home/alex/Downloads/amd-driver-installer-catalyst-13-4-x86.x86_64.run | cut -d '"' -f2 > /etc/ati/signature
