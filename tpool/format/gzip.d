module tpool.format.gzip;
import tpool.stream.rstream;
import tpool.stream.wstream;

//http://www.gzip.org/zlib/rfc-gzip.html

import etc.c.zlib;
auto gzipRStream(RStream)(RStream stream,void[] buffer){
	return zlibRStream!(a=>inflateInit2(a,15|16))(stream,buffer);
}
unittest{
	ubyte[1] buf;
	auto a=gzipRStream(MemRStream(),buf);
}

auto gzipWStream(RStream)(RStream stream,void[] buf,int compress=-1){
	return zlibWStream!((a,b)=>deflateInit2(a,b,Z_DEFLATED,15|16,8,Z_DEFAULT_STRATEGY))(stream,buf,compress);
}

unittest{
	ubyte[256] buf;
	auto a=gzipWStream(MemWStream(),buf,9);
}
