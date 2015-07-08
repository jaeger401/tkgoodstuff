# tkgoodstuff preferences stuff

# If typelist has variables, it is a terminal sheet
# If not, it has extension typelists, each of which is a 
# page for a tabnotebook.

# We expect TKGPrefs to get only legitimate typelists for a 
# window: a tabnotebook or a terminal sheet.  We draw the 
# sheet or notebook and buttons for Cancel Save Help 
# (no Back is necessary since we use less nesting now).


# Create a new preferences window
proc TKGPrefs {{typelist ""} {title Preferences} {prev .prefs}} {
    set name prefs[TKGEncode $typelist]
    set w .$name
    if [winfo exists $w] {
	wm deiconify $w
	raise $w
	return
    }
    if [Empty $typelist] {
	set buttonlist [ list \
			     [list cancel "Cancel" "PrefsCancel"]\
			     [list save "Save" PrefsSave]\
			     [list help "Help" whatever]]
    } else {
	set buttonlist [ list \
			     [list ok "Dismiss" "PrefsDismiss $w"] \
			     [list help "Help" whatever]]
    }
    TKGDialog $name \
	-wmtitle $title\
	-title $title\
	-nodeiconify\
	-nodismiss\
	-buttons $buttonlist
    label $w.comment -relief raised -borderwidth 1 \
	-textvariable Prefs_typecomment($w) \
	-justify left
    grid rowconfigure $w.comment 10 -minsize 16
    grid $w.comment -row 10 -sticky nsew -ipadx 10
    bind $w <Key-Escape> break
    #row 5 has weight 1
    grid [frame $w.main -relief raised -bd 1 -width 11i -height 7i] -row 5 -column 0 -sticky nsew
    grid propagate $w.main 0
    PrefsGoto $typelist $w.main
    TKGCenter $w
}

# win is the existing frame in which to draw our page or notebook.
# We look for a comment to put in the message window.
proc PrefsGoto {typelist win} {
    global TKGVars Prefs_typecomment
    set types [PrefsTypes $typelist]
    PrefsUpdate
    foreach child [winfo children $win] {
	destroy $child
    }
    if [info exists Prefs_typecomment(:[join $typelist ,])] {
	set Prefs_typecomment([winfo toplevel $win])\
	    $Prefs_typecomment(:[join $typelist ,])
    } else {
	set Prefs_typecomment([winfo toplevel $win]) ""
    }
    if ![Empty $types] {
	PrefsNotebook $types $typelist $win
    } else {
	PrefsPage $typelist $win
    }
}

# We look for a forced ordering of the notebook tabs (but we use only
# types that really exists, and we use ALL types that really exist).
proc PrefsTypes {typelist} {
    global TKGVars TKGVarnames TKGTypes Prefs_taborder
    set typelevel [llength $typelist]
    set typelevelplus [expr $typelevel + 1]
    set typelevelminus [expr $typelevel - 1]
    set types ""
    set varlist ""
    set ignoretypes {
	Clients Button LabelBox Stack Panel PanelButton PutPanel Swallow
    }
    catch {set types $TKGTypes(childtypes,[join $typelist ,])}
    foreach var [array names TKGVarnames] {
	upvar \#0 TKGVars($var,typelist) TL
	if {[Empty $typelist] && [In [lindex $TL 0] $ignoretypes]} continue
	if [string match [lrange $typelist -1 end] [lrange $TL -1 $typelevelminus]] {
	    if {[set type [lindex $TL $typelevel]] != {}} {
		if {[lsearch $types $type] == -1} {
		    lappend types $type
		}
	    }
	}
    }
    if [info exists Prefs_taborder(:[join $typelist ,])] {
	set otypes ""
	foreach type $Prefs_taborder(:[join $typelist ,]) {
	    if [In $type $types] {
		lappend otypes $type
	    }
	}
	foreach type $types {
	    if ![In $type $otypes] {
		lappend otypes $type
	    }
	}
	set types $otypes
    }
    return $types
}

proc PrefsPage {typelist w} {
    global TKGTypes TKGVars
    foreach child [winfo children $w] {
	destroy $child
    }
    set ww $w.main
    frame $ww -borderwidth 0
    set varlist ""
    catch {set varlist $TKGTypes([join $typelist ,])}
    TKGAddToHook Prefs_updatehook "set Prefs_CurrentVars \{$varlist\}"
    foreach var $varlist {
	PrefsWidget $var $ww
	if ![Empty $TKGVars($var,help)] {
	    lappend helpvars $var
	}
    }
    set helpbut [winfo toplevel $ww].buttons.help 
    if [info exists helpvars] {
	$helpbut configure -state normal\
	    -command [list PrefsVarHelp $helpvars]
    } else {
	$helpbut configure -state disabled
    }	
    update
    if {[winfo reqheight $ww] > [winfo height $w]} {
	vscrollcanvas $ww $w
    } else {
	grid $ww
    }
}

proc vscrollcanvas {f1 f2} {
    grid columnconfigure $f2 0 -weight 1
    grid rowconfigure $f2 0 -weight 1
    canvas $f2.c -yscrollcommand "$f2.s set" \
	-scrollregion [list 0 0 [winfo reqwidth $f1] [winfo reqheight $f1]]
    grid $f2.c -row 0 -column 0 -sticky nsew
    $f2.c create window 0 0 -window $f1 -anchor nw
    scrollbar $f2.s -orient vertical -command "$f2.c yview"
    grid $f2.s -row 0 -column 1 -sticky ns
    raise $f1
}

proc PrefsNotebook {types typelist w} {
    global Prefs_typelabel
    update idletasks
    for {set i 0} {$i < [llength $types]} {incr i} {
	set type [lindex $types $i]
	if [info exists Prefs_typelabel($type)] {
	    set label $Prefs_typelabel($type)
	} else {
	    set label $type
	}
	lappend pagelist [list $label {}]
    }
    TabNB $w.tnb -pages $pagelist \
	-width [expr [winfo reqwidth $w] - 20] \
	-height [expr [winfo reqheight $w] - 20] \
	-changecallback [list PrefsNBCallback $typelist $types]
    grid $w.tnb
}

proc PrefsNBCallback {typelist types w pagenum} {
    PrefsUpdate
    PrefsGoto [concat $typelist [lindex $types $pagenum]] $w.page
#    PrefsPage [concat $typelist [lindex $types $pagenum]] $w.page
}

proc PrefsWidget {var w} {
    global TKGVars $var
    if ![info exists TKGVars($var,nolabel)] {
	message $w.lab$var -text $TKGVars($var,label) -width 8c
	set label $w.lab$var
    } else {
	set label ""
    }
    set TKGVars($var,setting) $TKGVars($var,current)
    if ![info exists TKGVars($var,vartype)] {set TKGVars($var,vartype) entry}
    PrefsWidget-$TKGVars($var,vartype) $var $w
    if ![info exists TKGVars($var,nodefault)] {
	button $w.def$var -text "Default" -command "PrefsUseDefault $var $w"\
	    -takefocus 0
	set button $w.def$var
    } else {
	set button ""
    }
    if [string match $var TKG(config)] {
	set sticky "ns"
    } else {
	set sticky "w"
    }
    eval grid $label $w.widget$var $button -sticky $sticky -padx 3 -pady 3
}

proc PrefsVarHelp {vars} {
    global TKGVars
    TKGDialog prefsvarhelp -title "Preferences Help" -wmtitle "Preferences Help"\
	-text ""
    set w .prefsvarhelp.view.text
    $w tag configure label -underline 1
    $w tag configure help -lmargin1 20 -lmargin2 20
    $w configure -state normal
    foreach var $vars {
	$w insert end "\n$TKGVars($var,label) . . .\n\n" label \
	    "$TKGVars($var,help)\n\n" help
    }
    $w configure -state disabled
}

proc PrefsWidget-boolean {var w} {
    global TKGVars
    checkbutton $w.widget$var -variable TKGVars($var,setting)
}

proc PrefsWidget-optionMenu {var w} {
    global TKGVars
    frame $w.widget$var
    set c "tk_optionMenu $w.widget$var.om TKGVars($var,setting)"
    foreach option $TKGVars($var,optionlist) {
	append c " $option"
    }
    eval $c
    grid $w.widget$var.om -in $w.widget$var -sticky w
}

proc PrefsWidget-radio {var w} {
    global TKGVars
    frame $w.widget$var
    if ![info exists TKGVars($var,radioside)] {
	set TKGVars($var,radioside) top
    }
    set i 0
    foreach l $TKGVars($var,radiolist) {
	incr i
	pack [radiobutton $w.widget$var.b$i\
		  -variable TKGVars($var,setting) -value [lindex $l 1] \
		  -text [lindex $l 0]] \
	    -in $w.widget$var -side $TKGVars($var,radioside) -anchor w
    }
}

proc PrefsWidget-text {var w} {
    global TKGVars Prefs_updatehook
    set H 7 
    set W 50
    if [info exists TKGVars($var,textsize)] {
	scan $TKGVars($var,textsize) "%dx%d" W H
    }
    frame $w.widget$var
    set ww $w.widget$var.text
    frame $ww
    grid columnconfigure $ww 0 -weight 1
    grid rowconfigure $ww 0 -weight 1
    text $ww.text -wrap none -height $H -width $W\
	-yscrollcommand "$ww.yscroll set"\
	-xscrollcommand "$ww.xscroll set"
    scrollbar $ww.yscroll -command "$ww.text yview" -takefocus 0
    scrollbar $ww.xscroll -orient horizontal -command "$ww.text xview" -takefocus 0
    grid $ww.text $ww.yscroll -sticky nsew
    grid $ww.xscroll -sticky nsew
    global $var
    $ww.text insert 1.0 $TKGVars($var,setting)
    grid $ww -sticky nsew
    TKGAddToHook Prefs_updatehook \
	"set t \[$ww.text get 1.0 end\]
                 set t \[string range \$t 0 \[expr \[string length \$t\] - 2\]\]
                 set TKGVars($var,setting) \$t
                 unset t \n"
}

proc PrefsWidget-entry {var w} {
    global TKGVars $var
    set f [frame $w.widget$var]
    grid columnconfigure $f 0 -weight 1
    set e [entry $f.entry -width 50 \
	       -textvariable TKGVars($var,setting)]
    grid $e -sticky nsew
    if [info exists TKGVars($var,scrollbar)] {
	$f configure -relief ridge -bd 2
	set s [scrollbar $f.sb -orient horizontal -width 8 \
		   -command "$e xview" -takefocus 0]
	$e configure -xscrollcommand "$s set"
	grid $s -sticky nsew
    }
}

proc PrefsUseDefault {var w} {
    global TKGVars
    set TKGVars($var,setting) $TKGVars($var,default)
    if {$TKGVars($var,vartype) == "text"} {
	set tw $w.widget$var.text.text
	$tw delete 1.0 end
	$tw insert 1.0 [set TKGVars($var,setting)]
    }
}

proc PrefsUpdate {} {
    TKGDoHook Prefs_updatehook
    TKGResetHook Prefs_updatehook
    global Prefs_CurrentVars TKGVars
    if ![info exists Prefs_CurrentVars] return
    foreach var $Prefs_CurrentVars {
	set TKGVars($var,current) $TKGVars($var,setting)
    }
}

proc PrefsCheckDef {var} {
    global TKGVars $var
    if { $TKGVars($var,vartype) != "radio"} {
	set TKGVars($var,isdefault)\
	    [string match [list [set $var]] [list [subst [subst $TKGVars($var,default)]]]]
    } else {
	set TKGVars($var,isdefault)\
	    [string match [list [set $var]] [list [subst [subst [lindex [lindex $TKGVars($var,default) 0] 1]]]]]
    }
}

proc PrefsCancel {} {
    destroy .prefs
}

proc PrefsDismiss {w} {
    PrefsUpdate
    destroy $w
    if [winfo exists .prefs] {
	raise .prefs
	PrefsGoto "" .prefs.main
    }
}

proc PrefsSave {{action 0}} {
    PrefsUpdate
    global TKGVars TKGVarnames TKG
    set outstring "\# tkgoodstuff config file format $TKG(configfileformatversion)\n"
    foreach var [lsort [array names TKGVarnames]] {
	if {($var == "TKG(config)")} continue
	if {"a$TKGVars($var,current)" == "a$TKGVars($var,default)"} continue
	append outstring "TKGSet $var [list $TKGVars($var,current)]\n"
    }
    append outstring "\n-------Configuration-------\n"
    append outstring [set TKGVars(TKG(config),current)]
    
    catch "exec cp $TKG(rc) $TKG(rc)~"
    if [catch {set id [open $TKG(rc) w]}] {
	TKGError "Can't open Preferences file for writing. ($TKG(rc))"
	return
    }
    puts -nonewline $id $outstring
    close $id
    catch {destroy .prefs}
    if [string match $action restart] TKGRestart
    if [string match $action quiet] return
    TKGDialog -title "Preferences Saved"\
	-message "For the changes to take effect, you must restart tkgoodstuff."\
	-buttons { { restart Restart TKGRestart } }
}
