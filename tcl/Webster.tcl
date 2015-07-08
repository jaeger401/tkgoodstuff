# Webster (tkgoodstuff client)

proc WebsterDeclare {} {
    set Prefs_taborder(:Clients,Webster) "Misc Button"
    TKGDeclare Webster(url) \
	{http://www.m-w.com/cgi-bin/mweb?book=Dictionary&va=@word@} \
	-typelist [list Clients Webster Misc] \
	-scrollbar 1\
	-label "URL for fetching definition" \
	-help "This URL, should fetch the definition when `@word@' is replaced
with the word to be defined."
    TKGDeclare Webster(imagefile) {%webster} \
	-typelist [list Clients Webster Button Misc] \
	-label "Icon file"
    TKGDeclare Webster(label) "Webster" \
	-typelist [list Clients Webster Button Misc]
    ConfigDeclare Webster ClientButton1 Webster [list Clients Webster Button]
    ConfigDeclare Webster ClientButton3 Webster [list Clients Webster Button]
    ConfigDeclare Webster ClientButton5 Webster [list Clients Webster Button]

    TKGDeclare Webster(makebutton) 1 \
	-typelist [list Clients Webster Button Misc] -vartype boolean\
	-label "Make a button" \
	-help "Produce a button?  (If no, the command WebsterDefine is available as
a tcl command for the Menu client.)"
}

proc WebsterCreateWindow {} {
    global Webster
    if [TKGReGrid Webster] return
    if $Webster(makebutton) {
	lappend c TKGMakeButton Webster -command WebsterDefine\
	    -balloon "Get dictionary definition" \
	    -iconside $Webster(iconside) \
	    -relief $Webster(relief)
	if !$Webster(nolabel) {
	    lappend c -text $Webster(label)
	}
	if !$Webster(noicon) {
	    SetImage Webster(image) $Webster(imagefile)
	    lappend c -image Webster(image)
	}
	eval $c
	unset c
    }
}

proc WebsterDefine {{word ""}} {
    global Webster TKG
    if [Empty $word] {
  	if [catch "selection get" word] {
 	    WebsterDialog
  	    return
  	}
  	selection clear
    }
    set word [join $word +]
    regsub @word@ $Webster(url) $word url
    lappend c WWWGoto $TKG(browser) $url
      eval $c
}

proc WebsterDialog {} {
    TKGDialog tkgwebster -wmtitle "Webster . . ."\
 	-title "Webster . . ."\
 	-buttons [list [list ok OK {
	    WebsterDefine $Webster(word)
	    set Webster(word) ""
	    destroy .tkgwebster}]]
    grid [entry .tkgwebster.entry -width 40 -textvariable Webster(word)]\
 	-row 5 -column 0 -sticky nsew
    update
    focus .tkgwebster.entry
    bind .tkgwebster.entry <Key-Return> {
	.tkgwebster.buttons.ok flash
	.tkgwebster.buttons.ok invoke
	update
	break
    }
}

DEBUG "Loaded Webster.tcl"
