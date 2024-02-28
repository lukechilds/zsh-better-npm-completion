# Standarized ZSH polyfills, following:
# https://github.com/zdharma/Zsh-100-Commits-Club/blob/master/Zsh-Plugin-Standard.adoc
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

if [[ $PMSPEC != *f* ]] {
  fpath+=( "${0:h}/functions" )
}

autoload -Uz \
  zbnc_default_npm_completion  \
  zbnc_get_package_json_property_object  \
  zbnc_get_package_json_property_object_keys  \
  zbnc_list_cached_modules  \
  zbnc_no_of_npm_args  \
  zbnc_npm_command  \
  zbnc_npm_command_arg  \
  zbnc_npm_install_completion  \
  zbnc_npm_run_completion  \
  zbnc_npm_uninstall_completion  \
  zbnc_parse_package_json_for_deps  \
  zbnc_parse_package_json_for_script_suggestions  \
  zbnc_recursively_look_for  \
  zbnc_zsh_better_npm_completion \
  zbnc_zsh_better_npm_completion_npx \
  zbnc_npx_list_executables

compdef zbnc_zsh_better_npm_completion npm
compdef zbnc_zsh_better_npm_completion_npx npx
