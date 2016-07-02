# zsh-better-npm-completion

> Better completion for `npm`

<img src="demo.gif" width="690">

* Makes `npm install` recommendations from npm cache
* Shows detailed information on script contents for `npm run`
* Falls back to default npm completions if we don't have anything better

## Install

### Antigen

```shell
antigen bundle lukechilds/zsh-better-npm-completion
```

### oh-my-zsh

#### Install

```shell
git clone https://github.com/lukechilds/zsh-better-npm-completion ~/.oh-my-zsh/custom/plugins/zsh-better-npm-completion
```

#### Activate

in `.zshrc`:

```shell
plugins+=(zsh-better-npm-completion)
```

You may also need to activate completions if they aren't already on:

```shell
autoload -U compinit && compinit
```

### Manual Installation

Clone this repo or just download `zsh-better-npm-completion.plugin.zsh` and source it in your `.zshrc`.

## License

MIT © Luke Childs
