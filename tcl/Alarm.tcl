#######
# Alarm stuff
#######
proc AlarmView {} {
    global Alarm Clock Alarm_strings

    setifunset Alarm(hour) $Clock(modhour)
    if {$Alarm(hour) == 0 && !$Clock(24hour)} {set Alarm(hour) 12}
    setifunset Alarm(minute) $Clock(minute)
    if {!$Clock(24hour)} {
	setifunset Alarm(ampm) $Clock(ampm)
    }

    TKGDialog alarm_view \
	-wmtitle $Alarm_strings(settitle) \
	-title $Alarm_strings(isset) \
	-nodeiconify \
	-nodismiss \
	-buttons [ list \
		   [ list enable $Alarm_strings(enable) { 
		       set Alarm(enablealarms) 1
		       DEBUG "Enabling Alarm"
		       AlarmSet
		       destroy .alarm_view 
		   } 
		     ] \
		   [ list disable $Alarm_strings(disable) {
		       set Alarm(enablealarms) 0
		       DEBUG "Disabling Alarm"
		       AlarmSet
		       destroy .alarm_view 
		   }
		   ] 
		  ]
    
    frame .alarm_view.top -borderwidth 0 -highlightthickness 0
    grid .alarm_view.top -row 1 -column 0 -sticky ew -pady 10
    label .alarm_view.top.time -textvariable Alarm(timedisplay) \
	-font $Alarm(timefont) -relief sunken\
	 -pady 0 -borderwidth 0 -highlightthickness 0
    grid .alarm_view.top.time -row 0 -column 0 -padx 40

    frame .alarm_view.hour -borderwidth 0 -highlightthickness 0
    grid  .alarm_view.hour -row 2 -sticky nsw
    label .alarm_view.hour.hourlabel -text $Alarm_strings(hour)\
	 -pady 0 -borderwidth 0 -highlightthickness 0
    grid  .alarm_view.hour.hourlabel -row 0 -column 0 -padx 10
    if {!$Clock(24hour)} {
	tk_optionMenu .alarm_view.hour.hourbutton Alarm(hour) 12 1 2 3 4 5 6 7 8 9 10 11
	grid .alarm_view.hour.hourbutton  -row 0 -column 1
	tk_optionMenu .alarm_view.hour.ampmbutton Alarm(ampm) am pm
	grid .alarm_view.hour.ampmbutton  -row 0 -column 2
	trace variable Alarm(ampm) w AlarmUpdateDisplay
    } else {
	scale .alarm_view.hour.hourscale -orient horizontal -length 394 -from 0 -to 23 \
	    -tickinterval 10 -variable Alarm(hour) -command "AlarmUpdateDisplay"
	grid .alarm_view.hour.hourscale -row 0 -column 1 -sticky new
    }
    trace variable Alarm(hour) w AlarmUpdateDisplay
    frame .alarm_view.minute
    grid  .alarm_view.minute -row 3 -column 0 -sticky news -padx 10
    label .alarm_view.minute.minutelabel -text $Alarm_strings(minute)
    grid  .alarm_view.minute.minutelabel -row 0 -column 0
    scale .alarm_view.minute.minutescale -orient horizontal -length 394 -from 0 -to 59 \
	-tickinterval 10 -variable Alarm(minute) -command "AlarmUpdateDisplay"
    grid .alarm_view.minute.minutescale -row 0 -column 1 -sticky new

    frame .alarm_view.msgfrm
    grid columnconfigure .alarm_view.msgfrm 1 -weight 1
    grid .alarm_view.msgfrm -row 4 -column 0 -sticky new -padx 10 -pady 20
    label .alarm_view.msgfrm.lbl -text $Alarm_strings(message)
    grid .alarm_view.msgfrm.lbl -row 0 -column 0
    entry .alarm_view.msgfrm.entry -textvariable Alarm(message) \
	-background \#87ceff
    grid .alarm_view.msgfrm.entry -row 0 -column 1 -sticky nsew
    TKGCenter .alarm_view
}

proc AlarmUpdateDisplay args {
    global Alarm Clock
    if {!$Clock(24hour)} {
	set Alarm(timedisplay) "[format %2i $Alarm(hour)]:[format %02i $Alarm(minute)] $Alarm(ampm)"
    } else {
	set Alarm(timedisplay) "[format %2i $Alarm(hour)]:[format %02i $Alarm(minute)]"
    }
    set Alarm(minute) [TKGZeroTrim $Alarm(minute)]
}

proc AlarmSet {} {
    global Alarm Clock_window Clock
    if !$Alarm(enablealarms) {
	catch { $Clock_window.analog delete alarmflag }
	ColorConfig $Clock_window $Clock(foreground) -
	catch "unset Alarm(minute) Alarm(hour) Alarm(ampm)"
	return
    }
    if [winfo exists $Clock_window.analog] {
	 $Clock_window.analog create text 0 0 -text A -anchor nw\
	     -fill $Alarm(Analogflagcolor) -font $Alarm(flagfont) -tags alarmflag
    } else {
	ColorConfig $Clock_window $Alarm(NoAnalogflagcolor) -
	set Clock(currentfg) $Alarm(NoAnalogflagcolor)
    }
}

proc AlarmAlarm {} {
    global TKG Clock Alarm TKG Alarm_strings

    TKGDialog alarm_alarm \
	-image warning \
        -wmtitle "$Alarm_strings(title) $Clock(prettytime)" \
        -title "$Alarm_strings(title) $Clock(prettytime)" \
        -message $Alarm(message)
    ColorConfig .alarm_alarm.title \#000000 \#f81440
    if {!$Alarm(nobeep)} {TKGBell 1.2 1.3 10}
    if ![Empty $Alarm(event)] {eval exec $Alarm(event) &}
    catch { $Clock_window.analog delete alarmflag }
    set Alarm(enablealarms) 0
    AlarmSet
}
