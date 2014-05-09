import std.range;

struct Cache(R,F) if(isInputRange!R){
	this(R range_){
		range=range_;
		front=range.front;
	}
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
	assert(range.front==1);
	range.front=2;
	assert(ar==[1,2,3]);
	range.popFront();
	assert(range.front==2);
	
	ar.front=2;
	assert(ar==[2,2,3]);
}
