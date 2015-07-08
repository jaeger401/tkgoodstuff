proc REPORT args {
    foreach var $args {
	uplevel "
	    puts \"$var \[set $var\]\";flush stdout
	    DEBUG \"$var \[set $var\]\"
	"
    }
}

proc DEBUG { string } {
    global TKG TKG(log)
    if $TKG(filelogging) {
	if [!info exists TKG(logfileid)] {
	    set TKG(logfileid) [open $TKG(logfile) w+]
	    TKGAddToHook TKG_quithook "close $TKG(logfileid)"
	}
	puts $TKG(logfileid) $string
	flush $TKG(logfileid)
    }
    if $TKG(internallogging) {
	append TKG(log) "$string\n"
	if [winfo exists .tkglog] {
	    .tkglog.view.text configure -state normal
	    .tkglog.view.text insert end "$string\n"
	    .tkglog.view.text configure -state disabled
	    .tkglog.view.text see end
	}
    }
}

proc TKGViewLog {} {
  global TKG
  TKGDialog tkglog\
      -wmtitle "tkgoodstuff Log"\
      -title "tkgoodstuff Log"\
      -text "$TKG(log)"
  .tkglog.view.text see end
}
