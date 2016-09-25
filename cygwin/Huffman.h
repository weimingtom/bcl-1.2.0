#ifndef __CODER_C_HUFFMAN__
#define __CODER_C_HUFFMAN__

#include <stdio.h>
#include <malloc.h>

#define MAX_TREE_NODES 511

typedef struct {
    unsigned char *BytePtr;
    unsigned int  BitPos;
} huff_bitstream_t;

typedef struct {
    int Symbol;
    unsigned int Count;
    unsigned int Code;
    unsigned int Bits;
} huff_sym_t;

typedef struct huff_encodenode_struct huff_encodenode_t;
struct huff_encodenode_struct {
    huff_encodenode_t *ChildA, *ChildB;
    int Count;
    int Symbol;
};

typedef struct huff_decodenode_struct huff_decodenode_t;
struct huff_decodenode_struct {
    huff_decodenode_t *ChildA, *ChildB;
    int Symbol;
};

extern void Huffman_Uncompress( unsigned char *in, unsigned char *out, unsigned int insize, unsigned int outsize );
extern int  Huffman_Compress( unsigned char *in, unsigned char *out, unsigned int insize );

#endif
