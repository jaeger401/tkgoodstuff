# tkgbutton.tcl
# based on button.tcl

# button.tcl is:
# SCCS: @(#) tkgbutton.tcl 1.19 96/02/20 13:01:32
#
# Copyright (c) 1992-1994 The Regents of the University of California.
# Copyright (c) 1994 Sun Microsystems, Inc.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#

 #set tkPriv(buttonWindow) {}
 #set tkPriv(window) {}
 #set tkPriv(inMenuButton) 0 
 #set tkPriv(cursor) {}
 #set tkPriv(postedMb) {}

#-------------------------------------------------------------------------
# The code below creates the default class bindings for tkgbuttons and
# tkgmenubuttons.
#-------------------------------------------------------------------------

bind TkgButton <FocusIn> {}
bind TkgButton <Enter> { tkButtonEnter %W }
bind TkgButton <Leave> { tkButtonLeave %W }
bind TkgButton <1> { TKGbuttonDown %W }
bind TkgButton <ButtonRelease-1> { TKGbuttonUp %W }
bind TkgButton <space> { TKGbuttonInvoke %W }

bind TkgMenubutton <FocusIn> {}
bind TkgMenubutton <Enter> { tkMbEnter %W }
bind TkgMenubutton <Leave> { tkMbLeave %W }
bind TkgMenubutton <1> {
    if {$tkPriv(inMenubutton) != ""} {
	TKGMbPost $tkPriv(inMenubutton) %X %Y
    }
}
bind TkgMenubutton <ButtonRelease-1> {
    tkMbButtonUp %W
}

# TKGbuttonDown --
# The procedure below is invoked when the mouse button is pressed in
# a tkgbutton widget.  It records the fact that the mouse is in the tkgbutton,
# saves the tkgbutton's relief so it can be restored later, and changes
# the relief to sunken.  If it was sunken already, no action is taken.
#
# Arguments:
# w -		The name of the widget.

proc TKGbuttonDown w {
    global tkPriv
    if {([$w cget -state] != "disabled")
	&& ([$w cget -relief] != "sunken")} {
	set tkPriv(relief) [$w cget -relief]
	set tkPriv(buttonWindow) $w
	$w config -relief sunken
    }
}

# TKGbuttonUp --
# The procedure below is invoked when the mouse button is released
# in a tkgbutton widget.  It restores the tkgbutton's relief and invokes
# the command(s) as long as the mouse hasn't left the tkgbutton.
#
# Arguments:
# w -		The name of the widget.

proc TKGbuttonUp w {
    global tkPriv
    if {$w == $tkPriv(buttonWindow)} {
	set tkPriv(buttonWindow) ""
	if {($w == $tkPriv(window))
	    && ([$w cget -state] != "disabled")} {
	    TKGbuttonExec $w
	} else {
	    $w config -relief $tkPriv(relief)
	}
    }
}

# TKGbuttonExec --
# Do the tcl and unix commands, if any, associated with the
# button w.

proc TKGbuttonExec w {
    global tkPriv
    set tclcmd [SelectionSub [string trim [$w cget -command]]]
    if [catch {uplevel \#0 $tclcmd} err] {
	TKGError $err
    }
    set unixcmd [SelectionSub [string trim [$w cget -exec]]]
    if ![string match $unixcmd ""] {
	if [catch {TKGbuttonBgExec $unixcmd $w} err] {
	    TKGError $err
	}
    }
    if {[string match $unixcmd ""] || ![$w cget -staydown]} {
	$w config -relief $tkPriv(relief)
    }
}

proc TKGbuttonBgExec {cmd w} {
    global tkPriv
    set id [open "|[subst $cmd] 2> /dev/null" r]
    fileevent $id readable \
	[list TKGbuttonPipeRead $id $w $tkPriv(relief)]
}
				   
# TKGbuttonPipeRead --
# Invoked when the pipeline from a button's "-exec" command is
# readable.  We guess that eof means the command is exiting.
# 

proc TKGbuttonPipeRead {id w relief} {
    gets $id
    if [eof $id] {
	fileevent $id readable ""
	$w config -relief $relief
	close $id
    }
}

# TKGbuttonInvoke --
# The procedure below is called when a tkgbutton is invoked through
# the keyboard.  It simulate a press of the tkgbutton via the mouse.
#
# Arguments:
# w -		The name of the widget.

proc TKGbuttonInvoke w {
    if {[$w cget -state] != "disabled"} {
	global tkPriv
	set tkPriv(relief) [$w cget -relief]
	$w flash
	$w configure -relief sunken
	update idletasks
	TKGbuttonExec $w
    }
}

proc TKGMbPost {w x y} {
    global tkPriv
    if {([$w cget -state] == "disabled")
	|| ($w == $tkPriv(postedMb))} return
    set m [$w cget -menu]
    if {$m == ""} return
    if ![string match $w.* $m] {
	error "can't post $m:  it isn't a descendant of $w (this is a new requirement in Tk versions 3.0 and later)"
    }
    set cur $tkPriv(postedMb)
    if {$cur != ""} {
	tkMenuUnpost {}
    }
    set tkPriv(cursor) [$w cget -cursor]
    set tkPriv(relief) [$w cget -relief]
    $w configure -cursor arrow
    $w configure -relief sunken
    set tkPriv(postedMb) $w
    set tkPriv(focus) [focus]
    $m activate none
    set panel w
    regexp {^(\.[^\.]*\-panel)\.} $w panel panel
    TKGPopupPost $m $x $y $panel
    tkSaveGrabInfo $w
    grab -global $w
}
