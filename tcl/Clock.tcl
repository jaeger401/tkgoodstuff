# Clock Client Tcl code for tkgoodstuff

proc ClockDeclare {} {
    set Prefs_taborder(:Clients,Clock) "Misc Analog Alarm Geometry Fonts"
    set Prefs_taborder(:Clients,Clock,Analog) "Misc Colors"
    TKGDeclare Clock(24hour) 0 -typelist [list Clients Clock Misc]\
	-vartype boolean\
	-label "24-hour mode"
    TKGDeclare Clock(analog) 0 -typelist [list Clients Clock Misc]\
	-vartype boolean\
	-label "Analog Clock"
    TKGDeclare Clock(show) timeonly -typelist [list Clients Clock Misc]\
	-vartype radio -radioside left  -radiolist\
	{{"Time Only" timeonly} {"Date Only" dateonly} {Both both}}\
	-label "Digital . . ."
    TKGDeclare Clock(border) 0 -typelist [list Clients Clock Misc]\
	-label "Width in pixels of border around clock display"
    TKGDeclare Clock(hourlyevent) "" -typelist [list Clients Clock Misc]\
	-label "Unix command to execute every hour on the hour"

    # DIGITAL STUFF
    TKGDeclare Clock(orientation) {} -typelist [list Clients Clock Geometry]\
	-vartype radio -radiolist {{Horizontal horizontal} {Vertical vertical}}\
	-label "Overall Orientation"\
	-help "Default depends on panel orientation"
    TKGDeclare Clock(aside_horiz) right -typelist [list Clients Clock Geometry]\
	-label "Side of date/time taken by analog clock if horizontal." \
	-vartype optionMenu -optionlist "left right top bottom"
    TKGDeclare Clock(aside_vert) top  -typelist [list Clients Clock Geometry]\
	-label "Side of date/time taken by analog clock if vertical." \
	-vartype optionMenu -optionlist "left right top bottom"
    TKGDeclare Clock(dside_horiz_analog) top -typelist [list Clients Clock Geometry]\
	-label "Side of time taken by date if horizontal and using the analog clock." \
	-vartype optionMenu -optionlist "left right top bottom"
    TKGDeclare Clock(dside_horiz_noanalog) right -typelist [list Clients Clock Geometry]\
	-label "Side of time taken by date if horizontal and not using the analog clock." \
	-vartype optionMenu -optionlist "left right top bottom"
    TKGDeclare Clock(dside_vert) top -typelist [list Clients Clock Geometry]\
	-label "Side of time taken by date if vertical." \
	-vartype optionMenu -optionlist "left right top bottom"
    TKGDeclare Clock(BigFont) ""\
	-vartype font\
	-typelist [list Clients Clock Fonts]\
	-label "Larger font (leave blank for a default that depends on the tkgoodstuff\
font scale)"
    if [Empty $Clock(BigFont)] {
#	set Clock(BigFont) "Times [lindex {14 18 24} $TKG(fontscale)] bold"
	set Clock(BigFont) tkghuge
    }
    TKGDeclare Clock(SmallFont) ""\
	-vartype font\
	-typelist [list Clients Clock Fonts]\
	-label "Smaller font (leave blank for a default that depends on the tkgoodstuff\
font scale)"\
	-help "Used for the date if showing both date and time."
    if [Empty $Clock(SmallFont)] {
#	set Clock(SmallFont) "Times [lindex {12 14 18} $TKG(fontscale)] bold"
	set Clock(SmallFont) tkgbig
    }
    TKGColorDeclare Clock(foreground) "" [list Clients Clock Misc]\
	"Digital Foreground Color" black
    TKGColorDeclare Clock(background) "" [list Clients Clock Misc]\
	"Background Color" 

    # ALARM STUFF
    TKGDeclare Alarm(nobeep) 0 -typelist [list Clients Clock Alarm]\
	-label "Don't Beep" -vartype boolean
    TKGDeclare Alarm(event) "" -typelist [list Clients Clock Alarm]\
	-label "Unix command to execute when the alarm sounds"
    TKGDeclare Alarm(timefont) {Lucidatypewriter 24 bold} \
	-vartype font\
	-typelist [list Clients Clock Alarm] \
	-label "Large Fixed Font for Time Setting"
    TKGColorDeclare Alarm(Analogflagcolor) {} \
	[list Clients Clock Alarm] \
	"Color of Alarm Flag on Analog Clock" \
	$Clock(foreground)
    TKGDeclare Alarm(flagfont) "" -fallback tkgbigbold\
	-vartype font\
	-typelist [list Clients Clock Alarm]\
	-label "Font for Alarm Flag on Analog Clock"
    TKGColorDeclare Alarm(NoAnalogflagcolor) \#f81440 \
	[list Clients Clock Alarm]\
	"Color to which to Change All-Digital Display to Flag Alarm"

    # ANALOG STUFF
    TKGDeclare Analog(minsize) 50 -typelist [list Clients Clock Analog Misc]\
	-label "Minimum Diameter of Analog Clock"
    TKGDeclare Analog(expand_to_square) 1 -typelist [list Clients Clock Analog Misc]\
	-vartype boolean -label "Expand to Occupy Largest Available Dimension"
    TKGDeclare Analog(autoresize) 1 -typelist [list Clients Clock Analog Misc]\
	-vartype boolean -label "Resize Automatically (can go haywire)"
    TKGColorDeclare Analog(background) {} \
	[list Clients Clock Analog Colors] \
	"Background Color for Analog Clock" \
	 $Clock(background)
    TKGColorDeclare Analog(hubcolor) \#f81440 [list Clients Clock Analog Colors]\
	"Color of Center Hub"
    TKGColorDeclare Analog(facecolor) \#ffffe3 [list Clients Clock Analog Colors]\
	"Color of Clock Face"
    TKGColorDeclare Analog(minutecolor) \#000000 [list Clients Clock Analog Colors]\
	"Color of Minute Hand"
    TKGColorDeclare Analog(hourcolor) \#000000 [list Clients Clock Analog Colors]\
	"Color of Hour Hand"
    TKGDeclare Analog(bezel) 1 -typelist [list Clients Clock Analog Misc]\
	-vartype boolean -label "Draw a Bezel (a ring)"
    TKGColorDeclare Analog(bezelcolor) \#f81440 [list Clients Clock Analog Colors]\
	"Color of Bezel"
    TKGColorDeclare Analog(tickcolor) \#f81440 [list Clients Clock Analog Colors]\
	"Color of Small Tick Marks"
    TKGColorDeclare Analog(bigtickcolor) \#000000 [list Clients Clock Analog Colors]\
	"Color of Big Tick Marks"
} 

########
# General Clock stuff
########

proc ClockUpdate args {
    global Clock Clock_window Alarm

    set timedate [clock format [clock seconds] -format "%H %M %M %S %h %d"]
    scan $timedate {%s %s %s %s %s %s} Clock(hour) Clock(minute) prettyminute seconds month day
    foreach v { Clock(hour) Clock(minute) seconds day } {
	set $v [TKGZeroTrim [set $v]]
    }
    set Clock(offset) [ expr  60 - $seconds ]
    TKGPeriodic Clock_periodic 60 $Clock(offset) ClockUpdate

    if $Clock(24hour) {
	set Clock(modhour) $Clock(hour)
	set Clock(prettyhour) $Clock(hour)
	set Clock(prettytime) "$Clock(prettyhour):$prettyminute"
	if { $Alarm(enablealarms) && \
		($Clock(modhour) == $Alarm(hour)) && \
		"$Clock(minute)" == "$Alarm(minute)" } {
	    AlarmAlarm
	}
    } else {
	set Clock(modhour) [expr $Clock(hour) % 12]
	set Clock(prettyhour) [expr (($Clock(modhour) == 0) ? 12: $Clock(modhour))]
	if {$Clock(hour) > 11} {
	    set Clock(ampm) pm
	} else {
	    set Clock(ampm) am
	}
	set Clock(prettytime) "$Clock(prettyhour):$prettyminute"
	if { $Alarm(enablealarms) && \
		"$Clock(ampm)" == "$Alarm(ampm)" && \
		($Clock(modhour) == ($Alarm(hour) % 12)) && \
		"$Clock(minute)" == "$Alarm(minute)" } {
	    AlarmAlarm
	}
    }
    set Clock(prettydate) "$month $day"
        
    if { [winfo exists $Clock_window.analog]} {
	AnalogUpdate
    }     
    if {![Empty $Clock(hourlyevent)] && ($Clock(minute) == 0)} {
	eval exec $Clock(hourlyevent) &
    }
    # a hook for clients to run a process every minute
    TKGDoHook Clock_minute_hook
}

proc Clock_timedatetoggle {} {
    global Clock Clock_window

    set w $Clock_window.datetime
    if { $Clock(show) != "dateonly" } {
        if $Clock(togglestate) {
	   $w.time.msg config -textvariable Clock(prettydate)\
	       -font $Clock(SmallFont)
	} else {
           $w.time.msg config -textvariable Clock(prettytime)\
	       -font $Clock(BigFont)
	}
    }
    if { $Clock(show) != "timeonly"} {
        if $Clock(togglestate) {
	   $w.date.msg config -textvariable Clock(prettytime)
	} else {
           $w.date.msg config -textvariable Clock(prettydate)
	}
    }
    set Clock(togglestate) [expr 1 - $Clock(togglestate)]
    update idletasks
}

proc Clock_configure_window args {
    global Clock Clock_window Clients Alarm Analog TKG

    catch { destroy $Clock_window.datetime }
    catch { destroy $Clock_window.analog }
    
    set orientation $Clock(orientation)
    if [Empty $orientation] {
	if [In $TKG(screenedge) {left right}] {
	    set orientation vertical
	} elseif [In $TKG(screenedge) {top bottom}] {
	    set orientation horizontal
	} else {
	    set orientation $TKG(orientation)
	}
    }
    if {$orientation == "horizontal"} {
	set aside $Clock(aside_horiz)
	if $Clock(analog) {
	    set dside $Clock(dside_horiz_analog)
	} else {
	    set dside $Clock(dside_horiz_noanalog)
	}
    } else {
	set aside $Clock(aside_vert)
	set dside $Clock(dside_vert)
    }   
    # analog aside arow acolumn drow dcolumn c0 c1 r0 r1
    set configlist [ list \
			 { 1 left   0 0  0 1  1 1  1 0 } \
			 { 1 right  0 1  0 0  1 1  1 0 } \
			 { 1 top    0 0  1 0  1 0  1 1 } \
			 { 1 bottom 1 0  0 0  1 0  1 1 } \
			 { 0 left   0 0  0 0  1 0  1 0 } \
			 { 0 right  0 0  0 0  1 0  1 0 } \
			 { 0 top    0 0  0 0  1 0  1 0 } \
			 { 0 bottom 0 0  0 0  1 0  1 0 } ]
    foreach l $configlist {
	if {($Clock(analog) == [lindex $l 0]) && ($aside == [lindex $l 1])} {
	    scan [join [lrange $l 2 5]] "%d %d %d %d" arow acolumn drow dcolumn
	    set w $Clock_window
	    grid columnconfigure $w 0 -weight [lindex $l 6]
	    grid columnconfigure $w 1 -weight [lindex $l 7]
	    grid rowconfigure $w 0 -weight [lindex $l 8]
	    grid rowconfigure $w 1 -weight [lindex $l 9]
	    break
	}
    }
    if { $Clock(analog) } {
	setifunset Analog(width) $Analog(minsize)
	setifunset Analog(height) $Analog(minsize)
	canvas $Clock_window.analog \
	    -width $Analog(width) -height $Analog(height) \
	    -background $Analog(background) \
	    -highlightthickness 0 -borderwidth 0
	grid $Clock_window.analog -sticky nsew -row $arow -column $acolumn
	grid propagate $Clock_window.analog 0
	AnalogResize
	if $Analog(autoresize) {
	    bind $Clock_window.analog <Configure> [subst {
#		bind $Clock_window.analog <Configure> {}
		set Analog(width) %w
		set Analog(height) %h
		AnalogResize
		ClockUpdate
	    }]
	}
 #	if $Analog(autoresize) {
 #	    TKGAddToHook TKG_expose_hook [subst {
 #		set Analog(width) %w
 #		set Analog(height) %h
 #		AnalogResize
 #		ClockUpdate
 #	    }]
 #	}
	set Clock(currentfg) $Clock(foreground)
    } else {
	if $Alarm(enablealarms) {
	    set Clock(currentfg) $Alarm(NoAnalogflagcolor) 
	}
    }

    if { $Clock(show) != "neither"} {
	set dw $Clock_window.datetime
	grid [frame $dw -borderwidth 0 -highlightthickness 0]\
	    -row $drow -column $dcolumn -sticky nsew
	# dside daterow datecolum timerow timecolumn c0 c1 r0 r1
	set configlist [list \
			    { left   0 0 0 1 1 1 1 0 }\
			    { right  0 1 0 0 1 1 1 0 }\
			    { top    0 0 1 0 1 0 1 1 }\
			    { bottom 1 0 0 0 1 0 1 1 } ]
	foreach l $configlist {
	    if {$dside == [lindex $l 0]} {
		scan [join [lrange $l 1 4]] "%d %d %d %d" \
		    daterow datecolum timerow timecolumn
		grid columnconfigure $dw 0 -weight [lindex $l 5]
		grid columnconfigure $dw 1 -weight [lindex $l 6]
		grid rowconfigure $dw 0 -weight [lindex $l 7]
		grid rowconfigure $dw 1 -weight [lindex $l 8]
		break
	    }
	}

	switch $dside {
	    left { 
		set daterow 0; set datecolumn 0; set timerow 0; set timecolumn 1
		grid rowconfigure $dw 0 -weight 1
		grid rowconfigure $dw 1 -weight 0
	    } right {
		set daterow 0; set datecolumn 1; set timerow 0; set timecolumn 0
		grid rowconfigure $dw 0 -weight 1
		grid rowconfigure $dw 1 -weight 0
	    } top { 
		set daterow 0; set datecolumn 0; set timerow 1; set timecolumn 0
		grid columnconfigure $dw 0 -weight 1
		grid columnconfigure $dw 1 -weight 0
	    } bottom {
		set daterow 1; set datecolumn 0; set timerow 0; set timecolumn 0
		grid columnconfigure $dw 0 -weight 1
		grid columnconfigure $dw 1 -weight 0
	    }
	}

	if {$Clock(show) != "timeonly" } {
	    frame $dw.date -borderwidth 0 -highlightthickness 0
	    TKGRowCol $dw.date
	    label $dw.date.msg \
		-font $Clock(SmallFont) -text "XXX XX"\
		 -pady 0 -borderwidth 0 -highlightthickness 0
	    update idletasks
	    grid $dw.date.msg -sticky nsew
	    update idletasks
	    grid propagate $dw.date 0
	    $dw.date.msg configure \
		-textvariable Clock(prettydate) 
	    grid $dw.date -sticky nsew  -row $daterow -column $datecolumn
	}
	if {$Clock(show) == "dateonly"} {
	    if { $Clock(analog) == 0 } {
		grid propagate $dw.date 1
		$dw.date.msg configure\
		    -font $Clock(BigFont) -text "XXX XX"
		update idletasks
		grid propagate $dw.date 0
		$dw.date.msg configure \
		    -textvariable Clock(prettydate) 
	    }
	} else {
	    frame $dw.time -borderwidth 0 -highlightthickness 0
	    TKGRowCol $dw.time
	    label $dw.time.msg\
		-font $Clock(BigFont) \
		-text "88:88"\
		 -pady 0 -borderwidth 0 -highlightthickness 0
	    grid $dw.time.msg -sticky nsew
	    update idletasks
	    grid propagate $dw.time 0
	    $dw.time.msg configure \
		-textvariable Clock(prettytime) 
	    grid $dw.time -sticky nsew  -row $timerow -column $timecolumn
	}
	ColorConfig $dw $Clock(currentfg)  $Clock(background)
    }
    ClockBind
    ClockUpdate
}    

proc ClockBind {} {
    global Clock_window Clock
    RecursiveBind $Clock_window <1> {Clock_MenuPost %X %Y}
    if [In $Clock(show) {timeonly dateonly}] {
	bind $Clock_window <Enter> +ClockEnter
    }
}

proc Clock_MenuPost {x y} {
    global Clock Clock_window
    regexp {^(\.[^\.]*)} $Clock_window panel panel
    TKGPopupPost $Clock(menu) $x $y $panel
    focus $Clock(menu)
    grab set -global $Clock(menu)
    bind $Clock(menu) <ButtonRelease-1> [subst -nocommands {
        if [string match ${Clock_window}* \
		[eval winfo containing [winfo pointerxy .]]] {
            break
	}
    }]        
}


proc ClockEnter {} {
    global Clock
    if !$Clock(entered) {
	after 800 ClockReToggle
	set Clock(entered) 1
    }
}

proc ClockReToggle {} {
    global Clock_window Clock
    set stillin [string match ${Clock_window}* \
	    [eval winfo containing [winfo pointerxy .]]]
    if $stillin {
	if $Clock(togglestate) {
	    Clock_timedatetoggle
	    set Clock(togglestate) 0
	    after 800 ClockReToggle
	} else {
	    after 800 ClockReToggle
	}
    } elseif !$Clock(togglestate) {
	after 250 {
	    Clock_timedatetoggle
	    set Clock(togglestate) 1
	    set Clock(entered) 0
	}
    } else {
	set Clock(entered) 0
    }
}    

proc ClockInit {} {uplevel \#0 {	
    TKGClientStrings Clock
    TKGPopupAdd command -label $TKG_labels(Alarm) -command AlarmView
    TKGPopupAdd separator
    set Clock_minute_hook ""
}}


proc ClockCreateWindow {} {
    global Clock Clock_window TKG TKG_labels Clock_strings Alarm

    # initialize various stuff
    set Clock(togglestate) 1
    set Clock(entered) 0
    set Clock(offset) 0
    set Alarm(enablealarms) 0
    set Clock(currentfg) $Clock(foreground)
    setifunset Clock(menu) .tkgpopup

    TKGLabelBox Clock
    $Clock_window configure -borderwidth $Clock(border)
    TKGGrid $Clock_window

    TKGBalloonBind $Clock_window "Click for menu"

    ClockUpdate
    Clock_configure_window
}

proc ClockStart {} {
    global Clock
    # set up async processing
    set Clock(offset) [expr 60 - [TKGZeroTrim [clock format [clock seconds] -format %S]]]
    TKGPeriodic Clock_periodic 60 $Clock(offset) ClockUpdate
}

proc ClockSuspend {} {
    global Clock_window TKG
    TKGPeriodicCancel Clock_periodic
    destroy $Clock_window
    unset TKG(balloontext,$Clock_window)
}

DEBUG "Loaded Clock.tcl"

 
