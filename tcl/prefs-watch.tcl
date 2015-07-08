proc PrefsWidget-watch {var w} {
    global $var TKGVars
    set ww $w.widget$var
    frame $ww
    grid columnconfigure $ww 0 -weight 1
    grid rowconfigure $ww 0 -weight 1
    HList watch create \
	-pathname $ww.hlist\
	-data $TKGVars($var,setting)\
	-openimagefile(File) watchunchanged-sm.xpm\
	-width 25\
	-double1 PrefsWatchProps\
	-emptycommand PrefsWatchIns\
	-menu3 { 
	    {
		Properties PrefsWatchProps
	    } {
		Insert PrefsWatchIns
	    } { 
		Delete PrefsWatchDel
	    }
	}
    scrollbar $ww.yscroll -command "$ww.hlist yview"
    scrollbar $ww.xscroll -orient horizontal -command "$ww.hlist xview"
    $ww.hlist configure -yscrollcommand "$ww.yscroll set"\
	-xscrollcommand "$ww.xscroll set"
    grid $ww.hlist $ww.yscroll -sticky nsew
    grid $ww.xscroll -sticky nsew
    TKGAddToHook Prefs_updatehook \
	"set TKGVars($var,setting) \[set watch-hlparams(data)\]"
}

proc PrefsWatchProps {} {
    upvar \#0 watch-hlparams P
    set ped [lindex [HListGetSelectedPeds watch] 0]
    set joinped [join $ped -]
    set item [HListGetItem watch $ped]
    set mbname [lindex $item 1]
    set file [TKGEncode $mbname]
    PrefsUpdate
    TKGPrefs [list Clients Watch Files $mbname] \
	"$mbname File Preferences" .prefsClients~sWatch
}

proc PrefsWatchIns {} {
    global watch-hlparams
    upvar \#0 watch-hlparams P
    set ped [lindex [HListGetSelectedPeds watch] 0]
    if [Empty $ped] {set ped 0}
    TKGDialog bcins -title "Preferences: Watch: Insert"\
	-wmtitle "Preferences: Watch: Insert"\
	-nodismiss\
	-nodeiconify\
	-buttons {
	    {ok "OK" PrefsWatchDoInsert}
	    {cancel "Cancel" {destroy .bcins}}
	}
    grid [frame .bcins.w] -row 2 -column 0 -sticky nsew
    grid columnconfigure .bcins.w 1 -weight 1
    grid [label .bcins.w.l2 -text "Nickname for File:"] -row 1 -column 0 -sticky w
    set i 0
    while {[set P(bcinsname) File$i;\
		string first $P(bcinsname) $P(data)] != -1} {incr i}
    grid [entry .bcins.w.e2 -textvariable watch-hlparams(bcinsname)] \
	       -row 1 -column 1 -sticky we
    focus .bcins.w.e2
    bind .bcins.w.e2 <Key-Return> {
	.bcins.buttons.ok flash
	.bcins.buttons.ok invoke
    }
    set P(bcinsped) $ped
    TKGCenter .bcins
}

proc PrefsWatchDoInsert {} {
    upvar \#0 watch-hlparams P
    set name [string trim $P(bcinsname)]
    set item [list File $name]
    set ped [lindex [HListGetSelectedPeds watch] 0]
    if [Empty $ped] {
	set ped 0
    }
    HList watch insert $ped $item
    catch {destroy .bcins}
    WatchFileDeclare [TKGEncode $name]
}

proc PrefsWatchDel {} {
    upvar \#0 watch-hlparams P
    set ped [lindex [HListGetSelectedPeds watch] 0]
    HList watch delete $ped
}

