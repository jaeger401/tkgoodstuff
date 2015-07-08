# Each page: {"Tab title" wname} (empty wname if changecallback handles it)

set TKG(switches,TabNB) {
    {pages {}}
    {startpage 0}
    {width 20c}
    {height 15c}
    {relief flat}
    {borderwidth 0}
    {tabpady 2}
    {tabpadx 4}
    {headroom 10}
    {outlinethickness 2}
    {slantrun 8}
    {overlap -8}
    {changecallback {}}
    {font tkgbigbold}
    {background {$TKG(background)}}
    {foreground {$TKG(foreground)}}
    {disabledbackground {$TKG(background)}}
    {disabledforeground {$TKG(disabledforeground)}}
    {field {$TKG(background)}}
}

proc TabNB {w args} {
    global TKG
    # get arguments
    TKGParseArgs TabNB$w $args $TKG(switches,TabNB)
    TKGSetSwitchDefaults TabNB$w $TKG(switches,TabNB)
    upvar \#0 TabNB$w P
    # make overall frame
    set width [winfo pixels . $P(width)]
    frame $w -width $P(width) -height $P(height) \
	-relief $P(relief) -borderwidth $P(borderwidth) \
	-background $P(field)
    # get text height for tab labels
    label $w.dummy -font $P(font) -text Gg \
	-highlightthickness 0 -borderwidth 0 \
	-padx $P(tabpadx) -pady $P(tabpady)
    set labelheight [winfo reqheight $w.dummy]
    destroy $w.dummy

    set ytop [expr $P(borderwidth) + $P(headroom)]
    set ybottom [expr $ytop + $labelheight + 2*$P(outlinethickness)]
    set polygonbottom [expr $ybottom + $P(outlinethickness)/2]
    set linebottom [expr $ybottom - ($P(outlinethickness) +1)/2]
    set tabwinwidth [expr $width - 2*$P(borderwidth)]

    set canvas $w.tabcanvas
    canvas $w.tabcanvas -width $tabwinwidth -height $ybottom \
	-borderwidth 0 -highlightthickness 0 \
	-background $P(field)
    
    # Draw the tabs
    set leftx 5
    for {set i 0} {$i < [llength $P(pages)]} {incr i} {
	set tabname [lindex [lindex $P(pages) $i] 0]
	set label $canvas.lab$i
	label $label \
	    -font $P(font) \
	    -text [lindex [lindex $P(pages) $i] 0] \
	    -highlightthickness 0 -borderwidth 0 \
	    -foreground $P(disabledforeground) \
	    -background $P(disabledbackground) \
	    -padx $P(tabpadx) -pady $P(tabpady)
	set lwidth [winfo reqwidth $label]
	set x $leftx
	$canvas create line 0 $linebottom $leftx $linebottom \
	    -fill $P(foreground) -tags tab$i -width $P(outlinethickness)
	$canvas create polygon \
	    $x                    $polygonbottom \
	    [incr x $P(slantrun)] $ytop \
	    [incr x $lwidth]      $ytop \
	    [incr x $P(slantrun)] $polygonbottom \
	    -width $P(outlinethickness) \
	    -outline $P(disabledforeground) \
	    -fill $P(disabledbackground) \
	    -tags tab$i
	$canvas create line $x $linebottom [expr $tabwinwidth - 1] $linebottom \
	    -fill $P(foreground) -tags tab$i -width $P(outlinethickness)
	$canvas create window \
	    [expr $leftx + $P(slantrun)] \
	    [expr $ytop + $P(outlinethickness)] \
	    -window $label \
	    -anchor nw \
	    -tags tab$i
	$canvas bind tab$i <1> "TabNBGotoPage $w $i"
	bind $label <1> "TabNBGotoPage $w $i"
	set leftx [expr $x + $P(overlap)]
	# Lower tab so that the pages will appear to be stacked in order
	$w.tabcanvas lower tab$i
    }

    place $canvas -in $w -anchor nw -x 0 -y 0

    frame $w.page \
	-width [expr $width - 2*$P(borderwidth)] \
	-height [expr [winfo pixels . $P(height)] - $ybottom \
		     + $P(outlinethickness) - 2*$P(borderwidth)] \
	-takefocus 0 \
	-highlightthickness $P(outlinethickness) \
	-highlightbackground $P(foreground)
    grid propagate $w.page 0
    place $w.page -in $w -anchor nw \
	-x 0 -y [expr $ybottom - $P(outlinethickness)]
    catch {unset P(current)}
    TabNBGotoPage $w $P(startpage)
    return $w
}

proc TabNBGotoPage {w pagenum} {
    upvar \#0 TabNB$w P
    # change colors on tabs
    if [info exists P(current)] {
	$w.tabcanvas itemconfigure [expr 2 + 4*$P(current)] \
	    -outline $P(disabledforeground) \
	    -fill $P(disabledbackground)
	$w.tabcanvas.lab$P(current) configure \
	    -foreground $P(disabledforeground) \
	    -background $P(disabledbackground)
    }	    
    set tabitem [expr 2 + 4*$pagenum]
    $w.tabcanvas itemconfigure $tabitem \
	-outline $P(foreground) \
	-fill $P(background)
    $w.tabcanvas raise tab$pagenum
    $w.tabcanvas.lab$pagenum configure \
	-foreground $P(foreground) \
	-background $P(background)

    # Callback (which might put widgets in $w.page)
    if ![Empty $P(changecallback)] {
	eval $P(changecallback) $w $pagenum
    }

    # grid new window if defined.
    set pagew [lindex [lindex $P(pages) $pagenum] 1]
    if {![Empty $pagew] && [winfo exists $pagew]} {
	place $pagew -in $w.frame -anchor nw \
	    -x $P(outlinethickness) -y $P(outlinethickness)
    }

    raise $w.tabcanvas
    set P(current) $pagenum
}

proc TabNBTest {} {
    uplevel \#0 {
	catch "unset TabNB.tnb.n"
	catch "destroy .tnb.n"
	source /home/markcrim/TKGsrc/tcl/tabnotebook.tcl
	if ![winfo exists .tnb] {toplevel .tnb}
	TabNB .tnb.n -pages {{{One page} {}} {Another {}} {{Still Another} {}}}
	grid .tnb.n
	raise .tnb
    }
}
