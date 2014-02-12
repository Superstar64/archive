module tpool.stream.wstream;
import std.typetuple;
import std.range;
alias WStreamTur=TypeTuple!(WStream_,TypeWStream_,DisposeWStream_);


//generally you want a function that does all the flushing and closing calling the function that does all the writing

//a writeable stream
interface WStream_{//assigning or copying may make this stream invalid
	void writefill(const(void[]) buf);//fully write buf to output
	template IS(S){
		enum bool IS=isWStream!S;
	}
}

template isWStream(S){
	enum bool isWStream=is(typeof((inout int=0){
		S s=void;void[] buf=void;
		s.writefill(buf);
	}));
}

unittest {
	struct emp{};
	static assert(!isWStream!emp);
	static assert(isWStream!WStream_);
}

interface TypeWStream_:WStream_{
	void write(in ubyte b);//writes b to stream
	void write(in ushort b);//ditto used transform
	void write(in uint b);//ditto used transform
	void write(in ulong b);//ditto used transform
	void write(in byte b);//ditto used transform
	void write(in short b);//ditto used transform
	void write(in int b);//ditto used transform
	void write(in long b);//ditto used transform
	void write(in float b);//ditto used transform
	void write(in double b);//ditto used transform
	
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
		s.write(cast(ubyte)0);
		s.write(cast(ushort)0);
		s.write(cast(uint)0);
		s.write(cast(ulong)0);
		s.write(cast(byte)0);
		s.write(cast(short)0);
		s.write(cast(int)0);
		s.write(cast(long)0);
		s.write(cast(float)0);
		s.write(cast(double)0);
		void[] a=void;
		s.writeAr(cast(ubyte[])a);
		s.writeAr(cast(ushort[])a);
		s.writeAr(cast(uint[])a);
		s.writeAr(cast(ulong[])a);
		s.writeAr(cast(byte[])a);
		s.writeAr(cast(short[])a);
		s.writeAr(cast(int[])a);
		s.writeAr(cast(long[])a);
		s.writeAr(cast(float[])a);
		s.writeAr(cast(double[])a);
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
//Wraps s in a class usefull for virtual pointers
class WStreamWrap(S,Par=Object):Par,WStreamInterfaceOf!S{
	private S raw;alias raw this;
	this(S s){
		raw=s;
	}
	void writeFill(void[] buf){raw.writeFill(buf);}
	static if(isDisposeWStream!S){
		void flush(){raw.flush();}
		void close(){raw.close();}
	}
}
unittest {
	
}
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

template interFuse(T...){//fuse interfaces
	interface interFuse:T{}
}

//containers


struct RangeWStream(S){
	S stream_;
	this(S s){
		stream_=s;
	}
	void put(void[] buf){s.writeBuf(buf);}
}
