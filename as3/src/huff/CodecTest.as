package huff 
{
	import flash.display.Sprite;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class CodecTest extends Sprite
	{	
		public function CodecTest() 
		{
			/*
			trace("hello, world");
			
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0xF8);
			bytes.writeByte(0xF8);
			bytes.position = 0;
			var stream:Bitstream = new Bitstream(bytes);
			try 
			{
				//testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testRead8Bits(stream);
				testRead8Bits(stream);
				testRead8Bits(stream);
			}catch (e:Error) {
				trace(e.getStackTrace());
			}
			//----------------------------------------------------
			stream = new Bitstream();
			stream.writeBits(0xF8, 8);
			stream.writeBits(0xF8, 8);
			stream.rewind();
			try 
			{
				//testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testReadBit(stream);
				testRead8Bits(stream);
				testRead8Bits(stream);
				testRead8Bits(stream);
			}catch (e:Error) {
				trace(e.getStackTrace());
			}
			*/
			var stream:Bitstream = new Bitstream();
			
			//--------------------------------------------------
			[Embed(source='../../lib/output.dat', mimeType='application/octet-stream')]
			var output_dat:Class;
			
			//注意，是强制转换，不是new
			var data:ByteArray = ByteArray(new output_dat());
			trace("ByteArray.length = ", data.length);
			
			data.position = 0;
			//不知为何，与网络传输时正好相反
			//0xFF000000 --readUnsignedInt--> 0xFF 
			data.endian = Endian.LITTLE_ENDIAN;  
			if (data.bytesAvailable > 0)
			{
				// 第一个32位数是解压长度
				var uncompress_length:uint = data.readUnsignedInt();
				trace("uncompress_length:", uncompress_length);
				stream = new Bitstream(data);
				
				var uncompress_bytes:ByteArray = new ByteArray();
				stream.uncompress(uncompress_bytes, uncompress_length);
				uncompress_bytes.position = 0;
				trace("uncompress:", uncompress_bytes.bytesAvailable, "bytes");
				var str:String = uncompress_bytes.readMultiByte(uncompress_bytes.bytesAvailable, "gbk");
				trace(str);
			}
			
			//--------------------------------------------------
			//压缩测试
			
			uncompress_bytes.position = 0;
			var compress_bytes:ByteArray = new ByteArray();
			var stream2:Bitstream = new Bitstream();
			var compress_length:uint = stream2.compress(uncompress_bytes, 
				compress_bytes, 
				uncompress_bytes.bytesAvailable);
			compress_bytes.position = 0;
			trace("compress_length:", compress_length);
			trace("compress:", compress_bytes.bytesAvailable, "bytes");
			
			compress_bytes.position = 0;
			while (compress_bytes.bytesAvailable > 0)
			{
				var byte:uint = compress_bytes.readByte() & 0xff;
				trace(byte.toString(16));
			}
		}
		
		public function testRead8Bits(stream:Bitstream):void
		{
			var i:uint = stream.read8Bits();
			trace(i.toString(16));
		}
		
		public function testReadBit(stream:Bitstream):void
		{
			var i:uint = stream.readBit();
			trace(i);
		}
	}
}

