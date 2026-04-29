#!/usr/bin/env bash
cd "$(dirname "$0")"

pids=()
for wav in data/resynth/*.wav; do
    arr="${wav%.wav}.arr"
    args="arbsynth_preproc_128.ck:$wav:$arr:15:1"
    chuck --silent $args &   # spork!
    pids+=($!)
done

for pid in "${pids[@]}"; do
    wait "$pid"
done

echo "done"
