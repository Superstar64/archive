module tpool.stream.rstream_implementations;
import tpool.stream.rstream;
struct MemRStream{
	import std.c.string;
	const(void)[] arr;
	this(typeof(arr) mem){
		arr=mem;
	}
	size_t readFill(void[] buf){
		if(buf.length>=arr.length){
			memcpy(buf.ptr,arr.ptr,arr.length);
			auto len=arr.length;
			arr=arr[0..0];//i've invented a new emoticon
			return len;
		}else{
			memcpy(buf.ptr,arr.ptr,buf.length);
			arr=arr[buf.length..$];
			return buf.length;
		}
	}
	
	size_t skip(size_t len){
		if(len>=arr.length){
			auto arlen=arr.length;
			arr=arr[0..0];
			return arlen;
		}else{
			arr=arr[len..$];
			return len;
		}
		
	}
	@property bool eof(){
		return arr.length==0;
	}
	
	@property size_t avail(){
		return arr.length;
	}
	
	@property typeof(this) save(){return typeof(this)(arr);}
	
	@property ulong seek(){
		return avail();
	}
}

unittest{
	static assert(isSeekableRStream!MemRStream);
	static assert(isMarkableRStream!MemRStream);
	ubyte [7] data=[1,5,0,9,3,10,200];
	auto s=MemRStream(data);
	ubyte[2] temp;
	assert(2==s.readFill(temp));
	assert(5==s.seek);
	assert(5==s.avail);
	assert(temp==[1,5]);
	assert(4==s.skip(4));
	assert(1==s.readFill(temp));
	assert(temp[0]==200);
	assert(s.eof);
}


struct FileRStream{
	import std.stdio;
	File file;
	this(File file_){
		file=file_;
	}
	size_t readFill(void[] buf){
		auto s=file.rawRead(buf);
		return s.length;
	}
	
	@property{
		size_t skip(size_t size){
			import std.c.stdlib: alloca;
			auto tem=alloca(size);
			return readFill(tem[0..size]);
		}
		size_t avail(){
			if (seek>size_t.max){
				return size_t.max;
			}
			return cast(size_t) seek();
		}
		bool eof(){
			return file.eof;
		}
		
		void close(){
			file.close;
		}
		
		auto seek(){
			return file.size;
		}
	}
}
unittest {
	static assert(isDisposeRStream!FileRStream);
	
	debug(rstream_file){
		import std.stdio;
		auto fs=new RStreamWrap!FileRStream(FileRStream(stdin));
		ubyte buf[16];
		while(true){
			writeln(fs.readFill(buf));
			writeln(buf);
		}
	}
}
