#! /bin/sh

scp -r -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no data/* root@139.59.223.135:/mnt/volume_sgp1_01