module tpool.format.png_chunk;
//Png chunks
//https://en.wikipedia.org/wiki/Portable_Network_Graphics#.22Chunks.22_within_the_file
import tpool.stream.rstream;
import std.range;
import std.exception: enforce;

struct ChunkRRange(S,bool checkCrc=true) if(isRStream!S){//carefull constructer pops first chunk imidately
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
		front.stream.skip(uint.max);//reach the end of the chunk to fill the crc
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
version(chunk_test){
	void main(string args[]){//todo use FileRStream later
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
		
		auto chunks=chunkRRange(fstream);
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
