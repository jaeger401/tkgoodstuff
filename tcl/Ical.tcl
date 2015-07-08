# Ical (calendar program) alarm and launching Client for tkgoodstuff

proc IcalDeclare {} {
    set Prefs_taborder(:Clients,Ical) "Misc Button"
    set Prefs_taborder(:Clients,Ical,Button) "Misc Colors Fvwm"
    TKGDeclare Ical(file) {~/.calendar} -typelist [list Clients Ical Misc]\
	-label "Calendar file"
    TKGDeclare Ical(makebutton) 1 -typelist [list Clients Ical Button Misc]\
	-label "Produce a button"\
	-vartype boolean
    ConfigDeclare Ical ClientButton1 Ical [list Clients Ical Button]
    ConfigDeclare Ical ClientButton2 Ical [list Clients Ical Button]
    ConfigDeclare Ical ClientButton3 Ical [list Clients Ical Button]
    ConfigDeclare Ical ClientButton5 Ical [list Clients Ical Button]
    TKGSet Ical(windowname) "Calendar"
    set TKGVars(Ical(windowname),default) "Calendar"
    TKGDeclare Ical(text) Calendar -typelist [list Clients Ical Button Misc]\
	-label "Label text"
    TKGDeclare Ical(imagefile) {%ical}\
	-typelist [list Clients Ical Button Misc] -label "Icon file"
    TKGDeclare Ical(startuplist) 0 -typelist [list Clients Ical Misc]\
	-label "Post list of day's calendar items at startup"\
	-vartype boolean
    TKGDeclare Ical(enablealarms) 1 -typelist [list Clients Ical Misc]\
	-label "Enable alarms"\
	-vartype boolean
    TKGDeclare Ical(nobeep) 0 -typelist [list Clients Ical Misc]\
	-label "Do not beep"\
	-vartype boolean
    TKGDeclare Ical(fetch_interval) 120 -typelist [list Clients Ical Misc]\
	-label "How often (in seconds) to check if calendar file has changed"
    TKGColorDeclare Ical(nowfg) \#8b0000 [list Clients Ical Misc]\
	"Color to highlight current items in alarms"
    TKGDeclare Ical(clockbd) 1 -typelist [list Clients Ical Misc]\
	-label "Show that Ical client is loaded by changing Clock's border?"\
	-vartype boolean
}

proc IcalInit {} {
    global Ical Clock TKG
    set Ical(file) [glob $Ical(file)]
    set Ical(fetch_offset) 10
    set Ical(script) $TKG(libdir)/tcl/Ical-fetch.tcl
    setifunset Clock(foreground) chartreuse1
    set Ical(itemlist) {}
    set Ical(ignoreitems) {}
    set Ical(filemtime) 0
    set Ical(oldfilemtime) 0
    set Ical(old_formatted_items) {}
    set Ical(newday) 0
    if ![file exists $Ical(file)] {
	TKGError "File \"$Ical(file)\" (the value of the variable Ical(file)) does\
not exist.  Aborting Ical support." 
	return 0
    }
    if ![file readable $Ical(file)] {
	TKGError "File \"$Ical(file)\" (the value of the variable Ical(file)) is\
not readable.  Aborting Ical support." 
	return 0
    }

    if $Ical(startuplist) {
	IcalListItems
    }
}

proc IcalStart {} {
    global Ical
    TKGPeriodic IcalFetch $Ical(fetch_interval) $Ical(fetch_offset) IcalFetch
}

proc IcalCreateWindow {} {
    global Ical Ical-params
    if $Ical(makebutton) {
	if [TKGReGrid Ical] return
	lappend c TKGMakeButton Ical -exec "ical -calendar $Ical(file)" \
	    -balloon {Ical calendar}
	if !$Ical(nolabel) {
	    lappend c -text $Ical(text)
	}
	if {!$Ical(noicon) || $Ical(nolabel)} {
	    lappend c -imagefile $Ical(imagefile)
	}
	foreach switch {
	    iconside ignore font foreground background windowname tilefile
	    activeforeground activebackground staydown trackwindow relief
	} {
	    lappend c -$switch $Ical($switch)
	}
	eval $c
	bind [set Ical-params(pathname)] <3> IcalListItems
    } else {
	TKGAddToHook TKG_clientwindowscreated_hook \
	    {catch {RecursiveBind $Clock_window <2> IcalLaunch}}
    }
        if [winfo exists .tkgpopup.ical] {return}
    # we make a ring around the clock to show we're loaded
    if $Ical(clockbd) {
	TKGAddToHook TKG_clientwindowscreated_hook \
	    {catch {$Clock_window configure -background $Clock(foreground)}}
    }
    TKGPopupAddClient Ical
    .tkgpopup.ical add  command \
	-label "Today's Calendar Items" \
	-command {IcalListItems}
    .tkgpopup.ical  add command \
	-label "View Calendar" \
	-command {exec ical -calendar $Ical(file) &}
    .tkgpopup.ical add checkbutton \
	-label "Enable Alarms" \
	-variable {Ical(enablealarms)}
}

proc IcalListItems {} {
    global Ical
    exec ical -calendar $Ical(file) -popup &
}

proc IcalLaunch {} {
    global Ical
    if $Ical(makebutton) {
	TKGButtonInvoke Ical
    } else {
	exec ical -calendar $Ical(file) &
    }
}

proc IcalFetch {} {
    global Ical
    
    if {$Ical(enablealarms) == 0} {return}

    catch {set Ical(filemtime) [eval file mtime $Ical(file)]}

    if { ($Ical(filemtime) == $Ical(oldfilemtime))\
	     && !$Ical(newday) } {
	return
    }
    set Ical(oldfilemtime) $Ical(filemtime)
    set Ical(newday) 0
    set Ical(fetch_out) ""
    set Ical(itemlist) {}
    DEBUG "Starting Ical fetch in background."
    set cmd "ical -f $Ical(script) -calendar $Ical(file)"
    set id [open "|$cmd 2> /dev/null" r]
    fileevent $id readable [list IcalPipeRead $id]
    vwait Ical(fetchvar)
    DEBUG "Ical fetch returned."
    eval $Ical(fetch_out)
    if { $Ical(fetch_out) != "" } {
	DEBUG "Ical fetch output:"
	DEBUG $Ical(fetch_out)
	DEBUG "   (end fetch output)"
    } else {
	DEBUG "No output from Ical fetch."
    }
    global Clock_minute_hook
    if {[lsearch $Clock_minute_hook IcalCheck] == -1} {
	TKGAddToHook Clock_minute_hook IcalCheck
    }
    IcalCheck
}

proc IcalPipeRead {id} {
    global Ical
    if [eof $id] {
	fileevent $id readable ""
	close $id
	set Ical(fetchvar) 1
    } else {
	append Ical(fetch_out) "[gets $id]\n"
    }
}

proc IcalCheck {} {
    global Ical TKG

    if { ( (!$Ical(enablealarms)) || $TKG(nonotices) )} {return}

    #get minutes since midnight today
    scan [ clock format [clock seconds] -format {%H %M}] "%s %s" nowhour nowminute
    set nowhour [TKGZeroTrim $nowhour]
    set nowminute [TKGZeroTrim $nowminute]
    set now [expr ( $nowhour * 60 ) + $nowminute ]
    if !$now {
	set Ical(newday) 1
	IcalFetch
	return
    }
    if [llength $Ical(itemlist)] {
	set alarmlist {}
	foreach item $Ical(itemlist) {
	    set start [lindex $item 0]
	    set alarms [lindex $item 1]
	    foreach t $alarms {
		if  { (($start - $t) == $now)
		      && ([lsearch $Ical(ignoreitems) $item] == -1)} {
		    lappend alarmlist $item
		}
	    }
	}
	if [llength $alarmlist] {
	    IcalAlarm $alarmlist
	}
    }
}

proc IcalAlarm { items } {
    global Ical TKG Clock

    set Ical(formatted_items) ""
    foreach item $Ical(old_formatted_items) {
	if {[lsearch $items [lindex $item 2]] == -1} {
	    lappend Ical(formatted_items) $item
	}
    }
    foreach item [lsort $items ] {
	set start [lindex $item 0]
	set text [lindex $item 2]
	set realhour [expr ((($start/60)%12) == 0) ? 12 : (($start/60)%12)] 
	set realtime "$realhour:[format %02i [expr $start % 60]]"
	lappend Ical(formatted_items) [list $realtime $text $item]
    }
    set Ical(old_formatted_items) $Ical(formatted_items)
    
    TKGDialog ical_alarm \
	-wmtitle "tkgoodstuff: Ical Alarm" \
	-image ical.xpm \
        -title "Ical Alarm        (at $Clock(prettytime))" \
	-nodeiconify \
	-nodismiss \
	-buttons {
	    {
		dismiss
		Dismiss
		{ 
		    set Ical(old_formatted_items) ""
		    for {set j 0} {$j <  [llength $Ical(formatted_items)]} {incr j} {
			if [set Ical(item$j)] {
			    lappend Ical(ignoreitems) \
                              [lindex [lindex $Ical(formatted_items) $j] 2]
			    DEBUG "TKG Ical: ignoring [lindex [lindex $Ical(formatted_items) $j] 2]"
			}
		    }   
		    destroy .ical_alarm
		    }
	    } {
		noalarms
		"No Alarms!"
		{
		    set Ical(enablealarms) 0
		    set Ical(old_formatted_items) ""
		    destroy .ical_alarm
		}
	    } {
		view
		"View Calendar"
		{
		    destroy .ical_alarm
		    set Ical(old_formatted_items) ""
		    exec ical &
		}
	    }
	}
    focus .ical_alarm.buttons.dismiss

    frame .ical_alarm.items -relief ridge -borderwidth 3
    set firstnew [expr "[llength $Ical(formatted_items)] - [llength $items]"]
    set  i 0
    foreach item $Ical(formatted_items) {
	frame .ical_alarm.items.item$i
	set Ical(item$i) 0
	checkbutton .ical_alarm.items.item$i.time$i -text [lindex $item 0] \
		-variable Ical(item$i) -font tkghugebold
	label .ical_alarm.items.item$i.text$i -text [lindex $item 1] \
	    -font tkghugebold
	if { ($firstnew > 0) && ($i >= $firstnew) } {
	    .ical_alarm.items.item$i.time$i configure -fg $Ical(nowfg)
	    .ical_alarm.items.item$i.text$i configure -fg $Ical(nowfg)
	}
	grid .ical_alarm.items.item$i.time$i -sticky nw -row 0 -column 0
	grid .ical_alarm.items.item$i.text$i -sticky nw -row 0 -column 1 -pady 2
	grid .ical_alarm.items.item$i -sticky w
	incr i
    }

    label .ical_alarm.instr -text "Check box to ignore any further alarms for the item.\
	    \nClick on Dismiss when done."
    ColorConfig .ical_alarm.title black red
    grid columnconfigure .ical_alarm.items 0 -weight 1
    grid .ical_alarm.items -row 1 -column 0 -sticky ew -padx 3 -pady 3
    grid .ical_alarm.instr -row 3 -column 0 -sticky ew -padx 3 -pady 3
    if {$firstnew > 0} {
	label .ical_alarm.instr2 -text "(Newest alarms are highlighted.)" -fg $Ical(nowfg)
	grid .ical_alarm.instr2 -row 2 -column 0 -sticky ew -padx 3 -pady 3
    }
    TKGCenter .ical_alarm
    if {!$Ical(nobeep)} {TKGBell 1.2 1.3 10}
}

DEBUG "Loaded Ical.tcl"
