proc PrefsWidget-biff {var w} {
    global $var TKGVars
    set ww $w.widget$var
    frame $ww
    grid columnconfigure $ww 0 -weight 1
    grid rowconfigure $ww 0 -weight 1
    HList biff create \
	-pathname $ww.hlist\
	-data $TKGVars($var,setting)\
	-openimagefile(Mailbox) mailer.xpm\
	-width 25\
	-double1 PrefsBiffProps\
	-emptycommand PrefsBiffIns\
	-menu3 { 
	    {
		Properties PrefsBiffProps
	    } {
		Insert PrefsBiffIns
	    } { 
		Delete PrefsBiffDel
	    }
	}
    scrollbar $ww.yscroll -command "$ww.hlist yview"
    scrollbar $ww.xscroll -orient horizontal -command "$ww.hlist xview"
    $ww.hlist configure -yscrollcommand "$ww.yscroll set"\
	-xscrollcommand "$ww.xscroll set"
    grid $ww.hlist $ww.yscroll -sticky nsew
    grid $ww.xscroll -sticky nsew
    TKGAddToHook Prefs_updatehook \
	"set TKGVars($var,setting) \[set biff-hlparams(data)\]"
}

proc PrefsBiffProps {} {
    upvar \#0 biff-hlparams P
    set ped [lindex [HListGetSelectedPeds biff] 0]
    set joinped [join $ped -]
    set item [HListGetItem biff $ped]
    set mbname [lindex $item 1]
    set mailbox [TKGEncode $mbname]
    PrefsUpdate
    TKGPrefs [list Clients Biff Mailboxes $mbname] \
	"$mbname Mailbox Preferences" .prefsClients~sBiff
}

proc PrefsBiffIns {} {
    global biff-hlparams
    upvar \#0 biff-hlparams P
    set ped [lindex [HListGetSelectedPeds biff] 0]
    if [Empty $ped] {set ped 0}
    TKGDialog bcins -title "Preferences: Biff: Insert"\
	-wmtitle "Preferences: Biff: Insert"\
	-nodismiss\
	-nodeiconify\
	-buttons {
	    {ok "OK" PrefsBiffDoInsert}
	    {cancel "Cancel" {destroy .bcins}}
	}
    grid [frame .bcins.w] -row 2 -column 0 -sticky nsew
    grid columnconfigure .bcins.w 1 -weight 1
    grid [label .bcins.w.l2 -text "Nickname for Mailbox:"] -row 1 -column 0 -sticky w
    set i 0
    while {[set P(bcinsname) Mailbox$i;\
		string first $P(bcinsname) $P(data)] != -1} {incr i}
    grid [entry .bcins.w.e2 -textvariable biff-hlparams(bcinsname)] \
	       -row 1 -column 1 -sticky we
    focus .bcins.w.e2
    bind .bcins.w.e2 <Key-Return> {
	.bcins.buttons.ok flash
	.bcins.buttons.ok invoke
    }
    set P(bcinsped) $ped
    TKGCenter .bcins
}

proc PrefsBiffDoInsert {} {
    upvar \#0 biff-hlparams P
    set name [string trim $P(bcinsname)]
    set item [list Mailbox $name]
    set ped [lindex [HListGetSelectedPeds biff] 0]
    if [Empty $ped] {
	set ped 0
    }
    HList biff insert $ped $item
    catch {destroy .bcins}
    BiffMailboxDeclare [TKGEncode $name]
}

proc PrefsBiffDel {} {
    upvar \#0 biff-hlparams P
    set ped [lindex [HListGetSelectedPeds biff] 0]
    HList biff delete $ped
}

