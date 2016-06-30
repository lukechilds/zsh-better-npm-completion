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
    local options=("${(@f)$(node -e "var pkg = require('$dir/$filename'); pkg.scripts && Object.keys(pkg.scripts).forEach(function(script) { console.log(script+':'+pkg.scripts[script]) })")}")
    _describe 'values' options
  fi
}

compdef _npm_run_completion npm run
