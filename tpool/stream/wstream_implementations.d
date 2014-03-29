module tpool.stream.wstream_implementations;
import tpool.stream.wstream;
struct FileWStream{
	import std.stdio;
	File file;
	
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

class MemWStream{
	import std.typecons;
	void[] array;
	void writeFill(const void[] buf){
		array~=buf;
	}
	
	this(){}
	
	this(void[] a){
		array=a;
	}
	
	static final auto opCall(void[] a=(void[]).init){
		return new typeof(this)(a);
	}
	
}

unittest{
	static assert(isWStream!MemWStream);
	auto str=MemWStream();
	str.writeFill(cast(ubyte[])[1,2,3]);
	str.writeFill("hello");
	assert(str.array==(cast(const ubyte[])[1,2,3]~cast(const ubyte[])"hello"));
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

struct VoidWStream{
	void opDispatch(string s,T)(T t){}
}
unittest {
	static assert(isWStream!VoidWStream);
}
