Testing
=======

This script has been tested and Just Works on the following setup:

* 2016-03-18-raspbian-jessie-lite.img
* Wifi module: Realtek Semiconductor Corp. RTL8188CUS 802.11n WLAN Adapter
* Raspberry Pi 2 model B
* Raspberry Pi firmware version:
  1bf9a9a77026af9128a339c82d72e331d3532ee4 (clean) (release)

If you test this on other setups, please send me a note to let me know
how it goes! Goal is as much compatibility as possible.

You can find firmware version using: `vcgencmd version`

And wifi module with `lsusb`.


# Alternate hostapd binary

N.B. Older Raspbian versions such as `2016-03-18-raspbian-jessie-lite`
required, for some wifi modules, replacing the default `hostapd`
binary with a patched version (provided by Adafruit, compiled from
Realtek sources). Newer Raspbian versions (such as 2017-03-02) work
with the default, so this has been disabled in the script going
forward.