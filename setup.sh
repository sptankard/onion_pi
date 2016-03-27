#!/bin/bash
# Onion Pi, based on the Adafruit Learning Technologies Onion Pi project.
# For more info: http://learn.adafruit.com/onion-pi

set -e          #Exit as soon as any line in the bash script fails
#set -x          #Prints each command executed (prefix with ++)

if (( $EUID != 0 )); then
  /bin/echo "This script must be run as root. Type in 'sudo $0' to run it as root."
  exit 1
fi

/bin/cat <<'Onion_Pi'
                            ~
                           /~
                     \  \ /**
                      \ ////
                      // //
                     // //
                   ///&//
                  / & /\ \
                /  & .,,  \
              /& %  :       \
            /&  %   :  ;     `\
           /&' &..%   !..    `.\
          /&' : &''" !  ``. : `.\
         /#' % :  "" * .   : : `.\
        I# :& :  !"  *  `.  : ::  I
        I &% : : !%.` '. . : : :  I
        I && :%: .&.   . . : :  : I
        I %&&&%%: WW. .%. : :     I
         \&&&##%%%`W! & '  :   ,'/
          \####ITO%% W &..'  #,'/
            \W&&##%%&&&&### %./
              \###j[\##//##}/
                 ++///~~\//_
                  \\ \ \ \  \_
                  /  /    \
Onion_Pi

/bin/echo "This script will auto-setup a Tor wifi hotspot for you. It is recommended that you
run this script on a fresh installation of Raspbian."
read -p "Press [Enter] key to begin.."

/bin/bash ./ap_setup.sh
/bin/bash ./tor_setup.sh

/bin/echo "
###############################

  Wifi network:  OnionPi
  Wifi password: changemeplease!

Remember to change the wifi password on your Onion Pi!
From your Raspberry Pi's command prompt, \
use the following command to access the settings:

    sudo nano /etc/hostapd/hostapd.conf

###############################
"

exit
