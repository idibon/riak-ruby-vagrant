#!/usr/bin/env bash

download_unless_exist() {
  local filename=`basename $1`
  local url="$1"
  if [[ -e "$filename" ]]; then
      return 0
  fi
  `wget "$url"`
}

sudo apt-get update
sudo apt-get install -y openjdk-7-jre-headless

riak_version="2.0.0pre20"
riak_build="1"
download_unless_exist "http://s3.amazonaws.com/downloads.basho.com/riak/2.0/${riak_version}/ubuntu/precise/riak_${riak_version}-${riak_build}_amd64.deb"

dpkg -i riak_${riak_version}-${riak_build}_amd64.deb

sed -e 's/search = .*/search = on/;' -i /etc/riak/riak.conf
sed -e 's/anti_entropy = .*/anti_entropy = passive/;' -i /etc/riak/riak.conf
sed -e 's/storage_backend = .*/storage_backend = memory/;' -i /etc/riak/riak.conf
sed -e 's/listener.http.internal = .*/listener.http.internal = 0.0.0.0:8098/;' -i /etc/riak/riak.conf
sed -e 's/listener.protobuf.internal = .*/listener.protobuf.internal = 0.0.0.0:8087/;' -i /etc/riak/riak.conf


sudo riak stop
rm -rvf /var/lib/riak/{data,log}/*
ulimit -n 8192

sudo riak start
sudo riak ping
