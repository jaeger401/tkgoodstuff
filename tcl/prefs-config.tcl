proc PrefsWidget-config {var w} {
    global $var TKGVars
    set ww $w.widget$var
    frame $ww
    grid columnconfigure $ww 0 -weight 1
    grid rowconfigure $ww 0 -weight 1
    HList config create \
	-pathname $ww.hlist\
	-data [ConfigParse $TKGVars($var,setting)]\
	-width 50\
	-openimagefile(Client) client.xpm\
	-openimagefile(Stack) stack.xpm\
	-openimagefile(Panel) panel.xpm\
	-openimagefile(Button) button.xpm\
	-openimagefile(PanelButton) button.xpm\
	-openimagefile(LabelBox) labelbox.xpm\
	-openimagefile(Swallow) swallow.xpm\
	-double1 PrefsConfigProps\
	-emptycommand PrefsConfigIns\
	-allowedchildren [list Panel * Stack *] \
	-menu3 { 
	    {
		Properties PrefsConfigProps
	    } {
		Insert PrefsConfigIns
	    } { 
		Delete PrefsConfigDel
	    }
	}
    scrollbar $ww.yscroll -command "$ww.hlist yview"
    scrollbar $ww.xscroll -orient horizontal -command "$ww.hlist xview"
    $ww.hlist configure -yscrollcommand "$ww.yscroll set"\
	-xscrollcommand "$ww.xscroll set"
    grid $ww.hlist $ww.yscroll -sticky nsew
    grid $ww.xscroll -sticky nsew
    TKGAddToHook Prefs_updatehook "PrefsConfigUpdate $var w"
}

proc PrefsConfigUpdate {var w} {
    upvar \#0 config-hlparams P
    global PrefsConfig_tmp TKGVars
    set PrefsConfig_tmp ""
    foreach item $P(data) {
	append PrefsConfig_tmp [PrefsConfigParse $item]
    }
    set TKGVars($var,setting) $PrefsConfig_tmp
    unset PrefsConfig_tmp
}

proc PrefsConfigParse {item} {
    switch -regexp -- [lindex $item 0] {
	^Panel$|^Stack {
	    set out "[lindex $item 1]\n"
	    foreach child [lindex $item 3] {
		append out [PrefsConfigParse $child]
	    }
	    append out "End[lindex $item 0]\n"
	    return $out
	} default {
	    return "[lindex $item 1]\n"
	}
    }
}

proc PrefsConfigProps {} {
    upvar \#0 config-hlparams P
    set ped [lindex [HListGetSelectedPeds config] 0]
    set joinped [join $ped -]
    set item [HListGetItem config $ped]
    set type [lindex $item 0]
    PrefsUpdate
    set name [lrange [lindex $item 1] 1 end]
    switch -regexp $type {
	Client {
	    TKGPrefs "Clients [join $name ~]" "$name Preferences"
	} (^Button$|LabelBox|PanelButton|PutPanel|^Stack$|^Panel$|Swallow) {
	    set name [join [lrange [lindex $item 1] 1 end] ~]
	    TKGPrefs "$type [join $name ~]" "$name Preferences"
	}
    }
}

proc PrefsConfigIns {} {
    global config-hlparams
    upvar \#0 config-hlparams P
    set ped [lindex [HListGetSelectedPeds config] 0]
    if [Empty $ped] {set ped 0}
    TKGDialog pcins -title "Preferences: Configuration: Insert"\
	-wmtitle "Preferences: Configuration: Insert"\
	-nodismiss\
	-nodeiconify\
	-buttons {
	    {ok "OK" PrefsConfigDoInsert}
	    {help "Help" PrefsConfigInsertHelp}
	    {cancel "Cancel" {destroy .pcins}}
	}
    grab .pcins
    grid [frame .pcins.w] -row 2 -column 0 -sticky nsew
    grid columnconfigure .pcins.w 1 -weight 1
    grid [label .pcins.w.l1 -text "Insert:"] -row 0 -column 0 -sticky w
    set P(pcinstype Client)
    tk_optionMenu .pcins.w.om1 config-hlparams(pcinstype) \
       Client Button LabelBox Stack Panel PanelButton PutPanel Fill Swallow
    grid .pcins.w.om1 -row 0 -column 1 -sticky w
    grid [label .pcins.w.l2 -text "Name:"] -row 1 -column 0 -sticky w
    set i 0
    while {[set P(pcinsname) Item$i
	    string first $P(pcinsname) $P(data)] != -1} {incr i}
    grid [entry .pcins.w.e2 -textvariable config-hlparams(pcinsname)] \
	       -row 1 -column 1 -sticky we
    bind .pcins.w.e2 <Key-Return> {
	.pcins.buttons.ok flash
	.pcins.buttons.ok invoke
    }
    set P(pcinsped) $ped
    TKGCenter .pcins
}

proc PrefsConfigInsertHelp {} {
    TKGDialog pcinshelp -title Help -wmtitle "Preferences Help"\
	-message "If adding a client, the name is the name of the client.
For Panel and PutPanel, the name is the name of the panel.
For Fill, the name is ignored.
Otherwise, the name is only an identifier.

The \"within\" option is for putting a new item within a Stack or Panel.
"
}

proc PrefsConfigDoInsert {} {
    upvar \#0 config-hlparams P
    set type $P(pcinstype)
    set ba $P(relation)
    set name [string trim $P(pcinsname)]
    switch -regexp -- $type {
	Client {
	    set name [join $name -]; # (idiot proofing)
	    global TKG
	    if [catch {glob $TKG(libdir)/tcl/$name.tcl}] {
		TKGNotice "No client named $name can be found."
		return
	    }
	    uplevel \#0 "source $TKG(libdir)/tcl/$name.tcl"
	    if ![Empty [info procs ${name}Declare]] {
		uplevel \#0 [info body ${name}Declare]
	    }
	    set item [list Client "Client $name"]
	} LabelBox|^Button$|Stack|Panel|PanelButton|PutPanel|Swallow {
	    set text [$P(pathname) get 1.0 end]
	    if [regexp "\[^a-zA-Z0-9\]$type $name" $text] {
		TKGNotice "There is already a $type named $name."
		return
	    }
	    ConfigDeclare $name $type
	    set item [list $type "$type $name"]
	    if [In $type {Stack Panel}] {
		lappend item {} {}
	    }
	} Fill {
	    set item [list Fill Fill]
	}
    }
    set ped [lindex [HListGetSelectedPeds config] 0]
    if [Empty $ped] {
	set ped 0
    } else {
	switch $ba {
	    after {
		set ped [lreplace $ped end end [expr [lindex $ped end] + 1]]
	    } within {
		set parent [HListGetItem config $ped]
		if [In [lindex $parent 0] {Stack Panel}] {
		    lappend ped 0
		}
	    }
	}
    }
    HList config insert $ped $item
    catch {destroy .pcins}
}

proc PrefsConfigDel {} {
    upvar \#0 config-hlparams P
    set ped [lindex [HListGetSelectedPeds config] 0]
    HList config delete $ped
}

