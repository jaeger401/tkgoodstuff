# Pop-Imap (mail-fetching) Client Tcl code for tkgoodstuff

proc PopImapDeclare {} {
    TKGDeclare PopImap(interval) 300 -typelist [list Clients PopImap]\
	-label "How often to fetch new mail (seconds)"
    TKGDeclare PopImap(command) "xmessage no PopImap command set"\
	-typelist [list Clients PopImap]\
	-label "What unix command fetches new mail"
    TKGDeclare PopImap(fetch_command) "" -typelist [list Clients PopImap]\
	-label "What unix command retrieves your entire remote mailbox"
}

proc PopImap_do_pop {} {
    global PopImap TKG Net
    if $PopImap(popping) return
    set PopImap(popping) 1
    if { ([lsearch $TKG(clients) Net] != -1 ) && !$Net(linkstatus) } {
	DEBUG "Not checking for remote mail because net down."
	return
    }
    DEBUG "PopImap: $PopImap(command)"
    set id [open "|$PopImap(command) 2> /dev/null" r]
    fileevent $id readable \
	[list PopImapPipeRead $id]
}

proc PopImapPipeRead {id} {
    global PopImap TKG
    gets $id
    if [eof $id] {
	fileevent $id readable ""
	close $id
	set PopImap(popping) 0
	if { [lsearch $TKG(clients) Biff] != -1 } {
	    catch {BiffUpdate INBOX}
	}    
    }
}

proc PopImap_toggle_popping args {
    global PopImap TKG
    set cup [list TKGPeriodic PopImap_pop $PopImap(interval)\
		 $PopImap(offset) PopImap_do_pop]
    set cdn [list TKGPeriodicCancel PopImap_pop]
    if $PopImap(enable) {
	if { [lsearch $TKG(clients) Net] != -1 } {
	    TKGAddToHook Net_up_hook $cup
	    TKGAddToHook Net_down_hook $cdn
	} else {
	    eval $cup
	}
    } else {
	eval $cdn
	if { [lsearch $TKG(clients) Net] != -1 } {
	    TKGRemoveFromHook Net_up_hook $cup
	    TKGRemoveFromHook Net_down_hook $cdn
	}
    }
}
	
proc PopImapInit {} {
    global PopImap
    set PopImap(offset) 2
    trace variable PopImap(enable) w PopImap_toggle_popping
    set PopImap(enable) 1
    set PopImap(popping) 0

    TKGPopupAddClient PopImap
    .tkgpopup.popimap add checkbutton\
	-label "Enable periodic fetching" -variable PopImap(enable)
    .tkgpopup.popimap add command\
	-label "Fetch new mail now" -command {PopImap_do_pop}
    if { $PopImap(fetch_command) != "" } {
	.tkgpopup.popimap add command\
	    -label "Replace local with remote mailbox"\
	    -command {eval exec $PopImap(fetch_command) &}
    }
}

DEBUG "Loaded PopImap.tcl"
