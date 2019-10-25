# manual_duplex_linux
Driver for manual duplex

Bulding on this:
https://askubuntu.com/questions/981020/use-a-script-as-a-printer-to-process-output-pdf
and this:
https://unix.stackexchange.com/questions/137081/using-a-shell-script-as-a-virtual-printer

Works for HP-3630 printers. Can be adapted to any printer.

## HOW TO
1. Install your printer.
2. Run ./install.sh as root
3. Enjoy.


# TODO
1. Automatically modify ppd for the printer that will be used.
2. List available printers and pick the one to add duplexer to it.
