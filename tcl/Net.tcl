# Net status and toggle button client.  Tcl code for tkgoodstuff

proc NetDeclare {} {
    set Prefs_taborder(:Clients,Net) "Misc Commands Button Ping"
    set Prefs_taborder(:Clients,Net,Commands) "PPP SLIP TERM"
    set Prefs_taborder(:Clients,Net,Button) "Misc Colors MoreColors"
    TKGDeclare Net(nolabel) 0\
	-typelist [list Clients Net Button Misc]\
	-vartype boolean\
	-label "Don't use a text label"
    TKGDeclare Net(types) "PPP SLIP TERM"\
	-typelist [list Clients Net Misc]\
	-label "Types of net connection this client might be asked to control"
    TKGDeclare Net(type) {[lindex $Net(types) 0]}\
	-typelist [list Clients Net Misc]\
	-label "The default connection type (by default, the first in the above list)"
    TKGDeclare Net(PPP,on) Dialer\
	-typelist [list Clients Net Commands PPP]\
	-label "Unix command to open link"
    TKGDeclare Net(PPP,off) ppp-off\
	-typelist [list Clients Net Commands PPP]\
	-label "Unix command to close link"
    TKGDeclare Net(PPP,getstatuscommand) ""\
	-typelist [list Clients Net Commands PPP]\
	-label "Unix command to test if link is open"
    TKGDeclare Net(PPP,getaddresscommand) {ifconfig | grep inet.\*P-t-P | sed s/inet.*r:// | sed s/P-t-P.\*//}\
	-typelist [list Clients Net Commands PPP]\
	-vartype text\
	-label "Unix command to get local net address"

    TKGDeclare Net(SLIP,on) slipup\
	-typelist [list Clients Net Commands SLIP]\
	-label "Unix command to open link"
    TKGDeclare Net(SLIP,off) slipdown\
	-typelist [list Clients Net Commands SLIP]\
	-label "Unix command to close link"
    TKGDeclare Net(SLIP,getstatuscommand) ""\
	-typelist [list Clients Net Commands SLIP]\
	-label "Unix command to test if link is open"
    TKGDeclare Net(SLIP,getaddresscommand) {ifconfig | grep inet.\*P-t-P | sed s/inet.*r:// | sed s/P-t-P.\*//}\
	-vartype text\
	-typelist [list Clients Net Commands SLIP]\
	-label "Unix command to get local net address"

    TKGDeclare Net(TERM,on) term-on\
	-typelist [list Clients Net Commands TERM]\
	-label "Unix command to open link"
    TKGDeclare Net(TERM,off) term-off\
	-typelist [list Clients Net Commands TERM]\
	-label "Unix command to close link"
    TKGDeclare Net(TERM,getstatuscommand) ""\
	-typelist [list Clients Net Commands TERM]\
	-label "Unix command to test if link is open"
    TKGDeclare Net(TERM,getaddresscommand) {ifconfig | grep inet.\*P-t-P | sed s/inet.*r:// | sed s/P-t-P.\*//}\
	-typelist [list Clients Net Commands TERM]\
	-vartype text\
	-label "Unix command to get local net address"
    TKGDeclare Net(check_interval) 20\
	-typelist [list Clients Net Misc]\
	-label "How often to check if the net is up (seconds)"
    TKGDeclare Net(wait_period) 120\
	-typelist [list Clients Net Misc]\
	-label "After how long assume that net-connect command failed"

    TKGDeclare Net(auto_ping) 1\
	-typelist [list Clients Net Ping]\
	-label "Periodically issue \"ping\" command to keep the line\
active"
    TKGDeclare Net(ping_interval) 120\
	-typelist [list Clients Net Ping]\
	-label "How often (seconds)"
    TKGDeclare Net(ping_command) {ping -c 1 \$Net(ipaddr)}\
	-typelist [list Clients Net Ping]\
	-label "Using what command (\"\\\$Net(ipaddr)\" is the local net address)"
    TKGDeclare Net(showtime) 1\
	-typelist [list Clients Net Misc]\
	-vartype boolean\
	-label "Show up-time in button label"

    TKGDeclare Net(iconside) ""\
	-label "Side of icon on button" -vartype radio\
	-radioside left\
	-radiolist {{left left} {right right} {top top} 
	    {bottom bottom} {background background}} \
	-typelist [list Clients Net Button Misc]
    TKGDeclare Net(relief) ""\
	-label "Normal relief of button" -vartype radio\
	-radioside left\
	-radiolist {{raised raised} {flat flat}} \
	-typelist [list Clients Net Button Misc]
    TKGDeclare Net(font) "" \
	-vartype font\
	-typelist [list Clients Net Button Misc]\
	-label "Font of label on button"
    TKGDeclare Net(image,up) {%netup}\
	-typelist [list Clients Net Button Misc]\
	-label "Icon when connection is up"
    TKGDeclare Net(image,dn) {%netdn}\
	-typelist [list Clients Net Button Misc]\
	-label "Icon when connection is down"
    TKGDeclare Net(image,wt) {%netwt}\
	-typelist [list Clients Net Button Misc]\
	-label "Icon when connection is in transition"

    TKGColorDeclare Net(upforeground) chartreuse1 \
	[list Clients Net Button Colors] \
	"Foreground color: net up"
    TKGColorDeclare Net(upactiveforeground) {} \
	[list Clients Net Button Colors]\
	"Active (mouse on top) foreground color: net up"\
	$Net(upforeground)
    TKGColorDeclare Net(upbackground) {}\
	[list Clients Net Button Colors]\
	"Background color: net up" \
	$TKG(buttonbackground)
    TKGColorDeclare Net(upactivebackground) {} \
	[list Clients Net Button Colors]\
	"Active Background color: net up"\
	$TKG(butactivebackground)
    TKGColorDeclare Net(dnforeground) {} \
	[list Clients Net Button Colors]\
	"Foreground color: net down"\
	$TKG(buttonforeground)
    TKGColorDeclare Net(dnactiveforeground) {} \
	[list Clients Net Button Colors]\
	"Active foreground color: net down"\
	$Net(dnforeground)
    TKGColorDeclare Net(dnbackground) {} \
	[list Clients Net Button Colors]\
	"Background color: net down"\
	$TKG(buttonbackground)
    TKGColorDeclare Net(dnactivebackground) {} \
	[list Clients Net Button Colors]\
	"Active Background color: net down"\
	$TKG(butactivebackground)
    TKGColorDeclare Net(wtforeground) yellow\
	[list Clients Net Button MoreColors]\
	"Foreground color: net in transition"
    TKGColorDeclare Net(wtactiveforeground) {} \
	[list Clients Net Button MoreColors]\
	"Active foreground color: net in transition" \
	$Net(wtforeground)
    TKGColorDeclare Net(wtbackground) {} \
	[list Clients Net Button MoreColors]\
	"Background color: net in transition" \
	$TKG(buttonbackground)
    TKGColorDeclare Net(wtactivebackground) {} \
	[list Clients Net Button MoreColors]\
	"Active Background color: net in transition"\
	$TKG(butactivebackground)
}

proc Net_setstatus {} {
    global Net Net_strings 
   
    if {!$Net(linkstatus)} {
	TKGPeriodicCancel Net_ping
	TKGButton Net -mode netdn
	TKGButton Net -mode netdn
	Net_popup_menu normal
        set Net(ipaddr) $Net_strings(nonexistent)
	TKGDoHook Net_down_hook
    } else {
        # Get IP address for pinging
        catch {eval exec $Net($Net(type),getaddresscommand)} Net(ipaddr)
        set Net(ipaddr) [string trim $Net(ipaddr) " "]
	DEBUG "Net up: ip address is $Net(ipaddr)"
	TKGPeriodic Net_ping $Net(ping_interval) $Net(ping_interval) Net_ping
	TKGButton Net -mode netup
	TKGDoHook Net_up_hook
	if $Net(showtime) {
	    set Net(uptime)\
		[expr [clock seconds] - [clock scan 00:00]]
	}
    }
}

proc Net-stat {} {
    global Net Net-params TKG
    set oldstatus $Net(linkstatus)
    set Net(linkstatus) [eval $Net($Net(type),getstatus)]
    if {$oldstatus != $Net(linkstatus)} {
	set stat down
	if {$Net(linkstatus)} {set stat up}
	DEBUG "Net is $stat"
         Net_setstatus
	 Net_stop_wait
    }
    if [info exists Net(uptime)] {
	global Net-params
	set t [clock format [expr [clock seconds] - $Net(uptime)]\
		 -format %T]
	set Net-params(text,netup) $t
	set TKG(balloontext,[set Net-params(pathname)]) "Uptime: $t"
    }
}

proc Net_start_wait {} {
    global Net

    # accelerate status checking and set Net(stop_wait) to run
    DEBUG "Starting Net status-check vigilance"
    TKGPeriodic Net_update \
	$Net(waitcheck_interval) $Net(waitcheck_interval) Net-stat
    TKGPeriodic Net_stopwait \
	1 $Net(wait_period) {
	    DEBUG "Net: vigilance timed out"
	    Net_stop_wait
	    Net_setstatus
	}
}

proc Net_stop_wait {} {
    global Net

    DEBUG "Ending Net status-check vigilance"
    #get rid of wait button, resume normal checking, and no more of me
    TKGPeriodic Net_update $Net(check_interval) $Net(check_interval) Net-stat
    TKGPeriodicCancel Net_stopwait
    Net_popup_menu normal
}

proc Net_on_stuff {} {
    global Net
    DEBUG "Net: trying net-up"
    TKGButton Net -mode nettu
    if [catch {eval exec $Net($Net(type),on) &} err] {
	TKGError "Error in executing Net up command:\n$err"
	Net_reset_stuff
	return
    }
    Net_start_wait
    Net_popup_menu disabled
}

proc Net_off_stuff {} {
    global Net
    DEBUG "Net: trying net-down"
    TKGButton Net -mode nettd
    if [catch {eval exec $Net($Net(type),off) &} err] {
	TKGError "Error in executing Net down command:\n$err"
	Net_reset_stuff
	return
    }
    Net_start_wait
    if $Net(showtime) {
	global Net-params
	unset Net(uptime)
	set Net-params(text,netup) "00:00:00"
	set Net-params(balloon,netup) "Uptime: 00:00:00"
    }
}

proc Net_reset_stuff {} {
    Net_stop_wait
    Net_setstatus
}

proc Net_popup_menu {state} {
    global Net
    foreach type $Net(types) {
	.tkgpopup.net entryconfigure $type -state $state
    }
}


proc Net_ping {} { 
    global Net
    if $Net(auto_ping) {
    Net-stat
	if {$Net(linkstatus)} {
	    DEBUG "pinging  $Net(ipaddr)"
	    eval exec $Net(ping_command)
	}
    }
}

proc NetAskReset {} {
    global Net_strings
    TKGDialog netreset \
        -wmtitle $Net_strings(reset) \
        -title $Net_strings(reset) \
	-message $Net_strings(askreset)\
	-nodismiss\
	-buttons {
	    { yes Yes {Net_reset_stuff; destroy .netreset }}
	    { cancel Cancel {destroy .netreset}}
	}
    focus .netreset.buttons.yes
}

proc NetAskDown {} {
    TKGDialog netdown \
        -wmtitle "Net Down: confirm" \
        -title "Net" \
	-message "Really bring net connection down?"\
	-nodismiss\
	-buttons {
	    { yes Yes {Net_off_stuff; destroy .netdown }}
	    { cancel Cancel {destroy .netdown}}
	}
    focus .netdown.buttons.yes
}

proc NetChangeType args {
    global Net Net_strings Net-params TKG
    if ![info exists Net-params(pathname)] return
    if { !$Net(nolabel) && !$TKG(iconsonly) } {
	TKGButton Net \
	    -text(netwt) "$Net_strings(netwt)" \
	    -text(netdn) "$Net_strings(netdn)" \
	    -text(netup) "$Net_strings(netup)" \
	    -text(nettu) "$Net_strings(nettu)" \
	    -text(nettd) "$Net_strings(nettd)"
    }
}

proc NetCreateWindow {} {
    if [TKGReGrid Net] return
    global Net TKG Net-params Net_strings TKG_labels

    TKGClientStrings Net
    uplevel {
	set Net(check_offset) 0
	set Net(waitcheck_interval) 2
	trace variable Net(type) w NetChangeType
	# Initial settings
	set Net(linkstatus)    -1
	set Net(ipaddr) $Net_strings(nonexistent)
    }

    foreach type $Net(types) {
	if ![Empty $Net($Net(type),getstatuscommand)] {
	    set Net($type,getstatus)\
		"expr !\[catch {eval exec $Net($type,getstatuscommand)}\]"
	} elseif [file readable /proc/net/route] {
	    set Net($type,getstatus)\
		"string match  *[string tolower $type]* \[GetFile /proc/net/route\]"
	} else {
	    set Net($type,getstatus)\
		"expr !\[catch {eval exec ifconfig | grep [string tolower $type]}\]"
	}
    }
    SetImage netup_image $Net(image,up)
    SetImage netdn_image $Net(image,dn)
    SetImage netwt_image $Net(image,wt)
 
    if $Net(nolabel) {
	set twt ""
	set tup ""
	set tdn ""
	set ttu ""
	set ttd ""
    } else {
        set twt "$Net_strings(netwt)"
        set tup "$Net_strings(netup)"
        set tdn "$Net_strings(netdn)"
        set ttu "$Net_strings(nettu)"
        set ttd "$Net_strings(nettd)"
    }   
    if $Net(showtime) {
	set tup "00:00:00"
    }
    TKGMakeButton Net \
	-mode netwt \
	-image(netwt) netwt_image \
	-text(netwt) $twt \
	-command(netwt) NetAskReset\
	-staydown(netwt) 0\
        -foreground(netwt) $Net(wtforeground) \
        -background(netwt) $Net(wtbackground) \
        -activeforeground(netwt) $Net(wtactiveforeground) \
        -activebackground(netwt) $Net(wtactivebackground) \
	-image(netup) netup_image \
	-text(netup) $tup \
	-balloon(netup) $tup \
	-staydown(netup) 0 \
	-command(netup) NetAskDown\
        -foreground(netup) $Net(upforeground) \
        -background(netup) $Net(upbackground) \
        -activeforeground(netup) $Net(upactiveforeground) \
        -activebackground(netup) $Net(upactivebackground) \
	-image(netdn) netdn_image \
	-text(netdn) $tdn \
	-balloon(netdn) $tdn \
	-staydown(netdn) 0 \
	-command(netdn) Net_on_stuff\
        -foreground(netdn) $Net(dnforeground) \
        -background(netdn) $Net(dnbackground) \
        -activeforeground(netdn) $Net(dnactiveforeground) \
        -activebackground(netdn) $Net(dnactivebackground) \
	-font(netup) $Net(font) \
	-font(netdn) $Net(font) \
	-font(netwt) $Net(font) \
	-iconside $Net(iconside) \
	-relief $Net(relief)
    TKGButtonCopyMode Net netwt nettd
    set Net-params(text,nettd) $ttd
    set Net-params(balloon,nettd) $ttd
    TKGButtonCopyMode Net netwt nettu
    set Net-params(text,nettu) $ttu
    set Net-params(balloon,nettu) $ttu
    	
    TKGPopupAddClient Net
    foreach type $Net(types) {
	.tkgpopup.net add radiobutton -label $type -variable Net(type) -value $type
    }
    .tkgpopup.net add separator

    .tkgpopup.net add checkbutton\
	-label "$Net_strings(netping) " -variable Net(auto_ping)
    .tkgpopup.net add command\
	-label "$Net_strings(netshowip) " -command {
	    TKGDialog ipinfo -wmtitle $Net_strings(netipinfo)\
		-message "$Net_strings(netipaddr) $Net(ipaddr)"
	}
 #    RecursiveBind [set Net-params(pathname)] <3> {
 #	set newtype [lindex $Net(types) \
 #			 [expr (([lsearch $Net(types) $Net(type)] +1)\
 #				    %% [llength $Net(types)])]]
 #	.tkgpopup.net invoke $newtype
 #    }
    uplevel {
	TKGPeriodic Net_update $Net(check_interval) $Net(check_offset) Net-stat
    }
}

DEBUG "Loaded Net.tcl"
