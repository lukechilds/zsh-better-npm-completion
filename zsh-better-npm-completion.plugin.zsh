_zbnc_npm_command() {
  echo "${words[2]}"
}

_zbnc_npm_command_arg() {
  echo "${words[3]}"
}

_zbnc_no_of_npm_args() {
  echo "$#words"
}

_zbnc_list_cached_modules() {
  local term="${words[$CURRENT]}"
  
  case $term in
    '.'* | '/'* | '~'* | '-'* | '_'*)
      return
  esac

  # enable cache if the user hasn't explicitly set it
  local use_cache
  zstyle -s ":completion:${curcontext}:" use-cache use_cache
  if [[ -z "$use_cache" ]]; then
    zstyle ":completion:${curcontext}:" use-cache on
  fi

  # set default cache policy if the user hasn't set it
  local update_policy
  zstyle -s ":completion:${curcontext}:" cache-policy update_policy
  if [[ -z "$update_policy" ]]; then
    zstyle ":completion:${curcontext}:" cache-policy _zbnc_list_cached_modules_policy
  fi

  local hash=$(echo "$term" | md5)
  cache_name="zbnc_cached_modules_$hash"

  if _cache_invalid $cache_name  || ! _retrieve_cache $cache_name; then
    if [[ -z "$term" ]]; then
      _modules=$(_zbnc_list_cached_modules_no_cache)
    else
      _modules=$(_zbnc_list_search_modules)
    fi

    if [ $? -eq 0 ]; then
      _store_cache $cache_name _modules
    else
      # some error occurred, the user is probably not logged in
      # set _modules to an empty string so that no completion is attempted
      _modules=""
    fi
  else
    _retrieve_cache $cache_name
  fi
  echo $_modules
}

_zbnc_list_cached_modules_policy() {
  # rebuild if cache is more than an hour old
  local -a oldp
  # See http://zsh.sourceforge.net/Doc/Release/Expansion.html#Glob-Qualifiers
  oldp=( "$1"(Nmh+1) )
  (( $#oldp ))
}

_zbnc_list_search_modules() {
  local term="${words[$CURRENT]}"
  [[ ! -z "$term" ]] && NPM_CONFIG_SEARCHLIMIT=1000 npm search --no-description --parseable "$term" 2>/dev/null | awk '{print $1}'
  _zbnc_list_cached_modules_no_cache
}

_zbnc_list_cached_modules_no_cache() {
  local cache_dir="$(npm config get cache)/_cacache"
  export NODE_PATH="${NODE_PATH}:$(npm prefix -g)/lib/node_modules:$(npm prefix -g)/lib/node_modules/npm/node_modules"
  node --eval="require('cacache');" &>/dev/null || npm install -g cacache &>/dev/null
  if [ -d "${cache_dir}" ]; then
    node <<CACHE_LS 2>/dev/null
const cacache = require('cacache');
cacache.ls('${cache_dir}').then(cache => {
    const packages = Object.values(cache).forEach(entry => {
        const id = ((entry || {}).metadata || {}).id;
        if (id) {
            console.log(id.substr(0, id.lastIndexOf('@')));
        }
    });
});
CACHE_LS
  else
    # Fallback to older cache location ... i think node < 10
    ls --color=never ~/.npm 2>/dev/null
  fi
}

_zbnc_recursively_look_for() {
  local filename="$1"
  local dir=$PWD
  while [ ! -e "$dir/$filename" ]; do
    dir=${dir%/*}
    [[ "$dir" = "" ]] && break
  done
  [[ ! "$dir" = "" ]] && echo "$dir/$filename"
}

_zbnc_get_package_json_property_object() {
  local package_json="$1"
  local property="$2"
  cat "$package_json" |
    sed -nE "/^  \"$property\": \{$/,/^  \},?$/p" | # Grab scripts object
    sed '1d;$d' |                                   # Remove first/last lines
    sed -E 's/    "([^"]+)": "(.+)",?/\1=>\2/'      # Parse into key=>value
}

_zbnc_get_package_json_property_object_keys() {
  local package_json="$1"
  local property="$2"
  _zbnc_get_package_json_property_object "$package_json" "$property" | cut -f 1 -d "="
}

_zbnc_parse_package_json_for_script_suggestions() {
  local package_json="$1"
  _zbnc_get_package_json_property_object "$package_json" scripts |
    sed -E 's/(.+)=>(.+)/\1:$ \2/' |  # Parse commands into suggestions
    sed 's/\(:\)[^$]/\\&/g' |         # Escape ":" in commands
    sed 's/\(:\)$[^ ]/\\&/g'          # Escape ":$" without a space in commands
}

_zbnc_parse_package_json_for_deps() {
  local package_json="$1"
  _zbnc_get_package_json_property_object_keys "$package_json" dependencies
  _zbnc_get_package_json_property_object_keys "$package_json" devDependencies
}

_zbnc_npm_install_completion() {

  # Only run on `npm install ?`
  [[ $(_zbnc_no_of_npm_args) -lt 3 ]] && return

  local modules=($(_zbnc_list_cached_modules))
  
  # Add modules if we found some
  [[ ${#modules[@]} -gt 0 ]] && _values $modules

  # Include local files
  _files

  # Make sure we don't run default completion
  custom_completion=true
}

_zbnc_npm_uninstall_completion() {

  # Use default npm completion to recommend global modules
  [[ "$(_zbnc_npm_command_arg)" = "-g" ]] ||  [[ "$(_zbnc_npm_command_arg)" = "--global" ]] && return

  # Look for a package.json file
  local package_json="$(_zbnc_recursively_look_for package.json)"

  # Return if we can't find package.json
  [[ "$package_json" = "" ]] && return

  _values $(_zbnc_parse_package_json_for_deps "$package_json")

  # Make sure we don't run default completion
  custom_completion=true
}

_zbnc_npm_run_completion() {

  # Only run on `npm run ?`
  [[ ! "$(_zbnc_no_of_npm_args)" = "3" ]] && return

  # Look for a package.json file
  local package_json="$(_zbnc_recursively_look_for package.json)"

  # Return if we can't find package.json
  [[ "$package_json" = "" ]] && return

  # Parse scripts in package.json
  local -a options
  options=(${(f)"$(_zbnc_parse_package_json_for_script_suggestions $package_json)"})

  # Return if we can't parse it
  [[ "$#options" = 0 ]] && return

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
    i|install|add)
      _arguments -n -C \
        '(-g --global)'{-g,--global}'[Package will be installed as a global package.]' \
        '(-P --save-prod -D --save-dev -O --save-optional --no-save)'{-P,--save-prod}'[Package will appear in your dependencies. This is the default unless -D or -O are present.]' \
        '(-D --save-dev -P --save-prod -O --save-optional --no-save)'{-D,--save-dev}'[Package will appear in your devDependencies.]' \
        '(-O --save-optional -P --save-prod -D --save-dev --no-save)'{-O,--save-optional}'[Package will appear in your optionalDependencies.]' \
        '(--no-save -P --save-prod -D --save-dev -O --save-optional -E --save-exact -B --save-bundle)--no-save[Prevents saving to dependencies.]' \
        '(-E --save-exact --no-save)'{-E,--save-exact}'[Saved dependencies will be configured with an exact version rather than using npm’s default semver range operator.]' \
        '(-B --save-bundle --no-save)'{-B,--save-bundle}'[Saved dependencies will also be added to your bundleDependencies list.]' \
        '(- *)--help[show help message.]' \
        "(- *)--version[show program's version number and exit.]" \
        '*:args:_zbnc_npm_install_completion' && return 0
      ;;
    r|uninstall|remove|rm|un|unlink)
      _arguments -n -C \
        '(-g --global)'{-g,--global}'[Package will be removed from global packages.]' \
        '(-P --save-prod -D --save-dev -O --save-optional --no-save)'{-P,--save-prod}'[Package will be removed from your dependencies.]' \
        '(-D --save-dev -P --save-prod -O --save-optional --no-save)'{-D,--save-dev}'[Package will be removed from your devDependencies.]' \
        '(-O --save-optional -P --save-prod -D --save-dev --no-save)'{-O,--save-optional}'[Package will be removed from your optionalDependencies.]' \
        '(--no-save -P --save-prod -D --save-dev -O --save-optional)--no-save[Package will not be removed from your package.json file.]' \
        '(- *)--help[show help message.]' \
        "(- *)--version[show program's version number and exit.]" \
        '*:args:_zbnc_npm_uninstall_completion' && return 0
      ;;
    run)
      _zbnc_npm_run_completion
      ;;
  esac

  # Fall back to default completion if we haven't done a custom one
  [[ $custom_completion = false ]] && _zbnc_default_npm_completion
}

compdef _zbnc_zsh_better_npm_completion npm
