# Manual Duplex Printing for Linux
Driver for manual duplex (double side printing) for linux printers. Duplexer unit for linux printers.

The most intuitive and simple manual duplex driver for linux:
- Virtually no dependencies,
- No compliling,
- Short and simple bash script.

## HOW TO
1. Make sure your printer is installed;
2. Run ./install.sh as root (Download, extract, make sure files extracted without errors, move to the install.sh folder);
3. Send print jobs to your new manual_duplex printer;
4. Sit back and sip a coffe.


## About
This driver installs a virtual printer on top of the printer you choose at the install prompt.
Will print odd pages, will display a window with instructions in which you click "proceed" after you flip the finished odd pages.

So most of the settings are done in your phisical printer.
If you have more than one printer, you can run install.sh for every printer.

This is actually a "print to script" driver; the script is in usr/(...)/backends/ .

It should work on any printer and any linux with cups:
- It's tested on HP-3630 printers with PDF and LibreOffice files (Ubuntu and Debian). 
- It works perfectly on Samsung ML-2525W too ( using network connection, Ubuntu 18.04 ).
- Confirmed to work on Gentoo.


## NOTE
This shouldn't be an issue anymore:
If your cups-filters are older than 1.0.55, you might need to print an extra blank page
 in usr/lib/cups/backend/duplex-print when printing odd pages.
