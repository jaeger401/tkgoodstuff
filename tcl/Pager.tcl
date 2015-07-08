#  Pager, a Client for TkGoodstuff
#
#  Some code by  Eric Kahler(ekahler@mars.superlink.net) 

proc PagerDeclare {} {
    set Prefs_taborder(:Clients,Pager) "Misc Colors"
    TKGDeclare Pager(minpagewidth) 12 -typelist [list Clients Pager Misc]\
	-label "Minimum width per page (in pixels)"
    TKGDeclare Pager(minpageheight) 12 -typelist [list Clients Pager Misc]\
	-label "Minimum height per page (in pixels)"
    TKGColorDeclare Pager(ActiveBackground) \#87ceff\
	[list Clients Pager Colors]\
	"Color of current page"
    TKGColorDeclare Pager(Background) {}\
	[list Clients Pager Colors]\
	"Color of other pages"\
	$TKG(panelcolor)
    TKGDeclare Pager(Desks) 1 -typelist [list Clients Pager Misc]\
	-label "Number of desktops"
    TKGDeclare Pager(border) 3 -typelist [list Clients Pager Misc]\
	-label "Width in pixels of border around desktops"
}

proc PagerDoOnLoad {} {
    if ![info exists Fvwm(outid)] {
	TKGError "Pager client will not work unless
fvwm starts tkgoodstuff as an fvwm module." exit
    }
}

proc PagerStart {} {uplevel \#0 {
    foreach v [concat PagerW\
		   [info vars Pager_Page*]] {
	catch "unset $v"
    }
}}

proc PagerSuspend {} {
    global Pager Pager_Windows
    set Pager(suspended) 1
    for {set d 0} {$d < $Pager(Desks)} {incr d} {
	destroy $Pager_Windows($d)
    }
}

# PagerCreateWindow --
# We first wait until the Fvwm client has learned what page we're on.
# Then create the desks, leaving the pages until we're exposed.
proc PagerCreateWindow {} {
    global Pager Pager_Windows FvwmW

    if {(![info exists FvwmW(maxpagey)]) || ($FvwmW(maxpagey) == "")} {
	after 20000 {
	    if {(![info exists FvwmW(maxpagey)]) || ($FvwmW(maxpagey) == "")} {
		TKGError "Can't initialize Pager; didn't get page size from fvwm." exit
	    }
	}	    
	vwait FvwmW(maxpagey)
	if {$FvwmW(maxpagey) == ""} {vwait FvwmW(maxpagey)}
    }

    set Pager(ResX) [winfo vrootwidth .]
    set Pager(ResY) [winfo vrootheight .]

    set Pager(Columns) [expr 1 + $FvwmW(maxpagex)/$Pager(ResX)]
    set Pager(Rows) [expr 1 + $FvwmW(maxpagey)/$Pager(ResY)]
    set Pager(minheight) [expr $Pager(Rows) * $Pager(minpageheight)] 
    set Pager(minwidth)  [expr $Pager(Columns) * $Pager(minpagewidth)]

    for {set d 0} {$d < $Pager(Desks)} {incr d} {
	TKGGrid [TKGLabelBox Pager$d]
	global Pager${d}_window
	set Pager_Windows($d) [set Pager[set d]_window]
	$Pager_Windows($d) configure -borderwidth $Pager(border) \
	    -height 1 -width 1
    }

    bind $Pager_Windows(0) <Expose> {
	bind $Pager_Windows(0) <Expose> ""
	PagerCreateWindow-2
    }

    # In tk8.0, the id of a toplevel is one less than the window manager thinks
    set Pager(ourpanelid) \
	[format 0x%x [expr [winfo id [winfo toplevel $Pager0_window]] + 1]]
}

proc PagerCreateWindow-2 {} {
    global Pager Pager_Windows Fvwm

    set w $Pager_Windows(0)

    set Pager(W) [expr [winfo width $w] - 2*$Pager(border)]
    set Pager(H) [expr [winfo height $w] - 2*$Pager(border)]
    # Ensure we're over minimum size
    if {$Pager(W) < $Pager(minwidth)} {set Pager(W) $Pager(minwidth)}
    if {$Pager(H) < $Pager(minheight)} {set Pager(H) $Pager(minheight)}

    # Now autoscale
    set deskw [expr $Pager(ResX) * $Pager(Columns)]
    set deskh [expr $Pager(ResY) * $Pager(Rows)]
    set ratio [expr ($deskw+0.0)/$deskh]
    if {((0.0 + $Pager(W))/$deskw) >= ((0.0 + $Pager(H))/$deskh)} {
	regexp (.*)\\..* [expr $Pager(W) / $ratio ] Pager(H) Pager(H)
    } else {
	regexp (.*)\\..* [expr $Pager(H) * $ratio ] Pager(W) Pager(W)
    }
    # Correct the scale
    set Pager(PageWidth) [expr $Pager(W) / $Pager(Columns) - 1]
    set Pager(PageHeight) [expr $Pager(H) / $Pager(Rows) - 1]

    for {set D 0} {$D < $Pager(Desks)} {incr D} {
	set w $Pager_Windows($D)
    	for {set X 0} {$X < $Pager(Columns) } {incr X } {
	    grid columnconfigure $w $X -weight 1 -minsize $Pager(PageWidth)
	    for {set Y 0} {$Y < $Pager(Rows) } {incr Y } {
		set ww [set Pager_Windows($D,$X,$Y) $w.page($D,$X,$Y)]
		grid rowconfigure $w $Y -weight 1 -minsize $Pager(PageHeight)
		frame $ww -relief raised -borderwidth 1 \
		    -background $Pager(Background)\
		    -width $Pager(PageWidth) -height $Pager(PageHeight)
		grid $ww -in $w -sticky nsew -column $X -row $Y
		bind $ww <Button-1> "Pager_Goto $D $X $Y;break"
	    }
	}
    }
    update idletasks
    GoneToPage

    # Request messages
    global Fvwm_NewPage_hook
    if {![info exists Fvwm_newpage_hook] || ![In GoneToPage $Fvwm_NewPage_Hook]} {
	TKGAddToHook Fvwm_NewPage_hook GoneToPage
	TKGAddToHook Fvwm_NewDesk_hook GoneToPage
	TKGAddToHook Fvwm_ConfigureWindow_hook MarkPage
	TKGAddToHook Fvwm_FocusChange_hook PagerFocus
	TKGAddToHook Fvwm_DestroyWindow_hook UnMarkPage
    }
    catch {unset Pager(suspended)}
    fvwm send $Fvwm(outid) "Send_WindowList"
}

proc MarkPage { id } {
    global FvwmW PagerW Pager Pager_Windows
    if [info exists Pager(suspended)] return
    set D $FvwmW($id,t)
    set X $FvwmW($id,npagex)
    set Y $FvwmW($id,npagey)

    if [info exists PagerW($id,npagex)] {
	set oldD $PagerW($id,t)
	set oldX $PagerW($id,npagex)
	set oldY $PagerW($id,npagey)
	if {[list $oldX $oldY $oldD] == [list $X $Y $D]} return
	UnMarkPage $id
    }
    upvar \#0 Pager_Page-$X-$Y-$D P
    if {$id != $Pager(ourpanelid)} { 
	if {[array names P] == {}} {
	    if {$D < $Pager(Desks)} {
		$Pager_Windows($D,$X,$Y) configure -background $Pager(ActiveBackground)
	    }
	}
	set P($id) 1 
	set PagerW($id,t) $D
	set PagerW($id,npagex) $X
	set PagerW($id,npagey) $Y
    } 
}

proc UnMarkPage { id } {
    global FvwmW PagerW Pager_Windows Pager
    if [info exists Pager(suspended)] return
    if ![info exists PagerW($id,t)] return
    set D $PagerW($id,t)
    set X $PagerW($id,npagex)
    set Y $PagerW($id,npagey)
    upvar \#0 Pager_Page-$X-$Y-$D P
    catch {unset P($id)}
    if {[array names P] == {}} {
	if {$D < $Pager(Desks)} {
	    $Pager_Windows($D,$X,$Y) configure -background $Pager(Background)
	}
    }
    catch {unset PagerW($id,t) PagerW($id,npagex) PagerW($id,npagey)}
    return
}

# called on a click on a page
# we try to go to the same window as last time, unless user
# clicked on current page, in which case we cycle
proc Pager_Goto {D X Y} {
    global Fvwm FvwmW Pager
    upvar \#0 Pager_Page-$X-$Y-$D P
    upvar \#0 Pager(NextLast-$D-$X-$Y) NL
    if ![info exists NL] {
	set NL 0
    }
    if {($D != $FvwmW(desktop))
	|| ($X != $FvwmW(npagex))
	|| ($Y != $FvwmW(npagey))} {
	fvwm send $Fvwm(outid) "Desk 0 $D"
	fvwm send $Fvwm(outid) "GotoPage $X $Y"
    } else {
	incr NL
    }
    set wins [lsort -decreasing [array names P]]
    set l [llength $wins]
    for {set i 0} {$i < $l} {incr i} {
	set w [lindex $wins [expr ($NL+$i)%$l]]
	if !$FvwmW($w,iconic) {
	    set NL [expr ($NL+$i)%$l]
	    FvwmGoto $w
	    break
	}
    }
}

proc PagerFocus {w} {
    global FvwmW Pager
    if !$w return
    if [string match $FvwmW($w,resclass) Tkgoodstuff] return
    set X $FvwmW($w,npagex)
    set Y $FvwmW($w,npagey)
    set D $FvwmW($w,t)
    upvar \#0 Pager_Page-$X-$Y-$D P
    upvar \#0 Pager(NextLast-$D-$X-$Y) NL
    set NL [lsearch [lsort -decreasing [array names P]] $w]
}

proc GoneToPage {} {
    global Pager Pager_Windows FvwmW

    if [info exists Pager(suspended)] return

    set X $FvwmW(npagex)
    set Y $FvwmW(npagey)
    set D $FvwmW(desktop)

    if [info exists Pager(last,D)] {
	$Pager_Windows($Pager(last,D),$Pager(last,X),$Pager(last,Y)) configure -relief raised
    }

    if {(![info exists Pager_Windows($D,$X,$Y)]) \
	    || (![winfo exists $Pager_Windows($D,$X,$Y)])} return
    $Pager_Windows($D,$X,$Y) configure -relief sunken

    set Pager(last,D) $D
    set Pager(last,X) $X
    set Pager(last,Y) $Y
    return
}

DEBUG "Loaded Pager.tcl"
