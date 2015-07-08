# "Example" client code for tkgoodstuff
# (replace "Example" throughtout with your own client name)


# This gets called when the panel is being formed

proc ExampleCreateWindow {} {

    # The following is for redrawing the button when the panel is 
    # redrawn, e.g., following a screen-edge move.
    if [TKGReGrid Example] return

    global Example-params ;# The array of button parameters

    # This creates a tkgbutton and places it in the appropriate place 
    # in the panel.
    TKGMakeButton Example \
	-imagefile xlogo.xpm \
	-text "Example" \
	-balloon "This is the\nballoon help text." \
	-command "ExampleButton1Command"
    
    # Bind mouse button 3 to another command
    bind [set Example-params(pathname)] <3> ExampleButton3Command
}

proc ExampleButton1Command {} {
    TKGNotice "This is the button 1 command"
}

proc ExampleButton3Command {} {
    TKGNotice "This is one part of the button 3 command"

    # This is how to do unix commands.  Note the trailing "&",
    # which puts the command in the background, so as not to 
    # freeze up tkgoodstuff!
    exec xmessage "and this is the other part" &
}

# Procedures with special functions:
#
# ExampleDoOnLoad: called when client is first loaded.
#
# ExampleDeclare: called just after all the DoOnLoads, and when the 
#   client is added in the preferences manager.  Meant for calls to 
#   TKGDeclare.  See any client for examples
#
# ExampleStart: called when all panels have been created (including
#   after moving to another screen edge.
#
# ExampleSuspend: called when panel is about to be moved to 
#   another screen edge.

DEBUG "Loaded Example.tcl"

