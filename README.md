# Dotfiles

This repository is a work in progress with the most important setup steps and configurations for my devices.

> [!WARNING] 
> Since .githooks is not the default folder for git hooks, the path has to be changed:
> `git config --local core.hooksPath .githooks/`

## MacOS

Clone without the `raspberry` folder using sparse checkout:

```bash
git clone --sparse <repo-url> dotfiles
cd dotfiles
git sparse-checkout set mac shared .githooks
git config --local core.hooksPath .githooks/
```

Then stow both packages targeting `~`:

```bash
stow -t ~ shared mac
```

## Raspberry

Clone without the `mac` folder using sparse checkout:

```bash
git clone --sparse <repo-url> dotfiles
cd dotfiles
git sparse-checkout set raspberry shared .githooks
git config --local core.hooksPath .githooks/
```

Then stow the relevant packages. The `raspberry` folder uses non-home target directories, so check each package's intended target before running stow.
