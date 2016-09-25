#ifndef __LOADER_C_CSTYLEFILE__
#define __LOADER_C_CSTYLEFILE__

#include <stdio.h>

extern long GetFileSize( FILE *f );
extern void WriteWord32( int x, FILE *f );
extern int  ReadWord32 ( FILE *f );

#endif
