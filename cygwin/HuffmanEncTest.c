#include "Huffman.h"
#include "CStyleFile.h"

int main(int argc, char* argv[])
{
    FILE *f;
    unsigned char *in, *out, algo=0;
    unsigned int  insize, outsize=0;
    char *inname, *outname;

    if( argc < 3 )
    {
		printf( "Usage: %s infile outfile\n", argv[ 0 ] );
        return 0;
    }
    
	inname  = argv[ 1 ];
    outname = argv[ 2 ];

    f = fopen( inname , "rb" );
    if( !f )
    {
        printf( "Unable to open input file \"%s\".\n", inname );
        return 0;
    }

    insize = GetFileSize( f );

	printf( "compress " );
    printf( "%s to %s...\n", inname, outname );

    printf( "Input file: %d bytes\n", insize );
    in = (unsigned char *) malloc( insize );
    if( !in )
    {
        printf( "Not enough memory\n" );
        fclose( f );
        return 0;
    }
    fread( in, insize, 1, f );
    fclose( f );

    f = fopen( outname, "wb" );
    if( !f )
    {
        printf( "Unable to open output file \"%s\".\n", outname );
        free( in );
        return 0;
    }

    outsize = (insize*104+50)/100 + 384;

    out = (unsigned char*)malloc( outsize );
    if( !out )
    {
        printf( "Not enough memory\n" );
        fclose( f );
        free( in );
        return 0;
    }

	outsize = Huffman_Compress( in, out, insize );
    printf( "Output file: %d bytes (%.1f%%)\n", outsize, 100*(float)outsize/(float)insize );

	fwrite( &insize, sizeof(int), 1, f);
    fwrite( out, outsize, 1, f );
    fclose( f );

    free( in );
    free( out );

    return 0;
}

