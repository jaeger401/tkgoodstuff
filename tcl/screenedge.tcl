proc TKGScreenEdgeInit {} {
    global TKG
    if [string match $TKG(screenedge) no] return
    TKGPopupAdd checkbutton -label "Auto-minimize" -variable TKG(automin)
    set TKG(popupplace) "Auto-minimize"
    trace variable TKG(automin) w TKGScreenEdgeMin
}

proc TKGScreenEdgeSetup {w} {
    global TKG
    if [string match $TKG(screenedge) no] return
    $w configure -cursor crosshair
    bind $w <ButtonRelease-1> {TKGScreenEdgeMove %X %Y %W}
    bind $w <B1-Motion> {TKGScreenEdgeMotion %X %Y %W}
    bind $w <1> {TKGScreenEdgeMotion %X %Y %W}
    bind $w <Leave> TKGScreenEdgeMin
}

proc TKGScreenEdgeMin {args} {
    global TKG
    if !$TKG(automin) return
    catch {after cancel $TKG(screenedgeminid)}
    set TKG(screenedgeminid) [after 1000 TKGScreenEdgeDoMin]
}

proc TKGScreenEdgeDoMin {} {
    global TKG
    if [winfo exists .tkgminwin] return
    set w [winfo containing [winfo pointerx .] [winfo pointery .]]
    if {[string match ".*" $w] && [winfo viewable $w]} return
    switch -regexp $TKG(screenedge) {
	left|right {
	    set w 3
	    set h [winfo vrootheight .]
	} top|bottom {
	    set h 3
	    set w [winfo vrootwidth .]
	}
    }
    toplevel .tkgminwin -width $w -height $h -background $TKG(minbg)\
	-borderwidth 2 -relief raised
    wm title .tkgminwin tkgoodstuff
    tkwait visibility .tkgminwin
    wm minsize .tkgminwin $w $h
    switch -regexp $TKG(screenedge) {
	top|left {set g +0+0}
	bottom|right {set g -0-0}
    }
    wm geometry .tkgminwin $g
    bind .tkgminwin <Enter> TKGScreenEdgeMax
    update idletasks
    global TKG_postedpanels
    foreach w [array names TKG_postedpanels] {
	wm withdraw $w
    }
}

proc TKGScreenEdgeMax {} {
    if ![winfo exists .tkgminwin] return
    destroy .tkgminwin
    global TKG_postedpanels
    foreach w [array names TKG_postedpanels] {
	wm deiconify $w
    }
    update idletasks
    after 2000 {bind .main-panel <Leave> TKGScreenEdgeMin}
}

proc TKGScreenEdgeSide {x y} {
    set wx [winfo vrootwidth .]
    set wy [winfo vrootheight .]
    if {((($x + $wx/8)%$wx) < ($wx/4))\
	    && ((($y + $wy/8)%$wy) < ($wy/4))} return
    set slope [expr ${wy}.0 / $wx]
    if {$y < ($x * $slope)} {
	if {$y < ($wy - $x * $slope)} {
	    set side top
	} else {
	    set side right
	} 
    } elseif {$y < ($wy - $x * $slope)} {
	set side left
    } else {
	set side bottom
    }
    return $side
}

proc TKGScreenEdgeMotion {x y win} {
    global TKG
    set side [TKGScreenEdgeSide $x $y]
    set oldc [.main-panel cget -cursor]
    if [In $side {top bottom}] {
	set newc sb_v_double_arrow
    } else {
	set newc sb_h_double_arrow
    }
    if {$oldc != $newc} {
	.main-panel configure -cursor $newc
    }
}

proc TKGScreenEdgeMove {x y w} {
    global TKG
    .main-panel configure -cursor crosshair
    if [Empty [set side [TKGScreenEdgeSide $x $y]]] return
    if ![string match $w .main-panel] return
    if [string match $side $TKG(screenedge)] return
    
    set old_screenedge $TKG(screenedge)
    set TKG(screenedge) $side

    TKGSuspendClients
    TKGDraw
}
