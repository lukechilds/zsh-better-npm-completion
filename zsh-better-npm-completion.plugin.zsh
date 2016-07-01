_zbnc_npm_command() {
  echo "${words[2]}"
}

_zbnc_recursively_look_for() {
  local filename="$1"
  local dir=$PWD
  while [ ! -e "$dir/$filename" ]; do
    dir=${dir%/*}
    [ "$dir" = "" ] && break
  done
  [ ! "$dir" = "" ] && echo "$dir/$filename"
}

_zbnc_parse_package_json_for_script_suggestions() {
  local package_json="$1"
  cat "$package_json" |
    sed -nE '/^  "scripts": \{$/,/^  \},?$/p' |       # Grab scripts object
    sed '1d;$d' |                                     # Remove first/last lines
    sed -E 's/    "([^"]+)": "([^"]+)",?/\1:$ \2/' |  # Parse commands into suggestions
    sed 's/\(:\)[^ ]*:/\\&/'                          # Escape ":" in commands
}

_zbnc_default_npm_completion() {
  compadd -- $(COMP_CWORD=$((CURRENT-1)) \
              COMP_LINE=$BUFFER \
              COMP_POINT=0 \
              npm completion -- "${words[@]}" \
              2>/dev/null)
}

_zbnc_zsh_better_npm_completion() {

  # If we're on the run command
  if [ "$(_zbnc_npm_command)" = "run" ]; then

    # Look for a package.json file
    local package_json="$(_zbnc_recursively_look_for package.json)"

    # If we have one, parse the scripts
    if [ ! "$package_json" = "" ]; then
      local options=("${(@f)$(_zbnc_parse_package_json_for_script_suggestions "$package_json")}")
      if [ ! "$#options" = 0 ]; then
        _describe 'values' options
        return
      fi
    fi
  fi

  # Fall back to default completion if anything above failed
  _zbnc_default_npm_completion
}

compdef _zbnc_zsh_better_npm_completion npm
