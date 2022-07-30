# Manual Duplex Printing for Linux
Driver for manual duplex (double side printing) for linux printers. Duplexer unit for linux printers.

The most intuitive and simple manual duplex driver for linux:
- No dependencies,
- No compliling,
- Short and simple bash script.

## HOW TO
1. Make sure your printer is installed;
2. Run ./install.sh as root;
3. Send print jobs to your new manual_duplex printer;
4. Sit back and sip a coffe.


## About
This driver installs a virtual printer on top of the printer you choose at the install prompt.
So most of the settings are done in your phisical printer.
If you have more than one printer, you can run install.sh for every printer.

This is actually a "print to script" driver; the script is in usr/(...)/backends/ .

Inspired by:
- https://askubuntu.com/questions/981020/use-a-script-as-a-printer-to-process-output-pdf
- https://unix.stackexchange.com/questions/137081/using-a-shell-script-as-a-virtual-printer

It should work on any printer and any linux with cups:
- It's tested on HP-3630 printers with PDF and LibreOffice files (Ubuntu and Debian). 
- It works perfectly on Samsung ML-2525W too ( using network connection, Ubuntu 18.04 ).



## NOTE
Due to this bug:
https://bugs.launchpad.net/ubuntu/+source/cups-filters/+bug/1340435
 It's not needed to print one blank page.

If your cups-filters are older than 1.0.55, uncomment usr/lib/cups/backend/duplex-print from line 84.
This might be needed on non debian based systems (But i havent tested. Someone please feedback on this).
