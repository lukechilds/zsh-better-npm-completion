_yc_yarn_command() {
  echo "${words[2]}"
}

_yc_yarn_command_arg() {
  echo "${words[3]}"
}

_yc_no_of_yarn_args() {
  echo "$#words"
}

_yc_list_cached_modules() {
  ls ~/.npm 2>/dev/null
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

_yc_get_package_json_property_object() {
  local package_json="$1"
  local property="$2"
  cat "$package_json" |
    sed -nE "/^ *\"$property\": \{$/,/^ *\},?$/p" | # Grab scripts object
    sed '1d;$d' |                                   # Remove first/last lines
    sed -E 's/\s+"([^"]+)": "(.+)",?/\1=>\2/'      # Parse into key=>value
}

_yc_get_package_json_property_object_keys() {
  local package_json="$1"
  local property="$2"
  _yc_get_package_json_property_object "$package_json" "$property" | cut -f 1 -d "="
}

_yc_parse_package_json_for_script_suggestions() {
  local package_json="$1"
  _yc_get_package_json_property_object "$package_json" scripts |
    sed -E 's/(.+)=>(.+)/\1:$ \2/' |  # Parse commands into suggestions
    sed 's/\(:\)[^$]/\\&/g' |         # Escape ":" in commands
    sed 's/\(:\)$[^ ]/\\&/g'          # Escape ":$" without a space in commands
}

_yc_parse_package_json_for_deps() {
  local package_json="$1"
  _yc_get_package_json_property_object_keys "$package_json" dependencies
  _yc_get_package_json_property_object_keys "$package_json" devDependencies
}

_yc_yarn_add_completion() {
  # Only run on `yarn add ?`
  [[ ! "$(_yc_no_of_yarn_args)" = "3" ]] && return

  # Return if we don't have any cached modules
  [[ "$(_yc_list_cached_modules)" = "" ]] && return

  # If we do, recommend them
  _values $(_yc_list_cached_modules)

  # Make sure we don't run default completion
  custom_completion=true
}

_yc_yarn_remove_completion() {
  # Use default yarn completion to recommend global modules
  [[ "$(_yc_yarn_command_arg)" = "-g" ]] ||  [[ "$(_yc_yarn_command_arg)" = "--global" ]] && return

  # Look for a package.json file
  local package_json="$(_yc_recursively_look_for package.json)"

  # Return if we can't find package.json
  [[ "$package_json" = "" ]] && return

  _values $(_yc_parse_package_json_for_deps "$package_json")
}

_yc_yarn_run_completion() {
  # Only run on `yarn run ?`
  [[ ! "$(_yc_no_of_yarn_args)" = "3" ]] && return

  # Look for a package.json file
  local package_json="$(_yc_recursively_look_for package.json)"

  # Return if we can't find package.json
  [[ "$package_json" = "" ]] && return

  # Parse scripts in package.json
  local -a options
  options=(${(f)"$(_yc_parse_package_json_for_script_suggestions $package_json)"})

  # Return if we can't parse it
  [[ "$#options" = 0 ]] && return

  # Load the completions
  _describe 'values' options
}

_yc_yarn_commands_completion() {
  _values \
    'subcommnad' \
      'add[Installs a package and any packages that it depends on.]' \
      'bin[Displays the location of the yarn bin folder.]' \
      'cache[Yarn stores every package in a global cache in your user directory on the file system.]' \
      'check[Verifies that versions of the package.]' \
      'clean[Cleans and removes unnecessary files from package dependencies.]' \
      'config[Manages the yarn configuration files.]' \
      'generate-lock-entry[Generates a lock file entry.]' \
      'global[Install packages globally on your operating system.]' \
      'info[Show information about a package.]' \
      'init[Interactively creates or updates a package.json file.]' \
      'install[Install packages]' \
      'licenses[List licenses for installed packages.]' \
      'link[Symlink a package folder during development.]' \
      'login[Store registry username and email.]' \
      'logout[Clear registry username and email.]' \
      'ls[List installed packages.]' \
      'outdated[Checks for outdated package dependencies.]' \
      'owner[Manage package owners.]' \
      'pack[Creates a compressed gzip archive of package dependencies.]' \
      'publish[Publishes a package to the npm registry.]' \
      'remove[Remove package and update package.json and yarn.lock ]' \
      'run[Runs a defined package script.]' \
      'self-update[Updates Yarn to the latest version.]' \
      'tag[Add, remove, or list tags on a package.]' \
      'team[Maintain team memberships]' \
      'unlink[Unlink a previously created symlink for a package.]' \
      'upgrade[Upgrades packages to their latest version based on the specified range.]' \
      'version[Updates the package version.]' \
      'why[Show information about why a package is installed.]'
}

_yc_zsh_better_yarn_completion() {
  # Show yarn commands if not typed yet
  [[ $(_yc_no_of_yarn_args) -le 2 ]] && _yc_yarn_commands_completion && return

  # Load custom completion commands
  case "$(_yc_yarn_command)" in
    add)
      _yc_yarn_add_completion
      ;;
    remove)
      _yc_yarn_remove_completion
      ;;
    run)
      _yc_yarn_run_completion
      ;;
  esac
}

compdef _yc_zsh_better_yarn_completion yarn
