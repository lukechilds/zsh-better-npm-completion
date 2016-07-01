_zsh_better_npm_completion() {

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
    if [ ! "$dir" = "" ]; then
      local options=("${(@f)$(cat "$dir/$filename" | sed -nE '/^  "scripts": \{$/,/^  \},?$/p' | sed '1d;$d' | sed -E 's/    "([^"]+)": "([^"]+)",?/\1:$ \2/' | sed 's/\(:\)[^ ]*:/\\&/')}")
      if [ ! "$#options" = 0 ]; then
        _describe 'values' options
        return
      fi
    fi
  fi

  # Fall back to default completion if anything above failed
  compadd -- $(COMP_CWORD=$((CURRENT-1)) \
              COMP_LINE=$BUFFER \
              COMP_POINT=0 \
              npm completion -- "${words[@]}" \
              2>/dev/null)
  IFS=$si
}

compdef _zsh_better_npm_completion npm
