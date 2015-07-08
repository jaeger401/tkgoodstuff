proc TKGRCInit {} {uplevel #0 {
    set cmdlinepos [ lsearch $argv "-f" ]
    if { $cmdlinepos != -1 } {
	set TKG(configfile) [lindex $argv [expr $cmdlinepos + 1]]
	set TKG(rc) $TKG(configfile)
    } elseif [file exists $env(HOME)/.tkgrc] {
	set TKG(configfile) $env(HOME)/.tkgrc
	set TKG(rc) $TKG(configfile)
    } elseif [file exists $TKG(libdir)/system-tkgrc] {
	set TKG(rc) $env(HOME)/.tkgrc
	set TKG(configfile) $TKG(libdir)/system-tkgrc
    } else {
	set TKG(configfile) $env(HOME)/.tkgrc
	set TKG(rc) $TKG(configfile)
    }
}}

proc TKGLangInit {} {uplevel #0 {
    if [file exists "~/.tkgoodstuff_$TKG(language)"] {
	source "~/.tkgoodstuff_$TKG(language)"
    }
    if [file exists "$TKG(libdir)/tcl/$TKG(language).tcl"] {
	source "$TKG(libdir)/tcl/$TKG(language).tcl";
    } else {
	source "$TKG(libdir)/tcl/english.tcl";
    }
}}

proc TKGFvwmInit {} {uplevel #0 {
    # If we're an fvwm client, load Fvwm.tcl code
    if ![catch {format "%d %d" [lindex $argv 0] [lindex $argv 1]}] {
	source $TKG(libdir)/tcl/Fvwm.tcl
	uplevel \#0 [info body FvwmDeclare]
	uplevel \#0 [info body FvwmDoOnLoad]
    global TKG
    lappend TKG(clients) Fvwm
    }
}}

proc TKGGetPreferences {} {uplevel #0 {
    if {[file exists $TKG(configfile)] && ([file size $TKG(configfile)] != 0)} {
	set id [open $TKG(configfile)]
	set c [read $id]
	close $id
	flush stdout
	    if {(![regexp {^# tkgoodstuff config file format ([0-9]*)} $c fv fv])\
		|| [expr $fv < $TKG(configfileformatversion)]} {
	    TKGError "Current configuration file $TKG(configfile)
is in an old, unsupported format.  Using defaults."
	    return
	}
	set i [string first {-------Configuration-------} $c]
	set prefs [string range $c 0 [expr $i - 2]]
	set TKG(config) [string range $c [expr $i + 28] end]
	set TKGVars(TKG(config),current) $TKG(config)
	set command ""
	foreach line [split $prefs "\n"] {
	    append command "$line\n"
	    if ![info complete $command] {
		set startline $line
		continue
	    } else {
		if [catch {eval $command} err] {
		TKGError "Error in preferences.  Diagnose with stack
trace and/or enter preferences manager.
Problem line: 
$line
Error:
$err"
		}
		set command ""
	    }
	}
	if ![Empty $command] {
	    TKGError "Error in configuration.
A command is incomplete (perhaps the command
starting with the following line):

$line"
        }
	unset i c prefs
        set auto_path [concat $TKG(xtraauto) $auto_path]
    }
}}

proc ConfigParse {config} {
    global TKG
    set DATA ""
    set VAR DATA
    set i 0
    foreach line [split $config \n] {
	incr i
	if ![llength $line] continue
	set keyword [lindex $line 0]
	set line [lreplace $line 0 0]
	switch -regexp -- $keyword {
	    ^Client$ {
		lappend $VAR [list Client "Client $line"]
	    } ^Fill$ {
		lappend $VAR [list Fill Fill]
	    } (^Button$|^LabelBox$|^PanelButton$|^PutPanel$|Swallow) {
		set name [join $line ~]
		ConfigDeclare $name $keyword
		lappend $VAR [list $keyword "$keyword $line"]
	    } (^Stack$|^Panel$) {
		set name [join $line ~]
		ConfigDeclare $name $keyword
		lappend $VAR [list $keyword "$keyword $line"]
		lappend varstack $VAR
		set VAR DATA-$i
	    } (^EndStack$|^EndPanel$) {
		set PREVVAR [lindex $varstack end]
		set varstack [lreplace $varstack end end]
		set stackitem [lindex [set $PREVVAR] end]
		#add list of children items to item for stack
		if ![info exists $VAR] {set $VAR ""}
		lappend stackitem "" [set $VAR]
		unset $VAR
		set VAR $PREVVAR
		set $VAR [lreplace [set $VAR] end end $stackitem]
	    } 
	}
    }
    return $DATA
}

    # varname is the array holding preferences for the item
    # we load defaults for all array elements not defined (in user preferences)
proc ConfigDeclare {name type {varname ""} {typelist ""}} {
    if [Empty $varname] {set varname $type$name}
    if [Empty $typelist] {set typelist [list $type $name]}
    global TKGVarnames TKGVars TKG $varname Prefs_taborder
    if [info exists TKG(declared,$type,$name)] return
    set TKG(declared,$type,$name) 1
    set switches $TKG(switches,$type)
    TKGSetSwitchDefaults $varname $switches 0
    foreach switch $switches {
	set switchvar ${varname}([lindex $switch 0])
	set vartypelist [concat $typelist [lindex $switch 3]]
	eval TKGDeclare $switchvar\
	    \{[lindex $switch 1]\}\
	    -typelist \$vartypelist\
	    [lindex $switch 2]
    }
    if ![Empty $typelist] {
	set Prefs_taborder(:[join $typelist ,]) "Main Misc Colors Advanced Fvwm"
    }
}

proc TKGEvalConfig {} {uplevel #0 {
    set TKG(currentpanel) ""
    ConfigParse $TKG(config)
    set script [split $TKG(config) "\n"]
    foreach line $script {
	set type [lindex $line 0]
	set name [lindex $line 1]
	if [string match $type Client] {
	    uplevel \#0 "source $TKG(libdir)/tcl/$name.tcl"
	    if ![Empty [info procs ${name}DoOnLoad]] {
		uplevel \#0 [info body ${name}DoOnLoad]
	    }
	    if ![Empty [info procs ${name}Declare]] {
		uplevel \#0 [info body ${name}Declare]
	    }
	}
    }
    set command ""
    foreach line $script {
	append command "${line}\n"
	if ![info complete $command] {
	    set startline $line
	    continue
        } else {
	    if [catch {eval $command} err] {
	    TKGError "Error in configuration (or possibly preferences).
Diagnose with stack trace
and/or enter preferences manager.
Problem command: 

$command

Error: $err"
	    }
	    set command ""
	}
    }
    if ![Empty $command] {
	TKGError "Error in configuration.
A command is incomplete (perhaps the command
starting with the following line):

$line"
        }
    }
}

proc TKGResolvePreferences {} {uplevel #0 {
    set i 0
    while {($i < 20) && ![Empty $TKGSetHook]} {
	set TKGSet1Hook $TKGSetHook
	set TKGSetHook ""
	TKGDoHook TKGSet1Hook
	unset TKGSet1Hook
	incr i
    }
    if {$i == 20} {
	TKGError "Error in preferences: variable references
cannot be resolved (self-reference?)." exit
    }
    unset i TKGSetHook
}}

proc TKGLibInit {} {
    global TKG
    foreach pkg {Tkg Tkxpm} {
	if [catch {package require $pkg} err] {
	    TKGError "Cannot load $TKG(libdir)/lib${pkg}.
This should have been installed during tkgoodstuff installation.
Error message was:
$err" exit
	}
    }
}

proc TKGInitialize {} {
    global TKG TKGSetHook
    set TKG(clients) ""
    set TKG(stackindex) 0
    set TKG(Log) "TkGoodStuff Log starting\n\n"
    set TKGSetHook ""
    set TKG(currentBalloon) ""
}

proc TKGInitClients {} {
    global TKG
    foreach client $TKG(clients) {
	if ![Empty [info procs ${client}Init]] {${client}Init}
    }
}
