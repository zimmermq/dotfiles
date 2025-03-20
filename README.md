```
██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
```

Configurations for various tools and applications that I use on a daily basis. Feel free to explore and copy.

## Installation Steps

--------------------

1. **Install GNU Stow**:

```bash
sudo apt-get install stow
```

GNU Stow is a symlink farm manager that helps manage dotfiles and other configuration files.
2. **Install Zsh**:

```bash
sudo apt-get install zsh
```

Zsh is an extended version of the Bourne Shell with many improvements, including features like command-line completion and shared history.
3. **Set Zsh as the default shell**:

```bash
chsh -s /usr/bin/zsh
```

This command changes your default shell to Zsh.

## Post-Installation

-------------------

After running these commands:

1. Log out and log back in for the changes to take effect.
2. Verify that Zsh is now your default shell by running:

```bash
echo $SHELL
```

The output should be `/usr/bin/zsh` or similar.

### Download git submodules
``` bash
git submodule update --init --recursive
```


## Symlink
### Stow Apply
Remove parameter `n` to actually apply changes
``` bash
stow -Svn .
```

### Stow Delete
Remove parameter `n` to actually apply changes

``` bash
stow -Dvn .
```

### Install git-delta and symlink lazygit config
``` bash
cargo install git-deltaa
ln -s /Users/jonas/.config/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml
```
