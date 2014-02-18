module tpool.stream.wstream;
import std.typetuple;
import std.range;
import std.c.stdlib : alloca;//i'm dangerous
import tpool.stream.common;
alias WStreamTur=TypeTuple!(WStream_,TypeWStream_,DisposeWStream_,StringWStream_);


//generally you want a function that does all the flushing and closing calling the function that does all the writing

//a writeable stream
interface WStream_{//assigning or copying may make this stream invalid
	void writeFill(const(void[]) buf);//fully write buf to output
	template IS(S){
		enum bool IS=isWStream!S;
	}
}

template isWStream(S){
	enum bool isWStream=is(typeof((inout int=0){
		S s=void;const void[] buf=void;
		s.writeFill(buf);
	}));
}

unittest {
	struct emp{};
	static assert(!isWStream!emp);
	static assert(isWStream!WStream_);
}
//typed stream, you can write spesific types
interface TypeWStream_:WStream_{
	void write(ubyte b);//writes b to stream
	void write(ushort b);//ditto used transform
	void write(uint b);//ditto used transform
	void write(ulong b);//ditto used transform
	void write(byte b);//ditto used transform
	void write(short b);//ditto used transform
	void write(int b);//ditto used transform
	void write(long b);//ditto used transform
	void write(float b);//ditto used transform
	void write(double b);//ditto used transform
	
	void writeAr(in ubyte[] b);//ditto used transform
	void writeAr(in ushort[] b);//ditto used transform
	void writeAr(in uint[] b);//ditto used transform
	void writeAr(in ulong[] b);//ditto used transform
	void writeAr(in byte[] b);//ditto used transform
	void writeAr(in short[] b);//ditto used transform
	void writeAr(in int[] b);//ditto used transform
	void writeAr(in long[] b);//ditto used transform
	void writeAr(in float[] b);//ditto used transform
	void writeAr(in double[] b);//ditto used transform
	template IS(S){
		enum IS=isTypeWStream!S;
	}
}
template isTypeWStream(S){
	enum bool isTypeWStream=isWStream!S && is(typeof((inout int=0){
		S s=void;
		s.write(cast(const ubyte)0);
		s.write(cast(const ushort)0);
		s.write(cast(const uint)0);
		s.write(cast(const ulong)0);
		s.write(cast(const byte)0);
		s.write(cast(const short)0);
		s.write(cast(const int)0);
		s.write(cast(const long)0);
		s.write(cast(const float)0);
		s.write(cast(const double)0);
		void[] a=void;
		s.writeAr(cast(const ubyte[])a);
		s.writeAr(cast(const ushort[])a);
		s.writeAr(cast(const uint[])a);
		s.writeAr(cast(const ulong[])a);
		s.writeAr(cast(const byte[])a);
		s.writeAr(cast(const short[])a);
		s.writeAr(cast(const int[])a);
		s.writeAr(cast(const long[])a);
		s.writeAr(cast(const float[])a);
		s.writeAr(cast(const double[])a);
	}));
}
unittest{
	static assert(isTypeWStream!TypeWStream_);
	static assert(!isTypeWStream!WStream_);
}
//a stream that can flush output and close
interface DisposeWStream_:WStream_{
	@property void flush();//flush buf to the output, may do nothing
	@property void close();//close the steam may do nothing
	//on assertion mode close may make all methods of the stream throw errors
	template IS(S){
		enum bool IS=isDisposeWStream!S;
	}
}

template isDisposeWStream(S){
	enum bool isDisposeWStream= isWStream!S &&is(typeof((inout int=0){
		S s=void;
		s.flush;
		s.close;
	}));
}

unittest {
	static assert(!isDisposeWStream!WStream_);
	static assert(isDisposeWStream!DisposeWStream_);
}
//write string to a stream
interface StringWStream_:WStream_{
	void write(char c);//writes c to the steam
	void write(wchar c);//ditto use transform
	void write(dchar c);//ditto use transform
	void writeAr(in char[] c);//ditto use transform
	void writeAr(in wchar[] c);//ditto use transform
	void writeAr(in dchar[] c);//ditto use transform
	template IS(S){
		enum IS=isStringWStream!S;
	}
}
template isStringWStream(S){
	enum bool isStringWStream=isWStream!S&& is(typeof((inout int=0){
		S s=void;
		s.write(cast(char)0);
		s.write(cast(wchar)0);
		s.write(cast(dchar)0);
		void[] a=void;
		s.writeAr(cast(const char[])a);
		s.writeAr(cast(const wchar[])a);
		s.writeAr(cast(const dchar[])a);
	}));
}
unittest{
	static assert(isStringWStream!StringWStream_);
	static assert(!isStringWStream!WStream_);
}
//Wraps s in a class usefull for virtual pointers
class WStreamWrap(S,Par=Object):Par,WStreamInterfaceOf!S{
	private S raw;alias raw this;
	this(S s){
		raw=s;
	}
	override{
		void writeFill(const void[] buf){raw.writeFill(buf);}
		static if(isTypeWStream!S){
			void write(ubyte b){raw.write(b);}
			void write(ushort b){raw.write(b);}
			void write(uint b){raw.write(b);}
			void write(ulong b){raw.write(b);}
			void write(byte b){raw.write(b);}
			void write(short b){raw.write(b);}
			void write(int b){raw.write(b);}
			void write(long b){raw.write(b);}
			void write(float b){raw.write(b);}
			void write(double b){raw.write(b);}
			
			void writeAr(in ubyte[] b){raw.writeAr(b);}
			void writeAr(in ushort[] b){raw.writeAr(b);}
			void writeAr(in uint[] b){raw.writeAr(b);}
			void writeAr(in ulong[] b){raw.writeAr(b);}
			void writeAr(in byte[] b){raw.writeAr(b);}
			void writeAr(in short[] b){raw.writeAr(b);}
			void writeAr(in int[] b){raw.writeAr(b);}
			void writeAr(in long[] b){raw.writeAr(b);}
			void writeAr(in float[] b){raw.writeAr(b);}
			void writeAr(in double[] b){raw.writeAr(b);}
		}
		static if(isDisposeWStream!S){
			void flush(){raw.flush();}
			void close(){raw.close();}
		}
		static if(isStringWStream!S){
			void write(char b){raw.write(b);}
			void write(wchar b){raw.write(b);}
			void write(dchar b){raw.write(b);}
			void writeAr(in char[] b){raw.writeAr(b);}
			void writeAr(in wchar[] b){raw.writeAr(b);}
			void writeAr(in dchar[] b){raw.writeAr(b);}
		}
	}
}
unittest {
	auto str=new WStreamWrap!MemWStream(MemWStream());
	str.writeFill(cast(ubyte[])[1,2,3]);
	str.writeFill(cast(ubyte[])"hello");
	assert(str.array==(cast(const ubyte[])[1,2,3]~cast(const ubyte[])"hello"));
}

unittest{
	debug(wstream_file){
		import std.stdio;
		auto sr=new WStreamWrap!FileWStream(FileWStream(stdout));
		sr.writeFill(cast(void[])"hello world");
		sr.flush();
	}
}

template WStreamInterfaceOf(S){//return interface of all streams that S supports
	template I(A){
		enum I=A.IS!(S);
	}
	alias WStreamInterfaceOf=interFuse!(Filter!(I,WStreamTur));
}



//impletations



struct FileWStream{
	import std.stdio;
	File file;
	this(File file_){
		file=file_;
	}
	
	void writeFill(void[] buf){
		file.rawWrite(buf);
	}
	@property{
		void flush(){
			file.flush();
		}
		
		void close(){
			file.close();
		}
	}
}

struct MemWStream{
	void[] array;
	void writeFill(const void[] buf){
		array~=buf;
	}
}
unittest{
	static assert(isWStream!MemWStream);
	auto str=MemWStream();
	str.writeFill(cast(ubyte[])[1,2,3]);
	str.writeFill("hello");
	assert(str.array==(cast(const ubyte[])[1,2,3]~cast(const ubyte[])"hello"));
}


//containers



struct BigEndianWStream(S) if(isWStream!S){
	S stream;
	this(S s){
		stream=s;
	}
	void write(T)(T t){
		version(LittleEndian){
			(cast(void*)(&t))[0..T.sizeof].reverse;
		}
		stream.writeFill((cast(void*)(&t))[0..T.sizeof]);
	}
	
	void writeAr(T)(in T[] t){
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
	this(S s){
		stream=s;
	}
	void write(T)(T t){
		version(BigEndian){
			(cast(void*)(&t))[0..T.sizeof].reverse;
		}
		stream.writeFill((cast(void*)(&t))[0..T.sizeof]);
	}
	
	void writeAr(T)(in T[] t){
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


struct RangeWStream(S) if(isWStream!S){
	S stream;
	this(S s){
		stream=s;
	}
	void put(void[] buf){s.writeFill(buf);}
}
