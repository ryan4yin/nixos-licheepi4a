# Demo - Remote Deployment

> WIP, use at your own risk.

The sdImage built from this flake lacks configuration & cache for compilation.
Consequently, if you intend to execute an application not present within the sdImage, such as `nix run nixpkgs#cowsay hello`, nix will try to build `cowsay` and all its dependencies from scratch. This can take a long time!

To avoid this, you can deploy your configuration remotely from a high performance machine, this can be done with [colmena](https://github.com/zhaofengli/colmena).

## Deploying remotely with colmena


Modify the nix files in this directory to fit your needs.

Then, run the following command to deploy the configuration to your remote server:

```bash
# I have uploaded the build cache to cachix, you can use it to speed up builds.
› nix run nixpkgs#cachix -- use licheepi4a

› nix run nixpkgs#colmena apply 

warning: Git tree '/home/ryan/codes/nixos-licheepi4a' is dirty
[INFO ] Using flake: git+file:///home/ryan/codes/nixos-licheepi4a?dir=demo
[INFO ] Enumerating nodes...
[INFO ] Selected all 1 nodes.
      ✅ 29s All done!
 lp4a ✅ 4s Evaluated lp4a
 lp4a ✅ 3s Built "/nix/store/k3cknl4anspc0qsjdpy3lij0w5143j1q-nixos-system-lp4a-23.05pre-git"
 lp4a ✅ 6s Pushed system closure
 lp4a ✅ 15s Activation successful
```

If you're not familiar with remote deployment, please read this tutorial first: [Remote Deployment - NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/best-practices/remote-deployment)


## Notes on Network Proxy

If you are in a network environment that requires proxy(such as China), you may need to set up proxies or bypass routes to speed up downloads on both your local host and development board, otherwise your NixOS experience may be quite bad.

