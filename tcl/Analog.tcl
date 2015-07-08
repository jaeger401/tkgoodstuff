######
# Analog clock stuff
######

proc AnalogResize {} {
    global Analog Clock_window

    update idletasks
    $Clock_window.analog delete all
    if { $Analog(height) < $Analog(minsize) } { set Analog(height) $Analog(minsize) }
    if { $Analog(width) < $Analog(minsize) } { set Analog(width) $Analog(minsize) }
    if { $Analog(height) < $Analog(width) } {
	if $Analog(expand_to_square) {
	    set Analog(size) $Analog(width)
	} else {
	    set Analog(size) $Analog(height)
	} 
    } else {
	if $Analog(expand_to_square) {
	    set Analog(size) $Analog(height)
	} else {
	    set Analog(size) $Analog(width)
	} 
    }	

    if $Analog(expand_to_square) {
	$Clock_window.analog config \
	    -width $Analog(size) -height $Analog(size)
    } 

    set Analog(scale) [expr $Analog(size)/25 ]
    set Analog(padding) [expr $Analog(scale) + 3 ]
    set Analog(minutethick) [ expr $Analog(scale) + 3]
    set Analog(hourthick) [ expr $Analog(scale) + 3+ $Analog(scale)/3 ]
    set Analog(tickthick) [ expr $Analog(scale) / 2  + 1]
    set Analog(ticklong)  [ expr $Analog(scale) * 3/2 ]
    set Analog(bigticklong)  [ expr $Analog(scale) * 2 ]
    set Analog(bigtickthick) [ expr $Analog(scale) + 2 ]
    set Analog(bezelthick) [ expr $Analog(scale) ]
    set Analog(hubextent) [ expr $Analog(hourthick)/2]
    
    set Analog(xorig) [expr $Analog(width)/2 ]
    set Analog(yorig) [expr $Analog(height)/2]
    set Analog(extent) [expr ( ($Analog(size)/2) - $Analog(padding) )]
    set Analog(minuteextent) [expr $Analog(extent) - ($Analog(bezelthick)/2)]
    set Analog(hourextent) [expr ( $Analog(extent) * .6 )]
    set Analog(tickextent) [expr ( $Analog(extent) - $Analog(ticklong))]
    set Analog(bigtickextent) [expr ( $Analog(extent) - $Analog(bigticklong))]
    set Analog(minutearrowshape) [list \
      $Analog(minuteextent) \
      $Analog(minuteextent) \
      0 ]
    set Analog(hourarrowshape) [list \
      $Analog(hourextent) \
      $Analog(hourextent) \
      0 ]
    if { ! $Analog(bezel) } {
	set Analog(bezelcolor) $Analog(facecolor)
    }
    $Clock_window.analog create oval \
	[expr $Analog(xorig) - ($Analog(extent)) ] \
	[expr $Analog(yorig) - ($Analog(extent))] \
	[expr $Analog(xorig) + ($Analog(extent)) -1 ] \
	[expr $Analog(yorig) + ($Analog(extent)) ] \
	-outline $Analog(bezelcolor) -fill $Analog(facecolor) \
	-width $Analog(bezelthick)
    $Clock_window.analog create oval \
	[ expr $Analog(xorig)  - $Analog(hubextent)  ] \
	[ expr $Analog(yorig)  - $Analog(hubextent)  ] \
	[ expr $Analog(xorig) + $Analog(hubextent) -1 ]\
	[ expr $Analog(yorig) + $Analog(hubextent) -1 ]\
	-outline $Analog(hubcolor) -fill $Analog(hubcolor) -tags hub
    for {set time 0 } { $time != 60 } { incr time 5 } {
	if { 0 == ($time % 15) } { 
	    set fill $Analog(bigtickcolor)
	    set thick $Analog(bigtickthick)
	    set ext $Analog(bigtickextent)
	} else {
	    set fill $Analog(tickcolor)
	    set thick $Analog(tickthick)
	    set ext $Analog(tickextent)
	}
	set x1 [expr $Analog(xorig) + $Analog(extent) * cos($time * .10472) ]
	set y1 [expr $Analog(yorig) + $Analog(extent) * sin($time * .10472) ]
	set x2 [expr $Analog(xorig) + $ext * cos($time * .10472) ]
	set y2 [expr $Analog(yorig) + $ext * sin($time * .10472) ]
	$Clock_window.analog create line $x1 $y1 $x2 $y2 -fill $fill -width $thick
    }
    update idletasks
}

proc AnalogUpdate { } { 
    global Analog Clock Clock_window

    $Clock_window.analog delete killme

    set Analog(minute) $Clock(minute)
    set Analog(hour) [expr (5 * ($Clock(hour)%12)) + ($Clock(minute) / 12)]

    set x1 [expr $Analog(xorig) + $Analog(hubextent) * sin($Analog(minute) * .10472) ]
    set y1 [expr $Analog(yorig) - $Analog(hubextent) * cos($Analog(minute) * .10472) ]
    set x2 [expr $Analog(xorig) + $Analog(minuteextent) * sin($Analog(minute) * .10472) ]
    set y2 [expr $Analog(yorig) - $Analog(minuteextent) * cos($Analog(minute) * .10472) ]
    $Clock_window.analog create line $Analog(xorig) $Analog(yorig) \
	$x2 $y2 -arrow last -tags killme\
	-width $Analog(minutethick) -fill $Analog(minutecolor)\
	-arrowshape $Analog(minutearrowshape)
    set x1 [expr $Analog(xorig) + $Analog(hubextent) * sin($Analog(hour) * .10472) ]
    set y1 [expr $Analog(yorig) - $Analog(hubextent) * cos($Analog(hour) * .10472) ]
    set x2 [expr $Analog(xorig) + $Analog(hourextent) * sin($Analog(hour) * .10472) ]
    set y2 [expr $Analog(yorig) - $Analog(hourextent) * cos($Analog(hour) * .10472) ]
    $Clock_window.analog create line $Analog(xorig) $Analog(yorig) \
	$x2 $y2 -arrow last -tags  killme \
	-width $Analog(hourthick) -fill $Analog(hourcolor) \
	-arrowshape $Analog(hourarrowshape)
    $Clock_window.analog raise hub
    AlarmSet
}
