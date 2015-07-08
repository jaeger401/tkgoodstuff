# Calc (calculator) client for tkgoodstuff

# TODO: 
# - implement memory
# - implement auxilliary keypad of other functions

proc CalcDeclare {} {
    set Prefs_taborder(:Clients,Calc) "Misc Geometry Colors Button"
    TKGDeclare Calc(lines) 10 -typelist [list Clients Calc Geometry]\
	-label "Lines in display"
    TKGDeclare Calc(columns) 30 -typelist [list Clients Calc Geometry]\
	-label "Columns in display"
    TKGColorDeclare Calc(hotcolor) \#bcdfff [list Clients Calc Colors]
    TKGDeclare Calc(makebutton) 1 -typelist [list Clients Calc Misc]\
	-label "Produce a button"\
	-help "Otherwise, CalcPopup is available as a Menu client tcl command"\
	-vartype boolean
    TKGDeclare Calc(format) dec -typelist [list Clients Calc Misc]\
	-label "Default format" \
	-vartype optionMenu\
	-optionlist {dec hex oct}
    TKGColorDeclare Calc(deccolor) black [list Clients Calc Colors]
    TKGColorDeclare Calc(hexcolor) purple [list Clients Calc Colors]
    TKGColorDeclare Calc(octcolor) gold4 [list Clients Calc Colors]
    TKGDeclare Calc(text) Calculator -typelist [list Clients Calc Button Misc]\
	-label "Label text"
    TKGDeclare Calc(imagefile) %calc\
	-typelist [list Clients Calc Button] -label "Icon file"
    ConfigDeclare Calc ClientButton1 Calc [list Clients Calc Button]
    ConfigDeclare Calc ClientButton3 Calc [list Clients Calc Button]
}
    
proc CalcCreateWindow {} {
    if [TKGReGrid CalcButton] return
    uplevel {
	set Calc(f,dec) g
	set Calc(f,hex) x
	set Calc(f,oct) o
	set Calc(p,dec) e
	set Calc(p,hex) d
	set Calc(p,oct) d
	set Calc(base,dec) 10
	set Calc(base,hex) 16
	set Calc(base,oct) 8
	set tcl_precision 10
    }
    global Calc
    if $Calc(makebutton) {
	lappend C TKGMakeButton CalcButton -balloon Calculator
	foreach switch {
	    iconside ignore font imagefile text foreground background
	    activeforeground activebackground relief
	} {
	    lappend C -$switch $Calc($switch)
	}
	set w [eval $C]
	bind $w <1> +CalcPopup
    }
}

proc CalcPopup {} {
    upvar #0 CalcButton-params P
    if ![string match [$P(pathname) cget -relief] sunken] {
	$P(pathname) configure -relief sunken
    }
    global Calc CalcSB
    uplevel {
	set Calc(oldformat) $Calc(format)
	set Calc(prev) ""
	set Calc(expr) ""
	set Calc(leftparens) 0
	set Calc(rightparens) 0
	set Calc(justresponded) 0
    }
    set w .calc
    if [winfo exists $w] {
	wm deiconify $w
	focus $w
	raise $w
	return
    }
    toplevel $w
    wm withdraw $w
    wm title $w "Calculator"
    wm iconname $w "Calc"
    wm protocol $w WM_DELETE_WINDOW CalcDone
    
    pack [frame $w.menu -relief raised -bd 2] $w.menu -side top -fill x
    
    set m $w.menu.help.m
    pack [menubutton $w.menu.help -text "Help" -menu $m] -side right
    menu $m
    $m add command -label "About Calc" -command CalcAbout -underline 0
    $m add separator
    $m add command -label "Help" -command CalcHelp -underline 0
    
    pack [frame $w.middle]
    
    set ww $w.middle.calcentry 
    pack [frame $ww  -relief raised -bd 2] -side top

    pack [frame $ww.view] -side left -fill x -pady .3c -padx .3c
    text $ww.view.text -width $Calc(columns) -height $Calc(lines)\
	-takefocus 0 -yscrollcommand "$ww.view.scrollbar set" \
	-relief sunken -borderwidth 2 -state disabled -wrap word
    $ww.view.text tag configure all -justify right
    $ww.view.text tag configure tot -foreground red
    $ww.view.text tag configure dec -foreground $Calc(deccolor)
    $ww.view.text tag configure hex -foreground $Calc(hexcolor)
    $ww.view.text tag configure oct -foreground $Calc(octcolor)
    set Calc(textwindow) $ww.view.text
    pack $ww.view.text -side left -fill both -expand 1
    scrollbar $ww.view.scrollbar -command "$ww.view.text yview"
    pack $ww.view.scrollbar -side left -fill y -padx 2
    $ww.view.text configure -state normal

    frame $ww.mid 
    frame $ww.mid.formats 
    pack [radiobutton $ww.mid.formats.dec -variable Calc(format) -text dec \
	      -value dec -fg $Calc(deccolor)] -side top -anchor nw -expand n
    pack [radiobutton $ww.mid.formats.hex -variable Calc(format) -text hex \
	      -value hex -fg $Calc(hexcolor)] -side top -anchor nw -expand n
    pack [radiobutton $ww.mid.formats.oct -variable Calc(format) -text oct \
	      -value oct -fg $Calc(octcolor)] -side top -anchor nw -expand n
    pack $ww.mid.formats -side left -fill both -expand n
    trace variable Calc(format) w CalcReformat
    pack $ww.mid.formats -side top -fill x -expand n 

    set www $ww.mid.mem
    frame $www
    global m1 m2
    foreach m {m1 m2} {
	frame $www.$m -relief ridge -bd 2
	pack [entry $www.$m.entry -textvariable $m]
	frame $www.$m.buttons
	pack [button $www.$m.buttons.store -text Store -command "CalcMemStore $m"] -side left
	pack [button $www.$m.buttons.recall -text Recall -command "CalcMemRecall $m"] -side left
	pack $www.$m.buttons
	pack $www.$m -side top
    }
    pack $www -side top -fill x -expand n
    pack $ww.mid
    pack $ww

    set ww $w.bottom
    pack [frame $ww] -fill both -expand y
    pack [frame $ww.main -relief raised -bd 2] -side left -fill both -expand y
    pack [frame $ww.main.nums] -side left -fill both -expand y
    pack [frame $ww.main.cmds] -side left -fill both
    CalcReformat

    set www $ww.main.cmds
    global TKG
    set i 0
    foreach c {/ * - +} {
	set b [button $www.b$i -text $c -command "CalcInsert $c"\
		   -font tkgHugebold]
	pack $b -fill both -expand n -ipadx 3 -ipady 3
	incr i
    }
    set b [button $www.b$i -text = -command {CalcInsert =}\
	       -font tkgHugebold]
    pack $b -expand y -fill both -ipadx 10 -ipady 10

    frame $w.buttons 
    button $w.buttons.c -command CalcC -text "C" 
    pack $w.buttons.c -side left -expand y -fill y -padx .4c -pady .4c
    button $w.buttons.ca -command CalcCA -text "CA" 
    pack $w.buttons.ca -side left -expand y -fill y -padx .4c -pady .4c 
    button $w.buttons.done -command CalcDone -text "Done" 
    pack $w.buttons.done -side left -expand y -fill y -padx .4c -pady .4c
    pack $w.buttons -fill x -expand y

    TKGCenter $w

}

proc CalcWidgetInsert {s {tags {}}} {
    .calc.middle.calcentry.view.text insert end \
	$s [concat all $tags]
    .calc.middle.calcentry.view.text see end
}

proc CalcReformat args {
    global Calc
    set tw .calc.middle.calcentry.view.text
    set l [$tw get "end - 1 chars linestart" "end - 1 chars" ]
    if ![Empty $l] {
	$tw delete "end - 1 chars linestart" "end - 1 chars" 
	if [catch {set l [CalcFormat [CalcParse $l $Calc(oldformat)]]}] {
	   CalcC
	} else { 
	    CalcWidgetInsert $l $Calc(format)
	}
    }
    if $Calc(justresponded) {
	set l [$tw get "end - 1 lines linestart" "end - 1 lines lineend" ]
	REPORT l
	if ![catch {set l [CalcFormat [CalcParse $l $Calc(oldformat)]]}] {
	REPORT l
	    $tw delete "end - 1 lines linestart" "end - 1 lines lineend" 
	    $tw insert "end - 1 lines lineend" $l "$Calc(format) all"
	    set Calc(expr) "[CalcParse $l] "
	    REPORT Calc(expr)
	}
    }
    set Calc(oldformat) $Calc(format)

    set bw .calc.bottom.main.nums
    set nums(dec) {{7 8 9} {4 5 6} {1 2 3} {0 . +/-}}
    set nums(hex) {{c d e f} {8 9 a b} {4 5 6 7} {0 1 2 3}}
    set nums(oct) {{4 5 6 7} {0 1 2 3}}
    foreach b [winfo children $bw] {destroy $b}
    set r 0
    foreach l $nums($Calc(format)) {
	set f [frame $bw.row$r]
	pack $f -fill both -anchor w -expand y
	set c 0
	foreach i $l {
	    set b [button $f.but$c -text $i -command "CalcInsert $i"]
	    pack $b -side left -expand y -fill both
	    incr c
	}
	incr r
    }
}

proc CalcInsert {c} {
    global Calc
    set tw .calc.middle.calcentry.view.text
    set l [$tw get "end - 1 chars linestart" "end - 1 chars" ]
    puts "PRESSED $c";flush stdout
    switch -regexp -- $c {
	[0-9a-f] {
	    if {$Calc(justresponded)} {
		set Calc(justresponded) 0
		set Calc(prev) ""
		CalcWidgetInsert "\n"
	    }
	    if ![catch {CalcParse $l$c} err] {
		CalcWidgetInsert $c $Calc(format)
	    } else {puts $err ; flush stdout}
	} \\+\\/\\- {
	    if {!$Calc(justresponded) && [string match $Calc(format) dec]} {
		if [string match "-*" $l] {
		    $tw delete {end - 1 chars linestart}
		} else {
		    $tw insert {end - 1 chars linestart} "-" all
		}
	    }
	} \\. {
	    if {[string match $Calc(format) dec] &&\
		    ![catch {CalcParse $l.0}] } {
		CalcWidgetInsert .
	    }
	} \[-+/^%*\] {
	    if {$Calc(justresponded)} {
		set Calc(expr) [CalcParse $l]
		REPORT Calc(expr)
		set Calc(justresponded) 0
		set Calc(prev) ""
		CalcWidgetInsert "\n"
	    } elseif ![Empty $l] {
		append Calc(expr) "[CalcParse $l] "
		REPORT Calc(expr)
		CalcWidgetInsert "\n"
		set Calc(prev) ""
	    } 
	    if [regexp \[-+/^%*\\(\] $Calc(prev)] {
		bell
	    } else {
		CalcWidgetInsert "$c  \n"
		append Calc(expr) "$c "
		REPORT Calc(expr)
		set Calc(prev) $c
	    }
        } = {
	    if ![Empty $l] {
		append Calc(expr) [CalcParse $l]
		REPORT Calc(expr)
		set Calc(prev) ""
	    }
	    if {![Empty $Calc(expr)] && \
		    ![catch {set r [eval expr $Calc(expr)]}]} {
		set s [CalcFormat $r]
		CalcWidgetInsert "\n=\n" tot
		CalcWidgetInsert $s
		set Calc(justresponded) 1
		set Calc(expr) ""
		REPORT Calc(expr)
		set Calc(prev) "[CalcParse $r] "
		set Calc(leftparens) 0
		set Calc(rightparens) 0
	    }
	} default { 
	    puts "couldn't match $c"; flush stdout
	}
    }
}

proc CalcParse {s {fmt {}}} {
    global Calc
    if [Empty $fmt] {set fmt $Calc(format)}
    set m "0123456789abcdef"
    set n 0
    set mult 0
    foreach c [split $s {}] {
	switch -regexp -- $c {
	    [0-9a-f] {
		set c [string first $c $m]
		if {$mult == 0} {
		    set n [expr ($n * $Calc(base,$fmt)) + $c]
		} else {
		    set n [expr $n + ($mult * $c)]
		    set mult [expr $mult * .1]}
	    } \\. {
		set mult .1
	    }
	}
    }
    puts "PARSE in format $fmt of $s is $n"
    return [CalcFormat $n $Calc(p,$Calc(format))]
}    

proc CalcFormat {s {fmt {}}} {
    global Calc
    if [Empty $fmt] {set fmt $Calc(f,$Calc(format))}
    set o [format %$fmt $s]
    puts "FORMAT in format $fmt of $s is $o"
    return $o
}

proc CalcCA {} {
    uplevel 0 {
	set Calc(expr) ""
	CalcWidgetInsert "\n"
    }
}

proc CalcC {} {
    set tw .calc.middle.calcentry.view.text
    $tw delete {end - 1 chars linestart} {end - 1 chars}
}

proc CalcDone {} {
    set w .calc
    upvar #0 CalcButton-params P
    catch {$P(pathname) configure -relief $P(relief)}
    destroy $w
}
