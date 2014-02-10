module tpool.stream.wstream;
import std.typetuple;
import std.range;
alias WStreamTur=TypeTuple!(WStream_,DisposeWStream_);

//generally you want a function that does all the flushing and closing calling the function that does all the writing

//a writeable stream
interface WStream_{
	void writeFull(const(void[]) buf);//fully write buf to output
}

template isWStream(S){
	enum bool isWStream=is(typeof((inout int=0){
		S s=void;void[] buf=void;
		s.writeFull(buf);
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

template WStreamWrap(S,Par=Object){
	static assert(isWStream!S);
	class WStreamWrap:Par,WStreamInterfaceOf!S{
		private S raw;alias raw this;
		this(S s){
			raw=s;
		}
		void writeFull(void[] buf){raw.writeFull(buf);}
		static if(isDisposeWStream){
			void flush(){raw.flush();}
			void close(){raw.close();}
		}
	}
}
unittest {

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