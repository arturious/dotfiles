# github.com/arturious/dotfiles

my dotfiles, managed with [chezmoi](https://chezmoi.io).

Install on a new Mac (needs [Homebrew](https://brew.sh)):

Install them with:

```sh
chezmoi init --source ~/dotfiles arturious
```

Check what will change, then apply:

```sh
chezmoi diff
chezmoi apply
```

Day to day:

```sh
chezmoi edit --watch ~/.config/fish/config.fish   # edit the source, then
chezmoi apply                                     # put it in place
chezmoi re-add                                    # pull in changes an app made itself
chezmoi cd                                        # git commit / push from here
```
