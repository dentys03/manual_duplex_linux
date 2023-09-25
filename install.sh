#!/bin/bash
# Startup checks
# Script must be run as user with sudo capabilities


# Colors for more readable output
# Text colors
T_RED='\e[31m'
T_GREEN='\e[32m'
T_YELLOW='\e[33m'
T_CYAN='\e[36m'

# Text formatting
TF_RESET='\e[0m'
TF_BOLD='\e[1m'


log() {
    echo -e "${T_GREEN}[I]$*${TF_RESET}" 
}

log_error() {
    echo -e "${T_RED}[Error]$*${TF_RESET}"
}

log_warning() {
    echo -e "${T_YELLOW}[Warn]$*${TF_RESET}"
}

log_question() {
    echo -e "${T_CYAN}[?]$*${TF_RESET}"
}

clear
log "This script must be run from a limited account with root privileges."
log "Run the installation for every user which need the duplex driver."

if [ $(logname) == root ]; then
  log_error "Don't run this as root"

  exit 1
fi
if [ $(whoami) != root ]; then
  log_error "Use sudo to become root"
  exit 1
fi

#TODO
# add option to install for all users at once
# all_users=$(awk -F: '($3>=1000)&&($1!="nobody"){print $1}' /etc/passwd)

all_printers=$(lpstat -s | tail -n +2 | awk '{print $3}' | sed 's/.$//')
log_question "Type the number of the printer you want to add duplexing capabilities, then type ENTER:"
log_question "These are your installed printers:"

declare printers_array
i=0
for p in $all_printers
do
  i=$(( $i + 1 ))
  log_question "$i. $p"
  printers_array[$i]=$p
done

read -e -r chosen_printer

# Ask a user about the display they want to use
log "---"
log_warning "Setting up a permament display may cause issues with the comunicats! On some linux distributions it may be neccecery!"
echo -e "$T_CYAN"
read -e -r -p "[?]Do you wish to set up a permament display for the comunicats? [y/N]" -i "N" approve
echo -e "$TF_RESET"
if [ "$approve" == "Y" ]
then

displays=$(
  xdpyinfo | awk '{
  while (match($0, /[[:space:][:digit:]]:[[:digit:]](\.[[:digit:]])?/)) {
  print substr($0, RSTART, RLENGTH)
  $0 = substr($0, RSTART + RLENGTH)
  }
  }'
)
# iterate through the display numbers and print them out
log_question "Select the display you want to use [number][ENTER]: "
declare displays_array
i=0
for d in $displays
do
  i=$(( i + 1 ))
  log_question " $i. $d"
  displays_array[i]=$d
done

read -e -r chosen_display

display=${displays_array[$chosen_display]}
if [ -z "$display" ]
then
  log_error "No display selected, you trickster!"
  exit 1
fi

command="export DISPLAY=$display"

log "Writing to usr/lib/cups/backend/duplex-print"
sed -i "2i $command" usr/lib/cups/backend/duplex-print

fi

first_printer=${printers_array[$chosen_printer]}

function setup_duplexer {
  first_printer=$1
  if [ -z "$first_printer" ]
  then
    log_error "No printer selected, you trickster!"
    exit 1
  else
    log "Found printer: $first_printer"
    log "Setting up duplexer"
  fi

  CUPS_LIB_DIR="/usr/lib/cups"
  [ -d /usr/libexec/cups ] && [ ! -d /usr/lib/cups ] && CUPS_LIB_DIR="/usr/libexec/cups"

  #create dir for files to be printed
  mkdir -p /var/spool/cups/duplex/
  chmod 777 /var/spool/cups/duplex/
  #create dir for our files
  mkdir -p /usr/share/manual_duplex_linux/
  cp printer.png /usr/share/manual_duplex_linux/
  cp document-print.svg /usr/share/manual_duplex_linux/

  # Allow lp user to run zenity as the user running the installer
  zenity_user=$(logname)
  [ ! -d /etc/sudoers.d ] && mkdir /etc/sudoers.d
  touch /etc/sudoers.d/lp
  chmod 640 /etc/sudoers.d/lp
  # Remove previous entries of user installing the driver from sudoers.d/lp file. Prerequisite for multi user and helps with keeping the sudoers.d/lp file small
  sed -i "/lp ALL=($zenity_user) NOPASSWD:\/usr\/bin\/zenity/d" /etc/sudoers.d/lp
  sed -i "/\#user	host = (runas user) command/d" /etc/sudoers.d/lp
  # Append permissions to sudoers
  echo '#user	host = (runas user) command' >> /etc/sudoers.d/lp
  echo "lp ALL=($zenity_user) NOPASSWD:/usr/bin/zenity" >> /etc/sudoers.d/lp
  chmod 440 /etc/sudoers.d/lp

  cp -rf usr/lib/cups/filter/duplex_print_filter $CUPS_LIB_DIR/filter/duplex_print_filter
  chown root:root $CUPS_LIB_DIR/filter/duplex_print_filter
  chmod 755 $CUPS_LIB_DIR/filter/duplex_print_filter

  cp -rf usr/lib/cups/backend/duplex-print $CUPS_LIB_DIR/backend/duplex-print
  chown root:root $CUPS_LIB_DIR/backend/duplex-print
  chmod 700 $CUPS_LIB_DIR/backend/duplex-print
  [ ! -d $CUPS_LIB_DIR/backend-available ] && mkdir $CUPS_LIB_DIR/backend-available
  cp -rf usr/lib/cups/backend/duplex-print $CUPS_LIB_DIR/backend-available/duplex-print
  chown root:root $CUPS_LIB_DIR/backend-available/duplex-print
  chmod 700 $CUPS_LIB_DIR/backend-available/duplex-print

  log "Deleteing if already exists"
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

  service cups restart &> /dev/null
  rc-service cupsd restart &> /dev/null
  systemctl restart cups &> /dev/null

  #add duplexing printer
  lpadmin -p Manual_Duplexer_$first_printer -E -v duplex-print:$first_printer -P /etc/cups/ppd/Manual_Duplexer_$first_printer.ppd
  lpadmin -d Manual_Duplexer_$first_printer


  log "Duplexer installed"
  log_question "Do you wish to set up xhost to allow the cups user to access the display using the .config/autostart directory? [Y/N][ENTER]"
  log_warning "This can compromise Xserver security by allowing cups user group to acces the session"
  
  read -e -r approve

  if [ "$approve" == "Y" ]
  then
    cp -rf home/.config/autostart/xhost_cups.desktop /home/"$SUDO_USER"/.config/autostart/xhost_cups.desktop
    else
    log_error "Nothing was changed. Maybe use capital Y?"
    exit 0
  fi
  exit 0
  }

log "This script assumes /var/spool/cups/ is the folder used by the printing system"
log_question "The script will add"
log_question "  ${TF_BOLD}$first_printer"
log_question "printer with the duplex setup. Is this what you want?"
log_question "(Y/N) followed by [ENTER]:"
read -e -r approve

if [ $approve == "Y" ]
then
    setup_duplexer $first_printer
  else

  log_error "Nothing was changed. Maybe use capital Y?"

  exit 0
fi


