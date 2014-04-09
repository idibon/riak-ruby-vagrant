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

sed -e 's/search = .*/search = on/;' -i.back /etc/riak/riak.conf
sed -e 's/anti_entropy = .*/anti_entropy = passive/;' -i.back /etc/riak/riak.conf
sed -e 's/storage_backend = bitcask/storage_backend = memory/;' -i.back /etc/riak/riak.conf
sed -e 's/listener.http.internal = 127.0.0.1:8098/listener.http.internal = 0.0.0.0:8098/;' -i.back /etc/riak/riak.conf
sed -e 's/listener.protobuf.internal = 127.0.0.1:8087/listener.protobuf.internal = 0.0.0.0:8087/;' -i.back /etc/riak/riak.conf
cp /vagrant/advanced.config /etc/riak/advanced.config

sudo riak stop
rm -rvf /var/lib/riak/{data,log}/*
ulimit -n 8192

# expect - <<END_EXPECT
# spawn riak console
# expect "(riak@127.0.0.1)1>"
# send "riak_core_bucket_type:create\(<<\"maps\">>, \[\{datatype, map\}, \{allow_mult, true\}\]\), riak_core_bucket_type:activate\(<<\"maps\">>\),riak_core_bucket_type:create\(<<\"sets\">>, \[\{datatype, set\}, \{allow_mult, true\}\]\), riak_core_bucket_type:activate\(<<\"sets\">>),riak_core_bucket_type:create\(<<\"counters\">>, \[\{datatype, counter\}, \{allow_mult, true\}\]\), riak_core_bucket_type:activate\(<<\"counters\">>\).\n"
# expect "ok"
# send "\007"
# send "q\n"
# END_EXPECT

sudo riak start
sudo riak ping
