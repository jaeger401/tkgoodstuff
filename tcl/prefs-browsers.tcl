proc PrefsWidget-color {var w} {
    global TKGVars $var
    set f [frame $w.widget$var]
    grid columnconfigure $f 0 -weight 1
    set e [entry $f.entry -width 15 -textvariable TKGVars($var,setting)]
    grid $e -sticky nsew
    if [info exists TKGVars($var,scrollbar)] {
	$f configure -relief ridge -bd 2
	set s [scrollbar $f.sb -orient horizontal -width 8 \
		   -command "$e xview" -takefocus 0]
	$e configure -xscrollcommand "$s set"
	grid $s -sticky nsew
    }
    grid [button $f.color -text browse \
	      -command "PrefsColorBrowse $var"]\
	-row 0 -column 1
    trace variable TKGVars($var,setting) w "PrefsColorSet $var $f"
    TKGAddToHook Prefs_updatehook \
	"trace vdelete TKGVars($var,setting) w \"PrefsColorSet $var $f\""
    set TKGVars($var,setting) $TKGVars($var,setting)
}

proc PrefsColorBrowse {var} {
    global TKGVars
    if {![Empty [set c [tk_chooseColor]]]} {
	set TKGVars($var,setting) $c
    }
}

proc PrefsColorSet {var frame args} {
    global TKGVars TKG
    if [Empty $TKGVars($var,setting)] {
	set c [$frame cget -background]
	set h $c
	set r raised
    } else {
	eval set c $TKGVars($var,setting)
	set r flat
	set h $TKG(foreground)
    }
    $frame.color config -background $c -activebackground $c -relief $r \
	-highlightbackground $h
}	

proc PrefsWidget-font {var w} {
    global TKGVars $var
    set f [frame $w.widget$var]
    grid columnconfigure $f 0 -weight 1
    set e [entry $f.entry -width 35 -textvariable TKGVars($var,setting)]
    grid $e -sticky nsew
    if [info exists TKGVars($var,scrollbar)] {
	$f configure -relief ridge -bd 2
	set s [scrollbar $f.sb -orient horizontal -width 8 \
		   -command "$e xview" -takefocus 0]
	$e configure -xscrollcommand "$s set"
	grid $s -sticky nsew
    }
    grid [button $f.font -text browse \
	      -command "PrefsFontBrowse $var"]\
	-row 0 -column 1
    trace variable TKGVars($var,setting) w "PrefsFontSet $var $f"
    TKGAddToHook Prefs_updatehook \
	"trace vdelete TKGVars($var,setting) w \"PrefsFontSet $var $f\""
    set TKGVars($var,setting) $TKGVars($var,setting)
}

proc PrefsFontBrowse {var} {
    global TKGVars
    if {![Empty [set c [TKGChooseFont $TKGVars($var,setting)]]]} {
	set TKGVars($var,setting) $c
    }
}

proc PrefsFontSet {var frame args} {
    global TKGVars TKG
    if [Empty $TKGVars($var,setting)] {
	set f $TKG(generalfont)
    } else {
	set f $TKGVars($var,setting)
    }
    $frame.font config -font $f
}	

proc TKGChooseFont {font} {
    global TKG
    set w .choosefont
    set familys [font families]
    set sizes {6 8 9 10 11 12 14 16 18 20 24}
    set slants {roman italic}
    set weights {normal bold}
    
    TKGDialog choosefont \
	-title "Select Font" -wmtitle "Select Font"\
	-nodeiconify -nodismiss\
	-buttons {
	    {ok OK {destroy .choosefont}}
	    {cancel Cancel {set TKG(chooserfont) $TKG(origfont); destroy .choosefont}}
	}

    set TKG(origfont) $font

    grid [frame $w.optbuts] -row 2
    label $w.sample -text "Here is a SAMPLE of the font."
    catch {$w.sample configure -font $font}
    set font [$w.sample cget -font]
    catch {font create fontchooser}
    foreach param {family size slant weight} {
	font configure fontchooser -$param \
	     [font actual $font -$param]
	set TKG(choosefont.$param) [font actual $font -$param]
	eval tk_optionMenu $w.optbuts.$param TKG(choosefont.$param) [set ${param}s]
    }
    $w.sample configure -font fontchooser
    grid $w.optbuts.family $w.optbuts.size $w.optbuts.slant $w.optbuts.weight -row 2
    grid $w.sample -row 3 -rowspan 3
    foreach param {family size slant weight} {
	trace variable TKG(choosefont.$param) w TKGChooseFontUpdate
    }
    set TKG(chooserfont) $font
    TKGCenter $w
    tkwait window $w
    return $TKG(chooserfont)
}

proc TKGChooseFontUpdate {args} {
    global TKG
    update
    set params {family size slant weight}
    foreach param $params {
	set val $TKG(choosefont.$param)
	if {[catch {font configure fontchooser -$param $val}]} {
	    set val [font configure fontchooser -$param]
	    set TKG(choosefont.$param) $val
	}
    }
    set TKG(chooserfont) [list $TKG(choosefont.family) \
			      $TKG(choosefont.size) \
			      [list $TKG(choosefont.slant) \
				   $TKG(choosefont.weight)]]
}

    