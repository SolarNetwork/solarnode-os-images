#!/usr/bin/env bash

dir=${1:-/}

(
  export LC_ALL=C
  comm -23 <(find $dir -xdev -type f | sort) \
           <(sort -u /var/lib/dpkg/info/*.list)
)

