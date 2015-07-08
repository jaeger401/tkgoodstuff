# TkMan interface for tkgoodstuff
# Gary Dezern (gdezern@uniquecr.sundial.net)
#
# Developed with tkgoodstuff v4.1b6...  
#

proc TkManDeclare {} {
    set Prefs_taborder(:Clients,TkMan) "Misc Button"
    set Prefs_taborder(:Clients,TkMan,Button) "Misc Colors"
    TKGDeclare TkMan(pathname) {tkman} \
        -typelist [list Clients TkMan Misc]\
        -label "full pathname of \"tkman\" (or just tkman if its on your path)"
    ConfigDeclare TkMan ClientButton1 TkMan [list Clients TkMan Button]
    ConfigDeclare TkMan ClientButton2 TkMan [list Clients TkMan Button]
    ConfigDeclare TkMan ClientButton3 TkMan [list Clients TkMan Button]
    ConfigDeclare TkMan ClientButton5 TkMan [list Clients TkMan Button]
    TKGDeclare TkMan(text) "TkMan"\
        -typelist [list Clients TkMan Button Misc]\
        -label "Label text"
    TKGDeclare TkMan(imagefile) {%tkman}\
        -typelist [list Clients TkMan Button Misc]\
        -label "Icon file"
}

proc TkManCreateWindow {} {
    if [TKGReGrid TkMan] return
    global TKG TkMan TkMan-params
    
    lappend c TKGMakeButton TkMan -exec $TkMan(pathname) \
	-balloon "Launch TkMan"
    if !$TkMan(nolabel) {
	lappend c -text $TkMan(text)
    }
    if {!$TkMan(noicon) || $TkMan(nolabel)} {
	lappend c -imagefile $TkMan(imagefile)
    }
    if {[Empty $TkMan(windowname)]} {
	set TkMan(windowname) "TkMan"
    }
    foreach switch {
	iconside ignore font foreground background windowname 
	tilefile activeforeground activebackground staydown trackwindow 
	relief
    } {
	lappend c -$switch $TkMan($switch)
    }
    eval $c
    
    bind [set TkMan-params(pathname)] <3> TkMan-goto
}

# this is activated when button 3 is hit...
#  or.. at least it SHOULD be.. <chuckle>

proc TkMan-goto {} {
    upvar #0 TkMan-params P

    if [catch "selection get" sel] {
 	TKGError "Selection not set"
 	return
    }

# see if tkman is running.  If not, start it...

    if [catch "send tkman pid"] {
        set oldmode $P(mode)
        set oldcmd $P(exec,$oldmode)
        set P(exec,$oldmode) [list $P(exec,$oldmode) $sel]
        TKGbuttonInvoke $P(pathname)
        set P(exec,$oldmode) $oldcmd
    } else {

# if it IS running, then send a message to display a man page...

        send -async tkman manShowMan [string trim $sel]
	if {[info exists Fvwm(outid)]} {
	    FvwmNext TkMan
	} else {
	    send tkman "wm deiconify .man; raise ."
	}

    }
}
    
DEBUG "Loaded TkMan.tcl"





