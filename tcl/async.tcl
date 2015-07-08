# procedures for periodic background tasks.

proc TKGPeriodic {name period offset command} {
    global TKG_after
    TKGPeriodicCancel $name
    set TKG_after($name)\
	[after [expr 1000 * $offset] [list TKG_async_do $name $period $command]]
}

proc TKG_async_do {name period command} {
    global TKG_after
    set TKG_after($name)\
	[after [expr 1000 * $period] [list TKG_async_do $name $period $command]]
    eval $command
}

proc TKGPeriodicCancel {name} {
    global TKG_after
    catch {after cancel $TKG_after($name)}
}
