#!/bin/bash
# Startup checks
# Script must be run as user with sudo capabilities
clear
echo "This script must be run from a limited account with root privileges.".
echo "Run the installation for every user which need the duplex driver."
echo

if [ $(logname) == root ]; then
  echo "Don't run this as root"
  echo ""
  exit 1
fi
if [ $(whoami) != root ]; then
  echo "Use sudo to become root."
  echo ""
  exit 1
fi

#TODO
# add option to install for all users at once
# all_users=$(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd)

all_printers=$(lpstat -s | tail -n +2 | awk '{print $3}' | sed 's/.$//')

echo "These are your installed printers:"
echo
declare printers_array
i=0
for p in $all_printers
do
  i=$(( $i + 1 ))
  echo $i. $p
  printers_array[$i]=$p
done
echo
echo "Type the number of the printer you want to add duplexing capabilities, then type ENTER:"
echo
read chosen_printer

first_printer=${printers_array[$chosen_printer]}

function setup_duplexer {
  first_printer=$1
  if [ -z "$first_printer" ]
  then
    echo "No printer submitted. You trickster!"
    exit 1
  else
    echo "found printer: "$first_printer
    echo going ahead.
  fi

  #create dir for files to be printed
  mkdir -p /var/spool/cups/duplex/
  chmod 777 /var/spool/cups/duplex/
  #create dir for our files
  mkdir -p /usr/share/manual_duplex_linux/
  cp printer.png /usr/share/manual_duplex_linux/
  cp document-print.svg /usr/share/manual_duplex_linux/

  # Allow lp user to run zenity as the user running the installer
  zenity_user=$(logname)
  touch /etc/sudoers.d/lp
  chmod 640 /etc/sudoers.d/lp
  # Remove previous entries of user installing the driver from sudoers.d/lp file. Prerequisite for multi user and helps with keeping the sudoers.d/lp file small
  sed -i "/lp ALL=($zenity_user) NOPASSWD:\/usr\/bin\/zenity/d" /etc/sudoers.d/lp
  sed -i "/\#user	host = (runas user) command/d" /etc/sudoers.d/lp
  # Append permissions to sudoers
  echo '#user	host = (runas user) command' >> /etc/sudoers.d/lp
  echo "lp ALL=($zenity_user) NOPASSWD:/usr/bin/zenity" >> /etc/sudoers.d/lp
  chmod 440 /etc/sudoers.d/lp

  cp -rf usr/lib/cups/filter/duplex_print_filter /usr/lib/cups/filter/duplex_print_filter
  chown root:root /usr/lib/cups/filter/duplex_print_filter
  chmod 755 /usr/lib/cups/filter/duplex_print_filter

  cp -rf usr/lib/cups/backend/duplex-print /usr/lib/cups/backend/duplex-print
  chown root:root /usr/lib/cups/backend/duplex-print
  chmod 700 /usr/lib/cups/backend/duplex-print
  cp -rf usr/lib/cups/backend/duplex-print /usr/lib/cups/backend-available/duplex-print
  chown root:root /usr/lib/cups/backend-available/duplex-print
  chmod 700 /usr/lib/cups/backend-available/duplex-print

  echo "Deleting printer if already exists"
  lpadmin -x Manual_Duplexer_$first_printer

  cp -praf /etc/cups/ppd/$first_printer.ppd /etc/cups/ppd/Manual_Duplexer_$first_printer.ppd

#  sed -i 's/"0 hpcups"/"duplex_print_filter"/g' /etc/cups/ppd/Manual_Duplexer_$first_printer.ppd
  sed -i '/^*cupsFilter/d' /etc/cups/ppd/Manual_Duplexer_$first_printer.ppd

  echo '*cupsFilter: "application/pdf 0 duplex_print_filter"' >> /etc/cups/ppd/Manual_Duplexer_$first_printer.ppd
  echo '*cupsFilter: "text/html 0 duplex_print_filter"' >> /etc/cups/ppd/Manual_Duplexer_$first_printer.ppd
  echo '*cupsFilter: "text/plain 0 duplex_print_filter"' >> /etc/cups/ppd/Manual_Duplexer_$first_printer.ppd
  echo '*cupsFilter: "application/vnd.cups-raster 0 duplex_print_filter"' >> /etc/cups/ppd/Manual_Duplexer_$first_printer.ppd
  echo '*cupsFilter: "application/vnd.cups-pdf 0 duplex_print_filter"' >> /etc/cups/ppd/Manual_Duplexer_$first_printer.ppd


  sleep 1

  service cups restart

  #add duplexing printer
  lpadmin -p Manual_Duplexer_$first_printer -E -v duplex-print:$first_printer -P /etc/cups/ppd/Manual_Duplexer_$first_printer.ppd
  lpadmin -d Manual_Duplexer_$first_printer

  echo
  echo "Duplexer installed."
  echo
  exit 0
}

echo
echo "This script assumes /var/spool/cups/ is the folder used by the printing system."
echo
echo "The script will add"
echo "                        $first_printer "
echo
echo " printer with the duplex setup. Is this what you want?"
echo
echo "(Y/N) followed by [ENTER]:"
read approve

if [ $approve == "Y" ]
then
  echo
  echo
  echo
    setup_duplexer $first_printer
  else
  echo
  echo "Nothing was changed. Maybe use capital Y ?"
  echo
  exit 0
fi
