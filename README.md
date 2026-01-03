# decree

**decree** is a declarative package management system for all of your \*nix systems.

## Installation

You can install **decree** using *Homebrew* on macOS or Linux.

```bash
brew install stikypiston/formulae/decree
```

## Usage

To use **decree**, you will first create a package manager **spec**. This spec tells decree how to use your package manager.  
Configuration is done in **~/.config/decree**, and specs are placed inside **~/.config/decree/spec**, and are named **<package manager name>.yaml**

All configuration is done in **yaml**

Here is an example spec for **Homebrew**. Tailor this to whatever package manager you want to use.

```yaml
name: brew

commands:
  install: "brew install {{package}}"
  remove: "brew remove {{package}}"
  upgrade_all: "brew upgrade"

detection:
  command: "brew --version"
```

That `{{package}}` notation is replaced with the actual package to be installed/removed when decree runs.

Next, we'll want to define what packages we want to install. This takes place in the `config.yaml` file inside **~/.config/decree**

This file defines what packages we want on our system.

Here's an example config, where I've installed **fd** through Homebrew, which we made a spec for earlier

```yaml
packages:
    brew:
        - fd
```

Another config option you can specify is the **autoUpgrade** option, which dictates whether or not **decree** should run the `upgrade_all` command for all package managers when switching to a new generation.

```yaml
settings:
    autoUpgrade: true
```

Now that we have some packages specified, let's install them. We do that by **switching** to the new generation.

To do that, simply run

```bash
decree switch
```

But now, you've realised that you don't like those packages. Well, we can roll back to a previous generation with

```bash
decree rollback <generation number>
```
