# Code to draw and configure buttons and label-boxes

proc TKGMakeButton {name args} {
    global TKG
    set lcname [string tolower $name]
    set lcpanel [string tolower $TKG(currentpanel)]
    set pathname .${lcpanel}.$lcname
    global $name-params
    set $name-params(pathname) $pathname
    eval [concat TKGButton $name -pathname $pathname $args]
    TKGGrid $pathname
    return $pathname
}

set TKG(switches,TKGButton) {
    pathname
    {state normal}
    {mode normal}
    {iconside ""}
    {relief ""}
    {tileimage ""}
    {usebutton2 1}
    {ignore 0}
    {padding $TKG(padding)}
    {butsep $TKG(butsep)}
    {menu ""}
    {usemenu3 1}
    {menu3items ""}
    {borderwidth $TKG(butborder)}
    {textanchor ""}
    {imageanchor ""}
    {textweight ""}
    {imageweight ""}
}

set TKG(switches,TKGButton,ms) {
    {foreground $TKG(buttonforeground)}
    {background $TKG(buttonbackground)}
    {activeforeground $TKG(butactiveforeground)}
    {activebackground $TKG(butactivebackground)}
    {text ""}
    {image ""}
    {exec ""}
    {command ""}
    {balloon ""}
    {staydown 1}
    {trackwindow 0}
    {font $TKG(combofont)}
    {windowname ""}
} 

# TKGButton --
# Produces and configures mode-sensitive tkgbutton widgets.

proc TKGButton {name args} {
    global TKG $name-params TKG_iconSide Fvwm
    upvar #0 $name-params P

    # Parse arguments
    set args [TKGButtonArgStuff $name $args]
    set sswitches $TKG(switches,TKGButton)
    set msswitches $TKG(switches,TKGButton,ms)
    TKGParseArgs $name-params $args $sswitches $msswitches TKGButton
    if ![info exists P(init)] {
	TKGSetSwitchDefaults $name-params $TKG(switches,TKGButton)
	set P(init) 1
    }
    if ![In $P(mode) $P(modes)] {lappend P(modes) $P(mode)}
    foreach mode $P(modes) {
	if ![info exists P(init,$mode)] {
	    TKGSetMSSwitchDefaults $name-params $TKG(switches,TKGButton,ms) $mode
	    set P(init,$mode) 1
	}
    }
    
    # Create button if necessary, or configure
    if ![winfo exists $P(pathname)] {
	if ![Empty $P(menu)] {
	    lappend C tkgmenubutton $P(pathname) -menu $P(menu)
	    set P(exec,$P(mode)) ""
	    set P(command,$P(mode)) ""
	} else {
	    lappend C tkgbutton $P(pathname)
	}
	lappend C -highlightthickness 0 -borderwidth $P(borderwidth)\
	    -cursor top_left_arrow\
	    -padx $P(padding) -pady $P(padding) -sep $P(butsep)
	if {[Empty $P(relief)]} {
	    set P(relief) $TKG(butrelief)
	}
	lappend C -relief $P(relief)
    } else {
	lappend C $P(pathname) configure
    }
    
    # Pass switches to tkgbutton or tkgmenubutton
    lappend topass foreground background activeforeground \
	activebackground font windowname
    if {$P(ignore)
	|| !$TKG(labelsonly) 
	|| $TKG(iconsonly)
	|| [Empty $P(text,$mode)]} {
	set image $P(image,$P(mode))
    } else {
	set image ""
    }
    lappend C -image $image
    if ![Empty $image] {
	if [Empty $P(iconside)] {
	    set iconside $TKG_iconSide(current)
	} else {
	    set iconside $P(iconside)
	}
	lappend C -iconside $iconside
	switch -regexp $iconside {
	    top|bottom {
	    set textweight 0
	    set imageweight 1
	    set textanchor c
	    set imageanchor c
	} left|right {
	    set textweight 1
	    set imageweight 0
	    set textanchor w
	    set imageanchor c
	} default {
	    set textweight 1
	    set imageweight 1
	    set textanchor c
	    set imageanchor c
	}
	}
	foreach switch {textweight imageweight textanchor imageanchor} {
	    if {[Empty $P($switch)]} {
		lappend C -$switch [set $switch]
	    } else {
		lappend C -$switch $P($switch)
	    }
	}
    }
    if {![Empty $P(tileimage)]} {
	if  {![string match none $P(tileimage)]} {
	    lappend C -tileimage $P(tileimage)
	}
    } elseif ![Empty $TKG(buttontileimage)] {
	lappend C -tileimage $TKG(buttontileimage)
    }
    if {$P(ignore) 
	|| !$TKG(iconsonly)
	|| [Empty $P(image,$mode)]} {
	lappend C -textvar $name-params(text,$P(mode))
    } else {
	set cleartextvar 1
    }
    if [Empty [set windowname $P(windowname,$P(mode))]] {
	set windowname [file tail [lindex [subst {$P(exec,$P(mode))}] 0]]
	if ![Empty $windowname] {
	    lappend C -windowname $windowname
	} 
    }
    upvar \#0 Fvwm_trackbuttons($windowname) tracklist
    if {$P(trackwindow,$P(mode)) 
	&& [info exists Fvwm(outid)] 
	&& ![Empty $windowname]} {
	ListAdd tracklist $name
	lappend C -staydown 0 -exec "" \
	    -command [concat exec $P(exec,$P(mode)) &]
    } else {
	if [info exists tracklist] {
	    ListRemove tracklist $name
	    if [Empty $tracklist] {unset tracklist}
	}
	if [Empty $P(menu)] {
	    lappend topass exec command staydown
	}
    }
    foreach switch $topass {
	if ![Empty $P($switch,$P(mode))] {
	    lappend C -$switch $P($switch,$P(mode))
	}
    }
    eval $C

    # If no text, we clear the current text if any
    if [info exists cleartextvar] {
	uplevel \#0 {set dummy ""}
	$P(pathname) config -textvar dummy
	$P(pathname) config -textvar ""
    }

    # Set up bindings for balloon help
    if ![Empty $P(balloon,$P(mode))] {
	TKGBalloonBind $P(pathname) $P(balloon,$P(mode))
    }

    # Bind button2 to unix command, if any.
    if $P(usebutton2) {
	if [Empty $P(exec,$P(mode))] {
	    bind $P(pathname) <2> break
	} else {
	    bind $P(pathname) <2> \
		[concat exec $P(exec,$P(mode)) >& /dev/null & \; break]
	}
    }
    return $P(pathname)
}

proc TKGButtonArgStuff {name arglist} {
    global TKG(currentpanel) TKG
    if {[set i [lsearch $arglist "-imagefile"]] != -1} {
	if ![Empty [lindex $arglist [expr $i + 1]]] {
	    SetImage ${name}-image [lindex $arglist [expr $i + 1]]
	    set arglist \
		[lreplace $arglist [expr $i] [expr $i +1] -image ${name}-image]
	} else {
	    set arglist \
		[lreplace $arglist [expr $i] [expr $i +1]]
	    set j [expr [lsearch $arglist -text] + 1]
	    if [Empty [lindex $arglist $j]] {
		set arglist [lreplace $arglist $j $j [split $name ~]]
	    }
	}
    }
    if {[set i [lsearch $arglist "-tilefile"]] != -1} {
	if ![Empty [lindex $arglist [expr $i + 1]]] {
	    SetImage ${name}-tile [lindex $arglist [expr $i + 1]]
	    set arglist \
		[lreplace $arglist [expr $i] [expr $i +1] -tileimage ${name}-tile]
	} else {
	    set arglist \
		[lreplace $arglist [expr $i] [expr $i +1]]
	}
    }
    foreach switch $TKG(switches,TKGButton,ms) {
	set switch [lindex $switch 0]
	while {[set i [lsearch $arglist "-$switch"]] != -1} {
	    if {[string match {{}} [lindex $arglist [expr $i + 1]]]} {
		set arglist [lreplace $arglist $i [expr $i +1]]
	    } else {
		set arglist [lreplace $arglist $i $i "-${switch}(normal)"]
	    }
	}
    }
    return $arglist
}

proc TKGButtonCopyMode {name mode1 mode2} {
    global TKG
    upvar #0 $name-params P
    foreach s $TKG(switches,TKGButton,ms) {
	set s [lindex $s 0]
	set P($s,$mode2) $P($s,$mode1)
    }     
}

set TKG(switches,TKGLabelBox) {
    {text ""}
}

proc TKGLabelBox {name args} {
    set name [string trim [join $name ~]]
    set lcname [string tolower $name]
    global TKG $name-lbparams
    set lcpanel [string tolower $TKG(currentpanel)]
    set window .${lcpanel}.lb$lcname
    set sswitches $TKG(switches,TKGLabelBox)
    TKGSetSwitchDefaults $name-lbparams $TKG(switches,TKGLabelBox)
    TKGParseArgs $name-lbparams $args $sswitches {} TKGLabelBox
    DEBUG "creating $window"
    global [set name]_window
    set [set name]_window $window
    frame $window -borderwidth 3\
	-highlightthickness 0 -relief ridge -cursor top_left_arrow \
	-background $TKG(labelboxbackground)

    if ![Empty [set $name-lbparams(text)]] {
	frame $window.label\
	    -borderwidth 0 -highlightthickness 0
	label $window.label.lbtext \
	    -textvariable $name-lbparams(text)\
	    -pady 0 -borderwidth 0 -highlightthickness 0\
	    -foreground $TKG(labelboxforeground) \
	    -background $TKG(labelboxbackground)

	grid $window.label.lbtext -sticky nsew
	grid $window.label -sticky nsew
	TKGRowCol $window.label
	TKGRowCol $window.label.lbtext
    }
    TKGRowCol $window
    return $window
}

# Put a tkgbutton back in the panel during redraw after screenedge move
proc TKGReGrid {name} {
    upvar \#0 $name-params P
    global TKG_iconSide
    if ![info exists P] {return 0}
    grid forget $P(pathname)
    if {[info exists P(iconside)] &&[Empty $P(iconside)]} {
	$P(pathname) configure -iconside $TKG_iconSide(current)
    }
    TKGGrid $P(pathname)
    return 1
}
