# Demo - Remote Deployment

> WIP, use at your own risk.

The sdImage built from this flake lacks configuration & cache for compilation.
Consequently, if you intend to execute an application not present within the sdImage, such as `nix run nixpkgs#cowsay hello`, nix will try to build `cowsay` and all its dependencies from scratch. This can take a long time!

To avoid this, you can deploy your configuration remotely on a high performance machine, this can be done with [colmena](https://github.com/zhaofengli/colmena).

## Deploying remotely with colmena


Modify the nix files in this directory to fit your needs.

Then, run the following command to deploy the configuration to your remote server:

```bash
nix run nixpkgs#colmena apply 
```

If you're not familiar with remote deployment, please read this tutorial first: [Remote Deployment - NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/best-practices/remote-deployment)


