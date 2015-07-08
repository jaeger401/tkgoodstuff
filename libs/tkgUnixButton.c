/* 
 * tkUnixButton.c --
 *
 *	This file implements the Unix specific portion of the button
 *	widgets.
 *
 * Copyright (c) 1996 by Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * SCCS: @(#) tkUnixButton.c 1.3 96/11/07 20:00:02
 */

#include "tkgButton.h"

#include "default.h"
#include "tkPort.h"

#define max(a,b) (a > b ? a : b)
#define min(a,b) (a < b ? a : b)

/*
 * Declaration of Unix specific button structure.
 */

typedef struct UnixTkgButton {
    TkgButton info;		/* Generic button info. */
} UnixTkgButton;

/*
 * The class procedure table for the button widgets.
 */

TkClassProcs tkpTkgButtonProcs = { 
    NULL,			/* createProc. */
    TkgButtonWorldChanged,	/* geometryProc. */
    NULL			/* modalProc. */
};

/*
 *----------------------------------------------------------------------
 *
 * TkpCreateButton --
 *
 *	Allocate a new TkButton structure.
 *
 * Results:
 *	Returns a newly allocated TkButton structure.
 *
 * Side effects:
 *	Registers an event handler for the widget.
 *
 *----------------------------------------------------------------------
 */

TkgButton *
TkpCreateTkgButton(tkwin)
    Tk_Window tkwin;
{
    UnixTkgButton *butPtr = (UnixTkgButton *)ckalloc(sizeof(UnixTkgButton));
    return (TkgButton *) butPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TkpDisplayButton --
 *
 *	This procedure is invoked to display a button widget.  It is
 *	normally invoked as an idle handler.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Commands are output to X to display the button in its
 *	current mode.  The REDRAW_PENDING flag is cleared.
 *
 *----------------------------------------------------------------------
 */

void
TkpDisplayTkgButton(clientData)
    ClientData clientData;	/* Information about widget. */
{
    register TkgButton *butPtr = (TkgButton *) clientData;
  register Tk_Window tkwin = butPtr->tkwin;
    GC gc;
    Tk_3DBorder border;

  Pixmap pixmap;

  int width, height;              /* Width and height of button window */
  int x, y;                       /* Where to draw image or text */
  int relief;                     /* The button relief */
  int offset;                     /* The movement of button contents with relif */
  int lskirt, rskirt, yskirt;     /* Size of unusable edge of button window */
  int pixwidth, pixheight;        /* size of image */
  int pixxorig, pixyorig;         /* up-left corner of region in button for image */
  int pixwwidth, pixwheight;      /* size of region in button for image */
  int tilewidth, tileheight;      /* size of tile image */
  int textwidth, textheight;      /* size of text */
  int textxorig, textyorig;       /* up-left corner of region in button for text */
  int textwwidth, textwheight;    /* size of region in button for text */
  int wwidth, wheight;            /* size of usable region in button */
  int drawimage, drawbitmap, drawtext, drawtile;    /* do we draw an image, a bitmap, 
						    /*   text, tile? */
  char *side = butPtr->iconside; /* where does the image or bitmap go? */

    butPtr->flags &= ~REDRAW_PENDING;
    if ((butPtr->tkwin == NULL) || !Tk_IsMapped(tkwin)) {
	return;
    }

    border = butPtr->normalBorder;
    if ((butPtr->state == tkDisabledUid) && (butPtr->disabledFg != NULL)) {
	gc = butPtr->disabledGC;
    } else if ((butPtr->state == tkActiveUid)
	    && !Tk_StrictMotif(butPtr->tkwin)) {
	gc = butPtr->activeTextGC;
	border = butPtr->activeBorder;
    } else {
	gc = butPtr->normalTextGC;
    }
    if ((butPtr->flags & SELECTED) && (butPtr->state != tkActiveUid)
	    && (butPtr->selectBorder != NULL) && !butPtr->indicatorOn) {
	border = butPtr->selectBorder;
    }

    /*
     * Override the relief specified for the button if this is a
     * checkbutton or radiobutton and there's no indicator.
     */

    relief = butPtr->relief;
    if ((butPtr->type >= TYPE_CHECK_BUTTON) && !butPtr->indicatorOn) {
	relief = (butPtr->flags & SELECTED) ? TK_RELIEF_SUNKEN
		: TK_RELIEF_RAISED;
    }

    offset = ((butPtr->type == TYPE_BUTTON) ||
	      (butPtr->type == TYPE_MENU_BUTTON)) && !Tk_StrictMotif(butPtr->tkwin);

    /*
     * In order to avoid screen flashes, this procedure redraws
     * the button in a pixmap, then copies the pixmap to the
     * screen in a single operation.  This means that there's no
     * point in time where the on-sreen image has been cleared.
     */

    pixmap = Tk_GetPixmap(butPtr->display, Tk_WindowId(tkwin),
	    Tk_Width(tkwin), Tk_Height(tkwin), Tk_Depth(tkwin));
    Tk_Fill3DRectangle(tkwin, pixmap, border, 0, 0, Tk_Width(tkwin),
	    Tk_Height(tkwin), 0, TK_RELIEF_FLAT);


  /*
   * Calculate regions for image and text
   */

  drawimage = drawbitmap = drawtext = drawtile = 0;
  pixwidth = pixheight = textwidth = textheight = 0;
  if (butPtr->image != None) {
    drawimage = 1;
    Tk_SizeOfImage(butPtr->image, &pixwidth, &pixheight);
  } else if (butPtr->bitmap != None) {
    drawbitmap = 1;
    Tk_SizeOfBitmap(butPtr->display, butPtr->bitmap, &pixwidth, &pixheight);
  }
  if (butPtr->tileImage != None) {
    drawtile = 1;
    Tk_SizeOfImage(butPtr->tileImage, &tilewidth, &tileheight);
  }
  if (*butPtr->text) {
    drawtext = 1;
    textwidth = butPtr->textWidth;
    textheight = butPtr->textHeight;
  }

  width = Tk_Width(tkwin);
  height = Tk_Height(tkwin);
  rskirt = butPtr->inset + offset + butPtr->padX;
  lskirt = rskirt + butPtr->indicatorSpace;
  yskirt = butPtr->inset + offset + butPtr->padY;
  wwidth = width - lskirt - rskirt;
  wheight = height - 2 * yskirt;
  pixxorig =  textxorig = lskirt;
  pixyorig =  textyorig = yskirt;
  pixwwidth = textwwidth = wwidth - butPtr->indicatorSpace;
  pixwheight = textwheight = wheight;

  if (drawtile) {
    int tx, ty, tw, th;
    for (tx = butPtr->inset; tx < (width - butPtr->inset); tx += tilewidth) {
      for (ty = butPtr->inset; ty < (height - butPtr->inset); ty += tileheight) {
	tw = min(tilewidth,width - butPtr->inset - tx);
	th = min(tileheight,height - butPtr->inset - ty);
	Tk_RedrawImage(butPtr->tileImage, 0, 0, tw, th, pixmap,
		       tx, ty);
      }
    }
  }

  if (drawtext && (drawimage || drawbitmap)) {
    int iw, tw;
    iw = butPtr->imageWeight;
    tw = butPtr->textWeight;
    if (!(iw+tw)) {
      iw = 512;
    } else {
      iw = (int) (iw*1024)/(iw+tw);
    }
    /* we're drawing both; divide extra space according to weights*/
    if (!strcmp(side,LEFT) || !strcmp(side,RIGHT)) {
	pixwwidth = pixwidth + 
	  ((int) (wwidth - pixwidth - textwidth - butPtr->sep)*iw/1024);
	pixwwidth = max(pixwidth,pixwwidth);
	textwwidth = wwidth - pixwwidth - butPtr->sep;
	textwwidth = max(textwwidth,textwidth);
	if (!strcmp(side,LEFT)) {
	  textxorig = lskirt + pixwwidth +butPtr->sep;
	} else {
	  pixxorig = lskirt + textwwidth +butPtr->sep;
	}
    } else if (!strcmp(side,BOTTOM) || !strcmp(side,TOP)) {
      /* top or bottom */
	pixwheight = pixheight + 
	  ((int) (wheight - pixheight - textheight - butPtr->sep)*iw/1024);
	pixwheight = max(pixheight,pixwheight);
	textwheight = wheight - pixwheight - butPtr->sep;
	textwheight = max(textheight,textwheight);
	if (!strcmp(side,BOTTOM)) {
	  pixyorig = yskirt + textwheight + butPtr->sep;
	} else {
	  textyorig = yskirt + pixwheight + butPtr->sep;
	}
    }
  }
    
  /*
   * Locate image within its region on the button, and draw it.
   */
  if (drawimage || drawbitmap) {
    switch (butPtr->imageAnchor) {
    case TK_ANCHOR_NW: case TK_ANCHOR_W: case TK_ANCHOR_SW:
      x = pixxorig;
      break;
    case TK_ANCHOR_N: case TK_ANCHOR_CENTER: case TK_ANCHOR_S:
      x = pixxorig + ((int) (pixwwidth - pixwidth))/2;
      break;
    default:
      x = pixxorig + pixwwidth - pixwidth;
      break;
    }
    switch (butPtr->imageAnchor) {
    case TK_ANCHOR_NW: case TK_ANCHOR_N: case TK_ANCHOR_NE:
      y = pixyorig;
      break;
    case TK_ANCHOR_W: case TK_ANCHOR_CENTER: case TK_ANCHOR_E:
      y = pixyorig + (pixwheight - pixheight)/2;
      break;
    default:
      y = pixyorig + pixwheight - pixheight;
      break;
    }
    if (relief == TK_RELIEF_RAISED) {
      x -= offset;
      y -= offset;
    } else if (relief == TK_RELIEF_SUNKEN) {
      x += offset;
      y += offset;
    }
    if (drawimage) {
      Tk_RedrawImage(butPtr->image, 0, 0, pixwidth, pixheight, pixmap,
		     x, y);
    } else {
      XSetClipOrigin(butPtr->display, gc, x, y);
      XCopyPlane(butPtr->display, butPtr->bitmap, pixmap, gc, 0, 0,
		 (unsigned int) pixwidth, (unsigned int) pixheight, x, y, 1);
      XSetClipOrigin(butPtr->display, gc, 0, 0);
    }
  }

  /*
   * Locate text within its region on the button, and draw it.
   */

  if (drawtext) {
    switch (butPtr->textAnchor) {
    case TK_ANCHOR_NW: case TK_ANCHOR_W: case TK_ANCHOR_SW:
      x = textxorig;
      break;
    case TK_ANCHOR_N: case TK_ANCHOR_CENTER: case TK_ANCHOR_S:
      x = textxorig + ((int) (textwwidth - textwidth))/2;
      break;
    default:
      x = textxorig + textwwidth - textwidth;
      break;
    }
    switch (butPtr->textAnchor) {
    case TK_ANCHOR_NW: case TK_ANCHOR_N: case TK_ANCHOR_NE:
      y = textyorig;
      break;
    case TK_ANCHOR_W: case TK_ANCHOR_CENTER: case TK_ANCHOR_E:
      y = textyorig + ((int) (textwheight - textheight))/2;
      break;
    default:
      y = textyorig + textwheight - textheight;
      break;
    }
    if (relief == TK_RELIEF_RAISED) {
      x -= offset;
      y -= offset;
    } else if (relief == TK_RELIEF_SUNKEN) {
      x += offset;
      y += offset;
    }
    Tk_DrawTextLayout(butPtr->display, pixmap, gc, butPtr->textLayout,
		      x, y, 0, -1);
    Tk_UnderlineTextLayout(butPtr->display, pixmap, gc,
			   butPtr->textLayout, x, y, butPtr->underline);
    y += textheight/2;
  }

    /*
     * Draw the indicator for check buttons and radio buttons.  At this
     * point x and y refer to the top-left corner of the text or image
     * or bitmap.
     */

    if ((butPtr->type == TYPE_CHECK_BUTTON) && butPtr->indicatorOn) {
	int dim;

	dim = butPtr->indicatorDiameter;
	x -= butPtr->indicatorSpace;
	y -= dim/2;
	if (dim > 2*butPtr->borderWidth) {
	    Tk_Draw3DRectangle(tkwin, pixmap, border, x, y, dim, dim,
		    butPtr->borderWidth, 
		    (butPtr->flags & SELECTED) ? TK_RELIEF_SUNKEN :
		    TK_RELIEF_RAISED);
	    x += butPtr->borderWidth;
	    y += butPtr->borderWidth;
	    dim -= 2*butPtr->borderWidth;
	    if (butPtr->flags & SELECTED) {
		GC gc;

		gc = Tk_3DBorderGC(tkwin,(butPtr->selectBorder != NULL)
			? butPtr->selectBorder : butPtr->normalBorder,
			TK_3D_FLAT_GC);
		XFillRectangle(butPtr->display, pixmap, gc, x, y,
			(unsigned int) dim, (unsigned int) dim);
	    } else {
		Tk_Fill3DRectangle(tkwin, pixmap, butPtr->normalBorder, x, y,
			dim, dim, butPtr->borderWidth, TK_RELIEF_FLAT);
	    }
	}
    } else if ((butPtr->type == TYPE_RADIO_BUTTON) && butPtr->indicatorOn) {
	XPoint points[4];
	int radius;

	radius = butPtr->indicatorDiameter/2;
	points[0].x = x - butPtr->indicatorSpace;
	points[0].y = y;
	points[1].x = points[0].x + radius;
	points[1].y = points[0].y + radius;
	points[2].x = points[1].x + radius;
	points[2].y = points[0].y;
	points[3].x = points[1].x;
	points[3].y = points[0].y - radius;
	if (butPtr->flags & SELECTED) {
	    GC gc;

	    gc = Tk_3DBorderGC(tkwin, (butPtr->selectBorder != NULL)
		    ? butPtr->selectBorder : butPtr->normalBorder,
		    TK_3D_FLAT_GC);
	    XFillPolygon(butPtr->display, pixmap, gc, points, 4, Convex,
		    CoordModeOrigin);
	} else {
	    Tk_Fill3DPolygon(tkwin, pixmap, butPtr->normalBorder, points,
		    4, butPtr->borderWidth, TK_RELIEF_FLAT);
	}
	Tk_Draw3DPolygon(tkwin, pixmap, border, points, 4, butPtr->borderWidth,
		(butPtr->flags & SELECTED) ? TK_RELIEF_SUNKEN :
		TK_RELIEF_RAISED);
    }

    /*
     * If the button is disabled with a stipple rather than a special
     * foreground color, generate the stippled effect.  If the widget
     * is selected and we use a different background color when selected,
     * must temporarily modify the GC.
     */

    if ((butPtr->state == tkDisabledUid)
	    && ((butPtr->disabledFg == NULL) || (butPtr->image != NULL))) {
	if ((butPtr->flags & SELECTED) && !butPtr->indicatorOn
		&& (butPtr->selectBorder != NULL)) {
	    XSetForeground(butPtr->display, butPtr->disabledGC,
		    Tk_3DBorderColor(butPtr->selectBorder)->pixel);
	}
	XFillRectangle(butPtr->display, pixmap, butPtr->disabledGC,
		butPtr->inset, butPtr->inset,
		(unsigned) (Tk_Width(tkwin) - 2*butPtr->inset),
		(unsigned) (Tk_Height(tkwin) - 2*butPtr->inset));
	if ((butPtr->flags & SELECTED) && !butPtr->indicatorOn
		&& (butPtr->selectBorder != NULL)) {
	    XSetForeground(butPtr->display, butPtr->disabledGC,
		    Tk_3DBorderColor(butPtr->normalBorder)->pixel);
	}
    }

    /*
     * Draw the border and traversal highlight last.  This way, if the
     * button's contents overflow they'll be covered up by the border.
     */

    if (relief != TK_RELIEF_FLAT) {
	int inset = butPtr->highlightWidth;
	if (butPtr->isDefault) {
	    inset += 2;
	    Tk_Draw3DRectangle(tkwin, pixmap, border, inset, inset,
		    Tk_Width(tkwin) - 2*inset, Tk_Height(tkwin) - 2*inset,
		    1, TK_RELIEF_SUNKEN);
	    inset += 3;
	}
	Tk_Draw3DRectangle(tkwin, pixmap, border, inset, inset,
		Tk_Width(tkwin) - 2*inset, Tk_Height(tkwin) - 2*inset,
		butPtr->borderWidth, relief);
    }
    if (butPtr->highlightWidth != 0) {
	GC gc;

	if (butPtr->flags & GOT_FOCUS) {
	    gc = Tk_GCForColor(butPtr->highlightColorPtr, pixmap);
	} else {
	    gc = Tk_GCForColor(butPtr->highlightBgColorPtr, pixmap);
	}
	Tk_DrawFocusHighlight(tkwin, gc, butPtr->highlightWidth, pixmap);
    }

    /*
     * Copy the information from the off-screen pixmap onto the screen,
     * then delete the pixmap.
     */

    XCopyArea(butPtr->display, pixmap, Tk_WindowId(tkwin),
	    butPtr->copyGC, 0, 0, (unsigned) Tk_Width(tkwin),
	    (unsigned) Tk_Height(tkwin), 0, 0);
    Tk_FreePixmap(butPtr->display, pixmap);
}

/*
 *----------------------------------------------------------------------
 *
 * TkpComputeButtonGeometry --
 *
 *	After changes in a button's text or bitmap, this procedure
 *	recomputes the button's geometry and passes this information
 *	along to the geometry manager for the window.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The button's window may change size.
 *
 *----------------------------------------------------------------------
 */

void
TkpComputeTkgButtonGeometry(butPtr)
    register TkgButton *butPtr;	/* Button whose geometry may have changed. */
{
    int pixwidth, pixheight, textwidth, textheight, width, height;
    int avgWidth;
    Tk_FontMetrics fm;
  int drawimage, drawtext;	/* Are we drawing an image? text? */
  char *side;

  pixwidth = pixheight = textwidth = textheight = 
    width = height = drawimage = drawtext = 0;

    if (butPtr->highlightWidth < 0) {
	butPtr->highlightWidth = 0;
    }
    butPtr->inset = butPtr->highlightWidth + butPtr->borderWidth;

    /*
     * Leave room for the default ring if needed.
     */

    if (butPtr->isDefault) {
	butPtr->inset += 5;
    }
    butPtr->indicatorSpace = 0;

    /*
     * Get size of image or bitmap.
     */

    if (butPtr->image != NULL) {
	Tk_SizeOfImage(butPtr->image, &pixwidth, &pixheight);
	drawimage = 1;
    } else if (butPtr->bitmap != None) {
	Tk_SizeOfBitmap(butPtr->display, butPtr->bitmap, &pixwidth, &pixheight);
	drawimage = 1;
    }

    if (strlen(butPtr->text) > 0) {
      drawtext = 1;
	Tk_FreeTextLayout(butPtr->textLayout);
	butPtr->textLayout = Tk_ComputeTextLayout(butPtr->tkfont,
		butPtr->text, -1, butPtr->wrapLength, butPtr->justify, 0,
		&butPtr->textWidth, &butPtr->textHeight);

	textwidth = butPtr->textWidth;
	textheight = butPtr->textHeight;
    }

  side = butPtr->iconside;
  if (!strcmp(side,LEFT) || !strcmp(side,RIGHT)) {
    height = max(pixheight,textheight);
    width = pixwidth + textwidth;
    if (drawimage && drawtext) {
      width += butPtr->sep;
    }
  } else if (!strcmp(side,BOTTOM) || !strcmp(side,TOP)) {
    width = max(pixwidth,textwidth);
    height = pixheight + textheight;
    if (drawimage && drawtext) {
      height += butPtr->sep;
    }
  } else {
    width = max(pixwidth,textwidth);
    height = max(pixheight,textheight);
  }

  if ((butPtr->type >= TYPE_CHECK_BUTTON) && butPtr->indicatorOn) {
    butPtr->indicatorSpace = height;
    if (butPtr->type == TYPE_CHECK_BUTTON) {
      butPtr->indicatorDiameter = (65*height)/100;
    } else {
      butPtr->indicatorDiameter = (75*height)/100;
    }
  }
  width += butPtr->indicatorSpace;

  width += 2*butPtr->padX;
  height += 2*butPtr->padY;

    if ((butPtr->type == TYPE_BUTTON) && !Tk_StrictMotif(butPtr->tkwin)) {
	width += 2;
	height += 2;
    }

    if (butPtr->width > 0) {
      width = butPtr->width;
    }
    if (butPtr->height > 0) {
      height = butPtr->height;
    }

    Tk_GeometryRequest(butPtr->tkwin, (int) (width + butPtr->indicatorSpace
	    + 2*butPtr->inset), (int) (height + 2*butPtr->inset));
    Tk_SetInternalBorder(butPtr->tkwin, butPtr->inset);
}
