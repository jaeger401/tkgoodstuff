# Set up popup menu stuff.

proc TKGPopupInit {} {
    global TKG TKG_strings TKG_labels
    
    menu .menu -tearoff 0
    menu .tkgpopup  -disabledforeground $TKG(menutitleforeground)\
	-tearoff 0
    
    .tkgpopup add command -state disabled -label $TKG_labels(TKG)
    .tkgpopup add separator
    set TKG(popupplace) $TKG_strings(nonotices)
    .tkgpopup add checkbutton -label "$TKG(popupplace)" -variable TKG(nonotices)
    .tkgpopup add checkbutton -label $TKG_strings(nobeeps) -variable TKG(nobeep)
    .tkgpopup add separator
    .tkgpopup add command \
	-label $TKG_strings(help) -command { TKGHelp }
    .tkgpopup add command -label Preferences -command TKGPreferences
    if $TKG(internallogging) {
	.tkgpopup add command \
	    -label $TKG_strings(viewlog) -command { TKGViewLog }
    }
    .tkgpopup add separator
    .tkgpopup add cascade -label "Quit tkgoodstuff" -menu .tkgpopup.quit
    menu .tkgpopup.quit -tearoff 0 -disabledforeground $TKG(menutitleforeground)
    .tkgpopup.quit add command \
	-label $TKG_strings(restart) -command TKGRestart
    .tkgpopup.quit add command \
	-label $TKG_strings(exit) -command TKGQuit
}


proc TKGPopupPost {m x y {w .main-panel} {cascaderoom 200}} {
    global TKG
    switch $TKG(screenedge) {
	top {
	    set y [expr [winfo rooty $w]+[winfo height $w]]
	}  bottom {
	    set y [expr [winfo rooty $w]-[winfo reqheight $m]]
	} left {
	    set x [expr [winfo rootx $w]+[winfo width $w]]
	} right {
	    set x [expr [winfo rootx $w]-[winfo reqwidth $m]]
	}
    }
    #make room for cascades
    if {([winfo vrootwidth .] - $x - [winfo reqwidth $m]) < $cascaderoom} {
	set x [expr [winfo vrootwidth .] - $cascaderoom - [winfo reqwidth $m]]
    }
    $m post $x $y
    raise $m
    focus $m
}

proc TKGMBRelease {mb m} {
    set w [eval winfo containing [winfo pointerxy .]] 
    if [string match $mb $w] {
	global TKG_priv
	if $TKG_priv(inMenuButton) {
	    set TKG_priv(inMenuButton) 0
	} else {
	    $m unpost
	    grab release $m
	}
    }
}

proc TKGPopupAdd args {
    global TKG
    eval .tkgpopup insert \$TKG(popupplace) $args
}

proc TKGPopupAddClient {client} {
    global TKG TKG_labels
    setifunset TKG_labels($client) $client
    .tkgpopup insert $TKG(popupplace) cascade\
	-label $TKG_labels($client) \
	-menu ".tkgpopup.[string tolower $client]"
    .tkgpopup insert "$TKG(popupplace)" separator
    menu ".tkgpopup.[string tolower $client]" -tearoff 0 -tearoff 0
}

proc TKGPopupLocate {menu x y} {
    update idletasks
    set w [winfo width $menu]
    set h [winfo height $menu]
    set sw  [winfo screenwidth .]
    set sh  [winfo screenheight .]
    if {($w + $x) > $sw} {
	set x [expr $sw - $w]
    }
    if {($h + $y) > $sh} {
	set y [expr $sh - $h]
    }
    return "$x $y"
}
    
