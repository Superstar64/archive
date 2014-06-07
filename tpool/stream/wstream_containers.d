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
	alias stream this;
	
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
		}
		stream.writeFill(t);
	}
}
unittest{
	auto s=BigEndianWStream!MemWStream(MemWStream());
	//static assert(isTypeWStream!(typeof(s)));
	s.write(cast(ushort)10);
	s.writeAr(cast(ushort[])[1,3]);
	assert((cast(ubyte[])s.stream.array)==(cast(ubyte[])[0,10,0,1,0,3]));
}

auto bigEndianWStream(S ,size_t bufsize=1024)(S s){
	return BigEndianWStream!(S,bufsize)(s);
}
unittest{
	auto a=bigEndianWStream(MemWStream());
}
//a typed wstream wrapper around a sub wstream
struct LittleEndianWStream(S,size_t bufsize=1024) if(isWStream!S){
	S stream;
	alias stream this;
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
		stream.writeFill(t);
	}
}
unittest{
	auto s=LittleEndianWStream!MemWStream(MemWStream());
	static assert(isTypeWStream!(typeof(s)));
	s.write(cast(ushort)10);
	s.writeAr(cast(ushort[])[1,3]);
	assert((cast(ubyte[])s.stream.array)==(cast(ubyte[])[10,0,1,0,3,0]));
}
auto littleEndianWStream(S ,size_t bufsize=1024)(S s){
	return LittleEndianWStream!(S,bufsize)(s);
}
unittest{
	auto a=littleEndianWStream(MemWStream());
}

struct WStreamRange(S) if(isWStream!S){//converts a wstream into a range
	S stream;
	void put(const void[] buf){stream.writeFill(buf);}
	mixin autoSave!stream;
}

unittest{
	static assert(isOutputRange!(WStreamRange!(MemWStream),const void[]));
}
auto wStreamRange(S)(S s){//todo unittest
	return WStreamRange!S(s);
}
struct RangeWStream(R) if(isOutputRange!(R,const void[])){//converts a range to a wstream
	import std.traits;
	R range;
	void writeFill(const void[] buf){
		range.put(buf);
	}
}
unittest{
	struct Temp{
		void put(const void[] b){
			
		}
	}
	static assert(isWStream!(RangeWStream!(Temp)));
	
}
auto rangeWStream(S)(S s){//todo unittest
	return RangeWStream!(S)(s);
}
struct MultiPipeWStream(S...){//pipe single write stream to mulitple,
	S streams;
	void writeFill(in void[] buf){
		foreach(i;streams){
			i.writeFill(buf);
		}
	}
	static if(allSatisfy!(isTypeWStream,S)||allSatisfy!(isStringWStream,S)){
		void write(T)(T t){
			foreach(i;streams){
				i.write(t);
			}
		}

		void writeAr(T)(in T[] t){
			foreach(i;streams){
				i.writeAr(t);
			}
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
	auto stream=MultiPipeWStream!(MemWStream)(MemWStream());
	static assert(isWStream!(typeof(stream)));
	void[] temp;
	stream.writeFill(temp);
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
	static assert(isDisposeWStream!Temp);
}
auto multiPipeWStream(S...)(S s){
	return MultiPipeWStream!(S)(s);
}
unittest{
	auto a=multiPipeWStream(MemWStream(),MemWStream());
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
	auto stream=LittleEndianWStream!(CountWStream!MemWStream)(CountWStream!MemWStream(MemWStream()));
	stream.write(cast(int)5);
	assert(stream.stream.len==4);
}
auto countWStream(S)(S s){
	return CountWStream!(S)(s);
}
unittest{
	auto a=countWStream(MemWStream());
}

struct ZlibWStream(S,alias init=deflateInit) if(isWStream!S){//a wstream wrapper that uses zlib to compress and forward compress data to a sub stream
	import etc.c.zlib;import std.exception;
	S stream;
	z_stream_s zstream;alias z_stream_s=z_stream;
	void[] buf;
	this(S stream_,void[] buf_,int compressLev=-1,z_stream_s zstream_=z_stream_s.init){
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
		enforce(ret==Z_OK||ret==Z_STREAM_END);
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
	auto subS= MemWStream();
	auto a=ZlibWStream!(MemWStream)(subS,buffer);
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
	alias stream this;
	void write(T t){
		stream.writeFill(cast(void[])((&t)[0..1]));
	}
	
	void writeAr(T[] t){
		stream.writeFill(cast(void[])(t));
	}
}
unittest {
	void[] a;
	auto s=RawWStream!(MemWStream,char)(MemWStream(a));
	s.write('a');
	s.write('b');
	assert(cast(char[])(s.array)=="ab");
}
auto rawWStream(T,S)(S s){
	return RawWStream!(S,T)(s);
}
unittest {
	auto a=rawWStream!ubyte(MemWStream());
}
//generates crc32 around data written and forwards to sub stream
struct Crc32WStream(S) if(isWStream!S){//todo: unittest
	import etc.c.zlib;
	S Stream;alias stream=Stream;alias stream this;
	uint crc;
	void writeFill(const void[] buf){
		crc=crc32(crc,cast(ubyte*)buf.ptr,buf.length);
		Stream.writeFill(buf);
	}
}
unittest{
	auto stream=Crc32WStream!MemWStream(MemWStream());
	static assert(isWStream!((typeof(stream))));
	
}
auto crc32WStream(S)(S s){
	return Crc32WStream!S(s);
}
unittest{
	auto a=crc32WStream(MemWStream());
}
//generates adler32 around data written and forwards to sub stream
struct Adler32WStream(S) if(isWStream!S){//todo: unittest
	import etc.c.zlib;
	S Stream;alias stream=Stream;alias stream this;
	uint adler;
	void writeFill(const void[] buf){
		adler=adler32(adler,cast(ubyte*)buf.ptr,buf.length);
		Stream.writeFill(buf);
	}
}
unittest{
	auto stream=Adler32WStream!MemWStream(MemWStream());
	static assert(isWStream!((typeof(stream))));
}
auto adler32WStream(S)(S s){
	return Adler32WStream!S(s);
}
unittest{
	auto a=adler32WStream(MemWStream());
}
