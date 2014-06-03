module tpool.stream.rstream_implementations;
import tpool.stream.rstream;
struct MemRStream{
	import std.c.string;
	const(void)[] arr;
	size_t readFill(void[] buf) out(_outLength) {assert(_outLength<=buf.length ); } body{
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
	
	size_t skip(size_t len) out(_outLength) {assert(_outLength<=len ); } body{
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
	
	
	@property typeof(this) save(){return typeof(this)(arr);}
	
	@property ulong seek(){
		return arr.length;
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
	assert(temp==[1,5]);
	assert(4==s.skip(4));
	assert(1==s.readFill(temp));
	assert(temp[0]==200);
	assert(s.eof);
}
alias memRStream=MemRStream;

struct FileRStream(bool seekable=true){
	import std.stdio;
	File file;
	size_t readFill(void[] buf) out(_outLength) {assert(_outLength<=buf.length ); } body{
		if(buf.length==0){
			return 0;
		}
		auto s=file.rawRead(buf);
		return s.length;
	}
	
	@property{
		static if(seekable){
			size_t skip(size_t size){
				auto sz=file.size;
				auto cr=file.tell;
				if(cr+size>sz){
					file.seek(sz);
					return cast(size_t)(size-cr);
				}else{
					file.seek(size,SEEK_CUR);
					return size;
				}
			}
			bool eof(){
				return seek==0;
			}
		}else{
			mixin readSkip;
		}
		void close(){
			file.close;
		}
		
		static if(seekable){
			auto seek(){
				return file.size-file.tell;
			}
		}
	}
}
unittest{
	static assert(isDisposeRStream!(FileRStream!true));
}
debug(rstream_file){
	void main(){
		import std.stdio;
		auto fs=new RStreamWrap!(FileRStream!false)(FileRStream!false(stdin));
		ubyte buf[16];
		while(true){
			writeln(fs.readFill(buf));
			writeln(buf);
			fs.skip(16);
		}
	}
}
import std.stdio;
auto fileRStream(bool seekable=true)(File f){
	return FileRStream!(seekable)(f);
}
unittest{
	auto f=fileRStream(stdin);
}
