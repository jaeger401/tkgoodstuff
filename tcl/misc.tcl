proc TKGStartClients {} {
    global TKG
    foreach client $TKG(clients) {
	if ![Empty [info procs ${client}Start]] {${client}Start}
    }
}

proc TKGSuspendClients {} {
    global TKG
    foreach client $TKG(clients) {
	if ![Empty [info procs ${client}Suspend]] {${client}Suspend}
    }
}

proc TKGPreferences {} {
    if [Empty [info procs TKGPrefs]] {
	uplevel \#0 {
	    source $TKG(libdir)/tcl/prefs.tcl
	}
    }
    TKGPrefs
}

proc TKGIconify {} {
    wm iconify .
}

proc TKGRestart {} {
    global argv argv0 TKG
    catch {close $TKG(logfileid)}
    regexp {^[0-9]*x[0-9]*(.*$)} [wm geometry .main-panel] geo geo
    eval [concat exec $argv0 -geometry $geo $argv &]
    exit
}

proc TKGQuit {} {
    TKGDoHook TKG_quithook
    TKGReallyQuit
}

proc TKGReallyQuit {} {
    exit
}

proc TKGExec {cmd args} {
    eval exec $cmd & 
}

proc TKGBrowse {url} {
    global TKG
    if {[info procs WWWGoto] != ""} {
	WWWGoto $TKG(browser) $url
	return
    }
    switch $TKG(browser) {
	lynx "TKGExec {xterm -T lynx -e lynx $url} lynx"
	netscape {
	    set cmd [list exec netscape -remote openURL($url, newwindow, noraise)]
	    if [ catch $cmd err ] {
		if [string match "Couldn't find a netscape window" $err] {
		    exec netscape $url &
		}
	    }  
	}
	default "TKGExec {$TKG(browser) $url}"
    }
}

