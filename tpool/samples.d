module tpool.samples;
import std.stdio;
import tpool.stream.rstream;
import tpool.stream.wstream;
//compile with ./buildunit.sh -version=... on the root directory , and see the file at build/test(\.exe)?

version(readtar){
	import tpool.format.tar;
	void main(string args[]){
		if(args.length<2){
			writeln(args[0]~" file");
		}
		auto fs=fileRStream(File(args[1]));
		ubyte[512] tarbuffer;//for tar files the buffer size must be 512
		auto tar=tarRRange(fs,tarbuffer);
		foreach(i;tar){//reuses buffer, wrap in tarRSave if you want to save local copies (eg: std.array.save)
			writeln(i.name,' ',i.stream.seek);
		}
		//optional because File* is ref counted
		fs=tar.stream;//copy back because everything is passed by value
		fs.close;
	}
}

version (readgz) {
	import tpool.format.gzip;
	void main(string args[]){
		if(args.length<2){
			writeln(args[0]~ " file");
		}
		auto fs=fileRStream!false(File(args[1]));//fileRStream!true allows seeking fileRStream!false disables seeking , true is the default
		ubyte[256] gzbuffer;//unlike tar, this buffer can by any size greater than 0
		auto gz=gzipRStream(fs,gzbuffer);
		scope(exit){
			gz.close;//closes the gzip stream(zlib) and closes the file
		}
		ubyte[512] buffer;
		auto range=rangeRStream(&gz,buffer);//can pass by pointer if you like
		//range is saveable if the stream is saveable
		foreach(i;range){
			writeln(cast(char[])i);
		}
	}
}

version (readbytes){
	void main(string args[]){
		if(args.length<2){
			writeln(args[0]~" file");
		}
		auto fs=fileRStream!false(File(args[1]));
		auto strm=littleEndianRStream(peekRStream(fs));//peekRStream peeks 1 byte ahead to check for eof
		scope(exit){
			//as stated above this is optional
			strm.close;
		}
		while(!strm.eof){
			writeln(strm.read!ubyte);//read function provided by littleEndianRStream
		}
	}
}
