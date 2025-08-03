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

### What is GNU Stow?
GNU Stow is a symlink manager that makes it easy to manage dotfiles. It creates symbolic links from your dotfiles repository to your home directory, allowing you to:
- Keep all configurations in a single git repository
- Easily install/uninstall configurations
- Share configurations across multiple machines

### How Stow Works
- `-S` (stow): Creates symlinks from the source directory to the target directory
- `-D` (delete): Removes symlinks created by stow
- `-v` (verbose): Shows what stow is doing
- `-n` (no/dry-run): Simulates the operation without making changes
- `-d` (directory): Specifies the source directory containing dotfiles
- `-t` (target): Specifies where symlinks should be created (usually your home directory)

The `.` at the end refers to the "package" to stow/unstow within the source directory. It means "process everything in the dotfiles directory". Since we're using `-d /Users/jonas/repos/dotfiles`, the `.` is interpreted relative to that source directory, effectively meaning "all contents of /Users/jonas/repos/dotfiles". You could also specify individual subdirectories instead of `.` if you only wanted to stow/unstow specific configurations.

### Stow Apply
Remove parameter `n` to actually apply changes
``` bash
stow -Svn -d /Users/jonas/repos/dotfiles -t /Users/jonas .
```

### Stow Delete
Remove parameter `n` to actually apply changes

``` bash
stow -Dvn -d /Users/jonas/repos/dotfiles -t /Users/jonas .
```

### Install git-delta and symlink lazygit config
``` bash
cargo install git-deltaa
ln -s /Users/jonas/.config/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml
```
