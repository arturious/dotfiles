# dotfiles

macOS dotfiles, managed with [chezmoi](https://chezmoi.io).

Install on a new Mac (needs [Homebrew](https://brew.sh)):

```sh
git clone https://github.com/arturious/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

Day to day:

```sh
chezmoi edit ~/.config/fish/config.fish   # edit the source, then
chezmoi apply                             # put it in place
chezmoi re-add                            # pull in changes an app made itself
chezmoi cd                                # git commit / push from here
```
