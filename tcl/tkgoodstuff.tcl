#!/bin/sh
# \
exec tkgwish8.0 "$0" ${1+"$@"}

# tkgoodstuff version 8.0-final, 1 Oct, 1997
# See the file "COPYRIGHT" in the doc directory for more info

set TKG(version) "8.0-final"
set TKG(releasedate) "1 Oct, 1997"
set TKG(libdir) /usr/local/lib/TKGsrc
set TKG(language) english

set TKG(configfileformatversion) 1

if [catch {package require Tk 8.0}] {
  error "tkgoodstuff requires at least tcl/tk 8.0b1"
}

foreach f {
    startup.tcl defaults.tcl configcommands.tcl panelgeo.tcl
    elements.tcl dialogs.tcl international.tcl async.tcl mainwin.tcl
    popup.tcl inits.tcl misc.tcl tkgbutton.tcl swallow.tcl
} { source $TKG(libdir)/tcl/$f }
unset f

##############################################################
# Main Program:
##############################################################

TKGInitialize
TKGRCInit
TKGGetPreferences
TKGLibInit
TKGFvwmInit
TKGLangInit
TKGDefaults
TKGEvalConfig
TKGResolvePreferences
TKGSetResources
TKGDoHook TKG_clientsloaded_hook
TKGPopupInit
TKGScreenEdgeInit
TKGInitClients
TKGDraw
TKGDoHook TKG_alldone_hook
