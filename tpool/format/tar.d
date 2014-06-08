module tpool.format.tar;
import tpool.stream.rstream;

struct TarRRange(RStream) if(isRStream!RStream){
	RStream stream;
	
}
