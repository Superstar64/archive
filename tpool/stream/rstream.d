module tpool.stream.rstream;

import std.typetuple;
import tpool.stream.common;

public import tpool.stream.rstream_containers;
public import tpool.stream.rstream_implementations;

alias RStreamTur=TypeTuple!(RStream_,MarkableRStream_,SeekableRStream_,TypeRStream_,DisposeRStream_,StringRStream_);

//ReadStream
interface RStream_{//assigning or copying may make this stream invalid
	size_t readFill(void[] buf);//reads as much as possible into buf, when the return val is not equal to buf.length ,eof is assumed
	size_t skip(size_t len);//skips len bytes,returns bytes skiped, if the return val is not equal to buf.length, eof is assumed
	@property bool eof();//i want you to guess what this returns
	template IS(S){enum IS=isRStream!S;}
}
template isRStream(S){// thanks for std.range for nice exapmle code of this
	enum bool isRStream=is(typeof((inout int=0){
		S s=void;void[] a=void;size_t b=void;
		
		size_t len=s.readFill(a);
		size_t le=s.skip(b);
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
			s=s.save;
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
		final auto read(T)() if(isStringType!T){
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
		@property ulong seek(){return 0;}
		@property bool eof(){return true;}
	}
	auto cls=new RStreamWrap!TestSeek(TestSeek());
	void[] temp;
	cls.readFill(temp);
	cls.skip(0);
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

template hasR(S,T) {//checks if Stream supports type T
	enum bool hasR=is(typeof((inout int=0){
		S s=void;
		T a=s.read!(T);
		T[] v=void;
		size_t z=s.readAr(v);
	}));
}
unittest{
	BigEndianRStream!MemRStream a=void;
	static assert(hasR!(typeof(a),ubyte));
	static assert(!hasR!(typeof(a),bool));
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
}
unittest {
	char[] a=['a','b','c'];
	auto s=RawRStream!(MemRStream,char)(MemRStream(a));
	assert(s.read!char=='a');
	char[2] b2;
	s.readAr(b2);
	assert(b2=="bc");
}
