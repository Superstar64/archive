module tpool.png_chunk.chunk;
//Png chunks
//https://en.wikipedia.org/wiki/Portable_Network_Graphics#.22Chunks.22_within_the_file
import tpool.stream.rstream;
import std.range;
import std.exception: enforce;

struct ChunkRange(S) if(isRStream!S){//carefull constructer pops first chunk imidately
	struct Chunk{//type used for reading chunk
		char[4] name;
		LimitRStream!(Crc32RStream!(S),true) stream;
		@property auto length(){
			return stream.seek;
		}
	}
	
	BigEndianRStream!S stream;
	this(S stream_){
		stream=BigEndianRStream!(S)(stream_);
		popFront();
	}
	Chunk front;
	bool first=true;
	bool empty;
	@property void popFront(){
		if(first){
			first=false;
		}else{
			front.stream.skip(uint.max);//reach the end of the chunk to fill the crc
			stream=typeof(stream)(front.stream.stream.stream);//rewrap S into BigEndianRStream!S
			auto crc=stream.read!uint;
			enforce(crc==front.stream.stream.crc);
			empty=stream.eof;
			if(empty){
				return;
			}
		}
		auto len=stream.read!uint;
		auto crcstream=Crc32RStream!(S)(stream.stream);
		char[4] name;
		enforce(name.length==crcstream.readFill(name));
		front=Chunk(name,typeof(front.stream)(crcstream,len));
	}
	
}

version(chunk_test){
	void main(string args[]){
		import std.stdio;import std.file;
		if(args.length<2){
			writeln("no arguments");
			return;
		}
		auto buf=read(args[1]);
		auto fstream=FileRStream!false(File(args[1]));
		ubyte[8] sig;
		fstream.readFill(sig);
		enforce(sig==[0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a]);
		writeln(sig);
		
		auto chunks=ChunkRange!(typeof(fstream))  (fstream);
		static assert(isInputRange!(typeof(chunks)));
		foreach(i;chunks){
			writeln("name  :",i.name);
			writeln("length:",i.length);
			
		}
	}
}
