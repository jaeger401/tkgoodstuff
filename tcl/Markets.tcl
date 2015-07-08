# Markets client for tkgoodstuff
# Markets data from Yahoo

proc MarketsDeclare {} {
    TKGDeclare Markets(interval) 180 -typelist [list Clients Markets]\
	-label "How often to check the markets (seconds)"
    TKGDeclare Markets(nolabel) 0 -typelist [list Clients Markets]\
	-label "Omit text label"\
	-vartype boolean
    TKGDeclare Markets(label) Dow -typelist [list Clients Markets]\
	-label "Label text"
    TKGDeclare Markets(command) {TKGBrowse http://quote.yahoo.com} -typelist [list Clients Markets]\
	-label "Tcl command to run on a click"
    TKGDeclare Markets(exec) {} -typelist [list Clients Markets]\
	-label "Unix command to run on a click"
    TKGDeclare Markets(lines) 1 -vartype boolean -typelist [list Clients Markets]\
	-label "Split line between level and change"
    
}

proc MarketsCreateWindow {} {
    global Markets Markets-params TKG
    if [TKGReGrid Markets] return
    TKGMakeButton Markets \
	-command $Markets(command)\
	-exec $Markets(exec)\
	-text [MarketsUpdateText ??? ???]\
	-balloon "No data yet"
    
    package require http

    TKGPeriodic markets $Markets(interval) 0 MarketsUpdate
}

proc MarketsUpdateText {level change} {
    global Markets
    if $Markets(nolabel) {
	set text ""
    } else {
	set text $Markets(label)
    }
    if $Markets(lines) {
	append text "\n$level\n$change"
    } else {
	append text "$level $change"
    }
    return $text
}
		    
proc MarketsUpdate {} {
	http::geturl http://quote.yahoo.com/ -command MarketsPost
}

proc MarketsPost {token} {
    upvar \#0 $token state
    foreach var {time dLevel dChange dPercent nLevel nChange nPercent sLevel sChange sPercent} {
	set $var error
    }
    regexp "<small>(\[^\n\]*)\\ --" $state(body) dummy time
    regexp {Dow[^0-9]*([0-9\.]*)[^-+.]*([-+0][-+\.0-9]*)[^\(]*(\([^\)]*\))} $state(body) dummy dLevel dChange dPercent
    regexp {Nasdaq[^0-9]*([0-9\.]*)[^-+.]*([-+0][-+\.0-9]*)[^\(]*(\([^\)]*\))} $state(body) dummy nLevel nChange nPercent
    regexp {S&P\ 500[^0-9]*([0-9\.]*)[^-+.]*([-+0][-+\.0-9]*)[^\(]*(\([^\)]*\))} $state(body) dummy sLevel sChange sPercent
    if [string match -* $dChange] {
	set fg red
    } else {
	set fg black
    }
    TKGButton Markets -text [MarketsUpdateText $dLevel $dChange] \
	-foreground $fg -activeforeground $fg \
	-balloon "At: $time

Dow:\t$dLevel\t$dChange\t$dPercent
Nasdaq:\t$nLevel\t$nChange\t$nPercent
S&P:\t$sLevel\t$sChange\t$sPercent

Market data from quote.yahoo.com 
(click to visit)"

}

