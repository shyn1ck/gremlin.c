#!/bin/bash
# ci/prove.sh <set> <writer|reader> <shard> <shards>
set -u
set_name=$1; side=$2; shard=$3; shards=$4
root=$PWD; G=$root/build/gremlinc-gen/gremlinc-gen; O=$root/out/$set_name; mkdir -p $O
X=
case $set_name in
fixture) $G -R integration-test/verify -o $O wp_writer.proto; H=$O/wp_writer.pb.h
         X=-DCALLERS=$root/integration-test/verify/wp_writer_callers.c;;
normfs)  $G -R ci -o $O normfs.proto; H=$O/normfs.pb.h;;
*)       (cd descriptors/tests/proto_corpus && $G -R . -o $O $(find . -name '*.proto' | sed 's|^\./||' | sort)); H=$O/$set_name.pb.h;;
esac
cmake -DFRAMAC=$(command -v frama-c) -DHEADER=$H -DRUNTIME_INCLUDE=$root/runtime/include \
  -DREPORT=$root/report/$set_name-$side-$shard.json -DSHARD=$shard -DSHARDS=$shards $X \
  -P integration-test/verify/verify_$side.cmake
