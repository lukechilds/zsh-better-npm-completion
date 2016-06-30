_npm_run_completion() {

  # If we're on the run command
  if [ "${words[2]}" = "run" ]; then

    # Look for a package.json file
    local filename="package.json"
    local dir=$PWD
    while [ ! -e "$dir/$filename" ]; do
      dir=${dir%/*}
      if [ "$dir" = "" ]; then
          break
        fi
    done

    # If we have one, parse the scripts
    if [ ! "$dir" = "" ] && type node > /dev/null; then
      local options=("${(@f)$(node -e "var pkg = require('$dir/$filename'); pkg.scripts && Object.keys(pkg.scripts).forEach(function(script) { console.log(script.replace(':', '\\\:')+':$ '+pkg.scripts[script]) })")}")
      _describe 'values' options
    fi

  # Fall back to default completion for all other npm commands
  else
    compadd -- $(COMP_CWORD=$((CURRENT-1)) \
                COMP_LINE=$BUFFER \
                COMP_POINT=0 \
                npm completion -- "${words[@]}" \
                2>/dev/null)
    IFS=$si
  fi
}

compdef _npm_run_completion npm
