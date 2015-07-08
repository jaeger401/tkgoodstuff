# WWW browser launching Client Tcl code for tkgoodstuff

proc WWWDeclare {} {
    set Prefs_taborder(:Clients,WWW) "Misc Commands"
    set Prefs_taborder(:Clients,WWW,Commands) "Netscape Lynx "
    set Prefs_taborder(:Clients,WWW,Button) "Misc Colors Fvwm"
    TKGDeclare WWW(browserlist) netscape -typelist [list Clients WWW Misc]\
	-label "List of browsers (separated by spaces)"
    TKGDeclare WWW(lynx,launch) "xterm -T lynx -e lynx"\
	-typelist [list Clients WWW Commands Lynx] \
	-label "Unix launch command"
    TKGDeclare WWW(netscape,launch) "netscape -ncols 120"\
	-typelist [list Clients WWW Commands Netscape] \
	-label "Unix launch command"
    TKGDeclare WWW(netscape,windowname) Netscape\
	-typelist [list Clients WWW Commands Netscape] \
	-label "Window name"
    TKGDeclare WWW(lynx,windowname) lynx\
	-typelist [list Clients WWW Commands Lynx] \
	-label "Window name"
    TKGDeclare WWW(default,launch) {\$browser}\
	-typelist [list Clients WWW Commands Other] \
	-label "Unix launch command for other browsers"\
	-help "The default is just the browser name"
    TKGDeclare WWW(newwindow) 1 \
	-typelist [list Clients WWW Commands Netscape] \
	-label "Open new Netscape window for URLs in X selection" \
	-vartype boolean
    set WWW(netscape,goto) {tcl {WWWNetscapeGoto $url}}
    TKGDeclare WWW(lynx,goto) {xterm -T lynx -e lynx \$url}\
	-typelist [list Clients WWW Commands Lynx] \
	-label "Command to direct lynx to a specific URL"
    TKGDeclare WWW(default,goto) {tcl {exec \$browser \$url &} }\
	-typelist [list Clients WWW Commands Other] \
	-label "Command to direct unknown browser to a specific URL"
        ConfigDeclare Ical ClientButton1 Ical [list Clients Ical Button]
    ConfigDeclare WWW ClientButton1 WWW [list Clients WWW Button]
    ConfigDeclare WWW ClientButton2 WWW [list Clients WWW Button]
    ConfigDeclare WWW ClientButton3 WWW [list Clients WWW Button]
    ConfigDeclare WWW ClientButton4 WWW [list Clients WWW Button]
    ConfigDeclare WWW ClientButton5 WWW [list Clients WWW Button]
}

proc WWWCreateWindow {} {
    if [TKGReGrid WWW] return
    global WWW WWW-params

    if {[llength $WWW(browserlist)] == 1} {
	set WWW(browser) [lindex $WWW(browserlist) 0]
	set WWW(singlemode) 1
    } else {
	set WWW(singlemode) 0
	set WWW(browser) ""
    }

    switch $WWW(browser) {
	netscape {
	    set WWW(text) "Netscape"
	    if [Empty $WWW(imagefile)] {
		set WWW(imagefile) %netscape
	    }
	    if [Empty $WWW(windowname)] {
		set WWW(windowname) Netscape
	    }
	}
	default {
	    set WWW(text) "WWW"
	    if [Empty $WWW(imagefile)] {
		set WWW(imagefile) %www
	    }
	}
    }

    lappend c TKGMakeButton WWW -balloon "Launch Web browser"
    foreach switch {
	iconside ignore font foreground background windowname tilefile
	activeforeground activebackground staydown trackwindow relief
    } {
	lappend c -$switch $WWW($switch)
    }
    if !$WWW(nolabel) {
	lappend c -text $WWW(text)
    }
    if {!$WWW(noicon) || $WWW(nolabel)} {
	lappend c -imagefile $WWW(imagefile)
    }
    eval $c

    if !$WWW(singlemode) {	 
	bind [set WWW-params(pathname)] <1> "WWWChooseLaunch %X %Y"
	bind [set WWW-params(pathname)] <3> "WWWChooseGoto %X %Y"
    } else {
	bind [set WWW-params(pathname)] <3> "WWWGoto $WWW(browser)"
	if [info exists WWW($WWW(browser),launch)] {
	    TKGButton WWW -exec $WWW($WWW(browser),launch)
	} else {
	    set browser $WWW(browser)
	    eval TKGButton WWW -exec $WWW(default,launch)
	}
	if [info exists WWW($WWW(browser),windowname)] {
	    TKGButton WWW -windowname $WWW($WWW(browser),windowname)
	}
    }
}

proc WWWNetscapeGoto {url} {
    global WWW
    if $WWW(newwindow) {
	set cmd [list exec netscape -remote "openURL($url, newwindow, noraise)"]
    } else {
	set cmd [list exec netscape -remote "openURL($url)"]
    }
    if [ catch $cmd err ] {
	if [string match "Couldn't find a netscape window" $err] {
	    WWWLaunchWithURL netscape $url
	} else {TKGNotice $err}
    }
}

proc WWWButtonInvoke {command} {
    upvar \#0 WWW-params P
    set oldcommand $P(exec,normal)
    set P(exec,normal) $command
    TKGbuttonInvoke $P(pathname)
    set P(exec,normal) $oldcommand
}

proc WWWLaunchWithURL {browsertype url} {
    global WWW WWW-params 
    set oldlaunch $WWW($browsertype,launch)
    set WWW($browsertype,launch) "$oldlaunch $url"
    TKGbuttonInvoke [set WWW-params(pathname)]
    set WWW($browsertype,launch) $oldlaunch	    
}

proc WWWChooseGoto {x y} {
    global WWW
    set m .wwwchoose
    catch "destroy $m"
    menu $m
    foreach browser $WWW(browserlist) {
	$m add command -label $browser -command "WWWGoto $browser"
    }
    eval tk_popup $m [TKGPopupLocate $m $x $y]
    raise $m
}

proc WWWChooseLaunch {x y} {
    global WWW
    set m .wwwchoose
    catch "destroy $m"
    menu $m
    foreach browser $WWW(browserlist) {
	$m add command -label $browser -command "WWWLaunch $browser"
    }
    eval tk_popup $m [TKGPopupLocate $m $x $y]
}

proc WWWLaunch {browser} {
    global WWW
    if ![info exists WWW($browser,windowname)] {
	set WWW($browser,windowname) ""
    }
    if [info exists WWW($browser,launch)] {
	TKGExec $WWW($browser,launch) $WWW($browser,windowname)
    } else {
	TKGExec $WWW(default,launch)
    }
}

proc WWWGoto {browser {url ""}} {
    global WWW
    if [Empty $url] {
	if [catch "selection get" url] {
	    TKGError "Selection not set"
	    return
	}
	selection clear
	set url [WWWTrimURL $url]
    }
    if [info exists WWW($browser,goto)] {
	set c $WWW($browser,goto)
    } else {
	set c $WWW(default,goto)
    }
    if {[lindex $c 0] == "tcl"} {
	eval [lindex $c 1]
    } else {
	eval "eval exec $c &"
    }
}
 
proc WWWTrimURL {url} {
    set pattern [join {{(s?https?|ftp|file|gopher|news|telnet):}\
			   {([-a-zA-Z0-9_.]+:[0-9]*)?}\
			   {[-a-zA-Z0-9_=?#$@~`%&*+|\\/.,]+}} ""]
    if [regexp $pattern $url trimmed] {
  	return $trimmed
    } else { return $url }
}

DEBUG "Loaded WWW.tcl"

