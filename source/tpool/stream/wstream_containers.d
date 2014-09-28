module tpool.stream.wstream_containers;
import tpool.stream.wstream;
import tpool.stream.common;
import std.c.stdlib;//i'm dangerous
import std.typetuple;
import std.range;
import std.algorithm;
//a typed wstream wrapper around a sub wstream
//bufsize is in data per type not bytes
struct BigEndianWStream(S,size_t bufsize=1024) if(isWStream!S){//if bufsize == 0 then it calls alloca
	S stream;
	mixin walias!stream;
	
	void write(T)(T t) if(isDataType!T){
		version(LittleEndian){
			(cast(void*)(&t))[0..T.sizeof].reverse;
		}
		stream.writeFill((cast(void*)(&t))[0..T.sizeof]);
	}
	
	void writeAr(T)(in T[] t) if(isDataType!T){
		version(LittleEndian){//allaca and reverse
			static if(bufsize==0){
				auto length=T.sizeof*t.length;
				auto ptr=cast(ubyte*)alloca(length);
				for(uint i=0;i<length;i+=T.sizeof){
					foreach(val;0..T.sizeof){
						ptr[i+val]=(cast(ubyte[])t)[i+(T.sizeof-1-val)];
					}
				}
				stream.writeFill(ptr[0..length]);
				return;
			}else{
				T[bufsize] buf;
				size_t length;
				size_t nlength;
				bool cpy(){
					nlength=t.length-length>buf.length?buf.length:t.length-length;
					memcpy(buf.ptr,t.ptr+length,nlength*T.sizeof);
					scope(exit) length+=nlength;
					return length!=t.length;
				}
				while(cpy){
					foreach(i;buf.ptr..buf.ptr+nlength){
						reverse((cast(ubyte*)(i))[0..T.sizeof] );
					}
					stream.writeFill(buf[0..nlength]);
				}
				return;
			}
		}else{
			stream.writeFill(t);
		}
	}
}
unittest{
	auto s=bigEndianWStream(memWStream());
	//static assert(isTypeWStream!(typeof(s)));
	s.write(cast(ushort)10);
	s.writeAr(cast(ushort[])[1,3]);
	assert((cast(ubyte[])s.stream.array)==(cast(ubyte[])[0,10,0,1,0,3]));
}

auto bigEndianWStream(S ,size_t bufsize=1024)(S s){
	return BigEndianWStream!(S,bufsize)(s);
}

//a typed wstream wrapper around a sub wstream
struct LittleEndianWStream(S,size_t bufsize=1024) if(isWStream!S){
	S stream;
	mixin walias!stream;
	
	void write(T)(T t) if(isDataType!T){
		version(BigEndian){
			(cast(void*)(&t))[0..T.sizeof].reverse;
		}
		stream.writeFill((cast(void*)(&t))[0..T.sizeof]);
	}
	
	void writeAr(T)(in T[] t) if(isDataType!T){
		version(BigEndian){//allaca and reverse
			static if(bufsize==0){
				auto length=T.sizeof*t.length;
				auto ptr=cast(ubyte*)alloca(length);
				for(uint i=0;i<length;i+=T.sizeof){
					foreach(val;0..T.sizeof){
						ptr[i+val]=(cast(ubyte[])t)[i+(T.sizeof-1-val)];
					}
				}
				stream.writeFill(ptr[0..length]);
				return;
			}else{
				T[bufsize] buf;
				size_t length;
				size_t nlength;
				bool cpy(){
					nlength=t.length-length>buf.length?buf.length:t.length-length;
					memcpy(buf.ptr,t.ptr+length,nlength*T.sizeof);
					scope(exit) length+=nlength;
					return length!=t.length;
				}
				while(cpy){
					foreach(i;buf.ptr..buf.ptr+nlength){
						reverse((cast(ubyte*)(i))[0..T.sizeof] );
					}
					stream.writeFill(buf[0..nlength]);
				}
				return;
			}
		}
		else{
			stream.writeFill(t);
		}
	}
}
unittest{
	auto s=littleEndianWStream(MemWStream());
	static assert(isTypeWStream!(typeof(s)));
	s.write(cast(ushort)10);
	s.writeAr(cast(ushort[])[1,3]);
	assert((cast(ubyte[])s.stream.array)==(cast(ubyte[])[10,0,1,0,3,0]));
}
auto littleEndianWStream(S ,size_t bufsize=1024)(S s){
	return LittleEndianWStream!(S,bufsize)(s);
}

struct MultiPipeWStream(S...){//pipe single write stream to mulitple,
	S streams;
	
	void writeFill(in void[] buf){
		foreach(ref i;streams){
			i.writeFill(buf);
		}
	}
	
	static if(allSatisfy!(isDisposeWStream,S)){
		@property{
			void flush(){
				foreach(i;streams){
					i.flush;
				}
			}
			
			void close(){
				foreach(i;streams){
					i.close;
				}
			}
		}
	}
}
unittest{
	auto stream=multiPipeWStream(MemWStream(),MemWStream());
	static assert(isWStream!(typeof(stream)));
	ubyte[] data=[1,2,3];
	stream.writeFill(data);
	stream.writeFill(data);
	assert((cast(ubyte[])stream.streams[0].array)==[1,2,3,1,2,3]);
	assert((cast(ubyte[])stream.streams[1].array)==[1,2,3,1,2,3]);
	static assert(isWStream!(typeof(stream)));
	static assert(!isTypeWStream!((typeof(stream))));
	
	struct Temp{
		auto writeFill(in void[] buf){
			
		}
		
		@property{
			void flush(){
				
			}
			
			void close(){
				
			}
		}
	}
	static assert(isDisposeWStream!(MultiPipeWStream!Temp));
}
auto multiPipeWStream(S...)(S s){
	return MultiPipeWStream!(S)(s);
}

struct CountWStream(S) if(isWStream!S){//a wstream that counts the amount of bytes written and forwards to a substream
	S stream;
	ulong len;
	auto writeFill(const void[] buf){
		len+=buf.length;
		return stream.writeFill(buf);
	}
}
unittest {
	static assert(isWStream!(CountWStream!VoidWStream));
	auto stream=littleEndianWStream(countWStream(MemWStream()));
	stream.write(cast(int)5);
	assert(stream.stream.len==4);
}
auto countWStream(S)(S s){
	return CountWStream!(S)(s);
}

struct ZlibWStream(S,alias init=deflateInit) if(isWStream!S){//a wstream wrapper that uses zlib to compress and forward compress data to a sub stream
	import etc.c.zlib;import std.exception;
	S stream;
	z_stream zstream;
	void[] buf;

	this(S stream_,void[] buf_,int compressLev=-1,z_stream zstream_=z_stream.init){
		stream=stream_;
		buf=buf_;
		zstream=zstream_;
		zstream.next_out=cast(typeof(zstream.next_out)) buf.ptr;
		zstream.avail_out=cast(typeof(zstream.avail_out)) buf.length;
		enforce(init(&zstream,compressLev)==Z_OK);
	}
	
	void writeFill(const void[] data,int flushlev=Z_NO_FLUSH){
		zstream.next_in=cast(typeof(zstream.next_in)) data.ptr;
		zstream.avail_in=cast(typeof(zstream.avail_in)) data.length;
	start:
		auto ret=deflate(&zstream,flushlev);
		enforce(ret==Z_OK||ret==Z_STREAM_END||ret==Z_BUF_ERROR);
		if(zstream.avail_out==0){
			flush();
			goto start;
		}else if(zstream.avail_in==0){
			return;
		}
		throw new Exception("something went wrong with zlib");
	}
	
	void flush(){
		stream.writeFill(buf[0..$-zstream.avail_out]);
		zstream.next_out=cast(typeof(zstream.next_out))buf.ptr;
		zstream.avail_out=cast(typeof(zstream.avail_out)) buf.length;
	}
	
	void close(bool sub=true){
		ubyte[0] a;
		writeFill(a,Z_FINISH);
		flush();
		deflateEnd(&zstream);
		if(sub){
			static if(isDisposeWStream!(S)){
				stream.close();
			}
		}
	}
}

unittest{
	ubyte[3] buffer;
	auto a=zlibWStream(MemWStream(),buffer);
	static assert(isWStream!(typeof(a)));
	a.writeFill(cast(int[])[0,1,2,3,4,5]);
	a.close();
	import std.zlib;
	assert(uncompress(a.stream.array)==(cast(int[])[0,1,2,3,4,5]));
}
import etc.c.zlib;
auto zlibWStream(alias init=deflateInit,S)(S s,void[] buf,int compress=-1,z_stream z=z_stream.init){
	return ZlibWStream!(S,init)(s,buf,compress,z);
}

struct RawWStream(S,T) if(isWStream!S){//writes exactly from memory
	S stream;
	mixin walias!stream;
	
	void write(T t){
		stream.writeFill(cast(void[])((&t)[0..1]));
	}
	
	void writeAr(T[] t){
		stream.writeFill(cast(void[])(t));
	}
}
unittest {
	auto s=rawWStream!char(MemWStream());
	s.write('a');
	s.write('b');
	assert(cast(char[])(s.stream.array)=="ab");
}
auto rawWStream(T,S)(S s){
	return RawWStream!(S,T)(s);
}
//generates crc32 around data written and forwards to sub stream
struct Crc32WStream(S) if(isWStream!S){
	import etc.c.zlib;
	S stream;
	uint crc;
	
	void writeFill(const void[] buf){
		import std.zlib;
		crc=crc32(crc,buf);
		stream.writeFill(buf);
	}
}
unittest{
	import std.zlib;
	auto stream=crc32WStream(MemWStream());
	static assert(isWStream!((typeof(stream))));
	stream.writeFill("Hello world");
	stream.writeFill(cast(ubyte[])[0]);
	assert(stream.crc==crc32(0,"Hello world\0"));
}
auto crc32WStream(S)(S s){
	return Crc32WStream!S(s);
}

//generates adler32 around data written and forwards to sub stream
struct Adler32WStream(S) if(isWStream!S){
	import etc.c.zlib;
	S stream;
	uint adler;
	
	void writeFill(const void[] buf){
		import std.zlib;
		adler=adler32(adler,buf);
		stream.writeFill(buf);
	}
}
unittest{
	import std.zlib;
	auto stream=adler32WStream(MemWStream());
	static assert(isWStream!((typeof(stream))));
	stream.writeFill("Hello world");
	stream.writeFill(cast(ubyte[])[0]);
	assert(stream.adler==adler32(0,"Hello world\0"));
}
auto adler32WStream(S)(S s){
	return Adler32WStream!S(s);
}
