# Script for manage Checkpoint VPN connection (SNX)

## WARNING

This script tested on my work VPN and Fedora 34. I can't guarantee work with your VPN setup.

## Dependencies
1. You system must have `systemd` and use `systemd-resolved`.
2. Installed SNX for linux (build `800010003`, please search it on Checkpoint support site) with all dependencies (like `compat-libstdc++-33-3.2.3-72.el7.i686.rpm`).

## Configuration

You need to create two configuration files. One for SNX (standard config for snx client, see snx.conf.sample for all available options), second configuration file is profile. Profile used to fix some issue with DNS and network routes,

Available options:

```
CONFIG="/path/to/config"
```
Optional path to SNX config file. The default value is `snx.conf`.

```
EXTRA_ROUTES="10.0.0.1/24 10.0.1.1/32"
```
This option adds extra network routes. In some cases, SNX does not set routes or your admin has not configured it, you can manually add it. The default value is empty.

```
NEW_ROUTES="10.0.0.0/8"
```
Replace all routes set by SNX with new ones. In some cases, you can replace all routes, e.g. my home network is 192.168.1.1/24 and VPN networks are 10.1.1.1/24, 10.1.2.1/24, 10.1.3.1/24, I can set NEW_ROUTES="10.1.1.1/16", and have got one route instead of three.

```
EXTRA_DOMAINS="example.com mydomain.local"
```
If your company uses split DNS for VPN network and public queries you can add extra domains for forwarding queries to the DNS servers behind VPN.

## Usage

```
snx.sh -c snx.conf -p work.profile start
```

or 

```
snx.sh -p work.profile start
```

```
snx.sh -c snx.conf -p work.profile stop
```

or

```
snx.sh -p work.profile stop
```
