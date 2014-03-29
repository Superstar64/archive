module tpool.stream.rstream_containers;
import tpool.stream.rstream;
import tpool.stream.common;
import std.exception:enforce;
import std.algorithm;
class EofBadFormat:Exception{
	this(){
		this("Found eof when expecting Number");
	}
	
	this(string s){
		super(s);
	}
}

struct BigEndianRStream(S) if(isRStream!S){
	import std.exception;
	S stream;
	alias stream this;
	@property T read(T)() if(isDataType!T) {
		ubyte buf[T.sizeof];
		auto sz=stream.readFill(buf);
		if(sz!=T.sizeof){
			throw new EofBadFormat();
		}
		version(LittleEndian){
			buf.reverse;
		}
		return *(cast(T*)buf.ptr);
	}
	
	size_t readAr(T)(T[] buf) if(isDataType!T) {
		auto sz=stream.readFill(buf);
		if(sz%T.sizeof!=0){
			throw new EofBadFormat();
		}
		version(LittleEndian){
			auto temp=cast(ubyte[]) buf;//templates errors are scary
			uint count;
			for(uint i=0;i<temp.length;i+=T.sizeof){
				temp[i..i+T.sizeof].reverse;
			}
		}
		return sz/T.sizeof;
	}
	mixin autoSave!stream;
}

unittest {
	ubyte[12] buf=[0,0,1,0, 1,5,   0,1,  2,0, 1,3];
	auto stream=BigEndianRStream!MemRStream(MemRStream(buf));
	static assert(isTypeRStream!(typeof(stream)));
	assert(stream.read!int==256);
	assert(!stream.eof);
	assert(stream.read!ushort==261);
	ushort[3] buf2;
	assert(stream.readAr(buf2)==3);
	assert(stream.eof);
	assert(buf2==[1,512,259]);
}


struct LittleEndianRStream(S) if(isRStream!S){
	import std.exception;
	S stream;
	alias stream this;
	@property T read(T)() if(isDataType!T) {
		ubyte buf[T.sizeof];
		auto sz=stream.readFill(buf);
		if(sz!=T.sizeof){
			throw new EofBadFormat();
		}
		version(BigEndian){
			buf.reverse;
		}
		return *(cast(T*)buf.ptr);
	}
	
	size_t readAr(T)(T[] buf) if(isDataType!T) {
		auto sz=stream.readFill(buf);
		if(sz%T.sizeof!=0){
			throw new EofBadFormat();
		}
		version(BigEndian){
			auto temp=cast(ubyte[]) buf;//templates errors are scary
			uint count;
			for(uint i=0;i<temp.length;i+=T.sizeof){
				temp[i..i+T.sizeof].reverse;
			}
		}
		return sz/T.sizeof;
	}
	mixin autoSave!stream;
}

unittest {
	ubyte[12] buf=[0,1,0,0, 5,1,   1,0,  0,2, 3,1];
	auto stream=LittleEndianRStream!MemRStream(MemRStream(buf));
	static assert(isTypeRStream!(typeof(stream)));
	assert(stream.read!int==256);
	assert(!stream.eof);
	assert(stream.read!ushort==261);
	ushort[3] buf2;
	assert(stream.readAr(buf2)==3);
	assert(stream.eof);
	assert(buf2==[1,512,259]);
}

class EofBeforeLength:Exception{
	this(size_t read){
		super("Eof reached before limit");
	}
}
struct LimitRStream(S,bool excepOnEof=true) if(isRStream!S){//limiting stream, return eof when limit bytes are read
															//if excepOnEof is true, it throws if eof is reached before limit
	S stream;
	ulong limit;
	size_t readFill(void[] buf){
		if(buf.length>limit){
			auto len=stream.readFill(buf[0..cast(size_t)limit]);
			static if(excepOnEof){
				if(len!=limit){
					throw new EofBeforeLength(cast(size_t)limit);
				}
			}
			limit=0;
			return len;
		}else{
			auto len=stream.readFill(buf);
			static if(excepOnEof){
				if(len!=buf.length){
					throw new EofBeforeLength(len);
				}
			}
			limit-=len;
			return len;
		}
	}
	
	size_t skip(size_t amount){
		if(amount>limit){
			auto len=stream.skip(cast(size_t)limit);
			static if(excepOnEof){
				if(len!=limit){
					throw new EofBeforeLength(cast(size_t)limit);
				}
			}
			limit=0;
			return len;
		}else{
			auto len=stream.skip(amount);
			static if(excepOnEof){
				if(len!=amount){
					throw new EofBeforeLength(cast(size_t) amount);
				}
			}
			limit-=len;
			return len;
		}
	}
	@property{
		static if(excepOnEof){
			auto seek(){
				return limit;
			}
		}
		
		bool eof(){
			return limit==0;
		}
	}
	mixin autoSave!(stream,limit);
}
unittest {//todo unittest skip
	ubyte[12] buf=[0,1,0,0, 5,1,   1,0,  0,2, 3,1];
	auto stream=LimitRStream!MemRStream(MemRStream(buf),4);
	static assert(isRStream!(typeof(stream)));
	ubyte[3] temp;
	auto len=stream.readFill(temp);
	assert(len==3);
	len=stream.readFill(temp);
	assert(len==1);
	assert(stream.eof);
}

struct RangeRStream(S,BufType=ubyte) if(isRStream!S){//streams chunks of data as a range
	S stream;
	alias stream this;
	BufType[] _buf;
	bool _eof;
	
	this(S s,BufType[] buf_){
		stream=s;
		_buf=buf_;
		popFront();
	}
	this(S s,BufType[] buf,bool eof){//raw constructer , only use if you know what you are doing
		stream=s;
		_buf=buf;
		_eof=eof;
	}
	@property{
		auto front(){
			return cast(const (BufType)[])_buf;
		}
		
		void popFront(){
			auto len=stream.readFill(_buf);
			if(len!=_buf.length){
				_eof=true;
				_buf=_buf[0..len];
			}
		}
		
		bool empty(){
			return _eof;
		}
	}
	mixin autoSave!(stream,_buf,_eof);
}

unittest{
	ubyte[12] array=[0,0,1,0,1,5,0,1,2,0,1,3];
	ubyte[4] buf=void;
	auto chunker=RangeRStream!(MemRStream,ubyte)(MemRStream(array),buf);
	assert(!chunker.empty);
	assert(chunker.front==[0,0,1,0]);
	chunker.popFront;
	assert(chunker.front==[1,5,0,1]);
	chunker.popFront;
	assert(!chunker.empty);
	assert(chunker.front==[2,0,1,3]);
	chunker.popFront;
	assert(chunker.empty);
	assert(chunker.front==[]);
}

struct AllRStream(S) if(isRStream!S) {//a stream that throws a exception when a buffer is not fully filled
	S s;//stream
	alias stream=s;
	alias s this;
	size_t readFill(void[] buf){
		enforce(s.readFill(buf)==buf.length);
		return buf.length;
	}
	
	size_t skip(size_t si){
		enforce(s.skip(si)==si);
		return si;
	}
	mixin autoSave!s;
}
unittest{
	ubyte[7] buf;
	auto str= BigEndianRStream!(AllRStream!MemRStream)(AllRStream!MemRStream(MemRStream(buf)));
	str.read!uint;
	bool a=false;
	try{
		str.read!uint;
	}catch(Exception e){
		a=true;
	}
	assert(a);
}
struct RawRStream(S,T) if(isRStream!S){
	S stream;
	alias stream this;
	@property T read(Type:T)(){
		ubyte[T.sizeof] buf;
		stream.readFill(buf);
		return *(cast(T*)(buf.ptr));
	}
	
	size_t readAr(T[] t){
		auto a=stream.readFill(cast(void[])t);
		if(a%T.sizeof!=0){
			throw new EofBadFormat("Eof when expecting "~T.stringof);
		}
		return a/T.sizeof;
	}
	mixin autoSave!stream;
}
unittest {
	char[] a=['a','b','c'];
	auto s=RawRStream!(MemRStream,char)(MemRStream(a));
	assert(s.read!char=='a');
	char[2] b2;
	s.readAr(b2);
	assert(b2=="bc");
	assert(s.eof);
}
//todo unittest OuitOnStreamEnd
struct ZlibRStream(S,bool QuitOnStreamEnd=false) if(isRStream!S){//buffers, reads more than needed
	import etc.c.zlib;
	S stream;
	z_stream_s zstream;alias z_stream_s=z_stream;//possible bug:inflateEnd may not get called if constructed with new
	void[] buf;
	bool eof_;//end of buffering
	bool eof;//end of stream
	
	mixin autoSave!(stream,zstream,buf,eof_,eof);
	this(S stream_,z_stream_s zstream_,void []buf_,bool eof_0,bool eof0){//raw costructer plese ignore
		stream=stream_;
		inflateCopy(&zstream,&zstream_);
		buf=buf_;
		eof_=eof_0;
		eof=eof0;
	}
	
	this(S stream_,void[] buf_,z_stream_s z=z_stream_s.init){
		zstream=z;
		stream=stream_;
		buf=buf_;
		assert(buf.length>0);
		reloadbuf();
		zstream.next_in=cast(typeof(zstream.next_in))buf.ptr;
		zstream.avail_in=cast(typeof(zstream.avail_in))buf.length;
		enforce(inflateInit(&zstream)==Z_OK);
	}
	
	
	size_t readFill(void[] data){
		if(data.length==0||eof){
			return 0;
		}
		zstream.next_out=cast(typeof(zstream.next_out))data.ptr;
		zstream.avail_out=cast(typeof(zstream.avail_out))data.length;
	start:
		auto res=inflate(&zstream,Z_SYNC_FLUSH);
		enforce(res==Z_OK||res==Z_STREAM_END);
		static if(QuitOnStreamEnd){
			if(res==Z_STREAM_END){
				goto end;
			}
		}else{
			if(res==Z_STREAM_END){
				enforce(zstream.avail_in==0);
			}
		}
		if(zstream.avail_in==0){
			if(eof_){
	end:
				inflateEnd(&zstream);
 				auto ret=data.length-zstream.avail_out;
				eof=true;
				return ret;
			}else{
				reloadbuf();
				goto start;//sorry
			}
		}
		
		if(zstream.avail_out==0){
			return data.length;
		}
		throw new Exception("something went wrong with zlib");
	}
	
	mixin readSkip;
	
	void reloadbuf(){
		auto l=buf.length;
		assert(buf.length!=0);
		buf=buf[0..stream.readFill(buf)];
		eof_=l!=buf.length;
	}
	
	@property void close(bool sub=true){
		inflateEnd(&zstream);
		if(sub){			
			static if(isDisposeRStream!S){
				stream.close();
			}
		}
	}
}

unittest{import std.zlib;import std.stdio;
	ubyte[2^^8] buf;	//input buf
	auto input=compress("hello world");//data
	ubyte[10] buf2;		//output buf
	auto zs=ZlibRStream!(MemRStream)(MemRStream(input),buf);
	static assert(isDisposeRStream!(typeof(zs)));
	static assert(isMarkableRStream!(typeof(zs)));
	assert(!zs.eof);
	auto aaa=zs.save;
	assert(5==zs.readFill(buf2[0..5]));
	assert(!zs.eof);
	assert(buf2[0..5]=="hello");
	assert(5==aaa.readFill(buf2[0..5]));
	assert(buf2[0..5]=="hello");
	assert(!aaa.eof);
	assert(6==zs.readFill(buf2[0..6]));
	assert(buf2[0..6]==" world");
	assert(zs.eof);
}
