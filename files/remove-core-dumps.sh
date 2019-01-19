#!/bin/bash
# DESC: remove core dump files in home dir
# 20180914
# NOTE, THIS IS A WORKAROUND
/usr/bin/find /home/ -type f -name 'core.[0-9]*' -exec /bin/rm -fv {} \;
