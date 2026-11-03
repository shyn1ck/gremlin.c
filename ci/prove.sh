#!/bin/bash
# ci/prove.sh <set> <writer|reader> <shard> <shards>
set -u
set_name=$1; side=$2; shard=$3; shards=$4; sub=${5:-0}; subs=${6:-0}
root=$PWD; G=$root/build/gremlinc-gen/gremlinc-gen; O=$root/out/$set_name; mkdir -p $O
X=
case $set_name in
fixture) $G -R integration-test/verify -o $O wp_writer.proto; H=$O/wp_writer.pb.h
         X=-DCALLERS=$root/integration-test/verify/wp_writer_callers.c;;
normfs)  $G -R ci -o $O normfs.proto; H=$O/normfs.pb.h;;
*)       (cd descriptors/tests/proto_corpus && $G -R . -o $O $(find . -name '*.proto' | sed 's|^\./||' | sort)); H=$O/$set_name.pb.h;;
esac
# FCT/PIDX: prove one function under one ci/props.py selection; EXCLUDE: skip these functions.
tag=$shard-$sub; P=()
if [ -n "${FCT:-}" ]; then
  all=$(python3 ci/props.py $(grep -l "^$FCT(" $O/*.pb.h) $FCT) || exit 1
  [ "$(echo "$all" | wc -l)" -eq "$NP" ] || { echo "$FCT has $(echo "$all" | wc -l) selections, plan has $NP"; exit 1; }
  props=$(echo "$all" | sed -n "$((PIDX + 1))p")
  [ -n "$props" ] || { echo "no selection $PIDX for $FCT"; exit 1; }
  P=(-DFCT=$FCT "-DPROPS=$props"); tag=$FCT-p$PIDX; shards=0
fi
[ -n "${EXCLUDE:-}" ] && P+=("-DEXCLUDE=$EXCLUDE")
cmake -DFRAMAC=$(command -v frama-c) -DHEADER=$H -DRUNTIME_INCLUDE=$root/runtime/include \
  -DREPORT=$root/report/$set_name-$side-$tag.json -DSHARD=$shard -DSHARDS=$shards -DSUB=$sub -DSUBS=$subs $X "${P[@]}" \
  -P integration-test/verify/verify_$side.cmake
