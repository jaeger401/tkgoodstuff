/* 
 * tkFvwm.c --
 *
 * 	This file implements the "fvwm" command, which permits the
 *	comunication between the fvwm window manager and modules
 *	written in Tcl.
 *
 * Copyright(c) 1995 Andres Aravena (andres@aravena.mic.cl)
 * Portions Copyright(c) 1988-1994 The Regents of the University of California.
 * Portions Copyright(c) 1994 Sun Microsystems, Inc.
 * This file can be redistributed under the same terms of the Tcl/Tk core.
 * */

/* Updated for tk4.1, fvwm2 (and fvwm95) by M. Crimmins 1/96.  
 *  Various enhancements, bugfixes 2/96, 6/96
 *
 * Athr: Michael D. Beynon (mdb)
 * Date: 04/18/1996 : mdb - Converted Tk_*() calls that were moved to
 *                          Tcl_*() calls.  A Tcl_File type is now needed
 *                          for the Tcl_CreateFileHandler() call.
 */

static char version[] = "tkFvwm.c version 4.1";
#include "tcl.h"
#include "tk.h"
#include "fvwmlib.h" /* from fvwm source */
#include "module.h"  /* from fvwm source */

/*
 * These arrays contain the message types from fvwm.  Unfortunately, 
 * they change from time to time.  Up to date as of fvwm-2.0.43.
 */

static char *
fvwmName[] = {"DeadPipe", "NewPage", "NewDesk", "AddWindow",
	      "RaiseWindow", "LowerWindow", "ConfigureWindow", "FocusChange",
	      "DestroyWindow", "Iconify", "Deiconify", "WindowName",
	      "IconName", "ResClass", "ResName", "EndWindowlist",
	      "IconLocation", "Map", "Error", "ConfigInfo", "EndConfigInfo",
	      "IconFile", "DefaultIcon", "String", "MiniIcon",
	      "WindowShade", "DeWindowShade"};

static unsigned long
fvwmCode[] = {0, M_NEW_PAGE,  M_NEW_DESK, M_ADD_WINDOW,
	      M_RAISE_WINDOW, M_LOWER_WINDOW, M_CONFIGURE_WINDOW,
	      M_FOCUS_CHANGE, M_DESTROY_WINDOW, M_ICONIFY, M_DEICONIFY,
	      M_WINDOW_NAME, M_ICON_NAME, M_RES_CLASS, M_RES_NAME,
	      M_END_WINDOWLIST, M_ICON_LOCATION, M_MAP, M_ERROR,
	      M_CONFIG_INFO, M_END_CONFIG_INFO, M_ICON_FILE,
	      M_DEFAULTICON, M_STRING, M_MINI_ICON,
	      M_WINDOWSHADE, M_DEWINDOWSHADE};

static char *fvwmScript[MAX_MESSAGES+1] = {"exit", NULL};
static Tcl_Interp *fvwmInterp;
static int fvwmFD[2] = {-1,-1};

/*
 * These macros give access to the interface data, making easy to switch
 * to other data structures, if needed.
 */
#define FD fvwmFD
#define SCRIPT(I) fvwmScript[I]
#define CODE(I) fvwmCode[I]
#define NAME(I) fvwmName[I]
#define CHECK(X)  if(X==TCL_OK) {} else {return TCL_ERROR;}

/*
 *--------------------------------------------------------------
 *
 * DeadPipe --
 *
 *	The following function is requiered by ReadFvwmPacket
 * 	It's called whenever the pipe is closed, as when FVWM dies.
 *
 * Results: The script in SCRIPT(0) is evaluated in the context of
 *	fvwmInterp. Note that no expansion of percents is realized,
 *	because DeadPipe is not bound to any FVWM message.
 *
 * Side effects:
 *	If not changed by the user, DeadPipe evaluates "exit", so
 *	the interpreter is finished.
 *
 *-------------------------------------------------------------- */
void DeadPipe(int dummy)
{
    int ans;

    Tcl_DeleteFileHandler(FD[1]);
    /*    Tcl_FreeFile(Tcl_GetFile((ClientData)FD[1], TCL_UNIX_FD)); */
    close(FD[0]);
    close(FD[1]);
    ans=Tcl_GlobalEval(fvwmInterp,SCRIPT(0));
    if(ans==TCL_ERROR) {
	Tcl_AddErrorInfo(fvwmInterp, "\n (command bound to fvwm)");
	Tcl_BackgroundError(fvwmInterp);
    }
}

/*
 *--------------------------------------------------------------
 *
 * ExpandPercents --
 *
 *	Given a command and a FVWM Packet, produce a new command
 *	by replacing % constructs in the original command
 *	with information from the FVWM packet.
 *
 *      This is a modification of the analog function in tkBind.c,
 *	which has the following copyright:
 *
 * Copyright (c) 1989-1994 The Regents of the University of California.
 * Copyright (c) 1994-1995 Sun Microsystems, Inc.
 *
 * Results:
 *	The new expanded command is appended to the dynamic string
 *	given by dsPtr.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

static void
ExpandPercents(before, body, dsPtr)
    register char *before;	/* Command containing percent
				 * expressions to be replaced. */
    unsigned long *body;	/* FVWM data packet */
    Tcl_DString *dsPtr;		/* Dynamic string in which to append
				 * new command. */
{
    int spaceNeeded, cvtFlags;	/* Used to substitute string as proper Tcl
				 * list element. */
    unsigned long number;
    int length;
#define NUM_SIZE 40
    register char *string;
    char numStorage[NUM_SIZE+1];

    while (1) {
	/*
	 * Find everything up to the next % character and append it
	 * to the result string.
	 */

	for (string = before; (*string != 0) && (*string != '%'); string++) {
	    /* Empty loop body. */
	}
	if (string != before) {
	    Tcl_DStringAppend(dsPtr, before, string-before);
	    before = string;
	}
	if (*before == 0) {
	    break;
	}

	/*
	 * There's a percent sequence here.  Process it.
	 */

	number = 0;
	string = "??";
	switch (before[1]) {
	case 'W':
	    sprintf(numStorage, "0x%lx", body[0]); /* window id */
	    string = numStorage;
	    goto doString;
	case 'x':
	    number = body[3]; /* window horizontal pos */
	    goto doNumber;
	case 'y':
	    number = body[4]; /* window vertical pos */
	    goto doNumber;
	case 'w':
	    number = body[5]; /* window width */
	    goto doNumber;
	case 'h':
	    number = body[6]; /* window height */
	    goto doNumber;
	case 't':
	    number = body[7]; /* desktop (ConfigureWindow packet) */
	    goto doNumber;
	case 'f':
	    sprintf(numStorage, "0x%lx", body[8]);  /* flags */
	    string = numStorage;
	    goto doString;
	case 'N':
	    string = (char *)(&body[3]); /* window, icon or class name */
	    goto doString;
	case 'T':
	    number = body[0]; /* new desktop (NewDesk packet) */
	    goto doNumber;
	case 'D':
	    number = body[2]; /* new desktop (NewPage packet) */
	    goto doNumber;
	case 'X':
	    number = body[0]; /* new desk horizontal pos */
	    goto doNumber;
	case 'Y':
	    number = body[1]; /* new desk vertical pos */
	    goto doNumber;
	default:
	    numStorage[0] = before[1];
	    numStorage[1] = '\0';
	    string = numStorage;
	    goto doString;
	}

	doNumber:
	sprintf(numStorage, "%ld", number);
	string = numStorage;

	doString:
	spaceNeeded = Tcl_ScanElement(string, &cvtFlags);
	length = Tcl_DStringLength(dsPtr);
	Tcl_DStringSetLength(dsPtr, length + spaceNeeded);
	spaceNeeded = Tcl_ConvertElement(string,
		Tcl_DStringValue(dsPtr) + length,
		cvtFlags | TCL_DONT_USE_BRACES);
	Tcl_DStringSetLength(dsPtr, length + spaceNeeded);
	before += 2;
    }
}

/*
 *--------------------------------------------------------------
 *
 * FvwmMsgHandler --
 *
 *	This function is called when the pipe from fvwm has data to be
 *	read by the module.
 *
 * Results:
 *	If a handler for the given message has been defined, it is
 *	interpreted on the fvwmInterp global context.
 *
 * Side effects:
 *	None.
 *
 *-------------------------------------------------------------- */

static void
FvwmMsgHandler(ClientData clientData, int mask)
{
    unsigned long header[HEADER_SIZE], *body;
    int i;

    if(mask & TCL_EXCEPTION) {
	DeadPipe(0);
    }
    ReadFvwmPacket(FD[1],header,&body);
    for(i=1; i<=MAX_MESSAGES; i++) {
	if((CODE(i)==header[1]) &&
	   (SCRIPT(i)!=NULL) &&
	   (SCRIPT(i)[0]!='\0')) {
	    int ans;
	    Tcl_DString ds;

	    Tcl_DStringInit(&ds);
	    ExpandPercents(SCRIPT(i),body,&ds);
	    ans=Tcl_GlobalEval(fvwmInterp,Tcl_DStringValue(&ds));
	    if(ans==TCL_ERROR) {
		Tcl_AddErrorInfo(fvwmInterp, "\n (command bound to fvwm)");
		Tcl_BackgroundError(fvwmInterp);
	    }
	    Tcl_DStringFree(&ds);
	}
    }
    free(body);
}

void FvwmClose (ClientData data) {
  Tcl_DeleteFileHandler(FD[1]);
  /*  Tcl_FreeFile(Tcl_GetFile((ClientData)FD[1], TCL_UNIX_FD));*/
  close(FD[1]);
  close(FD[2]);
}  

/*
 *--------------------------------------------------------------
 *
 * FvwmCmd --
 *
 *      This procedure is invoked to process the "fvwm" Tcl command.
 *      See the user documentation for details on what it does.
 *
 * Results:
 *      A standard Tcl result.
 *
 * Side effects:
 *	The fvwmInterp variable gets defined the first time the "init"
 *	option is used. The message handlers may be modified.
 *
 *-------------------------------------------------------------- */

int 
FvwmCmd(ClientData clientData, Tcl_Interp *interp, int argc, char *argv[])
{
    int i,len;

    if (argc<2) {
	interp->result = "Wrong # of args";
	return TCL_ERROR;
    }
    if((argv[1][0]=='i') && !strcmp(argv[1],"init")) {
	if(argc!=4) {
	    sprintf(interp->result,"Wrong # of args, should be: %s init"
		    "<output-fd> <input-fd>",argv[0]);
	    return TCL_ERROR;
	}
	if((FD[0] != -1)||(FD[1] != -1)) {
	    interp->result="fvwm already initialized";
	    return TCL_ERROR;
	}
	CHECK(Tcl_GetInt(interp,argv[2],&FD[0]));
	CHECK(Tcl_GetInt(interp,argv[3],&FD[1]));
	Tcl_CreateFileHandler(FD[1],
			      TCL_READABLE|TCL_EXCEPTION, FvwmMsgHandler,
			      clientData);
	fvwmInterp=interp;
	Tcl_CreateExitHandler(FvwmClose,(ClientData)NULL);
	return TCL_OK;
    }

    if((argv[1][0]=='s') && !strcmp(argv[1],"send")) {
	if(argc!=4) {
	    sprintf(interp->result,"Wrong # of args, should be: %s send"
		    "windowID message",argv[0]);
	    return TCL_ERROR;
	}
	if(FD[0] == -1) {
	    interp->result="fvwm not initialized";
	    return TCL_ERROR;
	}
	CHECK(Tcl_GetInt(interp,argv[2],&i));
	SendInfo(FD,argv[3],i);
	return TCL_OK;
    }

    len=strlen(argv[1]);
    for(i=0; i<=MAX_MESSAGES; i++) {
	if(!strncasecmp(argv[1],NAME(i),len)) {
	    if(argc==2) {
		if(SCRIPT(i)!=NULL)
		    interp->result=SCRIPT(i);
		return TCL_OK;
	    }
	    if(argc==3) {
		if(SCRIPT(i)!=NULL) {
		    free(SCRIPT(i));
		}
		SCRIPT(i)=(char*)ckalloc(strlen(argv[2])+1);
		strcpy(SCRIPT(i),argv[2]);
		return TCL_OK;
	    }
	    sprintf(interp->result,"Wrong # of args, should be: %s %s"
		    " ?script?",argv[0],NAME(i));
	    return TCL_ERROR;	    
	}
    }

    sprintf(interp->result,"unknown option %s",argv[1]);
    return TCL_ERROR;
  }

/*REMAINING STUFF TAKEN FROM FVWM2'S LIBRARY CODE; FVWM COPYRIGHTS APPLY*/

/************************************************************************
 * 
 * Reads a single packet of info from fvwm. Prototype is:
 * unsigned long header[HEADER_SIZE];
 * unsigned long *body;
 * int fd[2];
 * void DeadPipe(int nonsense);  * Called if the pipe is no longer open  *
 *
 * ReadFvwmPacket(fd[1],header, &body);
 *
 * Returns:
 *   > 0 everything is OK.
 *   = 0 invalid packet.
 *   < 0 pipe is dead. (Should never occur)
 *   body is a malloc'ed space which needs to be freed 
 *
 **************************************************************************/
int ReadFvwmPacket(int fd, unsigned long *header, unsigned long **body)
{
  int count,total,count2,body_length;
  char *cbody;
  extern void DeadPipe(int);

  if((count = read(fd,header,HEADER_SIZE*sizeof(unsigned long))) >0)
    {
      if(header[0] == START_FLAG)
	{
	  body_length = header[2]-HEADER_SIZE;
	  *body = (unsigned long *)
	    safemalloc(body_length * sizeof(unsigned long));
	  cbody = (char *)(*body);
	  total = 0;
	  while(total < body_length*sizeof(unsigned long))
	    {
	      if((count2=
		  read(fd,&cbody[total],
		       body_length*sizeof(unsigned long)-total)) >0)
		{
		  total += count2;
		}
	      else if(count2 < 0)
		{
		  DeadPipe(1);
		}
	    }
	}
      else
	count = 0;
    }
  if(count <= 0)
    DeadPipe(1);
  return count;
}

/***********************************************************************
 *
 *  Procedure:
 *	safemalloc - mallocs specified space or exits if there's a 
 *		     problem
 *
 ***********************************************************************/
char *safemalloc(int length)
{
  char *ptr;

  if(length <= 0)
    length = 1;

  ptr = (char *)malloc(length);
  if(ptr == (char *)0)
    {
      fprintf(stderr,"malloc of %d bytes failed. Exiting\n",length);
      exit(1);
    }
  return ptr;
}

/***********************************************************************
 *
 *  Procedure:
 *	SendInfo - send a command back to fvwm 
 *
 ***********************************************************************/
void SendInfo(int *fd,char *message,unsigned long window)
{
  int w;

  if(message != NULL)
    {
      write(fd[0],&window, sizeof(unsigned long));
      w=strlen(message);
      write(fd[0],&w,sizeof(int));
      write(fd[0],message,w);

      /* keep going */
      w=1;
      write(fd[0],&w,sizeof(int));
    }
}

int 
Tkfvwm_Init(interp)
    Tcl_Interp *interp;		/* Interpreter in which the package is
				 * to be made available. */
{
    int code;
    code = Tcl_PkgProvide(interp, "Tkfvwm", "4.1");
    if (code != TCL_OK) {
	return code;
    }
  Tcl_CreateCommand(interp, "fvwm", FvwmCmd, (ClientData) 0,
	    (Tcl_CmdDeleteProc *) NULL);
  return TCL_OK;
}

 
