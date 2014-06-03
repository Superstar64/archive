module tpool.stream.rstream_containers;
import tpool.stream.rstream;
import tpool.stream.common;
import std.exception:enforce;
import std.algorithm;
import std.range;
class EofBadFormat:Exception{
	this(){
		this("Found eof when expecting Number");
	}
	
	this(string s){
		super(s);
	}
}

struct BigEndianRStream(S,bool check=true) if(isRStream!S){//if check is true then it check if readFill a aligned amount of data
	import std.exception;
	S stream;
	alias stream this;
	@property T read(T)() if(isDataType!T) {
		ubyte buf[T.sizeof];
		auto sz=stream.readFill(buf);
		static if(check){
			if(sz!=T.sizeof){
				throw new EofBadFormat();
			}
		}
		static if(T.sizeof!=1){
			version(LittleEndian){
				buf.reverse;
			}
		}
		return *(cast(T*)buf.ptr);
	}
	
	size_t readAr(T)(T[] buf) if(isDataType!T) {
		auto sz=stream.readFill(buf);
		static if(T.sizeof!=1){
			static if(check){
				if(sz%T.sizeof!=0){
					throw new EofBadFormat();
				}
			}
			version(LittleEndian){
				auto temp=cast(ubyte[]) buf;//templates errors are scary
				uint count;
				for(uint i=0;i<temp.length;i+=T.sizeof){
					temp[i..i+T.sizeof].reverse;
				}
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
auto bigEndianRStream(bool check=true,S)(S s){
	return BigEndianRStream!(S,check)(s);
}
unittest{
	auto a=bigEndianRStream(MemRStream());
}

struct LittleEndianRStream(S,bool check=true) if(isRStream!S){//if check is true then it check if readFill a aligned amount of data
	import std.exception;
	S stream;
	alias stream this;
	@property T read(T)() if(isDataType!T) {
		ubyte buf[T.sizeof];
		auto sz=stream.readFill(buf);
		static if(check){
			if(sz!=T.sizeof){
				throw new EofBadFormat();
			}
		}
		static if(T.sizeof!=1){
			version(BigEndian){
				buf.reverse;
			}
		}
		return *(cast(T*)buf.ptr);
	}
	
	size_t readAr(T)(T[] buf) if(isDataType!T) {
		auto sz=stream.readFill(buf);
		static if(T.sizeof!=1){
			static if(check){
				if(sz%T.sizeof!=0){
					throw new EofBadFormat();
				}
			}
			version(BigEndian){
				auto temp=cast(ubyte[]) buf;//templates errors are scary
				uint count;
				for(uint i=0;i<temp.length;i+=T.sizeof){
					temp[i..i+T.sizeof].reverse;
				}
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

auto littleEndianRStream(bool check=true,S)(S s){
	return LittleEndianRStream!(S,check)(s);
}
unittest{
	auto a=littleEndianRStream(MemRStream());
}

class EofBeforeLength:Exception{
	this(ulong read){
		import std.conv;
		super("Eof reached before limit "~to!string(read)~" bytes expected");
	}
}
struct LimitRStream(S,bool excepOnEof=true) if(isRStream!S){//limiting stream, return eof when limit bytes are read
															//if excepOnEof is true, it throws if eof is reached before limit
	S stream;
	ulong limit;
	size_t readFill(void[] buf) out(_outLength) {assert(_outLength<=buf.length ); } body {
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
	
	size_t skip(size_t amount) out(_outLength) {assert(_outLength<=amount ); } body{
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
					throw new EofBeforeLength(amount);
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
			bool eof(){
				return limit==0;
			}
		}else static if(isSeekableRStream!(S)){
			auto seek(){
				import std.math;
				return min(limit,stream.seek);
			}
		}		
	}
	mixin autoSave!(stream,limit);
}
unittest {
	ubyte[12] buf=[0,1,0,0, 5,1,   1,0,  0,2, 3,1];
	auto stream=LimitRStream!MemRStream(MemRStream(buf),4);
	static assert(isRStream!(typeof(stream)));
	static assert(isSeekableRStream!(typeof(stream)));
	static assert(isMarkableRStream!(typeof(stream)));
	assert(stream.seek==4);
	ubyte[3] temp;
	auto len=stream.readFill(temp);
	assert(len==3);
	len=stream.readFill(temp);
	assert(len==1);
	assert(stream.eof);
}
auto limitRStream(bool excepOnEof=true,S)(S s){
	return LimitRStream!(S,excepOnEof)(s);
}
unittest{
	auto a=limitRStream(MemRStream());
}
unittest {
	ubyte[12] buf=[0,1,0,0, 5,1,   1,0,  0,2, 3,1];
	auto stream=LimitRStream!MemRStream(MemRStream(buf),4);
	static assert(isRStream!(typeof(stream)));
	static assert(isSeekableRStream!(typeof(stream)));
	static assert(isMarkableRStream!(typeof(stream)));
	assert(stream.seek==4);
	assert(stream.skip(3)==3);
	assert(stream.skip(5)==1);
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
	static assert(isInputRange!(typeof(chunker)));
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

auto rangeRStream(Btype=ubyte,S)(S stream,Btype[] buf){
	return RangeRStream!(S,Btype)(stream,buf);
}
unittest{
	ubyte[1] buf;
	auto a=rangeRStream(MemRStream(),buf);
}

struct AllRStream(S) if(isRStream!S) {//a stream that throws a exception when a buffer is not fully filled
	S s;//stream
	alias stream=s;
	alias s this;
	size_t readFill(void[] buf) out(_outLength) {assert(_outLength<=buf.length ); } body{
		enforce(s.readFill(buf)==buf.length);
		return buf.length;
	}
	
	size_t skip(size_t si) out(_outLength) {assert(_outLength<=si ); } body{
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

auto allRStream(S)(S s){
	return AllRStream!S(s);
}
unittest{
	auto a=allRStream(MemRStream());
}

struct RawRStream(S,T,bool check=true) if(isRStream!S){
	S stream;
	alias stream this;
	@property T read(T)(){
		ubyte[T.sizeof] buf;
		auto len=stream.readFill(buf);
		static if(check){
			enforce(len==T.sizeof);
		}
		return *(cast(T*)(buf.ptr));
	}
	
	size_t readAr(T[] t){
		auto a=stream.readFill(cast(void[])t);
		static if(check){
			if(a%T.sizeof!=0){
				throw new EofBadFormat("Eof when expecting "~T.stringof);
			}
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
auto rawRStream(Type,bool check=true,S)(S stream){
	return RawRStream!(S,Type,check)(stream);
}
unittest{
	auto a=rawRStream!ubyte(MemRStream());
}
import etc.c.zlib;
struct ZlibIRangeRStream(R, alias init=inflateInit) if(isInputRange!R){
	R range;
	z_stream zstream;
	mixin readSkip;
	mixin autoSave!(range,zstream);
	this(R range_){
		range=range_;
		assert(range.front.ptr==range.front.ptr);//sanity test
		assert(range.front.length==range.front.length);
		zstream.next_in=cast(typeof(zstream.next_in))range.front.ptr;
		zstream.avail_in=cast(typeof(zstream.avail_in))range.front.length;
		init(&zstream);
	}
	
	this(R range_,z_stream z){//raw constructer plese ignore
		range=range_;
		enforce(inflateCopy(&zstream,&z)==Z_OK);
		zstream.next_in=cast(typeof(zstream.next_in))range.front.ptr;
		zstream.avail_in=cast(typeof(zstream.avail_in))range.front.length;
	}
	private auto refill(){
		range.popFront();
		if(range.empty){
			return true;
		}
		assert(range.front.ptr);
		assert(range.front.length!=0);
		zstream.next_in=cast(typeof(zstream.next_in))range.front.ptr;
		zstream.avail_in=cast(typeof(zstream.avail_in))range.front.length;
		return false;
	}
	size_t readFill(void[] buf){
		zstream.next_out=cast(typeof(zstream.next_out))buf.ptr;
		zstream.avail_out=cast(typeof(zstream.avail_out))buf.length;
	start:
		auto ret=inflate(&zstream,Z_SYNC_FLUSH);
		if(ret==Z_STREAM_END){
			return buf.length-zstream.avail_out;
		}
		enforce(ret==Z_OK);
		if(zstream.avail_in==0){
			if(refill()){
				return buf.length-zstream.avail_out;
			}
			goto start;
		}else{
			assert(zstream.avail_out==0);
			return buf.length;
		}
	}
	@property void close(){
		inflateEnd(&zstream);
	}
}
auto zlibIRangeRStream(alias init=inflateInit,R)(R range){
	return ZlibIRangeRStream!(R,init)(range);
}
struct ZlibRStream(S,alias init=inflateInit) if(isRStream!S){//buffers, reads more than needed
	ZlibIRangeRStream!(RangeRStream!(S,void),init) stream; alias stream this;
	this(S stream_,void[] buf){
		auto brange=rangeRStream(stream_,buf);
		stream=zlibIRangeRStream!(init)(brange);
	}
}
auto zlibRStream(alias init=inflateInit,S)(S s,void[] buf){
	return ZlibRStream!(S,init)(s,buf);
}

unittest{
	ubyte[1] buf;
	auto a=zlibRStream(MemRStream(),buf);
}

unittest{import std.zlib;import std.stdio;
	ubyte[2^^8] buf;	//input buf
	auto input=compress("hello world");//data
	ubyte[10] buf2;		//output buf
	auto zs=ZlibRStream!(MemRStream)(MemRStream(input),buf);
	
	scope(exit) zs.close;
	
	
	static assert(isDisposeRStream!(typeof(zs)));
	static assert(isMarkableRStream!(typeof(zs)));
	auto aaa=zs.save;
	
	scope(exit) aaa.close;
	
	
	assert(5==zs.readFill(buf2[0..5]));
	assert(buf2[0..5]=="hello");
	assert(5==aaa.readFill(buf2[0..5]));
	assert(buf2[0..5]=="hello");
	assert(6==zs.readFill(buf2[0..6]));
	assert(buf2[0..6]==" world");
}

unittest{import std.zlib;import std.stdio;
	ubyte[2^^8] buf;	//input buf
	auto input=compress("hello world");//data
	input~=cast(ubyte[])[4,1];//test for ZlibRStream!true
	ubyte[10] buf2;		//output buf
	auto zs=ZlibRStream!(MemRStream)(MemRStream(input),buf);
	
	scope(exit) zs.close;
	
	
	static assert(isDisposeRStream!(typeof(zs)));
	static assert(isMarkableRStream!(typeof(zs)));
	auto aaa=zs.save;
	
	scope(exit) aaa.close;
	
	
	assert(5==zs.readFill(buf2[0..5]));
	assert(buf2[0..5]=="hello");
	assert(5==aaa.readFill(buf2[0..5]));
	assert(buf2[0..5]=="hello");
	assert(6==zs.readFill(buf2[0..6]));
	assert(buf2[0..6]==" world");
}

struct Crc32RStream(S) if(isRStream!S){
	import etc.c.zlib;
	S stream;alias Stream=stream;alias stream this;
	uint crc;
	mixin readSkip;
	mixin autoSave!(Stream,crc);
	@property auto readFill(void[] arr) out(_outLength) {assert(_outLength<=arr.length ); } body{
		auto len=Stream.readFill(arr);
		assert(len<=arr.length);
		crc=crc32(crc,cast(ubyte*)arr.ptr,len);
		return len;
	}
}

unittest{
	import std.zlib;
	enum ubyte[] source=[3,4,5,9,0];
	auto str=Crc32RStream!MemRStream(MemRStream(source));
	static assert(isRStream!(typeof(str)));
	auto res=crc32(0,source);
	str.skip(1000);
	assert(str.crc==res);
}

auto crc32RStream(S)(S s){
	return Crc32RStream!(S)(s);
}
unittest{
	auto a=crc32RStream(MemRStream());
}

struct Adler32RStream(S) if(isRStream!S){
	import etc.c.zlib;
	S stream;alias Stream=stream;alias stream this;
	uint adler;
	mixin readSkip;
	mixin autoSave!(Stream,adler);
	@property auto readFill(void[] arr) out(_outLength) {assert(_outLength<=arr.length ); } body{
		auto len=Stream.readFill(arr);
		assert(len<=arr.length);
		adler=adler32(adler,cast(ubyte*)arr.ptr,len);
		return len;
	}
}
unittest{
	import std.zlib;
	enum ubyte[] source=[3,4,5,9,0];
	auto str=Adler32RStream!MemRStream(MemRStream(source));
	static assert(isRStream!(typeof(str)));
	auto res=adler32(0,source);
	str.skip(1000);
	assert(str.adler==res);
}

auto adler32RStream(S)(S s){
	return Adler32RStream!(S)(s);
}
unittest{
	auto a=adler32RStream(MemRStream());
}

//Left Right stream
//you can chain these together eg: LRStream!(MemRStream,LRStream(MemRStream,MemRStream))
struct LRStream(S1,S2) if(isRStream!S1 && isRStream!S2){// a stream that reads from the first until it's empty then reads from the second
	S1 stream1;
	S2 stream2;
	bool remain=true;
	static if(isCheckableRStream!S1&& isCheckableRStream!S2){
		@property bool eof(){
			return stream1.eof&&stream2.eof;
		}
	}
	size_t readFill(void[] buf) out(_outLength) {assert(_outLength<=buf.length ); } body{
		if(remain){
			auto read=stream1.readFill(buf); assert(read<=buf.length);
			if(read!=buf.length){
				remain=false;
				return read+readFill(buf[read..$]);
			}else{
				return buf.length;
			}
		}else{
			return stream2.readFill(buf);
		}
	}
	
	size_t skip(size_t size) out(_outLength) {assert(_outLength<=size ); } body{
		if(remain){
			auto read=stream1.skip(size); assert(read<=size);
			if(read!=size){
				remain=false;
				return read+skip(size-read);
			}else{
				return size;
			}
		}else{
			return stream2.skip(size);
		}
	}
	static if(isMarkableRStream!S1 && isMarkableRStream!S2){
		@property auto save(){
			return typeof(this)(stream1.save,stream2.save,remain);
		}
	}
	static if(isSeekableRStream!S1 && isSeekableRStream!S2){
		@property auto seek(){
			return stream1.seek+stream2.seek;
		}
	}
}
unittest{
	ubyte i[]=[1,2,3];
	auto str=LRStream!(MemRStream,MemRStream)(MemRStream(i),MemRStream(i));static assert(isMarkableRStream!(typeof(str)));
	ubyte o[6];
	assert(str.readFill(o[0..1])==1);
	assert(o[0]==1);
	
	assert(!str.eof);
	auto str2=str.save;
	assert(str2.readFill(o[0..4])==4);
	assert(o[0..4]==[2,3,1,2]);
	
	assert(str.readFill(o[0..4])==4);
	assert(o[0..4]==[2,3,1,2]);
	
	assert(!str.eof);
	
	assert(str.readFill(o[0..1])==1);
	
	assert(str.eof);
	
	assert(o[0]==3);
}

unittest{
	ubyte i[]=[1,2,3];
	auto str=LRStream!(MemRStream,MemRStream)(MemRStream(i),MemRStream(i));static assert(isMarkableRStream!(typeof(str)));
	ubyte o[6];
	assert(str.skip(1)==1);
	
	assert(!str.eof);
	
	auto str2=str.save;
	assert(str2.skip(4)==4);
	
	assert(str.skip(4)==4);
	
	assert(!str.eof);
	
	assert(str.skip(1)==1);
	
	assert(str.eof);
}
auto lrStream(S1,S2)(S1 s1,S2 s2){
	return LRStream!(S1,S2)(s1,s2);
}
unittest{
	auto a=lrStream(MemRStream(),MemRStream());
}
struct JoinRStream(R,bool allowsave=false) if(isInputRange!R && isRStream!(ElementType!R)){
	R range;
	bool eof_;
	size_t readFill(void[] buf) out(_outLength) {assert(_outLength<=buf.length ); } body{
		if(eof_){
			return 0;
		}
		auto sz=range.front.readFill(buf);
		if(sz==buf.length){
			return sz;
		}
		range.popFront();
		if(range.empty){
			eof_=true;
			return sz;
		}else{
			return sz+readFill(buf[sz..$]);
		}
	}
	
	size_t skip(size_t length) out(_outLength) {assert(_outLength<=length ); } body{
		if(eof_){
			return 0;
		}
		auto sz=range.front.skip(length);
		if(sz==length){
			return sz;
		}
		range.popFront();
		if(range.empty){
			eof_=true;
			return sz;
		}else{
			return sz+skip(length-sz);
		}
	}
	static if(isForwardRange!(R)&&isSeekableRStream!(ElementType!(R))){
		@property ulong seek(){
			auto iter=range.save;
			ulong sum;
			foreach(strem;iter){
				sum+=strem.seek;
			}
			return sum;
		}
		
		@property bool eof(){
			return seek==0;
		}
	}
	static  if(allowsave && isForwardRange!R){
		mixin autoSave!(range);
	}
}
unittest{
	ubyte[5] data=[1,2,3,4,5];
	auto range=[MemRStream(data),MemRStream(data),MemRStream(data)];
	auto stream=JoinRStream!(typeof(range))(range);
	static assert(isRStream!(typeof(stream)));
	
	assert(stream.seek==15);
	
	ubyte[6] buf;
	assert(stream.readFill(buf)==6);
	assert(buf==[1,2,3,4,5,1]);
	assert(!stream.eof);
	
	assert(stream.readFill(buf[0..1])==1);
	assert(buf[0..1]==[2]);
	assert(stream.skip(uint.max)==8);
	assert(stream.eof);
}
auto joinRStream(R)(R r){
	return JoinRStream!(R,false)(r);
}
unittest{
	auto a=joinRStream([MemRStream()]);
}

auto sjoinRStream(R)(R r){//saveable join stream, MAKE SURE R.save CALLS R.front.save
	//maybe use sjoinRStream(cache(map!(a=>a.save)(your_range_varible_here)))
	return JoinRStream!(R,true)(r);
}
unittest{
	import tpool.range;
	auto a=sjoinRStream([MemRStream()].map!(a=>a.save).cache);
}
