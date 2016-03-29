Onion Pi
========

*Note: Right now this script is maybe beta-quality. It should work but
 you may have to tweak some things still.*

Make a Raspberry Pi into a Tor-tunneling middlebox! (Anonymizing
backbox, proxy, what have you…)

:warning: **WARNING!** This software setup will **NOT** make you
anonymous. If you really need good, strong anonymity, go get
[TAILS](https://tails.boum.org/) or the
[Tor Browser](https://www.torproject.org/) and use that instead (and
make sure you get them from the right place, and read their
documentation carefully).

# What's it do?

So, this won't make you anonymous. What's the point, then?

* It should succeed in putting your ISP in the dark as to your
  internet activity. Like using a VPN.
* Anonymize you a little bit
* Make it easy to access Tor Hidden Services (for example if you are
  running some yourself)
* Confuse some advertising networks, etc.

The point here is to make it *really easy* and convenient to do your
internet browsing etc. over Tor as a *matter of routine*. So you can
use your normal web browser and you don't have to remember to type
`torify` all the time.

Please do note that bittorrenting over Tor is double-plus-ungood
(discouraged). If you want that, check out
[Tribler](https://www.tribler.org/).

# Setup

Run this script on a fresh install of Raspbian and you (should) get a
wifi-hotspot that proxies everything over Tor. The goal is to make the
whole process as simple as:

1. Flash Raspbian to an SD card
2. Plug in your Pi and accessories (power, ethernet, wifi module)
3. Run this script

```sh
git clone https://github.com/sptankard/onion_pi.git
# ls, cat, check it out before you run it…
sudo onion_pi/setup.sh
```

# TODO Ideas

## Long-term
* Use whonix-gateway
* Reimplement in ansible instead of bash
* Ask Adafruit to sign their hostapd binary, and check it that way instead
* Merge/expose the localnet hosts available on the parent LAN
* ncurses wizard for selecting parameters:
    * Network interfaces (wlan0, eth0...)
    * SSID, password

## Cleanup
* Remove all "sudo" (whole script is run as root)
* Normalize /full/path/to/bin vs bin
* Programmatically handle WPASupplicant (de)activation
* Use augtool more
* Do all augtool operations at once, because augtool is slow to start up
