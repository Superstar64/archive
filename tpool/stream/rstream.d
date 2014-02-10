module tpool.stream.rstream;
import std.typetuple;
import std.range;
import std.algorithm;
			
//ReadStream
interface RStream_{
	size_t readFill(void[] buf);//reads as much as possible into buf, when the return val is not equal to buf.length ,eof is assumed
	size_t skip(size_t len);//skips len bytes,returns bytes skiped, if the return val is not equal to buf.length, eof is assumed
	@property size_t avail();//how many bytes can be read right now
	@property bool empty();//i want you to guess what this returns
	template IS(S){enum IS=isRStream!S;}
}
template isRStream(S){// thanks for std.range for nice exapmle code of this
	enum bool isRStream=is(typeof((inout int=0){
		S s=void;void[] a=void;size_t b=void;
		
		size_t len=s.readFill(a);
		size_t le=s.skip(b);
		size_t av=s.avail;
		bool end=s.empty;
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
	@property size_t seek();//returns exactly how much is left in the stream
	template IS(S){enum IS=isSeekableRStream!S;}
}
template isSeekableRStream(S){
	enum bool isSeekableRStream=isRStream!(S) && 
		is(typeof((inout int=0){
			S s=void;
			static assert(is(size_t==typeof(s.seek)));
		}));
}
unittest {
	static assert(isSeekableRStream!SeekableRStream_);
	static assert(!isSeekableRStream!RStream_);
}
//a type stream
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
		@property size_t seek(){return 0;}
		@property bool empty(){return true;}
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

template RStreamWrap(S,Par=Object){//wrap S in a class
	static assert(isRStream!S);
		
		class RStreamWrap:Par,RStreamInterfaceOf!(S){
			private S raw;alias raw this;
			this(S s){
				raw=s;
			}
			size_t readFill(void[] b){return raw.readFill(b);}
			size_t skip(size_t b){return raw.skip(b);}
			@property size_t avail(){return raw.avail;}
			@property bool empty(){return raw.empty;}
			static if(isMarkableRStream!S){
				@property typeof(this) save(){return new RStreamWrap(raw);}
			}
			
			static if(isSeekableRStream!S){
				@property size_t seek(){return raw.seek;}
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
}

unittest{
	struct TestSeek{
		size_t readFill(void[]){return 0;}
		size_t skip(size_t p){return false;}
		@property avail(){return 0;}
		@property size_t seek(){return 0;}
		@property bool empty(){return true;}
	}
	auto cls=new RStreamWrap!(TestSeek)(TestSeek());
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
		@property size_t seek(){return 0;}
		@property auto read(T)(){
			return cast(T)0;
		}
		size_t readAr(T)(T[]){
			return 0;
		}
		bool empty(){return true;}
	}
	auto cls=new RStreamWrap!(TestType)(TestType());
	ubyte a=cls.read!ubyte;
}

template RStreamInterfaceOf(S){//return interface of all streams that S supports
	template I(A){
		enum I=A.IS!(S);
	}
	alias RStreamInterfaceOf=interFuse!(Filter!(I,RStreamTur));
}


template interFuse(T...){//fuse interfaces
	interface interFuse:T{}
}
alias RStreamTur=TypeTuple!(RStream_,MarkableRStream_,SeekableRStream_,TypeRStream_);




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
	@property bool empty(){
		return arr.length==0;
	}
	
	@property size_t avail(){
		return arr.length;
	}
	
	@property typeof(this) save(){return typeof(this)(arr);}
	
	@property size_t seek(){
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
	assert(s.empty);
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
			foreach(i;temp.chunks(T.sizeof).map!(a=>a.reverse)){
				foreach(ii;i){
					temp[count]=ii;
					count++;
				}
			}
		}
		return sz/T.sizeof;
	}
	
}

unittest {
	ubyte[12] buf=[0,0,1,0, 1,5,   0,1,  2,0, 1,3];
	auto stream=BigEndianRStream!MemRStream(MemRStream(buf));
	assert(stream.read!int==256);
	assert(!stream.empty);
	assert(stream.read!ushort==261);
	ushort[3] buf2;
	assert(stream.readAr(buf2)==3);
	assert(stream.empty);
	assert(buf2==[1,512,259]);
}
