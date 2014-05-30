module tpool.range;
import std.range;
import tpool.stream.common:autoSave;
struct Cache(R,F) if(isInputRange!R){
	this(R range_){
		range=range_;
		front=range.front;
	}
	R range;
	F front;
	@property void popFront(){
		range.popFront();
		front=range.front;
	}
	alias range this;
	mixin autoSave!(range);
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
struct OnPop(Range,alias fun) if(isInputRange!Range){
	Range r;
	alias r this;
	mixin autoSave!r;
	@property auto popFront(){
		static if(is(typeof((inout int=0){
			fun(r.front);
		}))){
			fun(r.front);
		}else{
			fun();
		}
		r.popFront;
	}
}
template onPop(alias fun){
	auto onPop(Range)(Range r){
		return OnPop!(Range,fun)(r);
	}
}
unittest {
	ubyte[]a =[0,1];
	bool test=false;
	auto range=onPop!(a=>test=true)(a);
	range.popFront;
	assert(test);
}
