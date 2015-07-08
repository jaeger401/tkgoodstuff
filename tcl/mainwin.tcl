# Main Window

proc TKGDraw {} {
    global TKG TKG_panels TKG PutPanelmain TKG_postedpanels \
	main-pparams geometry TKG_iconSide

    # clean up
    foreach panel [array names TKG_panels] {
	wm withdraw $panel
	wm geometry $panel ""
	wm sizefrom $panel ""
	wm minsize $panel 1 1
	set v [string trimleft $panel .]-pparams
	global $v
	if [info exists $v] {unset $v}
	foreach w [winfo children $panel] {
	    if [regexp ^$panel.stack\[^.\]*$|^$panel.fill\[^.\]*$|^$panel.lb\[^.\] $w] {
		destroy $w
	    } else {
		grid forget $w
	    }
	}
    }
    for {set i 1} {$i <= $TKG(stackindex)} {incr i} {
	global stack$i-sparams
	if [info exists stack$i-sparams] {unset stack$i-sparams}
    }
    foreach v {main-pparams TKG_stackside TKG_iconSide TKG_panels
	TKG_postedpanels} {
	if [info exists $v] {unset $v}
    }

    set TKG_iconSide(current) ""
    set TKG_stackside(current) ""
    set TKG(currentpanel) main
    set TKG(stackindex) 0
    set TKG(stackprefix) ""
    set TKG(pedigree) 0

    if [string match $TKG(screenedge) no] {
	if [ info exists geometry ] { set TKG(geometry) $geometry }
	set PutPanelmain(geometry) $TKG(geometry)
    }
    TKGStartPanel main-panel \
	-orientation $TKG(orientation) \
	-screenedge $TKG(screenedge) \
	-iconside $TKG(iconside) \
	-borderwidth $TKG(borderwidth) \
	-color $TKG(panelcolor) \
	-title tkgoodstuff

    if [catch {TKGDoHook TKG_createmainpanel}] {
	TKGError "Error in preferences or configuration while
creating main panel.  Diagnose with
stack trace and/or enter preferences manager."
	vwait whatevergreatscott
    }

    TKGScreenEdgeSetup .main-panel ;# sets up auto-min and drag bindings

    TKGStartClients
    TKGDoHook TKG_clientwindowscreated_hook
    update idletasks
    TKGPanelPlace main
    set TKG_postedpanels(.main-panel) 1
}
