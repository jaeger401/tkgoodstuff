# Ballon Help routines
# Set the global variable TKG(balloons) to 0 to disable balloon help.

# Set up general bindings for widgets that will have balloon help
bind balloon <Enter> {after 1000 {TKGDoBalloon %W}}
bind balloon <Leave> {TKGPopBalloon %W 1}
bind balloon <Any-Button> {TKGPopBalloon %W}

# Set up bindings for a help balloon 
# w - the widget for which the help balloon provides help.
# text - the contents of the balloon
proc TKGBalloonBind {w text} {
    global TKG
    if {[lsearch [bindtags $w] balloon] == -1} {
	bindtags $w [concat balloon [bindtags $w]]
    }
    set TKG(balloontext,$w) $text    
}

# Produce balloon if appropriate
proc TKGDoBalloon {w} {
    global TKG
    set b .tkgballoon
    # are help balloons enabled?
    if {[info exists TKG(balloons)] && !$TKG(balloons)} return
    if {[winfo exists $b]} return
    # has the pointer already left the window?
    if {![string match $w* [eval winfo containing [winfo pointerxy .]]]} {
	return
    }
    toplevel $b
    wm withdraw $b
    wm overrideredirect $b 1
    if {![info exists TKG(balloonbackground)]} {
	set TKG(balloonbackground) \#ffcf30
    }
    grid [label $b.lab -textvariable TKG(balloontext,$w) \
	      -bg $TKG(balloonbackground) \
	      -borderwidth 2 -relief ridge]
    update idletasks
    # compute position, staying on the screen and adjacent to the
    # widget in question
    set x [winfo rootx $w]
    set y [expr [winfo rooty $w] - [winfo reqheight $b]]
    if {$y < 0} {
	set y [expr [winfo rooty $w] + [winfo height $w]]
    }
    if {([winfo vrootwidth .] - $x - [winfo reqwidth $b]) < 0} {
	set x [expr [winfo vrootwidth .] - [winfo reqwidth $b]]
    }
    if {([winfo vrootheight .] - $y - [winfo reqheight $b]) < 0} {
	set y [expr [winfo vrootheight .] - [winfo reqheight $b]]
    }
    wm geometry $b +${x}+${y}
    wm deiconify $b
    # in fvwm I get the panel occluding the balloon sometimes:
    after 30 "catch \"raise $b\""
}

# Destroy the help baloon unless it's a leave event and the 
# pointer is in a child.
proc TKGPopBalloon {w {leave 0}} {
    global TKG
    after cancel [list TKGDoBalloon $w]
    if {$leave &&
	![string compare $w [eval winfo containing [winfo pointerxy .]]]} {
	return
    }
    destroy .tkgballoon
}
