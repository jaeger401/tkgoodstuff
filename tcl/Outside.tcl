# Outside client for tkgoodstuff
#  data from Yahoo

proc OutsideDeclare {} {
    TKGDeclare Outside(interval) 900 -typelist [list Clients Outside]\
	-label "How often to check the conditions (seconds)"
    TKGDeclare Outside(url) http://weather.yahoo.com/forecast/Detroit_MI_US_f.html\
	-typelist [list Clients Outside]\
	-label "URL for forecast" \
	-help "Outside.tcl understands only Weather Underground forecasts."
    TKGDeclare Outside(command) {TKGBrowse http://weather.yahoo.com/forecast/Detroit_MI_US_f.html}\
	-typelist [list Clients Outside]\
	-label "Tcl command to run on a click"
    TKGDeclare Outside(exec) {} -typelist [list Clients Outside]\
	-label "Unix command to run on a click"
    TKGDeclare Outside(lines) 1 -vartype boolean -typelist [list Clients Outside]\
	-label "Split line between temperature and humidity"    
}

proc OutsideCreateWindow {} {
    global Outside Outside-params TKG
    if [TKGReGrid Outside] return
    TKGMakeButton Outside \
	-command $Outside(command)\
	-exec $Outside(exec)\
	-text [OutsideUpdateText Outside... ??? ???]\
 	-balloon "From weather.yahoo.com\n(click for forecast)"
    
    package require http

    TKGPeriodic outside $Outside(interval) 3 OutsideUpdate
}

proc OutsideUpdateText {time temp hum} {
    global Outside
    if $Outside(lines) {
	return "$time\n$temp\n$hum"
    } else {
	return "$time\n$temp $hum"
    }
}

proc OutsideUpdate {} {
    global Outside
    http::geturl $Outside(url) -command OutsidePost
}

proc OutsidePost {token} {
    upvar \#0 $token state
    regexp {as of (.*)\ (a|p)m\ EDT[^+]*\+2>([0-9]*).*>RH:\ ([^<]*)} \
	$state(body) dummy time ampm temp hum
    TKGButton Outside \
	-text [OutsideUpdateText "At $time:" "$temp F" $hum]
}
