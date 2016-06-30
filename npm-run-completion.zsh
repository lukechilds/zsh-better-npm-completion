_npm_run_completion() {
  if [ "${words[2]}" = "run" ]; then
    local filename="package.json"
    local dir=$PWD
    while [ ! -e "$dir/$filename" ]; do
      dir=${dir%/*}
      if [ "$dir" = "" ]; then
          break
        fi
    done
    if [ ! "$dir" = "" ] && type node > /dev/null; then
      local options=("${(@f)$(node -e "var pkg = require('$dir/$filename'); pkg.scripts && Object.keys(pkg.scripts).forEach(function(script) { console.log(script.replace(':', '\\\:')+':$ '+pkg.scripts[script]) })")}")
      _describe 'values' options
    fi
  fi
}

compdef _npm_run_completion npm
