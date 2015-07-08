#include "tcl.h"
#include "tk.h"

EXTERN int Tk_TkgFrameCmd (ClientData clientdata, Tcl_Interp *interp, int argc, char **argv);
EXTERN int Tk_TkgToplevelCmd (ClientData clientdata, Tcl_Interp *interp, int argc, char **argv);
EXTERN int Tkg_LabelCmd (ClientData clientdata, Tcl_Interp *interp, int argc, char **argv);
EXTERN int Tkg_ButtonCmd (ClientData clientdata, Tcl_Interp *interp, int argc, char **argv);
EXTERN int Tkg_MenubuttonCmd (ClientData clientdata, Tcl_Interp *interp, int argc, char **argv);
EXTERN int Tkg_CheckbuttonCmd (ClientData clientdata, Tcl_Interp *interp, int argc, char **argv);
EXTERN int Tkg_RadiobuttonCmd (ClientData clientdata, Tcl_Interp *interp, int argc, char **argv);

#if !defined(HAVE_STRERROR)
char* strerror(code)
int code;
{
  return ("(Fake strerror, sorry.)");
}
#endif

int 
Tkg_Init(interp)
    Tcl_Interp *interp;		/* Interpreter in which the package is
				 * to be made available. */
{
  int code;
  if (Tkgwidgets_Init(interp) != TCL_OK) {
    return TCL_ERROR;
  }
  code = Tcl_PkgProvide(interp, "Tkg", "8.0");
  if (code != TCL_OK) {
    return code;
  }
  return TCL_OK;
}

int 
Tkgwidgets_Init(interp)
Tcl_Interp *interp;		/* Interpreter in which the package is
				 * to be made available. */
{
  int code;
  Tk_Window tkwin;

  if (!(tkwin = Tk_MainWindow(interp))) {
    return TCL_ERROR;
  }
  Tcl_CreateCommand(interp, "tkgframe", Tk_TkgFrameCmd, 
		    (ClientData) tkwin, (void (*)()) NULL);
  Tcl_CreateCommand(interp, "tkgtoplevel", Tk_TkgToplevelCmd, 
		    (ClientData) tkwin, (void (*)()) NULL);
  Tcl_CreateCommand(interp, "tkglabel", Tkg_LabelCmd, 
		    (ClientData) tkwin, (void (*)()) NULL);
  Tcl_CreateCommand(interp, "tkgbutton", Tkg_ButtonCmd, 
		    (ClientData) tkwin, (void (*)()) NULL);
  Tcl_CreateCommand(interp, "tkgmenubutton", Tkg_MenubuttonCmd, 
		    (ClientData) tkwin, (void (*)()) NULL);
  Tcl_CreateCommand(interp, "tkgcheckbutton", Tkg_CheckbuttonCmd, 
		    (ClientData) tkwin, (void (*)()) NULL);
  Tcl_CreateCommand(interp, "tkgradiobutton", Tkg_RadiobuttonCmd, 
		    (ClientData) tkwin, (void (*)()) NULL);
  return TCL_OK;
}

