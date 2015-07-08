#!/bin/sh
# \
exec wish8.0 "$0" ${1+"$@"}

# Dialer; for establishing connection and authorization for 
# ppp or term link.

# Version 8.0
# (numbered so as to coincide with the required version of tk)

# Assumes your modem takes AT... commands.
# Works for linux and several other platforms.  Your mileage may
# suck.

# M. Crimmins 1/27/97

if {([set tk_version] < 4.1)} {
   bgerror "This program requires tk version 4.1 or higher."
   exit
}

set file ""
if {$argv != ""} {
    set file [lindex $argv 0]
    set argv [lreplace $argv 0 0]
}
set debug 0
set send_slow {1 .1}
set quickwait 5
set labelwidth 20
set entrywidth 50

set stringvars { numbers repeatscript port speed init1 init2\
		     loginscript outcommand }
set booleans {login exitsucc repeat}

# Give the first-time user an example
set numbers "555-1000 555-2000"
set repeatscript { * {{ 555-1000 1} {555-2000 1} {555-1000 3}}}
set repeat 0
set port /dev/modem
set speed 38400
set init1 "ATZ"
set init2 ""
set login 1
set loginscript {
    {"" "host: " 10} 
    {ppp "login: " 20}
    { myloginname@umich.edu "Password: " 5}
    {mypassword "" "" }
}
set outcommand "/usr/lib/ppp/pppd $port $speed asyncmap 0 defaultroute crtscts modem noipdefault"
set exitsucc 0

option add *Listbox*font {Helvetica 14} startupFile
option add *Entry*font   {Helvetica 14} startupFile
option add *Label*font   {Helvetica 14} startupFile
option add *Text*font    {Helvetica 14} startupFile

proc DialWindow {} {
    global normalbg
    wm title . "Dialer"
    wm withdraw .
    wm iconname . "Dialer"

    bind . <Key-Escape> exit
    frame .status
    pack .status -side left -pady 20 -padx 10
    label .status.statuslabel -text "Dialing Status:" 
    pack .status.statuslabel -side top -pady 5
    text .status.text -height 12 -width 40 -takefocus 0
    set normalbg [.status.text cget -background]
    global statuswindow
    set statuswindow .status.text
    pack .status.text -side top -fill x -fill y -padx 15
    
    frame .buttons
    button .buttons.dial -text Dial -command Dial
    button .buttons.settings -text Settings -command EditSettings
    button .buttons.next -text "Try Next\nNumber"  -command {Next} -state disabled
    button .buttons.abort -text Abort -command {Abort} -state disabled
    button .buttons.dismiss -text Dismiss -command {exit}
    pack .buttons.dial .buttons.settings .buttons.next .buttons.abort .buttons.dismiss \
	-side top -expand y -fill x -padx 15 -pady 5
    pack .buttons -side left -fill x -expand y

    .status.statuslabel configure -font [.buttons.dial cget -font]
    
    focus .buttons.dial
    update
    set x [expr ([winfo screenwidth .] - [winfo reqwidth .] )/2]
    set y [expr ([winfo screenheight .] - [winfo reqheight .] )/2]
    wm geometry . +$x+$y
    wm deiconify .
}

proc Next {} {
    global numaborted
    set numaborted 1
}

proc Abort {} {
    global aborted
    set aborted 1
}

proc DoAbort {} {
    global normalbg
    Hangup
    Outstatus "Aborted"
    ResetButtons
    .status.text config -background $normalbg
}

proc Hangup {} {
    global id port
    Outmodem ""
    after 1250
    Outmodem + 0
    after 100
    Outmodem + 0
    after 100
    Outmodem + 0
    if [Dialexpect {} OK {} 3 ] {
	Dialexpect ATH OK {} 3
	after 500
    }
    exec stty sane < $port > $port
    exec stty 38400 raw -echo clocal < $port > $port
    return 1
}

proc CloseLine {} {
    global id
    if [info exists id] {
	close -i $id
	catch "unset id"
    }
}

proc CheckBoth {} {
    global aborted numaborted
    expr $aborted || $numaborted
}

proc Dial {{repeating 0}} {
    global statuswindow id nums loops
    global tkgsentok aborted numaborted
    global stringvars booleans
    foreach v [eval list $stringvars $booleans] {
	global $v
    }
    if !$repeating {
	.buttons.dial config -state disabled
	.buttons.dismiss config -state disabled
	.buttons.abort config -state normal
	.buttons.next config -state normal
	.status.text config -background yellow
	focus .buttons.next
	set aborted 0
	if !$repeat {
	    set nums $numbers
	    set loops 1
	} else {
	    set nums ""
	    foreach pair [lindex $repeatscript 1] {
		for {set i 0} {$i < [lindex $pair 1]} {incr i} {
		    lappend nums [lindex $pair 0]
		}
	    }
	    set loops [lindex $repeatscript 0]
	}
	if ![OpenModem] {return 0}
    } 
    for {set i 0} {$i < [llength $nums]} {incr i} {
	set number [lindex $nums $i]
	if {($i == ([llength $nums] - 1)) && \
		 ($loops != "*") && ($loops < 2 )} {
	    .buttons.next config -state disabled
	}
	set numaborted 0
	if ![ModemInit] {
	    Hangup
	    ResetButtons
	    set loops 1
	    break
	}
	if { ![DialNumber $number] || ![LoginScript] } { 
	    if $aborted {DoAbort; return}
	    continue
	}
	OutCommand
	ExitSucc
	ResetButtons
	focus .buttons.dismiss
	return 1
    }
    catch "incr loops -1"
    if {($loops == "*") || ($loops > 0)} {
	Dial 1
	return
    }
    .status.text config -background red
    Outstatus "Sorry, failed to connect."
    ResetButtons
    return 0
}

proc OpenModem {} {
    global port id 
    if [catch {set id [open $port w+]}] {
	Dialerror "Error opening modem port."
	.status.text config -background red
	Outstatus "Aborted"
	ResetButtons
	return 0
    }
    fconfigure $id -blocking 0 -buffering none
    exec stty 38400 raw -echo clocal < $port > $port
    return 1
}
	
proc ModemInit {} {
    global init1 init2
    #initialize modem
    if { $init1 != "" } {
	if ![Dialexpect "$init1" "OK\n" "Error initializing modem."] {
	    set loops 1 
	    return 0
	}
	if { $init2 != "" } {
	    if ![Dialexpect "$init2" "OK\n" "Error initializing modem."] {
		set loops 1 
		return 0
	    }
	}
    }
    return 1
}

proc DialNumber {number} {
    global Dialer_expect_out
    Outstatus "Dialing $number . . ."
    set fail 0
    if [Dialexpect ATDT$number \
	    { "OK" "BUSY" "NO DIAL TONE" "NO CARRIER" "NO ANSWER" "CONNECT .*\[\r\n\]" } \
	    {} 45 ] {
	switch -regexp -- $Dialer_expect_out {
	    "OK"  { Outstatus "  Unknown failure (\"OK\"!)."; set fail 1}
	    "BUSY" { Outstatus "  Line is busy."; set fail 1}
	    "NO CARRIER" { 
		Outstatus "  No carrier (no answer or phone line not connected)."
		set fail 1
	    } "NO DIAL TONE" { 
		Outstatus "  No dial tone (no busy signal or ringing detected)."
		set fail 1
	    } "NO ANSWER" { Outstatus "  No answer." ; set fail 1} 
	    "CONNECT .*\[\r\n\]" {Outstatus $Dialer_expect_out}
	}
	if $fail {
	    after 1000
	    return 0
	}
    } else {
	Hangup
	return 0
    }
    return 1
}

proc LoginScript {} {
    global loginscript login
    .status.text config -background yellowgreen
    if !$login {return 1}
    Outstatus "Running login script. . ."
    foreach entry $loginscript {
	if ![Dialexpect [lindex $entry 0] \
		 [lindex $entry 1] \
		 "In login script, never got \"[lindex $entry 1]\"" \
		 [lindex $entry 2] ] {
		     Hangup
		     return 0
		 }
    }
    Outstatus "Login script succeeded."
    .status.text config -background chartreuse1
    return 1
}

proc OutCommand {} {
    global outcommand
    if {$outcommand != ""} {
	Outstatus "Setting up the network:"
	Outstatus "  ([string range $outcommand 0 30] . . .)"
	eval exec $outcommand &
    }
}

proc ExitSucc {} {
    global exitsucc
    if !$exitsucc return
    if {[lsearch [winfo interps] tkgoodstuff] != -1} {
	if {[send tkgoodstuff {lsearch $TKG(clients) Net}] != -1} {
	    send tkgoodstuff Net_start_wait
	    send tkgoodstuff {DEBUG {Dialer suggests we look for net-up}}
	}
    }
    bell; after 250 { bell; after 5000 exit }
}

proc ResetButtons {} {
    .buttons.dial config -state normal
    .buttons.dismiss config -state normal
    .buttons.next config -state normal
    .buttons.abort config -state disabled
    .buttons.next config -state disabled
    focus .buttons.dial
}

proc Dialexpect "outstring instrings {error none} \"wait $quickwait\"" {
    global statuswindow global quickwait id aborted numaborted Dialer_expect_out
    set Dialer_expect_out ""
    if ![info exists id] { bgerror "no channel with id $id"}
    if [CheckBoth] {return 0}
    if { [regexp " *(&PAUSE|&pause) *(.*)$" $outstring l v pause] && ($pause != -1)} {
	if { [scan $pause "%f" pause1] && [info exists pause1]} {
	    after [format %.0f [expr $pause1 * 1000]]
	}
    } elseif [regexp " *(&RETURN|&return) *$" $outstring l l] {
	DEBUG "Sending return character. . ."
	Outmodem ""
    } elseif {$outstring != ""} {
	DEBUG "Sending \"$outstring\". . ."
	Outmodem "$outstring"
    }
    if {$instrings == ""} {return 1}
    DEBUG "Waiting $wait seconds for \"$instrings\""
    set timeout 1000
    for {set i 0} {$i < $wait} {incr i} {
	if [CheckBoth] {return 0}
	if ![info exists id] { bgerror "no \$id"}
	if [DialerExpect $id $instrings $timeout] {
	    return 1
	}
    }
    DEBUG "Never got $instrings."
    if [CheckBoth] {return 0}
    if {$error != "none"} {Dialerror $error}
    return 0
}

proc DialerExpect {id strings timeout} {
    after $timeout DialerCancelExpect
    fileevent $id readable [list DialerRead $strings $id]
    global Dialer_cancelexpect
    vwait Dialer_cancelexpect
    fileevent $id readable {}
    global Dialer_expect_out Dialer_expect_in
    set Dialer_expect_in ""
    set result [expr ![string match "" $Dialer_expect_out]]
    return $result
}

proc DialerRead {strings id} {
    global Dialer_expect_in Dialer_expect_out
    append Dialer_expect_in [read $id]
    foreach string $strings {
	if [regexp $string $Dialer_expect_in Dialer_expect_out] {
	    DialerCancelExpect
	}
    }    
}

proc DialerCancelExpect {} {
     global Dialer_cancelexpect
     set Dialer_cancelexpect 0
}
     

proc Outmodem {string {return 1}} {
    global id 
    switch $return {
	1 {eval puts -nonewline $id \"$string\\r\"}
	0 {eval puts -nonewline $id \"$string\"}
    }
}

proc Outstatus {string} {
    global statuswindow
    $statuswindow insert end "$string\n"
    $statuswindow see end
    update
}

proc DEBUG {string} {
    global debug
    switch $debug {
	0 return
	1 "Outstatus $string"
	2 "puts $string"
    }
}

proc Dialerror {error {die 0}} {
    global statuswindow id
    Outstatus "$error"
    if $die { 
	if [info exists id] { close -i $id }
	bgerror "$error" 
	exit
    }
}

proc EditSettings {} {
    global labelwidth file
    set w .editsettings
    catch {destroy $w}
    toplevel $w
    bind $w <Key-Escape> "destroy $w"
    wm title $w "Dialer Settings"
    wm iconname $w "Dialer Settings"

    trace variable file w UpdateFileDisplay 

    frame $w.menu -relief raised -bd 2
    pack $w.menu -side top -fill x
    
    set m $w.menu.file.m
    menubutton $w.menu.file -text "File" -menu $m -underline 0
    menu $m
    $m add command -label "Open settings file" -command Open
    $m add command -label "New settings file" -command New
    $m add command -label "Save settings" -command Save
    $m add command -label "Save settings As ..." -command SaveAs
    
    pack $w.menu.file -side left

    set m $w.menu.help.m
    menubutton $w.menu.help -text "Help" -menu $m -underline 0
    menu $m
    $m add command -label "About Dialer" -command About
    $m add separator
    $m add command -label "Dialer Help" -command HelpSettings

    pack $w.menu.help -side right

    button .b
    set bfont [.b cget -font]
    destroy .b
    frame $w.curfile
    label $w.curfile.label -font $bfont
    UpdateFileDisplay
    pack $w.curfile.label -side left
    label $w.curfile.file -textvariable file -font $bfont
    pack $w.curfile.file -side left
    pack $w.curfile -expand y -pady 10

    global labelwidth entrywidth
    frame $w.numbers
    radiobutton $w.numbers.check -variable repeat -value 0
    pack $w.numbers.check -side left -padx 10
    label $w.numbers.numberslabel -text "Dial these numbers:" -width $labelwidth -anchor c
    pack $w.numbers.numberslabel -side left
    entry $w.numbers.numbersentry -textvariable numbers -width $entrywidth
    pack $w.numbers.numbersentry -side left -fill x -expand y

    frame $w.repeat
    radiobutton $w.repeat.check -variable repeat -value 1
    pack $w.repeat.check -side left -padx 10
    label $w.repeat.label1 -text "Dial from repeat script"
    pack $w.repeat.label1 -side left

    AddEntry $w port Port:
    AddEntry $w speed Speed:
    AddEntry $w init1 "Modem\ninit string"
    AddEntry $w init2 "Second modem\ninit string"
    AddEntry $w outcommand "Command to execute\nwhen logged in:"

    frame $w.login
    checkbutton $w.login.check -variable login
    pack $w.login.check -side left -padx 10
    label $w.login.label1 -text "Run login script when connected"
    pack $w.login.label1 -side left
    
    frame $w.exitsucc
    checkbutton $w.exitsucc.check -variable exitsucc
    pack $w.exitsucc.check -side left -padx 10
    label $w.exitsucc.label1 -text "Exit on successful connection"
    pack $w.exitsucc.label1 -side left
    
    pack $w.numbers $w.repeat $w.port $w.speed $w.init1 $w.init2 $w.outcommand $w.login $w.exitsucc\
	-fill x -pady 5

    frame $w.buttons
    button $w.buttons.ers -command EditRepeatScript -text "Edit\nRepeat Script"
    pack $w.buttons.ers -side left -expand y -fill y -padx 15 -pady 15
    button $w.buttons.els -command EditLoginScript -text "Edit\nLogin Script"
    pack $w.buttons.els -side left -expand y -fill y -padx 15 -pady 15
    button $w.buttons.dismiss -text Dismiss -command "destroy $w"
    pack $w.buttons.dismiss -side left -expand y -fill y -padx 15 -pady 15
    pack $w.buttons -fill x -expand y
}

proc UpdateFileDisplay args {
    global file
    if {$file == ""} {
	.editsettings.curfile.label config -text "(No current file)"
    } else {
	.editsettings.curfile.label config -text "File:  "
    }
}

proc AddEntry { w v s } {
    global labelwidth entrywidth
    frame $w.$v
    label $w.$v.[set v]label -text $s -width $labelwidth -anchor c
    pack $w.$v.[set v]label -side left
    entry $w.$v.[set v]entry -textvariable $v -width $entrywidth
    pack $w.$v.[set v]entry -side left -fill x -expand y
}

proc EditRepeatScript {} {
    global labelwidth repeatscript rscript file repeat
    set entrywidth 25

    set w .editrepeatscript 
    catch {destroy $w}
    toplevel $w
    bind $w <Key-Escape> "UpdateRepeatScript; destroy $w"
    wm title $w "Dialer Repeat Script"
    wm iconname $w "Dialer Repeat Script"

    frame $w.title -relief raised
    pack $w.title -fill x -expand y
    label $w.title.0 -text "Numer:"
    pack $w.title.0 -pady 10 -fill x -expand y -side left
    label $w.title.1 -text "Repeat ___ times:"
    pack $w.title.1 -pady 10 -fill x -expand y -side left
    frame $w.entries
    pack $w.entries
    frame $w.entries.0
    frame $w.entries.1
    pack $w.entries.0 $w.entries.1 -side left -fill x
    foreach s {0 1} {
	for {set i 0} {$i<16} {incr i} {
	    set rscript($i,$s) [lindex [lindex [lindex $repeatscript 1] $i] $s]
	    entry $w.entries.$s.entry$i -width $entrywidth \
		-textvariable rscript($i,$s)
	    pack $w.entries.$s.entry$i -padx 5 -pady 3 -fill x
	}
    }
    frame $w.grep
    label $w.grep.greplabel -text "Repeat entire script ___ times:\n(\"*\" means forever)" -anchor c
    pack $w.grep.greplabel -side left
    entry $w.grep.grepentry -textvariable loops -width 4
    pack $w.grep.grepentry -side left
    pack $w.grep -fill x -pady 10
    frame $w.buttons
    button $w.buttons.dismiss -text Dismiss -command "UpdateRepeatScript; destroy $w"
    pack $w.buttons.dismiss -side left -expand y -fill y -padx 15 -pady 15
    pack $w.buttons -side bottom -fill x -expand y
}

proc UpdateRepeatScript {} {
    global rscript repeatscript loops
    set repeatscript ""
    set i 0
    set s ""
    while {($rscript($i,0) != "") || \
	       ($rscript($i,1) != "")} {
	lappend s [list $rscript($i,0) $rscript($i,1) ]
	incr i
    }
    set repeatscript [list $loops $s]
}

proc EditLoginScript {} {
    global labelwidth loginscript script file
    set entrywidth 25

    set w .editloginscript 
    catch {destroy $w}
    toplevel $w
    bind $w <Key-Escape> "UpdateScript; destroy $w"
    wm title $w "Dialer Login Script"
    wm iconname $w "Dialer Login Script"

    frame $w.title -relief raised
    pack $w.title -fill x -expand y
    label $w.title.0 -text "Send:"
    pack $w.title.0 -pady 10 -fill x -expand y -side left
    label $w.title.1 -text "Then Expect:"
    pack $w.title.1 -pady 10 -fill x -expand y -side left
    label $w.title.2 -text "After ___ seconds:"
    pack $w.title.2 -pady 10 -fill x -expand y -side left
    frame $w.entries
    pack $w.entries
    frame $w.entries.0
    frame $w.entries.1
    frame $w.entries.2
    pack $w.entries.0 $w.entries.1 $w.entries.2 -side left -fill x
    foreach s {0 1 2} {
	for {set i 0} {$i<16} {incr i} {
	    set script($i,$s) [lindex [lindex $loginscript $i] $s]
	    entry $w.entries.$s.entry$i -width $entrywidth \
		-textvariable script($i,$s)
	    pack $w.entries.$s.entry$i -padx 5 -pady 3 -fill x
	}
    }
    frame $w.buttons
    button $w.buttons.dismiss -text Dismiss -command "UpdateScript; destroy $w"
    pack $w.buttons.dismiss -side left -expand y -fill y -padx 15 -pady 15
    pack $w.buttons -side bottom -fill x -expand y
}

proc UpdateScript {} {
    global script loginscript
    set loginscript ""
    set i 0
    while {($script($i,0) != "") || \
	       ($script($i,1) != "") || \
	       ($script($i,2) != "")} {
	lappend loginscript [list $script($i,0) $script($i,1) $script($i,2) ]
	incr i
    }
}

proc HelpSettings {} {

    set text "
This Dialer assumes you have a basically Hayes-compatible modem (like\
nearly all modems sold these days).

All settings, including a login script, are saved in a settings file.\
In the Settings window, you can open and save settings files.  You can\
also select a settings file from the command line as follows:
\ \ \ \"Dialer mysettingsfile\"
If no settings file is given on the command line, Dialer looks for th\
file \".DialSettings\" in your home directory.\
To make the Dialer start dialing on invocation, you add \"Dial\" to the\
command line:
\ \ \ \"Dialer mysettingsfile Dial\"

(The Dialer also can be started automatically by the \"tkgoodstuff\"\
button bar's \"Net\" client.)

There are two dialing strategies to choose between:
  1. Each phone number in the list of phone numbers will be tried in\
succession.  You can use the usual Hayes characters in the dial string\
(consult your modem manual).  NOTE to those who want to type\
\"ATDP555-7777\" here: you should not include the \"ATD\" command, but\
only the phone number.
  2. A repeat script will be followed (which you edit by pressing a\
button in the Settings window).  Each number will be tried a specified\
number of times, and the whole list will be tried a specified number of\
time (or forever).

The \"port\" is a unix device file governing the serial port to which\
your modem is connected, such as /dev/modem or /dev/cua1.  (Linux\
users: remember that /dev/cua0 is COM1, . . ., and /dev/cua3 is\
COM4.)

The speed is the baud rate OF THE PORT, which typically is best set\
higher than the modem's baud rate.  You don't need to set the modem\
baud rate explicitly (though you can do so in one of the init\
strings if necessary).

The modem init strings are \"AT...\" commands to send to the modem (we\
look for an \"OK\" from the modem afterwards).  These are optional, and\
can be anything from \"AT\" to \"ATZ\" to the monstrously long ones modem\
freaks swear by (the author uses \"ATZ4\" with his Sportster v.34).

The entry \"command to execute when logged in\" allows you to start up\
your networking software once you have dialed in and authenticated to\
the server (through the login script, as described below).  Here you\
can start, for instance, ppp or term.  The author, for his dynamic ppp\
connection from home, uses:
\ \ \ \"/usr/lib/ppp/pppd /dev/modem 38400 asyncmap 0 defaultroute crtscts\
modem noipdefault\"

There is a checkbox which enables using the login script (on which more\
below). 

And there is a checkbox which tells the Dialer window to disappear\
once all its tasks are completed sucessfully (including launching the\
networking command, if you have set one).  Note that the Dialer itself\
does not check whether the networking command is successful in setting\
up the networking (for this indication, and for an easy way to use\
the dialer when needed, the author modestly suggests using his\
\"tkgoodstuff\" button bar's \"Net\" button).

To edit the login script associated with the current settings file,\
press the \"Edit Login Script\" button (did you guess that?).  The login\
script is a sequence of \"steps\".  Each step involves (optionally)\
sending a string to the modem (which automatically will be followed by\
a carriage return), and then (optionally) waiting a certain number of\
seconds for a string from the modem.  If you leave the entries for the\
send (or expect) strings empty, then at that step no string will be\
sent (or expected).  A send string of \"&pause 2.5\" will not send a\
string but instead will pause for 2.5 seconds.  A send string of\
\"&return\" will send just a return character\
You can include special characters according to\
tcl's backslash substitution rules (see \"man Tcl\").
"

    set w .loginscripthelp
    catch {destroy $w}
    toplevel $w
    wm title $w "Dialer Help"
    wm iconname $w "Dialer Help"

    button .b
    label $w.title -text "DIALER HELP" \
        -font [.b cget -font]
    destroy .b
    pack $w.title -pady 10 -fill x -expand y

    frame $w.view
    text $w.view.text -width 80 -height 20 \
	-takefocus 0 -yscrollcommand "$w.view.scrollbar set" \
	-relief sunken -borderwidth 2 -state disabled \
        -wrap word

    pack $w.view.text -side left -fill both -expand 1
    scrollbar $w.view.scrollbar -command "$w.view.text yview"
    pack $w.view.scrollbar -side left -fill y -padx 3
    pack $w.view -side top -fill both -expand 1 -padx 10
    $w.view.text configure -state normal
    $w.view.text insert end "$text"
    $w.view.text configure -state disabled

    frame $w.buttons
    button $w.buttons.dismiss -text Dismiss -command "destroy $w"
    pack $w.buttons.dismiss -side left -expand y -fill y -padx 15 -pady 15
    pack $w.buttons -side bottom -fill x -expand y

}    

proc About {} {

    set text "
Dialer, by Mark Crimmins (markcrim@umich.edu), copyright 1995.
Look for the latest version in the tkgoodstuff distribution at:
\ \ \ ftp://merv.philosophy.lsa.umich.edu/pub
"
    set w .about
    catch {destroy $w}
    toplevel $w
    wm title $w "About Dialer"
    wm iconname $w "About Dialer"

    button .b
    label $w.title -text "About Dialer" \
        -font [.b cget -font]
    destroy .b
    pack $w.title -pady 10 -fill x -expand y

    frame $w.view -relief groove -borderwidth 5
    message $w.view.text -width 18c -text $text

    pack $w.view.text -side left -fill both -expand 1
    pack $w.view -side top -fill both -expand 1 -padx 10

    frame $w.buttons
    button $w.buttons.dismiss -text Dismiss -command "destroy $w"
    pack $w.buttons.dismiss -side left -expand y -fill y -padx 15 -pady 15
    pack $w.buttons -side bottom -fill x -expand y

}    

proc Save {{f ""}} {
    global file stringvars booleans 
    if {$f != ""} {set file $f}
    if {$file == ""} {SaveAs; return}
    set id [ open $file w ]
    puts $id "\#Dialer Settings File"
    foreach v [eval list $stringvars $booleans] {
	global $v
	puts $id "set $v \{[set $v]\}"
    }
    close $id
}

proc Open {} {
    global file
    if ![select f "Open file:"] {
	return
    }
    if ![file exists $f] {
	bgerror "Error:  $f doesn't exist."
	return
    }
    if ![file readable $f] {
	bgerror "Error:  $f isn't readable."
	return
    }
    set file $f
    GetSettings
}

proc New {} {
    global file 
    if ![select f "New file name:"] {
	return
    }
    if [file exists $f] {
	bgerror "Error: can't create $f: file exists"
	return
    }
    if [catch "exec touch $f"] {
	bgerror "Error: can't create $f."
	return
    }
    ClearSettings
    set file $f
    wm title . "Dialer"
}

proc SaveAs {} {
    global file
    if ![select f "File name:"] {
	return
    }
    if [file exists $f] {
	bgerror "Error: can't create $f: file exists"
	return
    }
    if [catch "exec touch $f"] {
	bgerror "Error: can't create $f."
	return
    }
    set file $f
    Save
}

proc ClearSettings {} {
    global stringvars booleans
    foreach v $stringvars {
	global $v
	set $v ""
    }
    foreach v $booleans {
	global $v
	set $v 0
    }
}

proc GetSettings {} {
    global file 
    global stringvars booleans
    foreach v [eval list $stringvars $booleans] {
	global $v
    }
    set id [open $file]
    gets $id s
    close $id
    if {$s != "\#Dialer Settings File"} {
	bgerror "File $file is not a dialer settings file."
	return
    }
    source $file
    global loops
    set loops [lindex $repeatscript 0]
}

proc select {var {message "Open File"}} {
    global selection
    set selection ""
    fileselect selectdone $message
    tkwait window .fileSelectWindow
    uplevel "set $var \"$selection\"" 
    if { $selection == "" } {
	return 0
    } else {
	return 1
    }
}

proc selectdone {f} {
    global selection 
    set selection $f
}

#
# fileselect.tcl --
# simple file selector.
#
# Mario Jorge Silva			          msilva@cs.Berkeley.EDU
# University of California Berkeley                 Ph:    +1(510)642-8248
# Computer Science Division, 571 Evans Hall         Fax:   +1(510)642-5775
# Berkeley CA 94720                                 
# 
# Layout:
#
#  file:                  +----+
#  ____________________   | OK |
#                         +----+
#
#  +------------------+    Cancel
#  | ..               |S
#  | file1            |c
#  | file2            |r
#  |                  |b
#  | filen            |a
#  |                  |r
#  +------------------+
#  currrent-directory
#
# Copyright 1993 Regents of the University of California
# Permission to use, copy, modify, and distribute this
# software and its documentation for any purpose and without
# fee is hereby granted, provided that this copyright
# notice appears in all copies.  The University of California
# makes no representations about the suitability of this
# software for any purpose.  It is provided "as is" without
# express or implied warranty.
#


# names starting with "fileselect" are reserved by this module
# no other names used.

# use the "option" command for further configuration



# this is the default proc  called when "OK" is pressed
# to indicate yours, give it as the first arg to "fileselect"

proc fileselect.default.cmd {f} {
  puts stderr "selected file $f"
}


# this is the default proc called when error is detected
# indicate your own pro as an argument to fileselect

proc fileselect.default.errorHandler {errorMessage} {
    puts stdout "error: $errorMessage"
    catch { cd ~ }
}

# this is the proc that creates the file selector box

proc fileselect {
    {cmd fileselect.default.cmd} 
    {purpose "Open file:"} 
    {w .fileSelectWindow} 
    {errorHandler fileselect.default.errorHandler}} {

    catch {destroy $w}

    toplevel $w
    grab $w
    wm title $w "Select File"


    # path independent names for the widgets
    global fileselect

    set fileselect(entry) $w.file.eframe.entry
    set fileselect(list) $w.file.sframe.list
    set fileselect(scroll) $w.file.sframe.scroll
    set fileselect(ok) $w.bframe.okframe.ok
    set fileselect(cancel) $w.bframe.cancel
    set fileselect(dirlabel) $w.file.dirlabel

    # widgets
    frame $w.file -bd 10 
    frame $w.bframe -bd 10
    pack append $w \
        $w.file {left filly} \
        $w.bframe {left expand frame n}

    frame $w.file.eframe
    frame $w.file.sframe
    label $w.file.dirlabel -anchor e -width 24 -text [pwd] 

    pack append $w.file \
        $w.file.eframe {top frame w} \
	$w.file.sframe {top fillx} \
	$w.file.dirlabel {top frame w}


    label $w.file.eframe.label -anchor w -width 24 -text $purpose
    entry $w.file.eframe.entry -relief sunken 

    pack append $w.file.eframe \
		$w.file.eframe.label {top expand frame w} \
                $w.file.eframe.entry {top fillx frame w} 


    scrollbar $w.file.sframe.yscroll -relief sunken \
	 -command "$w.file.sframe.list yview"
    listbox $w.file.sframe.list -relief sunken \
	-yscroll "$w.file.sframe.yscroll set" 

    pack append $w.file.sframe \
        $w.file.sframe.yscroll {right filly} \
 	$w.file.sframe.list {left expand fill} 

    # buttons
    frame $w.bframe.okframe -borderwidth 2 -relief sunken
 
    button $w.bframe.okframe.ok -text OK -relief raised -padx 10 \
        -command "fileselect.ok.cmd $w $cmd $errorHandler"

    button $w.bframe.cancel -text cancel -relief raised -padx 10 \
        -command "fileselect.cancel.cmd $w"
    pack append $w.bframe.okframe $w.bframe.okframe.ok {padx 10 pady 10}

    pack append $w.bframe $w.bframe.okframe {expand padx 20 pady 20}\
                          $w.bframe.cancel {top}

    # Fill the listbox with a list of the files in the directory (run
    # the "/bin/ls" command to get that information).
    # to not display the "." files, remove the -a option and fileselect
    # will still work
 
    $fileselect(list) insert end ".."
    foreach i [exec /bin/ls -a [pwd]] {
        if {[string compare $i "."] != 0 && \
	    [string compare $i ".."] != 0 } {
            $fileselect(list) insert end $i
        }
    }

   # Set up bindings for the browser.
    bind $fileselect(entry) <Return> {eval $fileselect(ok) invoke; break}
    bind $fileselect(entry) <Control-c> {eval $fileselect(cancel) invoke; break}

    bind $w <Control-c> {eval $fileselect(cancel) invoke;break}
    bind $w <Return> {eval $fileselect(ok) invoke;break}


#    tk_listboxSingleSelect $fileselect(list)


    bind $fileselect(list) <Button-1> {
        # puts stderr "button 1 release"
        %W selection set [%W nearest %y]
	$fileselect(entry) delete 0 end
	$fileselect(entry) insert 0 [%W get [%W nearest %y]]
	break
    }

    bind $fileselect(list) <Key> {
        %W selection set [%W nearest %y]
        $fileselect(entry) delete 0 end
	$fileselect(entry) insert 0 [%W get [%W nearest %y]]
	break
    }

    bind $fileselect(list) <Double-ButtonPress-1> {
        # puts stderr "double button 1"
        %W selection set [%W nearest %y]
	$fileselect(entry) delete 0 end
	$fileselect(entry) insert 0 [%W get [%W nearest %y]]
	$fileselect(ok) invoke
	break
    }

    bind $fileselect(list) <Return> {
        %W selection set [%W nearest %y]
	$fileselect(entry) delete 0 end
	$fileselect(entry) insert 0 [%W get [%W nearest %y]]
	$fileselect(ok) invoke
	break
    }

    # set kbd focus to entry widget

    focus $fileselect(entry)

}


# auxiliary button procedures

proc fileselect.cancel.cmd {w} {
    # puts stderr "Cancel"
    destroy $w
}

proc fileselect.ok.cmd {w cmd errorHandler} {
    global fileselect
    set selected [$fileselect(entry) get]

    # some nasty file names may cause "file isdirectory" to return an error
    set sts [catch { 
	file isdirectory $selected
    }  errorMessage ]

    if { $sts != 0 } then {
	$errorHandler $errorMessage
	destroy $w
	return

    }

    # clean the text entry and prepare the list
    $fileselect(entry) delete 0 end
    $fileselect(list) delete 0 end
    $fileselect(list) insert end ".."

    # selection may be a directory. Expand it.

    if {[file isdirectory $selected] != 0} {
	cd $selected
	set dir [pwd]
	$fileselect(dirlabel) configure -text $dir

	foreach i [exec /bin/ls -a $dir] {
	    if {[string compare $i "."] != 0 && \
		[string compare $i ".."] != 0} {
		$fileselect(list) insert end $i
	    }
	}
	return
    }

    destroy $w
    $cmd $selected
}
##### end of fileselect code

# Main Program
DialWindow
if {($file != "") || \
      ([file exists $env(HOME)/.DialSettings] && \
             ![catch {set file $env(HOME)/.DialSettings}]) } { 
   ClearSettings
   GetSettings 
}
eval $argv
