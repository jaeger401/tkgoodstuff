wm title . tkgoodstuff
wm withdraw .

# Replace "~" with home directory in env(PATH)
if { [string first ~ $env(PATH)] != -1} {
    regsub -all ~ $env(PATH) [glob ~] env(PATH)
}

set auto_path [linsert $auto_path 0 $TKG(libdir)/tcl $TKG(libdir)]

