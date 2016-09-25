#include "CStyleFile.h"

void WriteWord32( int x, FILE *f )
{
	fputc( (x>>24)&255, f );
	fputc( (x>>16)&255, f );
	fputc( (x>>8)&255, f );
	fputc( x&255, f );
}
