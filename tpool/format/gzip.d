module tpool.format.gzip;
import tpool.stream.rstream;
import tpool.stream.wstream;

//http://www.gzip.org/zlib/rfc-gzip.html

import etc.c.zlib;
auto gzipRStream(bool QuitOnStreamEnd=false,RStream)(RStream stream,void[] buffer){
	return zlibRStream!(QuitOnStreamEnd,a=>inflateInit2(a,15|16))(stream,buffer);
}

auto gzipWStream(RStream)(RStream stream,void[] buf,int compress=-1){
	return zlibWStream!((a,b)=>deflateInit2(a,b,Z_DEFLATED,15|16,8,Z_DEFAULT_STRATEGY))(stream,buf,compress);
}
