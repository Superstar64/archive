module tpool.format.tar;
import tpool.stream.rstream;
import std.exception;
import std.c.string:strlen;
//only copy/slice if cpy is true
struct TarRRange(RStream,bool cpy=false) if(isRStream!RStream){
	struct TarElem{
		LimitRStream!RStream stream;
		char[] name;
		uint mode;
		uint ownID;
		uint groupID;
		uint lastModTime;//in unix time
		char link;
		char[] linkName;
		static if(isMarkableRStream!RStream){
			this(this){
				stream=stream.save;
			}
		}
	}
	
	RStream stream;
	TarElem front;
	bool empty;
	ubyte[] buf;
	uint remain;
	mixin autoSave!(stream,front,empty,buf,remain);
	this(RStream s,ubyte[] buffer){
		stream=s;
		assert(buffer.length==512,"buffer for tar must be size 512");
		buf=buffer;
		getNext();
	}
	this(RStream stream_,bool empty_,ubyte[512] buf_,uint remain_){//raw constructor plese ignore
		stream=stream_;
		empty=empty_;
		buf=buf_;
		remain=remain_;
	}
	
	
	void popFront(){
		front.stream.skip(uint.max);
		stream=front.stream.stream;
		stream.skip(remain);
		getNext();
	}
	
	private void getNext(){
		if(stream.readFill(buf)!=buf.length){
			empty=true;
			return;
		}
		foreach(i;buf){
			if(i!=0){
				goto parse;
			}
		}
		enforce(stream.readFill(buf)==buf.length);
		foreach(i;buf){
			enforce(i==0);
		}
		empty=true;
		return;
		
		parse:
		auto buf2=cast(char[]) buf[];
		{
			front.name=buf2[0..100];
			enforce(front.name[$-1]=='\0');
			front.name=front.name[0..strlen(front.name.ptr)];		
			buf2=buf2[100..$];
		}
		{
			auto mode=buf2[0..8];
			enforce(mode[$-1]=='\0');
			front.mode=parseOctal(mode[0..$-1]);
			
			buf2=buf2[8..$];
		}
		{
			auto ownID=buf2[0..8];
			enforce(ownID[$-1]=='\0');
			front.ownID=parseOctal(ownID[0..$-1]);
			
			buf2=buf2[8..$];
		}
		{
			auto groupID=buf2[0..8];
			enforce(groupID[$-1]=='\0');
			front.groupID=parseOctal(groupID[0..$-1]);
			
			buf2=buf2[8..$];
		}
		uint len;
		{
			auto length=buf2[0..12];
			enforce(length[$-1]=='\0');
			len=parseOctal(length[0..$-1]);
		}
		{
			auto lastModTime=buf2[0..12];
			enforce(lastModTime[$-1]=='\0');
			front.lastModTime=parseOctal(lastModTime[0..$-1]);
			
			buf2=buf2[12..$];
		}
		
		{
			buf2=buf2[8..$];
		}
		{
			front.link=buf2[0];
			buf2=buf2[1..$];
		}
		
		{
			front.linkName=buf2[0..100];
			enforce(front.linkName[$-1]=='\0');
			front.linkName=front.linkName[0..strlen(front.linkName.ptr)];
			buf2=buf2[100..$];
		}
		
		front.stream=limitRStream(stream,len);
		remain=512-len%512;
		if(remain==512){
			remain=0;
		}
	}
}
auto tarRRange(S)(S stream,ubyte[] buffer){
	return TarRRange!S(stream,buffer);
}

version (tar_test){
	void main(string args[]){
		import std.stdio;import tpool.format.gzip;
		File f=args[1];
		ubyte[256] gzipbuf;
		ubyte[512] buf;
		foreach(i;tarRRange(gzipRStream(fileRStream(f),gzipbuf),buf)){
			writeln(i.name);
		}
	}
}
T parseOctal(T=uint,S)(S string){
	T ret;
	foreach(i;string){
		ret=ret*8 + i-'0';
	}
	return ret;
}
unittest{
	assert(parseOctal("64")==52);
	assert(parseOctal("10")==8);
}
