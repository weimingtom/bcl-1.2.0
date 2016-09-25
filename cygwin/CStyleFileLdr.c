#include "CStyleFile.h"

int ReadWord32( FILE *f )
{
	unsigned char buf[4];
	fread( buf, 4, 1, f );
	return (((unsigned int)buf[3])<<24) +
	       (((unsigned int)buf[2])<<16) +
		   (((unsigned int)buf[1])<<8)  +
		   (unsigned int)buf[0];
}

long GetFileSize( FILE *f )
{
    long pos, size;

    pos = ftell( f );
    fseek( f, 0, SEEK_END );
    size = ftell( f );
    fseek( f, pos, SEEK_SET );

    return size;
}

