#ifndef FVWMLIB_H
#define FVWMLIB_H
#include <X11/Xlib.h>
#include <X11/Xutil.h>

int mystrcasecmp(char *a, char *b);
int mystrncasecmp(char *a, char *b,int n);
char *CatString3(char *a, char *b, char *c);
int mygethostname(char *client, int namelen);
void SendText(int *fd,char *message,unsigned long window);
void SendInfo(int *fd,char *message,unsigned long window);
char *safemalloc(int);
char *findIconFile(char *icon, char *pathlist, int type);
int ReadFvwmPacket(int fd, unsigned long *header, unsigned long **body);
void CopyString(char **dest, char *source);
void sleep_a_little(int n);
int GetFdWidth(void);
void *GetConfigLine(int *fd, char **tline);
void SetMessageMask(int *fd, unsigned long mask);
int  envExpand(char *s, int maxstrlen);
char *envDupExpand(const char *s, int extra);

typedef struct PictureThing
{
  char *name;
  Pixmap picture;
  Pixmap mask;
  int depth;
  int width;
  int height;
} Picture;

void GetPicture(Display *, Window Root, char *iconpath, char *pixmappath,
		char *name, Picture *p);
void DestroyPicture(Display *, Picture *p);
void InitPicture(Picture *p);

XFontStruct *GetFontOrFixed(Display *disp, char *fontname);

#endif
