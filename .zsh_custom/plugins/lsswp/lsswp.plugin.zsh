function lsswp(){
  for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done | sort -k 2 -n -r | head -n $[`tput lines` - 3]
}

function zswap_ratio(){
  sudo perl -E  "say $(sudo cat /sys/kernel/debug/zswap/stored_pages) * 4096 / $(sudo cat /sys/kernel/debug/zswap/pool_total_size)"
}

function zswap_size(){
  sudo perl -E  "say $(sudo cat /sys/kernel/debug/zswap/pool_total_size)/1000000000"
}

function zswap_same_size(){
  sudo perl -E  "say $(sudo cat /sys/kernel/debug/zswap/same_filled_pages) * 4096 / 1000000000"
}

function zswap_stats(){
  sudo zsh -c 'cd /sys/kernel/debug/zswap && grep -r .' | sed 's:\::\:	:' | column -t
}
