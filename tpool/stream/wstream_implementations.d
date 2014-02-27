module tpool.stream.wstream_implementations;
import tpool.stream.wstream;
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

struct VoidWStream{
	void opDispatch(string s,T)(T t){}
}
unittest {
	static assert(isWStream!VoidWStream);
}
