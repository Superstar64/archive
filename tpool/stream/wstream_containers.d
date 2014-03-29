module tpool.stream.wstream_containers;
import tpool.stream.wstream;
import tpool.stream.common;
import std.c.stdlib : alloca;//i'm dangerous
import std.typetuple;
import std.range;

struct BigEndianWStream(S) if(isWStream!S){
	S stream;
	void write(T)(T t) if(isDataType!T){
		version(LittleEndian){
			(cast(void*)(&t))[0..T.sizeof].reverse;
		}
		stream.writeFill((cast(void*)(&t))[0..T.sizeof]);
	}
	
	void writeAr(T)(in T[] t) if(isDataType!T){
		version(LittleEndian){//allaca and reverse
			auto length=T.sizeof*t.length;
			auto ptr=cast(ubyte*)alloca(length);
			for(uint i=0;i<length;i+=T.sizeof){
				foreach(val;0..T.sizeof){
					ptr[i+val]=(cast(ubyte[])t)[i+(T.sizeof-1-val)];
				}
			}
			stream.writeFill(ptr[0..length]);
			return;
		}
		stream.writeFill(t);
	}
}
unittest{
	auto s=BigEndianWStream!MemWStream(MemWStream());
	s.write(cast(ushort)10);
	s.writeAr(cast(ushort[])[1,3]);
	assert((cast(ubyte[])s.stream.array)==(cast(ubyte[])[0,10,0,1,0,3]));
}

struct LittleEndianWStream(S) if(isWStream!S){
	S stream;
	void write(T)(T t) if(isDataType!T){
		version(BigEndian){
			(cast(void*)(&t))[0..T.sizeof].reverse;
		}
		stream.writeFill((cast(void*)(&t))[0..T.sizeof]);
	}
	
	void writeAr(T)(in T[] t) if(isDataType!T){
		version(BigEndian){//allaca and reverse
			auto length=T.sizeof*t.length;
			auto ptr=cast(ubyte*)alloca(length);
			for(uint i=0;i<length;i+=T.sizeof){
				foreach(val;0..T.sizeof){
					ptr[i+val]=(cast(ubyte[])t)[i+(T.sizeof-1-val)];
				}
			}
			stream.writeFill(ptr[0..length]);
			return;
		}
		stream.writeFill(t);
	}
}
unittest{
	auto s=LittleEndianWStream!MemWStream(MemWStream());
	s.write(cast(ushort)10);
	s.writeAr(cast(ushort[])[1,3]);
	assert((cast(ubyte[])s.stream.array)==(cast(ubyte[])[10,0,1,0,3,0]));
}


struct WStreamRange(S) if(isWStream!S){//converts a wstream into a range
	S stream;
	void put(const void[] buf){stream.writeFill(buf);}
	mixin autoSave!stream;
}

unittest{
	static assert(isOutputRange!(WStreamRange!(MemWStream),const void[]));
}

struct RangeWStream(R) if(isOutputRange!(R,const void[])){//converts a range to a wstream
	import std.traits;
	R range;
	void writeFill(const void[] buf){
		range.put(buf);
	}
	static if(hasMember!(R,"save")&&typeof(R.save==R)){//todo unittest
		auto save(){
			return typeof(this)(range);
		}
	}
}
unittest{
	struct Temp{
		void put(const void[] b){
			
		}
	}
	static assert(isWStream!(RangeWStream!(Temp)));
	
}

struct MultiPipeWStream(S...){//pipe single write stream to mulitple,
//todo static if for other type of streams
//todo implement save
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
	void[] temp;
	stream.writeFill(temp);
	static assert(isWStream!(typeof(stream)));
	static assert(!isTypeWStream!((typeof(stream))));
}

struct CountWStream(S) if(isWStream!S){
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


struct ZlibWStream(S) if(isWStream!S){
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
		enforce(deflateInit(&zstream,compressLev)==Z_OK);
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
	
	void close(){
		ubyte[0] a;
		writeFill(a,Z_FINISH);
		flush();
		deflateEnd(&zstream);
		static if(isDisposeWStream!(S)){
			stream.close();
		}
	}
}

unittest{
	ubyte[3] buffer;
	auto subS= MemWStream();
	auto a=ZlibWStream!MemWStream(subS,buffer);
	a.writeFill(cast(int[])[0,1,2,3,4,5]);
	a.close();
	import std.zlib;
	assert(uncompress(a.stream.array)==(cast(int[])[0,1,2,3,4,5]));
}
