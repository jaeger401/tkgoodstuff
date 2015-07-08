proc SwallowEnsureTkSteal {} {
    package require Tksteal
}

set TKG(switches,Swallow) {
    {exec "" {-label {Unix command to produce the window to swallow.  It's often best to
specify the geometry explicitly (e.g.: -geometry 100x200).} -scrollbar 1} Main}
    {windowname "" {-label {Windowname of the window to swallow}\
			-help {This is the name usually put in the window-manager's
title bar.  It is our way of recognizing which window to swallow.}} Main}
    {width "" {-label "Width in pixels"} Main}
    {height "" {-label "Height in pixels"} Main}
    {foreground "" {-label Foreground} Colors}
    {background "" {-label Background} Colors}
    {balloon "" {-label {Text in help balloon}} Advanced}
    {borderwidth "3" {-label {Width of ridged border}} Advanced}
}

proc Swallow args {
    SwallowEnsureTkSteal
    set name [join $args ~]
    set args [TKGGetArgs Swallow $name]
    TKGAddToHook TKG_createmainpanel\
	"TKGMakeSwallow [concat $name $args]"
}

proc TKGMakeSwallow {name args} {
    global TKG
    set lcname [string tolower $name]
    set lcpanel [string tolower $TKG(currentpanel)]
    set pathname .${lcpanel}.$lcname
    if ![winfo exists $pathname] {
	global $name-params
	set $name-params(pathname) $pathname
	eval [concat TKGSwallow $name -pathname $pathname $args]
    }
    TKGGrid $pathname
    return $pathname
}

set TKG(switches,TKGSwallow) {
    pathname
    {foreground $TKG(buttonforeground)}
    {background $TKG(buttonbackground)}
    {height 60}
    {width 60}
    {exec ""}
    {windowname ""}
    {balloon ""}
    {borderwidth 3}
}

# TKGSwallow --
# Produces and configures mode-sensitive tkgbutton widgets.

proc TKGSwallow {name args} {
    global TKG TKG_iconSide
    upvar #0 $name-swparams P
    # Parse arguments
    set sswitches $TKG(switches,TKGSwallow)
    TKGParseArgs $name-swparams $args $sswitches {} TKGSwallow
    if ![info exists P(init)] {
	TKGSetSwitchDefaults $name-swparams $TKG(switches,TKGSwallow)
	set P(init) 1
    }
    if [Empty $P(windowname)] {
	set P(windowname) \
	    [file tail [lindex $P(exec) 0]]
    }
    foreach switch $sswitches {
	if [Empty $P([lindex $switch 0])] {
	    set P([lindex $switch 0]) [uplevel \#0 "subst \"[lindex $switch 1]\""]
	}
    }
    set bw $P(borderwidth)
    frame $P(pathname) -borderwidth $bw\
	-highlightthickness 0 -relief ridge -cursor top_left_arrow \
	-width [expr $P(width) + 2*$bw] -height [expr $P(height) + 2*$bw]
    TKGRowCol $P(pathname)
    grid propagate $P(pathname) 0
    lappend C tkSteal $P(pathname).stolen \
	-command $P(exec) -name $P(windowname) \
	-borderwidth 0 -width $P(width) -height $P(height)
    after 0 "
	eval [list $C]
	grid $P(pathname).stolen
        if ![Empty $P(balloon)] {TKGBalloonBind $P(pathname) \"$P(balloon)\"}
    "
}
