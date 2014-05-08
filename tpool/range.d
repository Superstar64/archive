import std.range;

struct Cache(R,F) if(isInputRange!R){
	R range;
	F front;
	void popFront(){
		range.popFront();
		front=range.front;
	}
	alias range this;
}
auto cache(R)(R range){
	return Cache!(R,ElementType!(R))(range);
}

unittest{
	ubyte[] ar=[1,2,3];
	auto range=cache(ar);
	range.front=2;
	assert(ar==[1,2,3]);
	ar.front=2;
	assert(ar==[2,2,3]);
}
