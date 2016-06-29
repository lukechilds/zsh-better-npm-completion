_npm_run_completion() {
  local filename="package.json"
  local dir=$PWD
  while [ ! -e "$dir/$filename" ]; do
    dir=${dir%/*}
    if [ "$dir" = "" ]; then
        break
      fi
  done
  if [ ! "$dir" = "" ]; then
    echo "$dir/$filename"
  fi
}
