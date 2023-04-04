# Script for manage Checkpoint VPN connection (SNX)

## WARNING

This script tested on my work VPN and Fedora 34, 37, 38. I can't guarantee work with your VPN setup.

## Dependencies
1. You system must have `systemd` and use `systemd-resolved`.
2. Install all dependencies (`nss-tools, openssl, xterm, glibc.i686, pam.i686, libX11.i686, libnsl.i686, compat-libstdc++-33-3.2.3-72.el7.i686.rpm`).

```
sudo dnf install nss-tools openssl xterm glibc.i686 pam.i686 libX11.i686 libnsl.i686
```
3. Download `compat-libstdc++-33-3.2.3-72.el7.i686.rpm`, and install it (i found it on https://www.rpmfind.net/):

```
sudo dnf install compat-libstdc++-33-3.2.3-72.el7.i686.rpm
```

4. Download and install SNX build 800010003 (`snx_install_linux30.sh` please search it on Checkpoint support site)

```
sudo snx_install_linux30.sh
```

## Configuration

You need to create two configuration files. One for SNX (standard config for snx client, see snx.conf.sample for all available options), second configuration file is profile. Profile used to fix some issue with DNS and network routes.

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

````
PASSWORD="SuperSecretPassword"
````
Dont't prompt password, use configured yet.

## Usage

For first time run you must run `snx` and accept certificates.

```
snx -f ./snx.conf
```

And follow instructions like this:

```
Check Point's Linux SNX
build 800010003
Please enter your password:
SNX authentication:
Please confirm the connection to gateway: *.example.com
Root CA fingerprint: STUK TEN DUD HUB MEIK MILD FLED FONT RUDE BETA TEAL REAM
Do you accept? [y]es/[N]o:

```

Now you can use wrapper!


```
up-snx.sh -c snx.conf -p work.profile start
```

or 

```
up-snx.sh -p work.profile start
```

```
up-snx.sh -c snx.conf -p work.profile stop
```

or

```
up-snx.sh -p work.profile stop
```
