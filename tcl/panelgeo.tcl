############################################################
# Procedures to manage stack geometry and to
#

# TKGGrid -- 
# Place an item (pathname) into the stack currently being constructed.
# Stack (with grid) it onto the appropriate side, and configure it to 
# "expand" in the dimension of the stack's orientation unless we are
# in (the top stack of) a screen-edge panel and "expand" is not an arg.

proc TKGGrid {pathname args} {
    global TKG TKG_stackside
    upvar \#0 $TKG(currentpanel)-pparams(screenedge) edge
    set inscreenedge \
	[expr ![string match $edge no] && \
	     [regexp {^\.[^.]*$} $TKG(stackprefix)]]
    if [In -nosep $args] {
	set sep 0
    } else {
	set sep $TKG(sep)
    }
    set w $TKG(stackprefix)
    if {"$TKG_stackside(current)" == "top"} {
	set r [llength [grid slaves $w -column 0]]
	set slaves [grid slaves $w -column 0]
	grid $pathname -sticky nsew -in $w \
	    -column 0 -row $r \
	    -padx $sep -pady $sep
	if {!$inscreenedge || [In expand $args]} {
	    grid rowconfigure $w $r -weight 1
	} else {
	    grid rowconfigure $w $r -weight 0
	}
    } else {
	set c [llength [grid slaves $w -row 0]]
	set slaves [grid slaves $w -row 0]
	grid $pathname -sticky nsew -in $w \
	    -row 0 -column $c\
	    -padx $sep -pady $sep
	if {!$inscreenedge || [In expand $args]} {
	    grid columnconfigure $w $c -weight 1
	} else {
	    grid columnconfigure $w $c -weight 0
	}
    } 
}

proc TKGRowCol {w} {
    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1
}

set TKG(switches,StartStack) {
    {orientation ""}
    {borderwidth ""}
    {color ""}
    {startpanel 0}
    {iconside ""}
    {title ""}
    {screenedge no}
}

proc StartStack args {
    global TKG TKG_stackside TKG_iconSide    
    upvar \#0 stack$TKG(stackindex)-sparams Parent
    incr TKG(stackindex)
    set paramsvar stack$TKG(stackindex)-sparams
    upvar \#0 $paramsvar Stack
    set switches $TKG(switches,StartStack)
    TKGSetSwitchDefaults $paramsvar $switches
    TKGParseArgs $paramsvar $args $switches "" StartStack
    foreach v {borderwidth color iconside title} {
	if [Empty $Stack($v)] {set Stack($v) $Parent($v)}
    }
    if ![info exists Stack(orientation)] {
	if [string match $Parent(orientation) horizontal] {
	    set Stack(orientation) vertical
	} else {set Stack(orientation) horizontal}
    }
    lappend TKG(pedigree) $TKG(stackindex)
    if $Stack(startpanel) {
	set TKG(stackprefix) .[string tolower $TKG(currentpanel)]
	if ![winfo exists $TKG(stackprefix)] {
	    tkgtoplevel $TKG(stackprefix) -class Tkgoodstuff -relief raised\
		-borderwidth $Stack(borderwidth) -background $Stack(color) \
		-tile $TKG(paneltileimage)
	}
	wm withdraw $TKG(stackprefix)
	wm title $TKG(stackprefix) $Stack(title)
    } else {
	set TKG(stackprefix) $TKG(stackprefix).stack$TKG(stackindex)
	tkgframe $TKG(stackprefix) -relief ridge -borderwidth $Stack(borderwidth) \
	    -background $Stack(color) -tile $TKG(paneltileimage)

    }
    if { $Stack(orientation) == "vertical" } {
	set TKG_stackside($TKG(stackindex)) top
	grid columnconfigure $TKG(stackprefix) 0 -weight 1
    } else {
	set TKG_stackside($TKG(stackindex)) left
	grid rowconfigure $TKG(stackprefix) 0 -weight 1 
    }
    set TKG_stackside(current) $TKG_stackside($TKG(stackindex))
    set TKG_iconSide($TKG(stackindex)) $Stack(iconside)
    set TKG_iconSide(current) $Stack(iconside)
}

set TKG(switches,TKGStartPanel) {
    {borderwidth ""}
    {color ""}
    {title ""}
    {orientation ""}
    {iconside ""}
    {screenedge "no"}
}

proc TKGStartPanel {name args} {
    global TKG TKG_panels TKG_prevpanel
    upvar \#0 $name-pparams P
    upvar \#0 $TKG(currentpanel)-pparams Prev
    set switches $TKG(switches,TKGStartPanel)
    TKGSetSwitchDefaults $name-pparams $switches
    TKGParseArgs $name-pparams $args $switches {} TKGStartPanel
    set TKG_prevpanel($name) $TKG(currentpanel)
    set TKG(currentpanel) $name
    set TKG_panels(.[string tolower $name]) 1
    if ![string match $P(screenedge) no] {
	if [In $P(screenedge) {left right}] {
	    set P(orientation) vertical
	} else {
	    set P(orientation) horizontal
	}
    }
    if {$P(orientation) == "horizontal"} {
	if [Empty $P(iconside)] {
	    set P(iconside) left
	}
    } else {
	    if [Empty $P(iconside)] {
		set P(iconside) top
	    }
    }
    foreach v {
	orientation borderwidth color iconside title screenedge} {
	if [Empty $P($v)] {set P($v) $Prev($v)}
	lappend outargs -$v $P($v)
    }
    eval [concat StartStack -startpanel 1 $outargs]
}

proc TKGEndPanel {} {
    global TKG TKG_prevpanel
    set TKG(currentpanel) $TKG_prevpanel($TKG(currentpanel))
    FinishStack 1
}

proc TKGPanelDismiss {panel} {
    set w  .[string tolower $panel]
    wm withdraw $w
    TKGDoHook TKGPanelDismiss_$w
    global TKGPanelDismiss_$w TKG_postedpanels
    TKGResetHook TKGPanelDismiss_$w
    catch {unset TKG_postedpanels($w)}
}

proc TKGPanelButtonInvoke {butname panelname} {
    global TKG TKG_postedpanels TKG_prevpanel
    set w .[string tolower $panelname]
    # if already posted, unpost
    if [info exists TKG_postedpanels($w)] {
	TKGPanelDismiss $panelname
	return
    }
    upvar \#0 $butname-params P
    set butpath $P(pathname)
    set panelw [winfo toplevel $butpath]
    set hook TKGPanelPost_$panelw
    TKGDoHook $hook
    TKGResetHook $hook
    TKGAddToHook $hook "TKGPanelDismiss $panelname"
    TKGAddToHook TKGPanelDismiss_$w "TKGResetHook $hook"
    if ![string match $panelw .main-panel] {
	TKGAddToHook TKGPanelDismiss_$panelw "TKGPanelDismiss $panelname"
    }
    regexp {([0-9]*)x([0-9]*)\+*(-*[0-9]*)\+*(-*[0-9]*)}\
	[wm geometry $panelw] ww ww wh wx wy
    set vw [winfo vrootwidth .]
    set vh [winfo vrootheight .]
    set bx [winfo rootx $butpath]
    set by [winfo rooty $butpath]
    set rh [winfo reqheight $w]
    set rw [winfo reqwidth $w]
    upvar \#0 [string trimleft $panelw .]-pparams(orientation) O
    switch $O {
	vertical {
	    if [string match -* $wx] {
		set x [expr -([string trimleft $wx -] + $ww)]
	    } else {
		set x +[expr $wx + $ww]
	    }
	    set y +$by
	    if {($y + $rh) > $vh} {
		set y +[expr $vh - $rh]
	    }
	} horizontal {
	    if [string match -* $wy] {
		set y [expr -([string trimleft $wy -] + $wh)]
	    } else {
		set y +[expr $wy + $wh]
	    }
	    set x +$bx
	    if {($x + $rw) > $vw} {
		set x +[expr $vw - $rw]
	    }
	}
    }
    wm geometry $w $x$y
    wm deiconify $w
    raise .main-panel
    set TKG_postedpanels($w) 1
}

proc TKGPanelPlace {name args} {
    global PutPanel$name
    upvar \#0 \
	[string tolower [join $name ~]]-panel-pparams(screenedge) \
	edge
    set w .[string tolower $name]-panel
    if [string match $edge no] {
	set geometry [set PutPanel${name}(geometry)]
	if ![Empty $geometry] {
	    if [catch {wm geometry $w $geometry} err] {
		TKGError $err
	    } 
	}
    } else {
	switch $edge {
	    left {
		wm minsize $w 0 [winfo vrootheight .]
		wm geometry $w +0+0
	    } right {
		wm minsize $w 0 [winfo vrootheight .]
		wm geometry $w -0+0
	    } top {
		wm minsize $w [winfo vrootwidth .] 0
		wm geometry $w +0+0
	    } bottom {
		wm minsize $w [winfo vrootwidth .] 0
		wm geometry $w +0-0
	    }
	}
    }
    bind $w <Expose> "TKGPanelExpose $name"
    wm deiconify $w
}

proc TKGPanelExpose {name} {
    set lpanelname [string tolower $name]-panel
    set w .$lpanelname
    bind $w <Expose> ""
    TKGDoHook TKG_postedhook-$lpanelname
}

proc FinishStack {{endpanel 0}} {
    global TKG TKG_stackside TKG_iconSide
    set childstack $TKG(stackprefix)
    set TKG(pedigree) [lreplace $TKG(pedigree) end end]
    set parentindex [lindex $TKG(pedigree) end ]
    set TKG(stackprefix) \
	[join [lreplace [split $TKG(stackprefix) .] end end] .]
    if [Empty $TKG(stackprefix)] {
	#back to another panel
	set TKG(stackprefix) .[string tolower $TKG(currentpanel)]
    }
    set TKG_stackside(current) $TKG_stackside($parentindex)
    set TKG_iconSide(current) $TKG_iconSide($parentindex)
    if !$endpanel {TKGGrid $childstack -nosep; lower $childstack}
}

proc DoFill {} {
    global TKG
    set w .[string tolower $TKG(currentpanel)]
    set i 0
    while {[winfo exists $w.fill$i]} {incr i}
    set pathname $w.fill$i
    tkgframe $pathname -cursor top_left_arrow -tile $TKG(paneltileimage)
    TKGGrid $pathname expand
}
