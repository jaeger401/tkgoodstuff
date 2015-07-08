# WindowList (tkgoodstuff client)

proc WindowListDeclare {} {
    set Prefs_taborder(:Clients,WindowList) "Misc WindowButtons Icons Geometry Colors"
    set Prefs_taborder(:Clients,WindowList,WindoButtons) "Misc Colors"
    TKGDeclare FWL(icons) 1 -typelist [list Clients WindowList WindowButtons Misc]\
	-vartype boolean -label "Produce icons on the window buttons"
    TKGDeclare FWL(iconside) left -typelist [list Clients WindowList WindowButtons Misc]\
	-label "Which side of the buttons the icons go on"\
	-vartype optionMenu\
	-optionlist {left right top bottom}
    TKGDeclare FWL(defaulticon) {win.xpm}\
	-typelist [list Clients WindowList WindowButtons Misc]\
	-label "Default window button icon"
    TKGColorDeclare FWL(fg) {} \
	[list Clients WindowList WindowButtons Colors]\
	 "Foreground" $TKG(foreground)
    TKGColorDeclare FWL(bg) {} \
	 [list Clients WindowList WindowButtons Colors]\
	 "Background" $TKG(buttonbackground)
    TKGColorDeclare FWL(afg) {} \
	 [list Clients WindowList WindowButtons Colors]\
	 "Active foreground" $TKG(butactiveforeground)
    TKGColorDeclare FWL(abg) {} \
	 [list Clients WindowList WindowButtons Colors]\
	 "Active background" $TKG(butactivebackground)
    TKGColorDeclare FWL(ifg) {} \
	 [list Clients WindowList WindowButtons Colors]\
	 "Foreground for iconified windows" $TKG(disabledforeground)
    TKGColorDeclare FWL(field)  {} \
	[list Clients WindowList Misc] \
	 "Color of background" $TKG(panelcolor)
    TKGDeclare FWL(ignore) "" -typelist [list Clients WindowList Misc]\
	-label "Space-separated list of window names of windows to ignore"\
	-help "Wildcards like \"*\" are acceptable.  X resource class names also are matched."
    TKGDeclare FWL(tilefile) {} \
	-typelist [list Clients WindowList Misc]\
	-label "Image (file) to tile in background of buttons."
    TKGDeclare FWL(font) "" -fallback tkgmedium\
	-vartype font\
	-typelist [list Clients WindowList WindowButtons Misc]\
	-label "Font on window buttons."
    TKGDeclare FWL(minsize) "1.5" -typelist [list Clients WindowList WindowButtons Misc]\
	-label "How small should we allow buttons to get before scrolling (centimeters)?"
    TKGDeclare FWL(maxsize) "10" -typelist [list Clients WindowList WindowButtons Misc]\
	-label "How large should we allow buttons to get (centimeters)?"
    TKGDeclare FWL(butpad) 1 -typelist [list Clients WindowList WindowButtons Misc]\
	-label "How many pixels of padding around icon and text?"
    TKGDeclare FWL(butsep) 3 -typelist [list Clients WindowList WindowButtons Misc]\
	-label "How many pixels of padding between icon and text?"
    TKGDeclare FWL(butrelief) flat -typelist [list Clients WindowList WindowButtons Misc]\
	-vartype optionMenu\
	-label {Normal relief for buttons.}\
	-optionlist {flat raised}
    TKGDeclare FWL(borderwidth) 1 -typelist [list Clients WindowList WindowButtons Misc]\
	-label "How deep is sunken or raised relief (pixels)?"
    TKGDeclare FWL(padding) "" -typelist [list Clients WindowList Misc]\
	-label "How many pixels of padding around window buttons?"
    TKGDeclare FWL(nofvwmicons) 1 -typelist [list Clients WindowList Misc]\
	-label "Tell fvwm not to post icons"\
	-vartype boolean
    TKGDeclare FWL(width) "" -typelist [list Clients WindowList Geometry]\
	-label "Width in pixels of WindowList field"\
	-help "Leave blank to use default (which depends on various factors)."
    TKGDeclare FWL(height) "" -typelist [list Clients WindowList Geometry]\
	-label "Height in pixels of WindowList field"\
	-help "Leave blank to use default (which depends on various factors)."
    lappend FWL(editors) Emacs Nedit Xedit Lyx
    lappend FWL(shells) XTerm
    lappend FWL(mailers) Exmh Xmh XFMail MH-E* Tkrat
    lappend FWL(newsreaders) Knews Xrn
    lappend FWL(browsers) Netscape Mosaic Surfit
    lappend FWL(graphics) XV* Bitmap Pixmap XPaint Gimp
    lappend FWL(filers) dsk_* Xfm XDir XFtp
    lappend FWL(manreaders) TkMan Xman
    lappend FWL(tks) *.tcl Wish* Toplevel
    set templist ""
    foreach type {
	editor shell mailer newsreader browser graphic filer manreader tk
    } {
	lappend templist [list $type $type $type.xpm]
	TKGDeclare FWL(${type}s) [set FWL(${type}s)]\
	    -typelist [list Clients WindowList Icons]\
	    -label "Names of ${type}s"
	TKGDeclare FWL(icon,${type}s) "${type}.xpm"\
	    -typelist [list Clients WindowList Icons]\
	    -label "Icon for $type applications"
	foreach name [set FWL(${type}s)] {
	    set FWL_icon($name) [set FWL(icon,${type}s)]
	}
	unset FWL(${type}s)
    }
    unset name type templist
}

proc WindowListDoOnLoad {} {
    global FWL
    if ![info exists Fvwm(outid)] {
	TKGError "WindowList client will not work unless 
fvwm starts tkgoodstuff as an fvwm module." exit
    }
}

proc WindowListCreateWindow {} {
    global Fvwm FWL TKG
    global $TKG(currentpanel)-pparams

    # Dragging panel to another screen-edge?
    if [info exists FWL(window)] {
	bind $FWL(window) <Configure> {}
	FWLClearWindowList
	FWLSetOrientation
	grid propagate $FWL(window) 0
	TKGGrid $FWL(window) expand
	return
    }
    foreach type {minsize maxsize} {
	if {[catch {
	    set FWL($type) \
		[expr {round([winfo fpixels . [set FWL($type)]c])}]
	}]} {
	    TKGError "Error in setting WindowList button minimum
or maximum button size; did you supply an integer?" exit
	}
    }
    set FWL(active) {}
    set FWL_images(0) 0
    set FWL(window) .[string tolower $TKG(currentpanel)].fwl
    tkgframe $FWL(window) -bd 0 -highlightthickness 0 \
	-background $FWL(field) -cursor top_left_arrow \
	-tileimage $TKG(paneltileimage)

    FWLSetOrientation
    grid propagate $FWL(window) 0
    set FWL(first) 0

    TKGGrid $FWL(window) expand -nosep

    TKGAddToHook TKG_postedhook-$TKG(currentpanel) \
	"TKGAddToHook Fvwm_WindowName_hook FWLWindowName"\
	"TKGAddToHook Fvwm_IconName_hook FWLIconName"\
	"TKGAddToHook Fvwm_DestroyWindow_hook FWLDestroyWindow"\
	"TKGAddToHook Fvwm_Iconify_hook FWLIconify"\
	"TKGAddToHook Fvwm_Deiconify_hook FWLDeiconify"\
	"TKGAddToHook Fvwm_FocusChange_hook FWLFocusChange"\
	"bind $FWL(window) <Configure> FWLNewDisplay"\
	"fvwm send $Fvwm(outid) Send_WindowList"

    if $FWL(nofvwmicons) {
	fvwm send $Fvwm(outid) {Style "*" NoIcon}
    }

    if [string match "" $FWL(tilefile)] {
	set FWL(tileimage) "none"
    } else {
	SetImage fwltile $FWL(tilefile)
	set FWL(tileimage) fwltile
    }

    bind $FWL(window) <3> {
	TKGPopupPost .tkgpopup %X %Y
	focus .tkgpopup
	grab set -global .tkgpopup
    }
}


#Code for dragging windows onto pages in the Pager client
proc FWLButton2 {id} {
    global FWL
    $FWL($id,pathname) configure -cursor crosshair
}

# Deiconify if necessary, go to new page, move window to current
# page with same page position, and focus if not MouseFocus.
proc FWLButtonRelease2 {id x y} {
    global FvwmW Fvwm FWL
    $FWL($id,pathname) configure -cursor top_left_arrow
    set w [winfo containing $x $y]
    if ![regexp {\.page\((.*),(.*),(.*)\)} $w v D X Y] return
    fvwm send $id "Iconify -1"
    fvwm send $Fvwm(outid) "Desk 0 $D"
    fvwm send $Fvwm(outid) "GotoPage $X $Y"
    fvwm send $id "WindowsDesk $D"
    set wx [expr $FvwmW($id,x) % [winfo vrootwidth .]]p
    set wy [expr $FvwmW($id,y) % [winfo vrootheight .]]p
    fvwm send $id "Move $wx $wy"
    fvwm send $id {Raise ""}
    if {$FvwmW($id,flags) & 3072} {
	fvwm send $id "Focus"
    }
}

# Get image appropriate to window name
proc FWLGetImage {id} {
    global FWL FWL_icon FWL_images FvwmW

    set name $FvwmW($id,windowname)
    set resclass $FvwmW($id,resclass)
    foreach type {name resclass} {
	foreach n [array names FWL_icon] {
	    if [string match $n [set $type]] {
		set f $FWL_icon($n)
		break
	    }
	}
    }
    if ![info exists f] {
	set f $FWL(defaulticon)
    }
    if [info exists FWL_images($f)] {
	return $FWL_images($f)
    } else {
	set i 0
	while {[lsearch [image names] "image$i"] != -1} {incr i}
	SetImage image$i $f
	set FWL_images($f) image$i
	return image$i
    }
}

proc FWLDefaultsArray {} {
    global FWL
    return [list \
		modes {normal iconic}\
		foreground,normal $FWL(fg)\
		background,normal $FWL(bg)\
		activeforeground,normal $FWL(afg)\
		activebackground,normal $FWL(abg)\
		font,normal $FWL(font)\
		tileimage $FWL(tileimage)\
		padding $FWL(butpad)\
		sep $FWL(butsep)\
		ignore 1\
		textanchor w\
		foreground,iconic $FWL(ifg)\
		background,iconic $FWL(bg)\
		activeforeground,iconic $FWL(ifg)\
		activebackground,iconic $FWL(abg)\
		font,iconic $FWL(font)\
	       ]
}

# Make new button and redisplay
proc FWLCreateButton {id} {
    global FvwmW FWL FWL${id}-params
    set FWL($id,ignored) 0
    array set FWL${id}-params [FWLDefaultsArray]
    set FWL($id,pathname) $FWL(window).l$id
    TKGButton FWL$id -pathname $FWL($id,pathname)\
	-borderwidth $FWL(borderwidth) -relief $FWL(butrelief)\
	-textweight 1 -imageweight 0
    FWLBind $id
    set FvwmW($id,iconic) 0
    lappend FWL(ids) $id
    FWLDisplay
}

proc FWLClearWindowList {{exceptscrollers 0}} {
    global FWL
    # clear WindowList
    if {!$exceptscrollers} {
	foreach slave [grid slaves $FWL(window)] {
	    grid forget $slave
	}
    } else {
	foreach slave [grid slaves $FWL(window)] {
	    if {[string match $FWL(window).scrollbar $slave] ||
		[string match $FWL(window).uparrow $slave] ||
		[string match $FWL(window).downarrow $slave]} {
		continue
	    }
	    grid forget $slave
	}
    }
}

# To be called when FWL window is newly sized
proc FWLNewDisplay {} {
    global FWL
    set FWL(configured) 0
    FWLDisplay
}

# To be called on creation of widget, or when panel is
# dragged to another screen edge.
proc FWLSetOrientation {} {
    global TKG FWL
    global $TKG(currentpanel)-pparams
    set FWL(configured) 0
    switch -regexp [set $TKG(currentpanel)-pparams(screenedge)] {
	"no" {
	    set FWL(orientation) \
		[set $TKG(currentpanel)-pparams(orientation)]
	    if {$FWL(orientation) == "vertical"} {
		if [Empty [set height $FWL(height)]] {
		    set height 200
		}
		if [Empty [set width $FWL(width)]] {	
		    set width 60
		}
	    } else {
		if [Empty [set height $FWL(height)]] {
		    set height 32
		}
		if [Empty [set width $FWL(width)]] {	
		    set width 400
		}
		$FWL(window) configure 
	    }
	    $FWL(window) configure -height $height -width $width
	} left|right {
	    set FWL(orientation) vertical
	} default {
	    set FWL(orientation) horizontal
	}
    }
}

# To be called on first call to FWLDisplay in new
# orientation
proc FWLConfigureDisplay {} {
    global FWL

    if {(![info exists FWL(ids)]) ||
	(![llength $FWL(ids)])} return

    set FWL(configured) 1

    FWLClearWindowList
    TKGClearWeights $FWL(window)

    set FWL(width) [winfo width $FWL(window)]
    set FWL(height) [winfo height $FWL(window)]
    
    if {![winfo exists $FWL(window).scrollbar]} {
	scrollbar $FWL(window).scrollbar \
	    -command FWLDisplay -width .3c\
	    -highlightthickness 0
    }
    
    if ![Empty $FWL(padding)] {
	set FWL(pad) $FWL(padding)
    } else {
	set FWL(pad) [expr int($FWL(width))/100]
    }
    
    set FWL(butheight) [winfo reqheight $FWL([lindex $FWL(ids) 0],pathname)]
    set FWL(rows) [expr int($FWL(height)/($FWL(butheight)+2))]
    for {set row 0} {$row < $FWL(rows)} {incr row} {
	grid rowconfigure $FWL(window) $row -weight 1
    }

    if {[string match horizontal $FWL(orientation)]} {
	# maximum buttons that will fit (if no scrolling)
	set FWL(butsperrow) \
	    [expr {int($FWL(width)/($FWL(minsize) + (2*$FWL(pad))))}]
    } else {
	set FWL(butsperrow) 1
    }
    set FWL(maxbuttons) [expr $FWL(butsperrow) * $FWL(rows)]
    set FWL(scrolledwidth) [expr $FWL(width) \
			   -([winfo reqwidth $FWL(window).scrollbar]\
			       + (2*$FWL(pad)))]
    set FWL(scrolledbutsperrow) \
	[expr {int($FWL(width)/($FWL(minsize) + (2*$FWL(pad))))}]
    set FWL(scrolledmaxbuttons) \
	[expr $FWL(scrolledbutsperrow) * $FWL(rows)]

}

# FWLDisplay displays all buttons if possible, and otherwise
# responds to the action by scrolling.  FWL(first)
# holds index of first displayed window in FWL(ids).  "action" 
# is "scroll" (actnum is amount and unit is units or page) or
# "moveto" (actnum is fraction).

proc FWLDisplay {{action ""} {actnum 0} {unit ""}} {
    global FWL

    if {![info exists FWL(configured)]} return
    if {!$FWL(configured)} FWLConfigureDisplay

    if ![info exists FWL(ids)] return

    set numwins [llength $FWL(ids)]

    # return if no buttons to place
    if {!$numwins} return

    set butheight $FWL(butheight)
    set rows $FWL(rows)
    set pad $FWL(pad)
    # do we need to draw scrollbar?
    set scrolling 0
    if {$numwins > $FWL(maxbuttons)} {

	set width $FWL(scrolledwidth)
	set butsperrow $FWL(scrolledbutsperrow)
	set maxbuttons $FWL(scrolledmaxbuttons)
	if {$maxbuttons < 1} return

	switch $action {
	    scroll {
		switch $unit {
		    units {
			set newfirst \
			    [expr $FWL(first) + $actnum * $butsperrow]
		    } pages {
			set newfirst \
			    [expr $FWL(first) + $actnum * $FWL(numbuttons)]
		    }
		}
	    } moveto {
		set actnum [Max $actnum 0]
		set actnum [Min $actnum 1]
		set newfirst \
		    [expr int($numwins*$actnum/$butsperrow) \
			 * $butsperrow]
	    }
	}
	if {[info exists newfirst]} {
	    if {$newfirst < 0} {
		set newfirst 0
	    }
	    # be sure we start with the beginning of a row;
	    # largest reasonable FWL(first) is (total rows - visible rows) *
	    # butsperrow (no need for empty rows).
	    set newfirst \
		[Min [expr int($newfirst/$butsperrow)*$butsperrow] \
		     [expr (int(($numwins+$butsperrow-1)/$butsperrow) \
				- $rows)*$butsperrow]]
	    if {$newfirst == $FWL(first)} return
	    set FWL(first) $newfirst
	} else {
	    if {$FWL(first) < 0} {
		set FWL(first) 0
	    }
	    set FWL(first) \
		[Min [expr int($FWL(first)/$butsperrow)*$butsperrow] \
		     [expr (int(($numwins+$butsperrow-1)/$butsperrow) \
				- $rows)*$butsperrow]]
	}

	set scrolling 1
	FWLClearWindowList 1
	
	set last\
	    [llength \
		 [lrange $FWL(ids) 0 \
		      [expr {$FWL(first) + ($rows*$butsperrow) - 1}]]]
	$FWL(window).scrollbar set \
	    [expr double($FWL(first))/$numwins] \
	    [expr double($last)/$numwins]
	
	if {![In $FWL(window).scrollbar [grid slaves $FWL(window)]]} {
	    grid $FWL(window).scrollbar \
		-row 0 -column 0 -rowspan $rows\
		-padx $pad -pady 0 -sticky ns
	}
	
	set FWL(numbuttons) $maxbuttons
	set butwidth [expr {int(($width/$butsperrow)-(2*$pad))}]

    } else {
	# we can draw all buttons; see how big we can make them
	# while dividing the window evenly.
	set width $FWL(width)
	set butsperrow $FWL(butsperrow)
	set maxbuttons $FWL(maxbuttons)
	if {$maxbuttons < 1} return
	FWLClearWindowList
	set FWL(numbuttons) $numwins
	set FWL(first) 0
	set butsperrow [expr int(($FWL(numbuttons)+$rows-1)/$rows)]
	while {(($width/$butsperrow)-(2*$pad)) > $FWL(maxsize)} {
	    incr butsperrow
	}
	set butwidth [expr {int(($width/$butsperrow)-(2*$pad))}]
    }

    # needed in case we had a single partial row last time
    for {set col 0} \
	{$col < [lindex [grid size $FWL(window)] 0]} \
	{incr col} {
	    grid columnconfigure $FWL(window) $col -weight 0
	}

    # grid the buttons
    if !$pad {set pad 1}
    for {set i 0} {$i < $FWL(numbuttons)} {incr i} {
	set id [lindex $FWL(ids) [expr $FWL(first)+$i]]
	if {[Empty $id]} break
	set w $FWL($id,pathname)
	$w configure -width $butwidth
	grid $w \
	    -row [expr int($i/$butsperrow)]\
	    -column [expr $scrolling + ($i%$butsperrow)]\
	    -padx [expr $pad - 1] -pady 0
    }

    # be sure we gravitate to the left (if single partial row) 
    set col [lindex [grid size $FWL(window)] 0]
    if {$col < $butsperrow} {
	grid columnconfigure $FWL(window) $col -weight 1
    }
}

proc FWLBind {id} {
    global FWL
    bind $FWL($id,pathname) <1> "FvwmGoto $id ; break"
    bind $FWL($id,pathname) <ButtonRelease-1> {break}
    bind $FWL($id,pathname) <2> "FWLButton2 $id ; break"
    bind $FWL($id,pathname) <ButtonRelease-2> \
	"FWLButtonRelease2 $id %X %Y; break"
}

proc FWLignored {id} {
    global FWL FvwmW
    set wname $FvwmW($id,windowname)
    set resclass $FvwmW($id,resclass)
    foreach pattern [concat $FWL(ignore) tkgoodstuff tkgsrc] {
	if {[string match $pattern $wname] ||\
		[string match $pattern $resclass]} {
	    return 1
	}
    }
    return 0
}

proc FWLWindowName {id} {
    global FvwmW FWL_icons FWL FWLwname
    upvar \#0 FWL${id}-params P
    set name $FvwmW($id,windowname)
    if {[info exists FWL($id,wname)] && ($FWL($id,wname) == $name)} return
    set FWL($id,wname) $name
    if ![info exists P(text,iconic)] {
	vwait FWL${id}-params(text,iconic)
    }
    if ![info exists FvwmW($id,resclass)] {
	vwait FvwmW($id,resclass)
    }
    if {([info exists FWL($id,ignored)] && $FWL($id,ignored))} return
    if [FWLignored $id] {
	set FWL($id,ignored) 1
	return
    }

    set P(text,normal) $name
    set P(balloon,normal) $name
    set P(balloon,iconic) $name
    if $FWL(icons) {
	set P(iconside) $FWL(iconside) 
	set P(image,normal) [FWLGetImage $id]
	set P(image,iconic) $P(image,normal)
    }

    if {![info exists FWL($id,pathname)] 
	|| ![winfo exists $FWL($id,pathname)]} {
	FWLCreateButton $id
    } else {
	# update the tkgbutton
	TKGButton FWL$id
    }

    bind $FWL($id,pathname) <3> "fvwm send $id \"Iconify\"; break"
    FWLBind $id
}

proc FWLIconName {id} {
    global FvwmW FWL${id}-params FWL
    set FWL${id}-params(text,iconic) $FvwmW($id,iconname)
}

proc FWLAbbrev {name len} {
    if {[set l [string length $name]] <= $len} {return $name}
    join [list [string range $name 0 [expr $len - 3]] ..] ""
}

proc FWLDestroyWindow {id} {
    global FvwmW FWL
    if {[set n [lsearch $FWL(ids) $id]] == -1} return
    destroy $FWL($id,pathname)
    foreach name [array names FWL] {
	if {[string match ${id},* $name]} {
	    unset FWL($name)
	}
    }
    set FWL(ids) [lreplace $FWL(ids) $n $n]
    FWLDisplay $n
}

proc FWLIconify {id} {
    global FWL
    if [info exists FWL($id,pathname)] {
	global  FWL${id}-params
	TKGButton FWL$id -mode iconic
	FWLBind $id
    }
}

proc FWLDeiconify {id} {
    global FWL
    if [info exists FWL($id,pathname)] {
	TKGButton FWL$id -mode normal
	FWLBind $id
    }
}

proc FWLFocusChange {id} {
    global FvwmW FWL FWL$id-params
    if {$FWL(active)!=""} {
	catch {$FWL(active) configure -relief $FWL(butrelief)}
    }
    if {[info exists FWL($id,pathname)] && [winfo exists $FWL($id,pathname)]} {
	set FWL(active) $FWL($id,pathname)
	$FWL(active) configure -relief sunken
	# ensure button for focused window can be seen
	if {![In $FWL($id,pathname) [grid slaves $FWL(window)]]} {
	    set FWL(first) [lsearch $FWL(ids) $id]
	    FWLDisplay
	}
    } else {
	set FWL(active) ""
    }
}

DEBUG "Loaded WindowList"
