# Hierarchical listbox pseudowidget
# data in $name-hldata
# each item gets a list:
#  0 -- "mode" (whatever)
#  1 -- text
#  2 -- list of options
#  3 -- list of child items
#  4 -- open/closed
# many features unimplemented
# see prefs-config.tcl for an example of use.

proc HList {name action args} {
    switch $action {
	create {
	    HListCreate $name $args
	} insert {
	    eval [concat HListInsert $name $args]
	} delete {
	    eval [concat HListDelete $name $args]
	} select {
	    eval [concat HListSelect $name $args]
	} default {
	    bgerror "bad action switch to HList"
	}
    }
}

##########
# Creation

set TKG(switches,HListCreate) {
    pathname
    {data ""}
    menu3
    emptycommand
    {double1 break}
    closedimagefile
    openimagefile
    iconcommand
    {selectmode single}
    selectcommand
    deletecommand
    {allowedchildren ""}
    {font $TKG(textfont)}
    {width 60}
    {height 20}
    {foreground $TKG(foreground)}
    {background $TKG(textbackground)}
    {selectforeground $TKG(foreground)}
    {selectbackground white}
    {activeforeground $TKG(activeforeground)}
    {activebackground $TKG(activebackground)}
}

set TKG(switches,HListCreate,ms) {
    closedimagefile openimagefile iconcommand selectcommand deletecommand
    movecommand menu3
}

proc HListCreate {name args} {
    upvar #0 $name-hlparams P
    set P(modes) ""
    set P(iconcounter) 0
    set P(relation) before
    set args [lindex $args 0]
    # Parse switches
    global TKG
    set switches $TKG(switches,HListCreate)
    set modeswitches $TKG(switches,HListCreate,ms)
    TKGParseArgs $name-hlparams $args\
	$switches $modeswitches "HListCreate"
    TKGSetSwitchDefaults $name-hlparams $switches
    TKGSetMSSwitchDefaults $name-hlparams $switches
    foreach type {closed open} {
	foreach mode $P(modes) {
	    if [info exists P(${type}imagefile,$mode)] {
		set imagefile $P(${type}imagefile,$mode)
		set P(${type}image,$mode) HL$imagefile
		if {[lsearch [image names] HL$imagefile] == -1} {
		    SetImage HL$imagefile $imagefile
		}
	    }
	}
	if [info exists P(${type}imagefile)] {
	    set imagefile $P(${type}imagefile)
	    set P(${type}image) HL$imagefile
	    if {[lsearch [image names] HL$imagefile] == -1} {
		SetImage HL$imagefile $imagefile
	    }
	}
    }
    text $P(pathname) -font $P(font) -height $P(height) -width $P(width)\
	-foreground $P(foreground) -background $P(background)\
	-tabs {0 26 46} -cursor top_left_arrow -state disabled
    $P(pathname) tag configure withinItem -relief sunken -borderwidth 1
    $P(pathname) tag configure underItem -underline 1
    $P(pathname) tag configure selected -foreground $P(selectforeground) \
	-background $P(selectbackground)
    bind $P(pathname) <Motion> break
    bind $P(pathname) <1> "HListCheckEmpty $name;break"
#    bind $P(pathname) <Leave> "HListLeave $name"
    if ![Empty [info procs HListInit-$name]] HListInit-$name
    HListMenus $name
    HListDraw $name
}

proc HListCheckEmpty {name} {
    upvar \#0 $name-hlparams P
    if ![llength $P(data)] {
	$P(emptycommand)
    } 
}

#########################
# Draw the whole hlist

proc HListDraw {name} {
    upvar \#0 $name-hlparams P
    $P(pathname) configure -state normal
    $P(pathname) delete 1.0 end
    $P(pathname) insert 1.0 \
	"                                        \n" item
    $P(pathname) configure -state disabled
    set ped 0
    set index 2
    foreach item [set P(data)] {
	HListWidgetInsertAtIndex $name $ped $item $index.0
	set index [HListDrawKids $name $ped $item $index]
	incr index
	incr ped
    }
    HListTagPeds $name
}

proc HListDrawKids {name ped item index} {
    set kidnum 0
    foreach child [lindex $item 3] {
	incr index
	HListWidgetInsertAtIndex $name [concat $ped $kidnum] $child $index.0
	set index [HListDrawKids $name [concat $ped $kidnum] $child $index]
	incr kidnum
    }
    return $index
}

########################
# Insertion and deletion

proc HListInsert {name ped item} {
    HListDataReplace $name $ped "" $item
    HListDraw $name
    HListSee $name $ped
    HListItemSelect $name $ped
}

proc HListWidgetInsertAtIndex {name ped item index} {
    upvar \#0 $name-hlparams P
    set joinped [join $ped -]
    set mode [lindex $item 0]
    set label [lindex $item 1]
    set options [lindex $item 2]
    set open [expr ![string match [lindex item 4] closed]]
    if $open {set oc open} {set oc closed}
    # Determine tags
    set tags [list item]
    if {[set i [lsearch $options -T]] != -1} {
	lappend tags [lindex $options [expr $i + 1]]
    }
    # Enable writing
    $P(pathname) configure -state normal
    # Indent
    set tabs "\t"
    for {set i 1} {$i < [llength $ped]} {incr i} {
	append tabs "\t"
    }
    $P(pathname) insert $index "$tabs"
    # Maybe insert an icon
    if [info exists P(${oc}image,$mode)] {
	set image [set P(${oc}image,$mode)]
    } elseif [info exists P(${oc}image)] {
	set image [set P(${oc}image)]
    }
    if [info exists image] {
	set iconpath $P(pathname).i[incr P(iconcounter)]
	label $iconpath -image $image -background $P(background)
	set iconindex [$P(pathname) index "$index lineend"]
	$P(pathname) window create $iconindex -window $iconpath
	if [info exists P(iconcommand,[lindex $item 0])] {
	    bind $iconpath <1> \
		"$P(iconcommand,[lindex $item 0]) $name $ped; break"
	    bind $iconpath <Double-1> break
	}
    }
    # Always write the label
    $P(pathname) insert "$index lineend" "\t${label}\n" $tags
    # Disable writing
    $P(pathname) configure -state disabled
}

proc HListSee {name ped} {
    upvar \#0 $name-hlparams P
    catch {$P(pathname) see Ped-[join $ped -].first}
}

proc HListDelete {name ped1 {ped2 {}}} {
    if [Empty $ped2] {set ped2 $ped1}
    upvar \#0 $name-hlparams P
    HListDataReplace $name $ped1 $ped2
    HListDraw $name
    HListSee $name $ped1
}

proc HListDataReplace {name ped1 {ped2 {}} {insertitem {}}} {
    if [Empty $ped2] {set ped2 $ped1}
    upvar \#0 $name-hlparams P
    if {[llength $ped1] == 1} {
	if [Empty $insertitem] {
	    set P(data) [lreplace $P(data) $ped1 $ped2]
	} else {
	    set P(data) [linsert $P(data) $ped1 $insertitem]
	}
	return
    }
    # ok, we have to dissect the tree...
    set end [expr [llength $ped1] - 1]
    set item(0) $P(data)
    set i [lindex $ped1 0]
    set item(1) [lindex $item(0) $i]
    for {set level 2} {$level <= $end} {incr level} {
	set i [lindex $ped1 [expr $level - 1]]
	set item($level) [lindex [lindex $item([expr $level - 1]) 3] $i]
    }
    set i [lindex $ped1 end]
    set j [lindex $ped2 end]
    if [Empty $insertitem] {
	set item($end) [lreplace $item($end) 3 3 \
			    [lreplace [lindex $item($end) 3] $i $j]]
    } else {
	set item($end) [lreplace $item($end) 3 3 \
			    [linsert [lindex $item($end) 3] $i $insertitem]]
    }
    for {set level [expr $end - 1]} {$level > 0} {incr level -1} {
	set i [lindex $ped1 $level]
	set newkids [lreplace [lindex $item($level) 3] $i $i $item([expr $level + 1])]
	set item($level) [lreplace $item($level) 3 3 $newkids]
    }
    set i [lindex $ped1 0]
    set P(data) [lreplace $item(0) $i $i $item(1)]
}

#################################
# Tags

proc HListTagPeds {name} {
    upvar \#0 $name-hlparams P
    set w $P(pathname)
    foreach tag [$w tag names] {
	if [string match Ped-* $tag] {
	    $w tag delete $tag
	}
    }
    HListTagWithPed $name $P(pathname) 1 top top
    set D $P(data)
    set line 2
    for {set i 0} {$i < [llength $D]} {incr i} {
	set item [lindex $D $i]
	HListTagWithPed $name $w $line $i [lindex $item 0]
	set line [HListTagKids $name $item $w [expr $line + 1] $i]
    }
}

proc HListTagKids {name item w line ped} {
    set kids [lindex $item 3]
    if [string match [lindex $item 4] closed] {return $line}
    for {set i 0} {$i < [llength $kids]} {incr i} {
	set kid [lindex $kids $i]
	HListTagWithPed $name $w $line [concat $ped $i] [lindex $kid 0]
	set line [HListTagKids $name $kid $w [expr $line + 1] [concat $ped $i]]
    }
    return $line
}

proc HListTagWithPed {name w line ped mode} {
    upvar \#0 $name-hlparams P
    set jp [join $ped -]
    $w tag add Ped-$jp $line.0 [$w index "$line.0 lineend + 1 chars"]
    $w tag bind Ped-$jp <Enter> [list HListItemMotion $name $ped %x %y]
    $w tag bind Ped-$jp <Motion> [list HListItemMotion $name $ped %x %y]
    $w tag bind Ped-$jp <1> [list HList1 $name $ped]
    $w tag bind Ped-$jp <B1-Motion> [list HList1Motion $name $ped %x %y]
    $w tag bind Ped-$jp <ButtonRelease-1> [list HList1Release $name $ped %x %y]
    $w tag bind Ped-$jp <3> [list HList3 %X %Y $name $ped $mode]
    $w tag bind Ped-$jp <Double-1> "
	if {!\[string match top $jp\]} $P(double1)
    "
}    
	
##########################################
# Getting items and indices

proc HListGetItem {name ped} {
    upvar \#0 $name-hlparams P
    set data [lindex $P(data) [lindex $ped 0]]
    set ped [lreplace $ped 0 0]
    while {[llength $ped] != 0} {
	set data [lindex [lindex $data 3] [lindex $ped 0]]
	set ped [lreplace $ped 0 0]
    }
    return $data
}

proc HListGetIconPath {name ped} {
    upvar \#0 $name-hlparams P
    set range [$P(pathname) tag nextrange Ped-[join $ped -] 1.0]
    set dump [eval $P(pathname) dump -window $range]
    return [lindex $dump 1]
}

proc HListPedLess {ped1 ped2} {
    for {set i 0} {$i < [llength $ped1]} {incr i} {
	set e1 [lindex $ped1 $i]
	if [Empty [set e2 [lindex $ped2 $i]]] {return 0}
	if ![string match $e1 $e2] {
	    return [expr $e1 < $e2]
	}
    }
    return [expr [llength $ped1] < [llength $ped2]]
}

proc HListNextPed {ped} {
    return [lreplace $ped end end [expr [lindex $ped end] + 1]]
}

######################
# Entering and leaving

proc HListItemMotion {name ped x y} {
    upvar \#0 $name-hlparams P
    set w $P(pathname)
    set joinped [join $ped -]
    set bbox [$w bbox [$w index "Ped-$joinped.last - 1 chars"]]
    set ymiddle [expr [lindex $bbox 1] + (3*[lindex $bbox 3]/4)]
    if {($y < $ymiddle) && (![string match top $ped])} {
	HListLeave $name
	$w tag add withinItem Ped-$joinped.first Ped-$joinped.last
	set P(relation) within
    } else {
	HListLeave $name
	$w tag add underItem Ped-$joinped.first Ped-$joinped.last
	if {[string match top $ped]} {
	    set P(relation) before
	} else {
	    set P(relation) after
	}
    }
}

proc HListLeave {name} {
    upvar \#0 $name-hlparams P
    set w $P(pathname)
    catch {
	$w tag remove underItem underItem.first underItem.last
    }
    catch {
	$w tag remove withinItem withinItem.first withinItem.last
    }
}

################
# Selection

proc HList1 {name ped} {
    upvar \#0 $name-hlparams P
    HListClearSelection $name
    if {[string match top $ped]} return
    HListItemSelect $name $ped
    $P(pathname) configure -cursor crosshair
}

proc HList1Motion {name ped x y} {
    upvar \#0 $name-hlparams(pathname) w
    if {(![string match top $ped]) &&
	![string match crosshair [$w cget -cursor]]} {
	HListClearSelection $name
	HListItemSelect $name $ped
    }
    set inIndex [$w index @$x,$y]
    if {[regexp {Ped-([^ ]*)} [$w tag names $inIndex] v v]} {
	set ped [split $v -]
	HListItemMotion $name $ped $x $y
    }
}

proc HList1Release {name ped x y} {
    upvar \#0 $name-hlparams P
    set w $P(pathname)
    if ![string match crosshair [$w cget -cursor]] return
    set inIndex [$w index @$x,$y]
    set inTags [$w tag names $inIndex]
    if {![regexp {Ped-([^ ]*)} $inTags tag v]} {
	$w configure -cursor top_left_arrow
	return
    }
    set newped [split $v -]
    if {[In selected $inTags]} {
	$w configure -cursor top_left_arrow
	return
    }
    if {[string match top $newped]} {
	set newped 0
    }
    HListDragDrop $name $newped
    $w configure -cursor top_left_arrow
}    

proc HListDragDrop {name targetped} {
    upvar \#0 $name-hlparams P
    # Get item to be moved (item1)
    set selindex [$P(pathname) index selected.first]
    regexp {Ped-([-0-9]*)} [$P(pathname) tag names $selindex] v ped1
    set ped1 [split $ped1 -]
    set item1 [HListGetItem $name $ped1]
    set mode1 [lindex $item1 0]

    # moving an item into itself? 
    if {[string match ${ped1}* $targetped]} return

    switch $P(relation) {
	before {
	    # "before" only happens with ped = {0}
	} within {
	    # Make this a child if allowed; else default to "after" behavior
	    set item2 [HListGetItem $name $targetped]
	    set mode2 [lindex $item2 0]
	    array set allowedkids $P(allowedchildren)
	    foreach parentmode [array names allowedkids] {
		if {[string match $parentmode $mode2]} {
		    foreach childmode $allowedkids($parentmode) {
			if {[string match $childmode $mode1]} {
			    lappend targetped 0
			    set break 1
			    break
			}
		    }
		}
		if {[info exists break]} break
	    }
	    if {![info exists break]} {
		set targetped [HListNextPed $targetped]
	    }
	} after {
	    # increment the last element of the pedigree
	    set targetped [HListNextPed $targetped]
	}
    }
    if {[string match $ped1 $targetped]} return
    if [HListPedLess $ped1 $targetped] {
	HList $name insert $targetped $item1
	HList $name delete $ped1
    } else {
	HList $name delete $ped1
	HList $name insert $targetped $item1
    }
}

proc HListItemSelect {name ped} {
    upvar \#0 $name-hlparams P
    $P(pathname) tag add selected \
	Ped-[join $ped -].first Ped-[join $ped -].last
    if ![Empty [set w [HListGetIconPath $name $ped]]] {
	$w configure -foreground $P(selectforeground) \
	    -background $P(selectbackground)
    }
}   

proc HListClearSelection {name} {
    upvar \#0 $name-hlparams P
    while {![Empty [set range [$P(pathname) tag nextrange selected 1.0]]]} {
	set first [lindex $range 0]
	regexp {Ped-([-0-9]*)} [$P(pathname) tag names $first] ped ped
	set ped [split $ped -]
	HListItemDeselect $name $ped
    }
}

proc HListItemDeselect {name ped} {
    upvar \#0 $name-hlparams P
    catch {
	$P(pathname) tag remove selected \
	    Ped-[join $ped -].first Ped-[join $ped -].last
    }
    if ![Empty [set w [HListGetIconPath $name $ped]]] {
	$w configure\
	    -foreground $P(foreground) -background $P(background)
    }
}   

proc HListGetSelectedPeds {name} {
    upvar \#0 $name-hlparams(pathname) w
    set start "1.0"
    set ret ""
    while {![Empty [set range [$w tag nextrange selected $start]]]} {
	set first [lindex $range 0]
	regexp {Ped-([-0-9]*)} [$w tag names $first] tag ped
	set ped [split $ped -]
	lappend ret $ped
	set start [$w index "$tag.last + 1 chars"]
    }
    return $ret
}

#################
# Mouse-3 menus

proc HList3 {x y name ped mode} {
    HList1 $name $ped
    set w .hlmenu-$name
    if [winfo exists $w$mode] {
	tk_popup $w$mode $x $y
    } elseif [winfo exists $w] {
	tk_popup $w $x $y
	grab $w
    }
}

proc HListMenus {name} {
    upvar \#0 $name-hlparams P
    foreach mode [concat {{}} $P(modes)] {
	set m .hlmenu-$name$mode
	if ![Empty $mode] {
	    set itemsvar P(menu3,mode)
	} else {
	    set itemsvar P(menu3)
	}
	if ![info exists $itemsvar] return
	set items [set $itemsvar]
	catch {destroy $m}
	menu $m -tearoff 0
	foreach item $items {
	    $m add command -label [lindex $item 0]\
		-command [lindex $item 1]
	}
    }
}

