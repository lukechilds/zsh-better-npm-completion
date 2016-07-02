_zbnc_npm_command() {
  echo "${words[2]}"
}

_zbnc_no_of_npm_args() {
  echo "$#words"
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
    sed -E 's/    "([^"]+)": "(.+)",?/\1:$ \2/' |     # Parse commands into suggestions
    sed 's/\(:\)[^$]/\\&/g' |                         # Escape ":" in commands
    sed 's/\(:\)$[^ ]/\\&/g'                          # Escape ":$" without a space in commands
}

_zbnc_npm_install_completion() {

  # Only run on `npm install ?`
  [ ! "$(_zbnc_no_of_npm_args)" = "3" ] && return

  # Reccomend cached modules
  _values $(ls ~/.npm)

  # Make sure we don't run default completion
  custom_completion=true
}

_zbnc_npm_run_completion() {

  # Only run on `npm run ?`
  [ ! "$(_zbnc_no_of_npm_args)" = "3" ] && return

  # Look for a package.json file
  local package_json="$(_zbnc_recursively_look_for package.json)"

  # Return if we can't find package.json
  [ "$package_json" = "" ] && return

  # Parse scripts in package.json
  local options=("${(@f)$(_zbnc_parse_package_json_for_script_suggestions "$package_json")}")

  # Return if we can't parse it
  [ "$#options" = 0 ] && return

  # Load the completions
  _describe 'values' options

  # Make sure we don't run default completion
  custom_completion=true
}

_zbnc_default_npm_completion() {
  compadd -- $(COMP_CWORD=$((CURRENT-1)) \
              COMP_LINE=$BUFFER \
              COMP_POINT=0 \
              npm completion -- "${words[@]}" \
              2>/dev/null)
}

_zbnc_zsh_better_npm_completion() {

  # Store custom completion status
  local custom_completion=false

  # Load custom completion commands
  case "$(_zbnc_npm_command)" in
    install)
      _zbnc_npm_install_completion
      ;;
    run)
      _zbnc_npm_run_completion
      ;;
  esac

  # Fall back to default completion if we haven't done a custom one
  [ $custom_completion = false ] && _zbnc_default_npm_completion
}

compdef _zbnc_zsh_better_npm_completion npm
