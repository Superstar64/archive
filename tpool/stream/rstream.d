module tpool.stream.rstream;
import std.typetuple;
import std.range;
import std.algorithm;
import tpool.stream.common;
import std.math;
alias RStreamTur=TypeTuple!(RStream_,MarkableRStream_,SeekableRStream_,TypeRStream_,DisposeRStream_,StringRStream_);

//ReadStream
interface RStream_{//assigning or copying may make this stream invalid
	size_t readFill(void[] buf);//reads as much as possible into buf, when the return val is not equal to buf.length ,eof is assumed
	size_t skip(size_t len);//skips len bytes,returns bytes skiped, if the return val is not equal to buf.length, eof is assumed
	@property size_t avail();//how many bytes can be read right now
	@property bool eof();//i want you to guess what this returns
	template IS(S){enum IS=isRStream!S;}
}
template isRStream(S){// thanks for std.range for nice exapmle code of this
	enum bool isRStream=is(typeof((inout int=0){
		S s=void;void[] a=void;size_t b=void;
		
		size_t len=s.readFill(a);
		size_t le=s.skip(b);
		size_t av=s.avail;
		bool end=s.eof;
	}));
}
unittest{
	struct Emp{}
	static assert(isRStream!(RStream_));
	static assert(!isRStream!(Emp));
}

//a stream that can save the curren position
interface MarkableRStream_:RStream_{
	@property typeof(this) save();//saves current pos to the return value
	template IS(S){enum IS=isMarkableRStream!S;}
}
template isMarkableRStream(S){
	enum bool isMarkableRStream=isRStream!(S) && 
		is(typeof((inout int=0){
			S s=void;
			static assert(is(S==typeof(s.save)));
		}));
}
unittest{
	static assert(isMarkableRStream!(MarkableRStream_));
	static assert(!isMarkableRStream!(RStream_));
}

//a stream that know exactly how much data is left
interface SeekableRStream_:RStream_{
	@property ulong seek();//returns exactly how much is left in the stream
	template IS(S){enum IS=isSeekableRStream!S;}
}
template isSeekableRStream(S){
	enum bool isSeekableRStream=isRStream!(S) && 
		is(typeof((inout int=0){
			S s=void;
			static assert(is(ulong==typeof(s.seek)));
		}));
}
unittest {
	static assert(isSeekableRStream!SeekableRStream_);
	static assert(!isSeekableRStream!RStream_);
}
//a type stream, read spesific types
interface TypeRStream_:RStream_{
	@property{
		final{
			auto read(T)(){//throws exception if eof is reached before T could be fully copyed
				mixin("return read_"~T.stringof~";");
			}
		}
		ubyte read_ubyte();//never call these, only implement if you overriding this interface
		ushort read_ushort();//ditto used transform
		uint read_uint();//ditto used transform
		ulong read_ulong();//ditto used transform
		byte read_byte();//ditto used transform
		short read_short();//ditto used transform
		int read_int();//ditto used transform
		long read_long();//ditto used transform
		float read_float();//ditto used transform
		double read_double();//ditto used transform
	}
	size_t readAr(ubyte[]);//returns num of data read, throws exception if eof is reached when a number is fully copyed
	size_t readAr(ushort[]);//ditto used transform
	size_t readAr(uint[]);//ditto used transform
	size_t readAr(ulong[]);//ditto used transform
	size_t readAr(byte[]);//ditto used transform
	size_t readAr(short[]);//ditto used transform
	size_t readAr(int[]);//ditto used transform
	size_t readAr(long[]);//ditto used transform
	size_t readAr(float[]);//ditto used transform
	size_t readAr(double[]);//ditto used transform
	template IS(S){enum IS=isTypeRStream!S;}
}
template isTypeRStream(S){
	enum bool isTypeRStream=isRStream!(S) && 
		is(typeof((inout int=0){
			S s=void;
			static assert(is(ubyte ==typeof(s.read!ubyte)) );
			static assert(is(ushort ==typeof(s.read!ushort)) );
			static assert(is(uint ==typeof(s.read!uint)) );
			static assert(is(ulong ==typeof(s.read!ulong)) );
			static assert(is(byte ==typeof(s.read!byte)) );
			static assert(is(short ==typeof(s.read!short)) );
			static assert(is(int ==typeof(s.read!int)) );
			static assert(is(long ==typeof(s.read!long)) );
			static assert(is(float ==typeof(s.read!float)) );
			static assert(is(double ==typeof(s.read!double)) );
			
			ubyte[] k;
			ushort[] m;
			uint[] n;
			ulong[] o;
			byte[] p;
			short[] q;
			int[] r;
			long[] ss;
			float[] t;
			double[] u;
			static assert(is(size_t ==typeof(s.readAr(k))));
			static assert(is(size_t ==typeof(s.readAr(m))));
			static assert(is(size_t ==typeof(s.readAr(n))));
			static assert(is(size_t ==typeof(s.readAr(o))));
			static assert(is(size_t ==typeof(s.readAr(p))));
			static assert(is(size_t ==typeof(s.readAr(q))));
			static assert(is(size_t ==typeof(s.readAr(r))));
			static assert(is(size_t ==typeof(s.readAr(ss))));
			static assert(is(size_t ==typeof(s.readAr(t))));
			static assert(is(size_t ==typeof(s.readAr(u))));
		}));
}
unittest{
	struct TestType{
		size_t readFill(void[]){return 0;}
		size_t skip(size_t p){return false;}
		@property avail(){return 0;}
		@property ulong seek(){return 0;}
		@property bool eof(){return true;}
		@property auto read(T)(){
			return cast(T)0;
		}
		size_t readAr(T)(T[]){
			return 0;
		}
	}
	static assert(isTypeRStream!TestType);
	static assert(isTypeRStream!TypeRStream_);
	static assert(!(isTypeRStream!RStream_));
}
//close able Rstream
interface DisposeRStream_:RStream_{
	@property void close();
	template IS(S){enum IS=isDisposeRStream!S;}
}

template isDisposeRStream(S){
	enum bool isDisposeRStream=isRStream!(S) && 
		is(typeof((inout int=0){
			S s=void;
			s.close;
		}));
}

unittest{
	static assert(!isDisposeRStream!RStream_);
	static assert(isDisposeRStream!DisposeRStream_);
}
//read string from a stream
interface StringRStream_:RStream_{
	@property{
		final auto read(T)(){
			mixin("return read_"~T.stringof~';');
		}
		char read_char();//do not call these
		wchar read_wchar();//ditto use transform
		dchar read_dchar();//ditto use transform
	}
	size_t readAr(char[] c);//reads into c reads amount read
	size_t readAr(wchar[] c);//ditto use transform
	size_t readAr(dchar[] c);//ditto use transform
	template IS(S){
		enum IS=isStringRStream!S;
	}
}
template isStringRStream(S){
	enum bool isStringRStream=isRStream!S&& is(typeof((inout int=0){
		S s=void;
		static assert(is(typeof(s.read!char)==char));
		static assert(is(typeof(s.read!wchar)==wchar));
		static assert(is(typeof(s.read!dchar)==dchar));
		void[] a=void;
		static assert(is(size_t ==typeof(s.readAr(cast(char[])a))));
		static assert(is(size_t ==typeof(s.readAr(cast(wchar[])a))));
		static assert(is(size_t ==typeof(s.readAr(cast(dchar[])a))));
	}));
}
unittest{
	static assert(isStringRStream!StringRStream_);
	static assert(!isStringRStream!RStream_);
}
//wrap S in a class, usefull if you prefer virtual pointers over code duplication
class RStreamWrap(S,Par=Object):Par,RStreamInterfaceOf!(S) {//need to find a better way to do this
	private S raw;alias raw this;
	this(S s){
		raw=s;
	}
	override{
		size_t readFill(void[] b){return raw.readFill(b);}
		size_t skip(size_t b){return raw.skip(b);}
		@property size_t avail(){return raw.avail;}
		@property bool eof(){return raw.eof;}
		static if(isMarkableRStream!S){
			@property typeof(this) save(){return new RStreamWrap(raw);}
		}
		
		static if(isSeekableRStream!S){
			@property ulong seek(){return raw.seek;}
		}
		
		static if(isTypeRStream!S){
			@property{
				ubyte read_ubyte(){return raw.read!ubyte;}
				ushort read_ushort(){return raw.read!ushort;}
				uint read_uint(){return raw.read!uint;}
				ulong read_ulong(){return raw.read!ulong;}
				byte read_byte(){return raw.read!byte;}
				short read_short(){return raw.read!short;}
				int read_int(){return raw.read!int;}
				long read_long(){return raw.read!long;}
				float read_float(){return raw.read!float;}
				double read_double(){return raw.read!double;}
			}
			size_t readAr(ubyte[] a){return raw.readAr(a);}
			size_t readAr(ushort[] a){return raw.readAr(a);}
			size_t readAr(uint[] a){return raw.readAr(a);}
			size_t readAr(ulong[] a){return raw.readAr(a);}
			size_t readAr(byte[] a){return raw.readAr(a);}
			size_t readAr(short[] a){return raw.readAr(a);}
			size_t readAr(int[] a){return raw.readAr(a);}
			size_t readAr(long[] a){return raw.readAr(a);}
			size_t readAr(float[] a){return raw.readAr(a);}
			size_t readAr(double[] a){return raw.readAr(a);}
		}
	}
	static if(isDisposeRStream!S){
		@property void close(){raw.close;}
	}
	static if(isStringRStream!S){
			@property{
				char read_char(){return raw.read!char;}
				wchar read_wchar(){return raw.read!wchar;}
				dchar read_dchar(){return raw.read!dchar;}
			}
			size_t readAr(char[] c){return raw.readAr(c);}
			size_t readAr(wchar[] c){return raw.readAr(c);}
			size_t readAr(dchar[] c){return raw.readAr(c);}
	}
}

unittest{
	struct TestSeek{
		size_t readFill(void[]){return 0;}
		size_t skip(size_t p){return false;}
		@property avail(){return 0;}
		@property ulong seek(){return 0;}
		@property bool eof(){return true;}
	}
	auto cls=new RStreamWrap!TestSeek(TestSeek());
	void[] temp;
	cls.readFill(temp);
	cls.skip(0);
	cls.avail();
	cls.seek();
	void testFun(RStream_ test){
		test.readFill(temp);
	}
	testFun(cls);
}

unittest{//spesific unittest for TypeRStream
	struct TestType{
		size_t readFill(void[]){return 0;}
		size_t skip(size_t p){return false;}
		@property avail(){return 0;}
		@property ulong seek(){return 0;}
		@property auto read(T)(){
			return cast(T)0;
		}
		size_t readAr(T)(T[]){
			return 0;
		}
		bool eof(){return true;}
	}
	auto cls=new RStreamWrap!TestType(TestType());
	ubyte a=cls.read!ubyte;
}

template RStreamInterfaceOf(S){//return interface of all streams that S supports
	template I(A){
		enum I=A.IS!(S);
	}
	alias RStreamInterfaceOf=interFuse!(Filter!(I,RStreamTur));
}




//implementations




struct MemRStream{
	import std.c.string;
	const(void)[] arr;
	this(typeof(arr) mem){
		arr=mem;
	}
	size_t readFill(void[] buf){
		if(buf.length>=arr.length){
			memcpy(buf.ptr,arr.ptr,arr.length);
			auto len=arr.length;
			arr=arr[0..0];//i've invented a new emoticon
			return len;
		}else{
			memcpy(buf.ptr,arr.ptr,buf.length);
			arr=arr[buf.length..$];
			return buf.length;
		}
	}
	
	size_t skip(size_t len){
		if(len>=arr.length){
			auto arlen=arr.length;
			arr=arr[0..0];
			return arlen;
		}else{
			arr=arr[len..$];
			return len;
		}
		
	}
	@property bool eof(){
		return arr.length==0;
	}
	
	@property size_t avail(){
		return arr.length;
	}
	
	@property typeof(this) save(){return typeof(this)(arr);}
	
	@property ulong seek(){
		return avail();
	}
}

unittest{
	static assert(isSeekableRStream!MemRStream);
	static assert(isMarkableRStream!MemRStream);
	ubyte [7] data=[1,5,0,9,3,10,200];
	auto s=MemRStream(data);
	ubyte[2] temp;
	assert(2==s.readFill(temp));
	assert(5==s.seek);
	assert(5==s.avail);
	assert(temp==[1,5]);
	assert(4==s.skip(4));
	assert(1==s.readFill(temp));
	assert(temp[0]==200);
	assert(s.eof);
}


struct FileRStream{
	import std.stdio;
	File file;
	this(File file_){
		file=file_;
	}
	size_t readFill(void[] buf){
		auto s=file.rawRead(buf);
		return s.length;
	}
	
	@property{
		size_t skip(size_t size){
			import std.c.stdlib: alloca;
			auto tem=alloca(size);
			return readFill(tem[0..size]);
		}
		size_t avail(){
			if (seek>size_t.max){
				return size_t.max;
			}
			return cast(size_t) seek();
		}
		bool eof(){
			return file.eof;
		}
		
		void close(){
			file.close;
		}
		
		auto seek(){
			return file.size;
		}
	}
}
unittest {
	static assert(isDisposeRStream!FileRStream);
	
	debug(rstream_file){
		import std.stdio;
		auto fs=new RStreamWrap!FileRStream(FileRStream(stdin));
		ubyte buf[16];
		while(true){
			writeln(fs.readFill(buf));
			writeln(buf);
		}
	}
}

//stream containers

class EofBadFormat:Exception{
	this(){
		super("Found eof when expecting Number");
	}
}

struct BigEndianRStream(S) if(isRStream!S){
	import std.exception;
	S stream;
	this(S stream_){
		stream=stream_;
	}
	alias stream this;
	@property T read(T)(){
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
	
	size_t readAr(T)(T[] buf){
		auto sz=stream.readFill(buf);
		if(sz==0||sz%T.sizeof!=0){
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
	this(S stream_){
		stream=stream_;
	}
	alias stream this;
	@property T read(T)(){
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
	
	size_t readAr(T)(T[] buf){
		auto sz=stream.readFill(buf);
		if(sz==0||sz%T.sizeof!=0){
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
	this(S s,ulong limit_){
		stream=s;
		limit=limit_;
	}
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
		size_t avail(){
			auto av=stream.avail();
			return min(av,limit);
		}
		
		bool eof(){
			return limit==0;
		}
	}
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