proc PrefsWidget-menu {var w} {
    global $var TKGVars
    set ww $w.widget$var
    frame $ww
    grid columnconfigure $ww 0 -weight 1
    grid rowconfigure $ww 0 -weight 1
    HList menu create \
	-pathname $ww.hlist\
	-data $TKGVars($var,setting)\
	-openimagefile(Menu) menu.xpm\
	-openimagefile(TKGMenu) menu.xpm\
	-openimagefile(Exec) exec.xpm\
	-openimagefile(Separator) separator.xpm\
	-openimagefile(Tcl) tcl.xpm\
	-openimagefile(Run) run.xpm\
	-allowedchildren [list Menu *]\
	-width 50\
	-double1 PrefsMenuProps\
	-emptycommand PrefsMenuIns\
	-menu3 { 
	    {
		Properties PrefsMenuProps
	    } {
		Insert PrefsMenuIns
	    } { 
		Delete PrefsMenuDel
	    }
	}
    scrollbar $ww.yscroll -command "$ww.hlist yview"
    scrollbar $ww.xscroll -orient horizontal -command "$ww.hlist xview"
    $ww.hlist configure -yscrollcommand "$ww.yscroll set"\
	-xscrollcommand "$ww.xscroll set"
    grid $ww.hlist $ww.yscroll -sticky nsew
    grid $ww.xscroll -sticky nsew
    TKGAddToHook Prefs_updatehook \
	"set TKGVars($var,setting) \[set menu-hlparams(data)\]"
}

proc PrefsMenuProps {} {
    upvar \#0 menu-hlparams P
    set ped [lindex [HListGetSelectedPeds menu] 0]
    set joinped [join $ped -]
    set item [HListGetItem menu $ped]
    set type [lindex $item 0]
    set P(mcpropsname) [lindex $item 1]
    set P(mcpropscommand) [lindex [lindex $item 2] \
			       [expr [lsearch [lindex $item 2] -command] + 1]]
    switch -regexp $type {
	^Menu$|Separator|Run|TKGMenu {
	    bell;return
	} Exec {
	    set P(mcpropstype) "Execute"
	} Tcl {
	    set P(mcpropstype) "Tcl Command"
	}
    }
    TKGDialog mcprops -title "Menu Item Properties: $P(mcpropstype)"\
	-wmtitle "Menu Item Properties: $P(mcpropstype)"\
	-nodismiss\
	-nodeiconify\
	-buttons {
	    {ok "OK" PrefsMenuDoProps}
	    {help "Help" PrefsMenuPropsHelp}
	    {cancel "Cancel" {destroy .mcprops}}
	}
    grid [frame .mcprops.w] -row 2 -column 0 -sticky nsew
    grid columnconfigure .mcprops.w 1 -weight 1
    grid [label .mcprops.w.l2 -text "Label:"] -row 1 -column 0 -sticky w
    setifunset P(mcpropsba) before
    grid [entry .mcprops.w.e2 -textvariable menu-hlparams(mcpropsname) -width 40] \
	       -row 1 -column 1 -sticky we
    grid [label .mcprops.w.l4 -text "Command:"] -row 3 -column 0 -sticky w
    grid [entry .mcprops.w.e4 -textvariable menu-hlparams(mcpropscommand)\
	     -xscrollcommand ".mcprops.w.s4 set"] \
	-row 3 -column 1 -sticky we
    grid [scrollbar .mcprops.w.s4 -command ".mcprops.w.e4 xview" \
	      -orient horizontal -width 8] -row 4 -column 1  -sticky we
    set P(mcpropsped) $ped
    TKGCenter .mcprops
}

proc PrefsMenuDoProps {} {
    upvar \#0 menu-hlparams P
    set type $P(mcpropstype)
    if [string match $type "Execute"] {set type Exec}
    if [string match $type "Tcl Command"] {set type Tcl}
    set name [string trim $P(mcpropsname)]
    set item [list $type $name [list -command $P(mcpropscommand)]]
    set ped [lindex [HListGetSelectedPeds menu] 0]
    HList menu delete $ped
    HList menu insert $ped $item
    catch {destroy .mcprops}
}

proc PrefsMenuPropsHelp {} {
    TKGDialog mcpropshelp -title Help -wmtitle "Preferences Help"\
	-message "If the command is blank, the label will be used
as the command. 

The string \"@selection@\" in a command will be replaced with
the current X selection when the command is executed.
"
}

proc PrefsMenuIns {} {
    global menu-hlparams
    upvar \#0 menu-hlparams P
    set ped [lindex [HListGetSelectedPeds menu] 0]
    if [Empty $ped] {set ped 0}
    TKGDialog mcins -title "Preferences: Menu: Insert"\
	-wmtitle "Preferences: Menu: Insert"\
	-nodismiss\
	-nodeiconify\
	-buttons {
	    {ok "OK" PrefsMenuDoInsert}
	    {help "Help" PrefsMenuInsertHelp}
	    {cancel "Cancel" {destroy .mcins}}
	}
    grab .mcins
    grid [frame .mcins.w] -row 2 -column 0 -sticky nsew
    grid columnconfigure .mcins.w 1 -weight 1
    grid [label .mcins.w.l1 -text "Insert:"] -row 0 -column 0 -sticky w
    setifunset P(mcinstype) Execute
    tk_optionMenu .mcins.w.om1 menu-hlparams(mcinstype) \
       Execute Menu "Tcl Command" Separator "tkgoodstuff Menu" "Run . . ."
    grid .mcins.w.om1 -row 0 -column 1 -sticky w
    grid [label .mcins.w.l2 -text "Label:"] -row 1 -column 0 -sticky w
    set i 0
    while {[set P(mcinsname) Item$i;\
		string first $P(mcinsname) $P(data)] != -1} {incr i}
    grid [entry .mcins.w.e2 -textvariable menu-hlparams(mcinsname)] \
	       -row 1 -column 1 -sticky we
    grid [label .mcins.w.l4 -text "Command:"] -row 3 -column 0 -sticky w
    grid [entry .mcins.w.e4 -textvariable menu-hlparams(mcinscommand)\
	     -xscrollcommand ".mcins.w.s4 set"] \
	-row 3 -column 1 -sticky we
    grid [scrollbar .mcins.w.s4 -command ".mcins.w.e4 xview" \
	      -orient horizontal -width 8] -row 4 -column 1  -sticky we
    bind .mcins.w.e2 <Key-Return> {
	.mcins.buttons.ok flash
	.mcins.buttons.ok invoke
    }
    set P(mcinsped) $ped
    TKGCenter .mcins
}

proc PrefsMenuInsertHelp {} {
    TKGDialog mcinshelp -title Help -wmtitle "Preferences Help"\
	-message "The label is ignored for Separators, the \"Run . . .\"
command, and the tkgoodstuff Menu.

The command is ignored for all execept Execute items 
(which call for a unix command), and Tcl Command items.

The \"within\" option is for putting a new item within a sub-menu.
"
}

proc PrefsMenuDoInsert {} {
    upvar \#0 menu-hlparams P
    set type $P(mcinstype)
    if [string match $type "Run . . ."] {set type Run}
    if [string match $type "Execute"] {set type Exec}
    if [string match $type "Tcl Command"] {set type Tcl}
    if [string match $type "tkgoodstuff Menu"] {set type TKGMenu}
    set name [string trim $P(mcinsname)]
    switch -regexp -- $type {
	Exec|Tcl {
	    set item [list $type $name [list -command $P(mcinscommand)]]
	} Run {
	    set item [list $type "Run . . ."]
	} Separator { 
	    set item [list $type "-------"]
	} TKGMenu {
	    set item [list $type "tkgoodstuff Menu"]
	} ^Menu$ {
	    set item [list Menu $name {} {}]
	}
    }
    set ped [lindex [HListGetSelectedPeds menu] 0]
    if [Empty $ped] {
	set ped 0
    } else {
	switch $P(relation) {
	    after {
		set ped [lreplace $ped end end [expr [lindex $ped end] + 1]]
	    } within {
		set parent [HListGetItem menu $ped]
		if [string match [lindex $parent 0] Menu] {
		    lappend ped 0
		}
	    }
	}
    }
    HList menu insert $ped $item
    catch {destroy .mcins}
}

proc PrefsMenuDel {} {
    upvar \#0 menu-hlparams P
    set ped [lindex [HListGetSelectedPeds menu] 0]
    HList menu delete $ped
}

