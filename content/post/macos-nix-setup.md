+++
author = "Marco Bauce"
title = "MacOs with Nix Flakes"
date = "2024-12-04"
description = "MacOs and Nix Together!"
tags = [
	"macos",
	"homebrew",
	"nix",	
]
+++

First thing first, a couple of premises.

This will be a blog post on how i manage my stuff with Nix on my
MacBook. That's not a tutorial, and probably i'm not doing a lot of
stuff in the right way; i just want to share my configurations for
other people who want a starting point on using nix within Macos.
And, most important, i'm by no means a Nix expert, but i'll take some
stuff as granted; if you have any doubts, probably the best places to ask listed here:
https://nixos.org/community/

You will find most of the stuff described in this blog post here:
https://github.com/heph2/NixOs-Mac

## Let's Flake together

Okay, let's dive into our flake.

```nix
{
  description = "Marco's darwin system";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    emacs.url = "github:cmacrae/emacs";
    emacs-overlay = {
      url =
        "github:nix-community/emacs-overlay/db47b2483942771a725cf10e7cd3b1ec562750b7";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    devenv.url = "github:cachix/devenv";
    cachix-deploy-flake.url = "github:cachix/cachix-deploy-flake";
    cachix-deploy-flake.inputs.darwin.follows = "darwin";
    flake-parts.url = "github:hercules-ci/flake-parts";
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./flake/aron/default.nix
        ./flake/fnord/default.nix
      ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];
    };
}
```

Here we have a bunch of inputs. The most notable ones are:

- flake-parts (a nix utility library that help us tidy a little bit, more informations here: https://flake.parts )
- darwin (This is used for managing a lot of stuff about the Mac itself, interely in Nix)
- emacs-overlay (well, manage emacs using nix that parse an `init.el`)
- home-manager (Dotfiles! Dotfiles! Dotfiles!)

And then we leverage `mkFlake` for manage our configurations.
Currently i manage two configs here, the Macbook itself (aron) and a
VM within the Macbook (fnord).

There's not that much to say here, the majority of the stuff are
managed inside each configuration. There's more to talk later.

## Fnord

This is a new-coming, i needed a linux VM for a bunch of stuff where
being on MacOs it's a little bit "restrective".
So i basically copy-pasted the configuration from [Hashimoto](https://github.com/mitchellh/nixos-config/tree/main) and configured the VM using VMWare Fusion (you can also use Parallel, or UTM).

```nix
{ pkgs, inputs, ... }: {
  flake.nixosConfigurations.fnord = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./configuration.nix
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.heph = import ./home.nix;
        home-manager.sharedModules = [
        ];
      }
    ];
  };
}
```

Again, not much to say here, i'm importing the `configuration.nix` and
using the HM input.

I encorauge you to take a look into the configurations directly in the
repo.  There's nothing amazing here. Probably the most interesting
stuff here is how to configure Sway.

```nix
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.sway}/bin/sway";
        user = "heph";
      };
      default_session = initial_session;
    };
  };
```

This handles the LoginManager, automatically login with user `heph`
and starting `sway`.

```nix
  hardware.graphics = {
    enable = true;
  };
```

This is for OpenGL.

and finally the Sway configuration itself

```nix
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    config = rec {
      modifier = "Mod4";
      terminal = "foot";
    };
  };
```

That's enough for a basic working configuration of sway (this will
basically using the default sway configuration).

## Aron

Finally here's the MacOs's nix configuration :)
Let's start again with the `default.nix` which has some substantial differences.

```nix
{ pkgs, inputs, ... }: {
  flake.darwinConfigurations.aron = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      ./configuration.nix
      {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];
      }
      inputs.nur.nixosModules.nur
      inputs.home-manager.darwinModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.marco = import ./home.nix;
        home-manager.sharedModules = [
          inputs.spicetify-nix.homeManagerModules.default
        ];
      }
    ];
  };
}
```

First we are using the system `aarch64-darwin`, and most importantly
we are using the darwin input: `flake.darwinConfigurations.<hostname>
= inputs.darwin.lib.darwinSystem`. This allow us to leverage the
nix-darwin flake and define our nix configuration.

Using nix-darwin we can also manage dock and other system preferences
with nix, but i'm not currently using them.

### Homebrew

If you are using a MacOs, you probably know something about Homebrew,
which is a sort of "de-facto standard" for packaging stuff inside
MacOs.  Even with nix, we want to use it for some GUI stuff (actually
there's some problem using nix for GUI application, they're not seen
as part of the system and are then not seen by MacOs).

You need to install it as always, nix unfortunately can't handle the
installation for us; refere then to https://brew.sh

After the installation, you can manage what need to be installed
declaratively, using the module `homebrew`

```nix
  homebrew = {
    enable = true;
    casks = [
      "telegram-desktop"
	];
  };
```

This will install the telegram-desktop cask when you rebuild the system.

### Yabai and Skhd

If you're coming from Linux, you're probably aware of how many DE and
Window Manager exists. Well, MacOs lacks that huge pool selection, but
fortunately we still have Yabai (WM) and Skhd (keybindings).

You'll find the relevant configuration (and some test) in `flake/aron/wm.nix`
