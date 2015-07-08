# data format { {Misc~sEditors {Misc Editors} {filename.xpm {Name1 Name2 . . .}}} . . .}

proc PrefsWidget-FWLIcons {var w} {
    global $var TKGVars
    set ww $w.widget$var
    frame $ww
    grid columnconfigure $ww 0 -weight 1
    grid rowconfigure $ww 0 -weight 1
    HList fwlicons create \
	-pathname $ww.hlist\
	-data $TKGVars($var,setting)\
	-width 25\
	-double1 PrefsFWLIconsProps\
	-emptycommand PrefsFwlIns\
	-menu3 { 
	    {
		Properties PrefsFWLIconsProps
	    } {
		Insert PrefsFWLIconsIns
	    } { 
		Delete PrefsFWLIconsDel
	    }
	}
    scrollbar $ww.yscroll -command "$ww.hlist yview"
    scrollbar $ww.xscroll -orient horizontal -command "$ww.hlist xview"
    $ww.hlist configure -yscrollcommand "$ww.yscroll set"\
	-xscrollcommand "$ww.xscroll set"
    grid $ww.hlist $ww.yscroll -sticky nsew
    grid $ww.xscroll -sticky nsew
    TKGAddToHook Prefs_updatehook \
	"set TKGVars($var,setting) \[set fwlicons-hlparams(data)\]"
}

proc PrefsFWLIconsProps {} {
    upvar \#0 fwlicons-hlparams P
    set ped [lindex $P(selection) 0]
    set joinped [join $ped -]
    set item [HListGetItem fwlicons $ped]
    set type [lindex $item 0]
    set filename [lindex [lindex $item 2] 0]
    set namelist [lindex [lindex $item 2] 1]
    set new [PrefsFWLConfigure $filename $namelist]
    set filename [lindex new 0]
    set namelist [lindex new 1]
    set P(openimagefile,$type) $filename
    HListDelete fwlicons $ped
    HListInsert fwlicons $ped \
	[lreplace $item 2 2 [list $filename $namelist]]
}

proc PrefsFWLIconsIns {} {
    global fwlicons-hlparams
    upvar \#0 fwlicons-hlparams P
    set ped [lindex $P(selection) 0]
    if [Empty $ped] {set ped 0}
    TKGDialog bcins -title "Preferences: WindowList Icons: Insert"\
	-wmtitle "Preferences: WindowList Icons: Insert"\
	-nodismiss\
	-nodeiconify\
	-buttons {
	    {ok "OK" PrefsFWLIconsDoInsert}
	    {cancel "Cancel" {destroy .bcins}}
	}
    grid [frame .bcins.w] -row 2 -column 0 -sticky nsew
    grid columnconfigure .bcins.w 1 -weight 1
    grid [label .bcins.w.l2 -text "Nickname for Mailbox:"] -row 1 -column 0 -sticky w
    set i 0
    while {[set P(bcinsname) Mailbox$i;\
		string first $P(bcinsname) $P(data)] != -1} {incr i}
    grid [entry .bcins.w.e2 -textvariable fwlicons-hlparams(bcinsname)] \
	       -row 1 -column 1 -sticky we
    focus .bcins.w.e2
    bind .bcins.w.e2 <Key-Return> {
	.bcins.buttons.ok flash
	.bcins.buttons.ok invoke
    }
    set P(bcinsped) $ped
    TKGCenter .bcins
}

proc PrefsFWLIconsDoInsert {} {
    upvar \#0 fwlicons-hlparams P
    set name [string trim $P(bcinsname)]
    set item [list Icon $name]
    set ped [lindex $P(selection) 0]
    if [Empty $ped] {
	set ped 0
    }
    HList fwlicons insert $ped $item
    catch {destroy .bcins}
    BiffMailboxDeclare [TKGEncode $name]
}

proc PrefsFWLIconsDel {} {
    upvar \#0 fwlicons-hlparams P
    set ped [lindex $P(selection) 0]
    HList fwlicons delete $ped
}

