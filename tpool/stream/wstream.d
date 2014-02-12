module tpool.stream.wstream;
import std.typetuple;
import std.range;
alias WStreamTur=TypeTuple!(WStream_,DisposeWStream_);

//generally you want a function that does all the flushing and closing calling the function that does all the writing

//a writeable stream
interface WStream_{
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
