module tpool.stream.wstream_implementations;
import tpool.stream.wstream;
struct FileWStream{//a wstream wrapper for stdio.file
	import std.stdio;
	File file;
	
	void writeFill(const void[] buf){
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
	static assert(isWStream!FileWStream);
}
alias fileWStream=FileWStream;
struct MemWStream{//a stream that stores data into memory
	import std.typecons;
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
alias memWStream=MemWStream;
struct VoidWStream{//a stream that ignores all calls
	void opDispatch(string s,T)(T t){}
}
unittest {
	static assert(isWStream!VoidWStream);
}
alias voidWStream=VoidWStream;
import std.socket;
struct SocketWStream{
	Socket s;
	alias s this;
	void writeFill(const void[] ar){
		s.send(ar);
	}
	@property void flush(){}
}
unittest{
	static assert(isWStream!SocketWStream);
	static assert(isDisposeWStream!SocketWStream);
}
