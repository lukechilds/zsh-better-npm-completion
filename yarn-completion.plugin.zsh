_yc_yarn_command() {
  echo "${words[2]}"
}

_yc_yarn_command_arg() {
  echo "${words[3]}"
}

_yc_no_of_yarn_args() {
  echo "$#words"
}

_yc_check_jq() {
  (( ${+commands[jq]} )) || echo "\nyarn-completion needs jq\n"
}

_yc_recursively_look_for() {
  local filename="$1"
  local dir=$PWD
  while [ ! -e "$dir/$filename" ]; do
    dir=${dir%/*}
    [[ "$dir" = "" ]] && break
  done
  [[ ! "$dir" = "" ]] && echo "$dir/$filename"
}

_yc_yarn_add_completion() {
  # Only run on `yarn add ?`
  [[ ! "$(_yc_no_of_yarn_args)" = "3" ]] && return

  local packages=($(yarn cache list --json | jq --raw-output '.data.body[] | .[0]' 2> /dev/null))

  # Return if we don't have any cached modules
  [[ "$#packages" = 0 ]] && return

  # If we do, recommend them
  _values 'packages' $packages
}

_yc_yarn_remove_completion() {
  # Use default yarn completion to recommend global modules
  [[ "$(_yc_yarn_command_arg)" = "-g" ]] ||  [[ "$(_yc_yarn_command_arg)" = "--global" ]] && return

  # Look for a package.json file
  local package_json="$(_yc_recursively_look_for package.json)"

  # Return if we can't find package.json
  [[ "$package_json" = "" ]] && return

  local values=($(jq --raw-output '(.devDependencies, .dependencies) | keys[]' $package_json 2> /dev/null))

  [[ "$#values" = 0 ]] && return

  _values 'installed' $values
}

_yc_yarn_run_completion() {
  # Only run on `yarn run ?`
  [[ ! "$(_yc_no_of_yarn_args)" = "3" ]] && return

  # Look for a package.json file
  local package_json="$(_yc_recursively_look_for package.json)"

  # Return if we can't find package.json
  [[ "$package_json" = "" ]] && return

  local -a scripts
  scripts=(${(f)"$(
      jq --raw-output '
      .scripts | to_entries[] | "\(.key):\(.value | gsub("\n";"\\\\n"))"
    ' $package_json 2> /dev/null
  )"})

  [[ "$#scripts" = 0 ]] && return

  _describe 'scripts' scripts
}

_yc_zsh_better_yarn_completion() {
  # Show yarn commands if not typed yet
  [[ $(_yc_no_of_yarn_args) -le 2 ]] && _yarn "$@" && return

  # Load custom completion commands
  case "$(_yc_yarn_command)" in
    add)
      _yc_check_jq
      _yc_yarn_add_completion
      ;;
    remove)
      _yc_check_jq
      _yc_yarn_remove_completion
      ;;
    run)
      _yc_check_jq
      _yc_yarn_run_completion
      ;;
    *)
      _yarn "$@"
  esac
}

compdef _yc_zsh_better_yarn_completion yarn
