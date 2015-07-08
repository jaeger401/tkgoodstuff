#Biff "IMAP" method: look for "Unseen" messages on IMAP server

proc BiffIMAPInit {} {
}

proc BiffIMAPDeclare {f} {
    TKGDeclare Biff($f,host) "" \
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] IMAP] \
	-label "Hostname of IMAP server" 
    TKGDeclare Biff($f,port) 143 \
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] IMAP] \
	-label "IMAP port number on server" 
    TKGDeclare Biff($f,user) "" -fallback [exec whoami] \
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] IMAP] \
	-label "Username on IMAP server"
    TKGDeclare Biff($f,password) "" \
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] IMAP] \
	-label "Password"  \
	-help "If password is left empty, you will be asked for it at
tkgoodstuff startup."
    TKGDeclare Biff($f,useNet) 1 \
	-typelist [list Clients Biff Mailboxes [TKGDecode $f] IMAP] \
	-vartype boolean \
	-label "Rely on Net client, if used" \
	-help "When enabled, if the tkgoodstuff Net client is used we will 
check for mail on the IMAP server only when the net is up."
}

proc BiffIMAPFolderInit {f} {
    global Biff
    set Biff($f,unseen) ""
    set Biff($f,all) ""
    BiffIMAPSetBusy $f 0
}

proc BiffIMAPStart {f} {
    global Biff TKG Net
    lappend mapcmd TKGPeriodic BiffUpdate$f \
	$Biff($f,update_interval) $Biff($f,update_interval) {BiffUpdate $f}
    if {([lsearch $TKG(clients) Net] != -1) && $Biff($f,useNet)} {
	TKGAddToHook Net_up_hook $mapcmd "BiffUpdate $f"
	TKGAddToHook Net_down_hook \
	    "TKGPeriodicCancel BiffUpdate$f"
	if !!$Net(linkstatus) {BiffUpdate $f}
    } else {
	eval $mapcmd
	BiffUpdate $f
    }
}

# Check if there is new "Unseen" mail, and fetch the 
# header data (frmlist) if there are changes in the lists
# of unseen messages.
proc BiffIMAPTest {f} {
    global Biff
    if [BiffIMAPBusy $f] {
	return nochange
    }
    BiffIMAPSetBusy $f 1
    if ![BiffIMAPEnsure $f] {
	BiffIMAPSetBusy $f 0
	return nochange
    }

    set oldunseen $Biff($f,unseen)
    BiffIMAPCheck $f

    BiffIMAPSetBusy $f 0
    if {(![string match $oldunseen $Biff($f,unseen)])
	|| ![info exists Biff($f,frmlist)]} {
	set Biff($f,frmlist) [BiffIMAPGetFrmList $f 0]
    }
    if {[string match $oldunseen $Biff($f,unseen)]} {
	set ret nochange
    } else {
	set ret 0
	foreach unseen $Biff($f,unseen) {
	    if {![In $unseen $oldunseen]} {
		set ret 1
	    }
	} 
    } 
    return $ret
}

proc BiffIMAPCheck {f} {
    global Biff TKGExpect
    set id $Biff($f,id)
    if ![TKGExpect $Biff($f,id) \
	"Check1 check" "{Check1 OK }"] return
    if [TKGExpect $id \
		"Check2 search unseen" "{\\* SEARCH(.*)\n.*Check2 OK }"] {
	set Biff($f,unseen) $TKGExpect($id,submatch1)
    }
    if $Biff(count) {
	BiffCountLabel $f [llength $Biff($f,unseen)]
    }
}

proc BiffIMAPIgnore {f} {
}

# Because it may take too long, if possible don't fetch a new frmlist.
proc BiffIMAPScan {f} {
    global Biff
    if {![info exists Biff($f,frmlist)]
	|| [string match error [lindex $Biff($f,frmlist) 0]]} {
	set Biff($f,frmlist) [BiffIMAPGetFrmList $f]
    }
    return $Biff($f,frmlist)
}

proc BiffIMAPGetFrmList {f {docheck 1}} {
    global Biff TKGExpect
    if [BiffIMAPBusy $f] {
	return "error {IMAP connection busy.  Try again later.}"
    }
    BiffIMAPSetBusy $f 1
    if ![BiffIMAPEnsure $f] {
	BiffIMAPSetBusy $f 0
	return "error {Could not log into IMAP server.  Try again later.}"
    }
    set id $Biff($f,id)
    if $docheck {BiffIMAPCheck $f}
    set error 0
    set frmlist ""
    set Biff($f,all) ""
    if [TKGExpect $id \
	    "Scan1 search all" "{\\* SEARCH(.*)\n.*Scan1 OK }"] {
	set Biff($f,all) $TKGExpect($id,submatch1)
    } else {
	set error 1
    }
    if $Biff($f,listall) {
	set msgs all
    } else {
	set msgs unseen
    }
    foreach mnum $Biff($f,$msgs) {
	if ![TKGExpect $id \
		 "f$mnum fetch $mnum envelope" \
		 "{\\* $mnum FETCH \\(ENVELOPE (.*)\\)\nf$mnum OK } \
                  {\\* $mnum FETCH \\(ENVELOPE (.*)\\)\n\\* $mnum FETCH}"] {
	    set error 1
	    break
	}
	regsub -all \n $TKGExpect($id,submatch1) \r\n E
	set E [TKGSexpr $E]
	set addr [lindex [lindex $E 2] 0]
	if ![string match NIL [lindex $addr 0]] {
	    set From [lindex $addr 0]
	} else {
	    set From "[lindex $addr 2]@[lindex $addr 3]"
	}
	set Subj [lindex $E 1]
	set New [In $mnum $Biff($f,unseen)]
	lappend frmlist [list $From $Subj $New $mnum]
    }	
    if $error {
	set frmlist "error {Error fetching list of messages from IMAP server.}"
    }
    BiffIMAPSetBusy $f 0
    return $frmlist
}

proc BiffIMAPGetMessage {f mnum} {
    global Biff TKGExpect
    if [BiffIMAPBusy $f] {
	return "error {IMAP connection busy.  Try again later.}"
    }
    BiffIMAPSetBusy $f 1
    if ![BiffIMAPEnsure $f] {
	BiffIMAPSetBusy $f 0
	return "error {Could not log into IMAP server.  Try again later.}"
    }
    set id $Biff($f,id)
    if ![TKGExpect $id "g$mnum fetch $mnum rfc822" "{\\* $mnum FETCH \\(RFC822 {(\[0-9\]*)}\n(.*)\ng$mnum OK}"] {
	set result "error {Error fetching message from IMAP server.}"
    } else {
	regsub -all "\n" $TKGExpect($id,submatch2) "\n\n" result
	set result [string range $result 0 \
			[expr $TKGExpect($id,submatch1) - 1]]
	regsub -all "\n\n" $result "\n" result
    }
    BiffIMAPSetBusy $f 0
    return $result
}

proc BiffIMAPLogin {f} {
    global Biff TKGExpect
    foreach v {host port user password} {
	set $v $Biff($f,$v)
    }
    while 1 {
	if [string match $password @@ABORT@@] {return 0}
    	if {![info exists Biff($f,id)]} {
	    if [catch {
		set Biff($f,id) [socket -async $host $port]
	    }] {
		return 0
	    }
	    fconfigure $Biff($f,id) -buffering none -blocking 0
	    if ![TKGExpect $Biff($f,id) "" {{\* OK }}] {return 0}
	}
	if ![Empty $password] {
	    if ![TKGExpect $Biff($f,id) \
		     "Login1 login $user $password" \
		     "{\\* BYE .*\n|Login1 OK|Login1 NO .*\n|Login1 BAD .*\n}"] {return 0}
	    set match $TKGExpect($Biff($f,id),match)
	    if [regexp "\\* BYE (\[^\n\]*)\n.*" $match err err] {
		set Biff($f,password) @@ABORT@@
		TKGNotice "Aborting IMAP login of $user to $host failed:\n\n $err"
		return 0
	    } elseif {[regexp "Login1 NO (\[^\n\]*)\n.*" $match err err] 
		      || [regexp "Login1 BAD (\[^\n\]*)\n.*" $match err err]} {
		set err "Login of $user on $host failed:\n\n   $err\n\nTry again?\n\n"
	    } else break 
	} else {
	    set err ""
	}
	set password [TKGGetPassword "IMAP Password for [TKGDecode $f]" $err]
	set Biff($f,password) $password
    }
    if ![TKGExpect $Biff($f,id) \
	     "Login2 select $Biff($f,folder)" \
	     "{Login2 OK } {Login2 NO .*\n}"] {return 0}
    if [regexp "Login2 NO (\[^\n\]*)\n.*" $TKGExpect($Biff($f,id),match) err err] {
	set Biff($f,password) @@ABORT**
	TKGNotice "Aborting IMAP checking for $f:\n\n  $err"
	return 0
    }
    return 1
}

proc BiffIMAPLogout {f} {
    global Biff
    if {![catch {fconfigure $Biff($f,id)}]} {
	TKGExpect $Biff($f,id) "666 logout" {{\* BYE .*$}}
    }
    BiffIMAPClose $f
}

proc BiffIMAPClose {f} {
    global Biff
    catch {close $Biff($f,id)}
    catch {
	unset Biff($f,id)
    }
}

proc BiffIMAPEnsure {f} {
    global Biff
    set count 3
    if [string match $Biff($f,password) @@ABORT@@] {
	return 0
    }
    while {![BiffIMAPConnected $f]} {
	BiffIMAPClose $f
	BiffIMAPLogin $f
	incr count -1
	if !$count {
	    BiffIMAPClose $f
	    break
	}
	if [string match $Biff($f,password) @@ABORT@@] {
	    return 0
	}
    }
    return !!$count
}

proc BiffIMAPBusy {f} {
    global Biff
    set wait 15
    set i 0
    while {[info exists [set v Biff(busywait$i)]]} {incr i}
    while {[BiffIMAPSetBusy $f] && $wait} {
	after 1000 set $v 1
	vwait $v
	incr wait -1
    }
    catch {unset $v}
    return [BiffIMAPSetBusy $f]
}

proc BiffIMAPSetBusy {f {busy {}}} {
    global Biff
    eval set Biff(busy,$Biff($f,host),$Biff($f,user)) $busy
}

proc BiffIMAPConnected {f} {
    global Biff
    if {![info exists Biff($f,id)]} {return 0}
    return [TKGExpect $Biff($f,id) "cnct noop" "{cnct OK.*$}" 10000]
}
