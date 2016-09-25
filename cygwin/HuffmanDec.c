#include "Huffman.h"

static void _Huffman_InitBitstream( huff_bitstream_t *stream, unsigned char *buf )
{
	stream->BytePtr  = buf;
	stream->BitPos   = 0;
}

static unsigned int _Huffman_ReadBit( huff_bitstream_t *stream )
{
	unsigned int  x, bit;
	unsigned char *buf;

	buf = stream->BytePtr;
	bit = stream->BitPos;

	x = (*buf & (1<<(7-bit))) ? 1 : 0;
	bit = (bit+1) & 7;
	if( !bit )
	{
		++ buf;
	}

	stream->BitPos = bit;
	stream->BytePtr = buf;

	return x;
}


static unsigned int _Huffman_Read8Bits( huff_bitstream_t *stream )
{
	unsigned int  x, bit;
	unsigned char *buf;

	buf = stream->BytePtr;
	bit = stream->BitPos;

	x = (*buf << bit) | (buf[1] >> (8-bit));
	++ buf;

	stream->BytePtr = buf;

	return x;
}

static void _Huffman_WriteBits( huff_bitstream_t *stream, unsigned int x, unsigned int bits )
{
	unsigned int  bit, count;
	unsigned char *buf;
	unsigned int  mask;

	buf = stream->BytePtr;
	bit = stream->BitPos;

	mask = 1 << (bits-1);
	for( count = 0; count < bits; ++ count )
	{
		*buf = (*buf & (0xff^(1<<(7-bit)))) + ((x & mask ? 1 : 0) << (7-bit));
		x <<= 1;
		bit = (bit+1) & 7;
		if( !bit )
		{
			++ buf;
		}
	}

	stream->BytePtr = buf;
	stream->BitPos  = bit;
}

static void _Huffman_Hist( unsigned char *in, huff_sym_t *sym, unsigned int size )
{
	int k;

	for( k = 0; k < 256; ++ k )
	{
		sym[k].Symbol = k;
		sym[k].Count  = 0;
		sym[k].Code   = 0;
		sym[k].Bits   = 0;
	}

	for( k = size; k; -- k )
	{
		sym[*in ++].Count ++;
	}
}

static void _Huffman_StoreTree( huff_encodenode_t *node, huff_sym_t *sym, huff_bitstream_t *stream, unsigned int code, unsigned int bits )
{
	unsigned int sym_idx;

	if( node->Symbol >= 0 )
	{
		_Huffman_WriteBits( stream, 1, 1 );
		_Huffman_WriteBits( stream, node->Symbol, 8 );

		for( sym_idx = 0; sym_idx < 256; ++ sym_idx )
		{
			if( sym[sym_idx].Symbol == node->Symbol ) 
				break;
		}

		sym[sym_idx].Code = code;
		sym[sym_idx].Bits = bits;
		
		return;
	}
	else
	{
		_Huffman_WriteBits( stream, 0, 1 );
	}

	_Huffman_StoreTree( node->ChildA, sym, stream, (code<<1)+0, bits+1 );

	_Huffman_StoreTree( node->ChildB, sym, stream, (code<<1)+1, bits+1 );
}

static void _Huffman_MakeTree( huff_sym_t *sym, huff_bitstream_t *stream )
{
	huff_encodenode_t nodes[MAX_TREE_NODES], *node_1, *node_2, *root;
	unsigned int k, num_symbols, nodes_left, next_idx;

	num_symbols = 0;
	for( k = 0; k < 256; ++ k )
	{
		if( sym[k].Count > 0 )
		{
			nodes[num_symbols].Symbol = sym[k].Symbol;
			nodes[num_symbols].Count = sym[k].Count;
			nodes[num_symbols].ChildA = (huff_encodenode_t *) 0;
			nodes[num_symbols].ChildB = (huff_encodenode_t *) 0;
			++ num_symbols;
		}
	}

	root = (huff_encodenode_t *) 0;
	nodes_left = num_symbols;
	next_idx = num_symbols;
	while( nodes_left > 1 )
	{
		node_1 = (huff_encodenode_t *) 0;
		node_2 = (huff_encodenode_t *) 0;
		for( k = 0; k < next_idx; ++ k )
		{
			if( nodes[k].Count > 0 )
			{
				if( !node_1 || (nodes[k].Count <= node_1->Count) )
				{
					node_2 = node_1;
					node_1 = &nodes[k];
				}
				else if( !node_2 || (nodes[k].Count <= node_2->Count) )
				{
					node_2 = &nodes[k];
				}
			}
		}

		root = &nodes[next_idx];
		root->ChildA = node_1;
		root->ChildB = node_2;
		root->Count = node_1->Count + node_2->Count;
		root->Symbol = -1;
		node_1->Count = 0;
		node_2->Count = 0;
		++ next_idx;
		-- nodes_left;
	}

	if( root )
	{
		_Huffman_StoreTree( root, sym, stream, 0, 0 );
	}
	else
	{
		root = &nodes[0];
		_Huffman_StoreTree( root, sym, stream, 0, 1 );
	}
}

static huff_decodenode_t * _Huffman_RecoverTree( huff_decodenode_t *nodes, huff_bitstream_t *stream, unsigned int *nodenum )
{
	huff_decodenode_t * this_node;

	this_node = &nodes[*nodenum];
	*nodenum = *nodenum + 1;

	this_node->Symbol = -1;
	this_node->ChildA = (huff_decodenode_t *) 0;
	this_node->ChildB = (huff_decodenode_t *) 0;

	if( !_Huffman_ReadBit( stream ) )
	{
		this_node->Symbol = _Huffman_Read8Bits( stream );
		return this_node;
	}

	this_node->ChildA = _Huffman_RecoverTree( nodes, stream, nodenum );

	this_node->ChildB = _Huffman_RecoverTree( nodes, stream, nodenum );

	return this_node;
}

void Huffman_Uncompress( unsigned char *in, unsigned char *out, unsigned int insize, unsigned int outsize )
{
	huff_decodenode_t nodes[MAX_TREE_NODES], *root, *node;
	huff_bitstream_t  stream;
	unsigned int      k, node_count;
	unsigned char     *buf;

	if( insize < 1 ) 
		return;

	_Huffman_InitBitstream( &stream, in );
	node_count = 0;
	root = _Huffman_RecoverTree( nodes, &stream, &node_count );

	buf = out;
	for( k = 0; k < outsize; ++ k )
	{
		node = root;
		while( node->Symbol < 0 )
		{
			if( _Huffman_ReadBit( &stream ) )
				node = node->ChildB;
			else
				node = node->ChildA;
		}

		*buf ++ = (unsigned char) node->Symbol;
	}
}
