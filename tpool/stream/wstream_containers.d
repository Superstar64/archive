module tpool.stream.wstream_containers;
import tpool.stream.wstream;
import std.c.stdlib : alloca;//i'm dangerous
import std.typetuple;
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


struct WStreamRange(S) if(isWStream!S){//converts a wstream into a range
	S stream;
	this(S s){
		stream=s;
	}
	void put(void[] buf){s.writeFill(buf);}
}

struct RangeWStream(R) if(isOutputRange!R){//converts a range to a wstream
	R range;
	this(R r){
		range=r;
	}
	void writeFill(void[] buf){
		range.put(buf);
	}
}

struct MultiPipeWStream(S...){//pipe single write stream to mulitple,
//todo static if for other type of streams
	S streams;
	this(S s){
		streams=s;
	}
	void writeFill(in void[] buf){
		foreach(i;streams){
			i.writeFill(buf);
		}
	}
	static if(allSatisfy!(isTypeWStream,S)||allSatisfy!(isStringWStream,S)){
		void write(T)(T t){
			foreach(i;streams){
				i.write(t);
			}
		}

		void writeAr(T)(in T[] t){
			foreach(i;streams){
				i.writeAr(t);
			}
		}
	}
	static if(allSatisfy!(isDisposeWStream,S)){
		@property{
			void flush(){
				foreach(i;streams){
					i.flush;
				}
			}
			
			void close(){
				foreach(i;streams){
					i.close;
				}
			}
		}
	}
}
unittest{
	auto stream=MultiPipeWStream!(MemWStream)(MemWStream());
	void[] temp;
	stream.writeFill(temp);
	static assert(isWStream!(typeof(stream)));
	static assert(!isTypeWStream!((typeof(stream))));
}

struct CountWStream(S) if(isWStream!S){
	ulong len;
	S stream;
	this(S stream_){
		stream=stream_;
	}
	auto writeFill(const void[] buf){
		len+=buf.length;
		return stream.writeFill(buf);
	}
	
}
unittest {
	static assert(isWStream!(CountWStream!VoidWStream));
	auto stream=LittleEndianWStream!(CountWStream!MemWStream)(CountWStream!MemWStream(MemWStream()));
	stream.write(cast(int)5);
	assert(stream.stream.len==4);
}void main(){}
