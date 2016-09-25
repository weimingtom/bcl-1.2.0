package huff 
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public final class Bitstream
	{		
		private static const MAX_TREE_NODES:int = 511;
		
		//public var bytePtr:ByteArray;
		public var bitPos:uint;
		//public var currentByte:uint;
		public var bytes:Array = null;
		public var bytePtr:uint = 0;
		
		
		public var nodeCount:uint = 0;
		public var decodenodes:Array = new Array(MAX_TREE_NODES);
		
		public var sym:Array = new Array(256);
		public var encodenodes:Array = new Array(MAX_TREE_NODES);
		
		public function Bitstream(buf:ByteArray = null):void
		{
			this.bitPos   = 0;
			this.bytePtr  = 0;
			this.bytes    = new Array();
			while (buf != null && buf.bytesAvailable > 0) 
			{
				bytes.push(buf.readUnsignedByte());
			}
			
			for (var i:int = 0; i < MAX_TREE_NODES; i++)
			{
				decodenodes[i] = new DecodeNode();
				encodenodes[i] = new EncodeNode();
			}
		}
		
		//////////////////////////////////////////////////
		//底层API
		public function readBit():uint
		{
			var x:uint, bit:uint;
			var buf:Array;
			var ptr:uint;
			buf = this.bytes;
			ptr = this.bytePtr;
			bit = this.bitPos;
			x = (buf[ptr] & (1 << (7 - bit))) ? 1 : 0;
			bit = (bit + 1) & 7;
			if(bit == 0)
			{
				++this.bytePtr;
			}
			this.bitPos = bit;
			return x & 0xff;
		}
		
		public function read8Bits():uint
		{
			var x:uint, bit:uint;
			var buf:Array;
			var ptr:uint;
			buf = this.bytes;
			ptr = this.bytePtr;
			bit = this.bitPos;
			if (ptr >= bytes.length)
			{
				throw new Error("end of stream");
			}
			x = (buf[ptr] << bit) | (buf[ptr + 1] >> (8 - bit));
			++this.bytePtr;
			return x & 0xff;
		}
		
		public function writeBits(x:uint, bits:uint):void
		{
			var bit:uint, count:uint;
			var buf:Array;
			var ptr:uint;
			var mask:uint;
			buf = this.bytes;
			ptr = this.bytePtr;
			bit = this.bitPos;
			mask = 1 << (bits - 1);
			for( count = 0; count < bits; ++count )
			{
				buf[ptr] = (buf[ptr] & (0xff ^ (1 << (7 - bit)))) + ((x & mask ? 1 : 0) << (7 - bit));
				x <<= 1;
				bit = (bit+1) & 7;
				if(bit == 0)
				{
					++ptr;
				}
			}
			this.bytePtr = ptr;
			this.bitPos  = bit;
		}
		
		public function rewind():void
		{
			this.bitPos   = 0;
			this.bytePtr  = 0;
		}

		//----------------------------------------------
		//树操作
		private function recoverTree():DecodeNode
		{
			var this_node:DecodeNode;
			this_node = decodenodes[nodeCount];
			nodeCount++;
			this_node.symbol = -1;
			this_node.childA = null;
			this_node.childB = null;
			if(this.readBit() == 0)
			{
				this_node.symbol = this.read8Bits();
				return this_node;
			}
			this_node.childA = recoverTree();
			this_node.childB = recoverTree();
			return this_node;
		}
		
		
		//----------------------------------------------
		//解压
		public function uncompress(out:ByteArray, outsize:uint):void
		{
			var root:DecodeNode, node:DecodeNode;
			if( this.bytes.length < 1 ) 
				return;
			rewind();
			this.nodeCount = 0;
			root = recoverTree();
			for(var k:int = 0; k < outsize; ++ k )
			{
				node = root;
				while( node.symbol < 0 )
				{
					if( this.readBit() != 0)
						node = node.childB;
					else
						node = node.childA;
				}
				out.writeByte(node.symbol);
			}
		}
		
		//-----------------------------------------
		
		private function hist(input:ByteArray, size:uint):void
		{
			//0 ~ 0xFF共计256个符号
			for( var k:int = 0; k < 256; ++ k )
			{
				sym[k] = new Symbol();
				(sym[k] as Symbol).symbol = k;
				(sym[k] as Symbol).count  = 0;
				(sym[k] as Symbol).code   = 0;
				(sym[k] as Symbol).bits   = 0;
			}
			for( k = size; k; -- k )
			{
				(sym[input.readUnsignedByte()] as Symbol).count++;
			}
		}

		
		public function storeTree(node:EncodeNode, code:uint, bits:uint):void
		{
			var sym_idx:uint;
			if( node.symbol >= 0 )
			{
				writeBits( 0, 1 );
				writeBits( node.symbol, 8 );
				for( sym_idx = 0; sym_idx < 256; ++sym_idx )
				{
					if( (sym[sym_idx] as Symbol).symbol == node.symbol ) 
						break;
				}
				(sym[sym_idx] as Symbol).code = code;
				(sym[sym_idx] as Symbol).bits = bits;
				return;
			}
			else
			{
				writeBits( 1, 1 );
			}
			storeTree( node.childA, (code << 1) + 0, bits + 1 );
			storeTree( node.childB, (code << 1) + 1, bits + 1 );
		}
			
		
		public function makeTree():void
		{
			var node_1:EncodeNode, node_2:EncodeNode, root:EncodeNode;
			var k:uint, num_symbols:uint, nodes_left:uint, next_idx:uint;
			num_symbols = 0;
			for( k = 0; k < 256; ++ k )
			{
				var current_sym:Symbol = sym[k] as Symbol;
				if( current_sym.count > 0 )
				{
					var current_node:EncodeNode = encodenodes[num_symbols] as EncodeNode;
					current_node.symbol = current_sym.symbol;
					current_node.count = current_sym.count;
					current_node.childA = null;
					current_node.childB = null;
					++ num_symbols;
				}
			}
			root = null;
			nodes_left = num_symbols;
			next_idx = num_symbols;
			while( nodes_left > 1 )
			{
				node_1 = null;
				node_2 = null;
				for( k = 0; k < next_idx; ++k )
				{
					var current_node2:EncodeNode = encodenodes[k] as EncodeNode;
					if( current_node2.count > 0 )
					{
						if( !node_1 || (current_node2.count <= node_1.count) )
						{
							node_2 = node_1;
							node_1 = current_node2;
						}
						else if( !node_2 || (current_node2.count <= node_2.count) )
						{
							node_2 = current_node2;
						}
					}
				}
				root = encodenodes[next_idx] as EncodeNode;
				root.childA = node_1;
				root.childB = node_2;
				root.count = node_1.count + node_2.count;
				root.symbol = -1;
				node_1.count = 0;
				node_2.count = 0;
				++next_idx;
				--nodes_left;
			}
			if( root )
			{
				storeTree(root, 0, 0 );
			}
			else
			{
				root = encodenodes[0] as EncodeNode;
				storeTree(root, 0, 1 );
			}
		}
		
		//----------------------------------------------
		//压缩
		public function compress(input:ByteArray, output:ByteArray, insize:uint):uint
		{
			var k:uint, total_bytes:uint, swaps:uint, symbol:uint;
			if( insize < 1 ) 
				return 0;
			var pos:uint = input.position;
			hist( input, insize );
			input.position = pos;
			makeTree();
			do
			{
				swaps = 0;
				for( k = 0; k < 255; ++ k )
				{
					if( (sym[k] as Symbol).symbol > (sym[k+1] as Symbol).symbol )
					{
						var tmp:Symbol = sym[k];
						sym[k]   = sym[k+1];
						sym[k+1] = tmp;
						swaps    = 1;
					}
				}
			} while( swaps );
			for( k = 0; k < insize; ++ k )
			{
				symbol = input.readUnsignedByte();
				//查字典
				writeBits((sym[symbol] as Symbol).code, (sym[symbol] as Symbol).bits);
			}
			total_bytes = this.bytePtr;
			if( this.bitPos > 0 )
			{
				++total_bytes;
			}
			output.endian = Endian.LITTLE_ENDIAN;
			//最开始的4个字节是解压后的长度
			output.writeUnsignedInt(insize);
			for (var i:int = 0; i < this.bytes.length; i++)
			{
				output.writeByte(this.bytes[i] as uint);
			}
			return total_bytes;
		}
	}
}
