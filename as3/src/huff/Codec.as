package huff 
{
	import flash.utils.ByteArray;
	public class Codec extends Object
	{
		private const MAX_TREE_NODES:int = 511;
		
		public static function uncompress(input:ByteArray, 
			output:ByteArray, 
			insize:uint, 
			outsize:uint):void
		{
			var nodes:Array = new Array(MAX_TREE_NODES);
			var root:DecodeNode, node:DecodeNode;
			var stream:Bitstream = new Bitstream();
			var k:uint, node_count:uint;
			
			if(insize < 1) 
				return;
			
			stream.init(input);
			node_count = 0;
			root = stream.recoverTree(nodes, node_count);
			
			for(k = 0; k < outsize; ++k)
			{
				node = root;
				while(node.symbol < 0)
				{
					if(stream.readBit())
						node = node.childB;
					else
						node = node.childA;
				}

				output.writeUnsignedInt(uint(node.symbol));
			}
		}
		
		public static function compress(input:ByteArray, 
			output:ByteArray, 
			insize:uint):void
		{
			var syms:Array = new Array(256);
			var tmp:Symbol;
			var stream:Bitstream = new Bitstream();
			var k:uint, total_bytes:uint, swaps:uint, symbol:uint;
			
			if( insize < 1 ) 
				return 0;
			
			stream.init(out);
			hist(input,sym, insize );
			_Huffman_MakeTree( sym, &stream );
			
			do
			{
				swaps = 0;
				for(k = 0; k < 255; ++k)
				{
					if((syms[k] as Symbol).symbol > (syms[k + 1] as Symbol).symbol)
					{
						tmp        = sym[k];
						sym[k]     = sym[k + 1];
						sym[k + 1] = tmp;
						swaps      = 1;
					}
				}
			} while(swaps);

			input.position = 0;
			for( k = 0; k < insize; ++ k)
			{
				symbol = input.readUnsignedByte();
				stream.writeBits((syms[symbol] as Symbol).code, (sym[symbol] as Symbol).bits);
			}
			
			total_bytes = int(stream.bytePtr - out);
			if( stream.bitPos > 0 )
			{
				++ total_bytes;
			}
			
			return total_bytes;
		}
		
		public static function hist(input:uint, syms:Array, size:uint):uint
		{
			var k:int;
			for(k = 0; k < 255; ++k)
			{
				(syms[k] as Symbol).symbol = k;
				(syms[k] as Symbol).count  = 0;
				(syms[k] as Symbol).code   = 0;
				(syms[k] as Symbol).bits   = 0;
			}
			
			for(k = size; k; --k)
			{
				(sym[input++] as Symbol).count++;
			}
			return input;
		}
	}
}

