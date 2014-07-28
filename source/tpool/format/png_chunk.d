module tpool.format.png_chunk;
//Png chunks
//https://en.wikipedia.org/wiki/Portable_Network_Graphics#.22Chunks.22_within_the_file
import tpool.stream.wstream;
import tpool.stream.rstream;
import std.range;
import std.exception: enforce;

//do not call functions that copy and save this element with out call chuckRSave
struct ChunkRRange(S,bool checkCrc=true) if(isRStream!S){
	
	struct Chunk{//type used for reading chunk
		char[4] name;
		static if(checkCrc){
			LimitRStream!(Crc32RStream!(S),true) stream;
		}else{
			LimitRStream!(S,true) stream;
		}
		@property auto length(){
			return stream.seek;
		}
	}
	
	
	this(S stream_){
		stream=BigEndianRStream!(S)(stream_);
		getNext();
	}
	this(BigEndianRStream!S stream_,Chunk front_,bool first_,bool empty_){//raw constructor
		stream=stream_;
		front=front_;
		first=first_;
		empty=empty_;
	}
	BigEndianRStream!S stream;
	Chunk front;
	bool first=true;
	bool empty;
	@property void popFront(){
		front.stream.skipRest;//reach the end of the chunk to fill the crc
		static if(checkCrc){
			stream=typeof(stream)(front.stream.stream.stream);//rewrap S into BigEndianRStream!S
		}else{
			stream=typeof(stream)(front.stream.stream);//rewrap S into BigEndianRStream!S
		}
		auto crc=stream.read!uint;
		static if(checkCrc){
			enforce(crc==front.stream.stream.crc);
		}
		getNext();
	}
	
	private void getNext(){
		uint[1] temp;
		if(stream.readAr(temp)==0){
			empty=true;
			return;
		}
		uint len=temp[0];
		static if(checkCrc){
			auto crcstream=Crc32RStream!(S)(stream.stream);
		}else{
			auto crcstream=stream.stream;
		}
		char[4] name;
		enforce(name.length==crcstream.readFill(name));
		front=Chunk(name,typeof(front.stream)(crcstream,len));
	}
	mixin autoSave!(stream,front,first,empty);
}
auto chunkRRange(bool checkCrc=true,S)(S stream){
	return ChunkRRange!(S,checkCrc)(stream);
}
auto chuckRSave(R)(R range){
	import std.algorithm;
	return range.map!(a=>{auto b=a;b.stream=b.stream.save;return b;}());
}

version(chunk_test){
	void main(string args[]){
		import std.stdio;import std.file;
		if(args.length<2){
			writeln("no arguments");
			return;
		}
		auto fstream=(FileRStream!false(File(args[1])));
		ubyte[8] sig;
		fstream.readFill(sig);
		enforce(sig==[0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a]);
		writeln(sig);
		
		auto chunks=chunkRRange(fstream);
		static assert(isInputRange!(typeof(chunks)));
		foreach(i;chunks){
			writeln("name  :",i.name);
			writeln("length:",i.length);
			
		}
	}
}

version(chunk_test2){//save and no crc test
	void main(string args[]){
		import std.stdio;import std.file;
		if(args.length<2){
			writeln("no arguments");
			return;
		}
		auto buf=read(args[1]);
		
		auto fstream=MemRStream(buf);
		ubyte[8] sig;
		fstream.readFill(sig);
		enforce(sig==[0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a]);
		writeln(sig);
		
		auto chunks=chunkRRange(fstream).chuckRSave;
		static assert(isForwardRange!(typeof(chunks)));
		foreach(i;chunks.save){
			writeln("name  :",i.name);
			writeln("length:",i.length);
		}
		foreach(i;chunks){
			writeln("save test ",i.stream.seek);
		}
	}
}

struct ChunkW{
	char[4] name;
	void[] data;
}

struct ChunkWRange(WStream) if(isWStream!WStream){
	WStream stream;
	void put(ChunkW c){
		auto s=bigEndianWStream(&stream);
		s.write(cast(uint)c.data.length);
		auto s2=bigEndianWStream(crc32WStream(&stream));
		s2.writeFill(c.name);
		s2.writeFill(c.data);
		s.write(s2.crc);
	}
}
auto chunkWRange(WStream)(WStream w){
	return ChunkWRange!WStream(w);
}
unittest{
	auto w=chunkWRange(memWStream());
	w.put(ChunkW("test",cast(ubyte[])[0,1,2]));
}
