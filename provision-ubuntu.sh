#!/usr/bin/env bash

# i took these from https://github.com/sstephenson/ruby-build/blob/master/bin/ruby-build
compute_md5() {
  if type md5 &>/dev/null; then
    md5 -q
  elif type openssl &>/dev/null; then
    local output="$(openssl md5)"
    echo "${output##* }"
  elif type md5sum &>/dev/null; then
    local output="$(md5sum -b)"
    echo "${output% *}"
  else
    return 1
  fi
}

verify_checksum() {
  # If there's no MD5 support, return success
  [ -n "$HAS_MD5_SUPPORT" ] || return 0

  # If the specified filename doesn't exist, return success
  local filename="$1"
  [ -e "$filename" ] || return 0

  # If there's no expected checksum, return success
  local expected_checksum=`echo "$2" | tr [A-Z] [a-z]`
  [ -n "$expected_checksum" ] || return 0

  # If the computed checksum is empty, return failure
  local computed_checksum=`echo "$(compute_md5 < "$filename")" | tr [A-Z] [a-z]`
  [ -n "$computed_checksum" ] || return 1

  if [ "$expected_checksum" != "$computed_checksum" ]; then
    { echo
      echo "checksum mismatch: ${filename} (file is corrupt)"
      echo "expected $expected_checksum, got $computed_checksum"
      echo
    } >&4
    return 1
  fi
}

download_unless_exist() {
  local filename=`basename $1`
  local url="$1"
  if [[ -e "$filename" ]]; then
      return 0
  fi
  `wget "$url"`
}

sudo apt-get update
sudo apt-get install -y build-essential libncurses5-dev openssl libssl-dev git curl libpam0g-dev expect openjdk-7-jdk 

riak_version="2.0.0pre20"
riak_build="1"
download_unless_exist "http://s3.amazonaws.com/downloads.basho.com/riak/2.0/${riak_version}/ubuntu/precise/riak_${riak_version}-${riak_build}_amd64.deb"

dpkg -i riak_${riak_version}-${riak_build}_amd64.deb

sed -e 's/yokozuna = off/yokozuna = on/;' -i.back /etc/riak/riak.conf
sed -e 's/anti_entropy = on/anti_entropy = off/;' -i.back /etc/riak/riak.conf
sed -e 's/storage_backend = bitcask/storage_backend = memory/;' -i.back /etc/riak/riak.conf
sed -e 's/listener.http.internal = 127.0.0.1:8098/listener.http.internal = 0.0.0.0:8098/;' -i.back /etc/riak/riak.conf
sed -e 's/listener.protobuf.internal = 127.0.0.1:8087/listener.protobuf.internal = 0.0.0.0:8087/;' -i.back /etc/riak/riak.conf

sudo riak stop
rm -rvf /var/lib/riak/{data,log}/*
ulimit -n 8192
sudo riak start
sudo riak ping
