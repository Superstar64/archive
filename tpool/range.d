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
	@property{
		void popFront(){
			range.popFront();
			front=range.front;
		}
		auto empty(){
			return range.empty;
		}
	}
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
	@property auto front(){
		return r.front;
	}
	@property auto empty(){
		return r.empty;
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
	static assert(isForwardRange!(typeof(range)));
	auto r2=range.save;
	range.popFront;
	assert(test);
}

struct CRange(alias gfront,alias gempty){//create range
	@property 
	{
		auto front(){
			return gfront();
		}
		void popFront(){
		}
		bool empty(){
			return gempty();
		}
	}
}
auto cRange(alias gfront,alias gempty)(){
	return CRange!(gfront,gempty)();
}
unittest{
	uint cur;
	auto range=cRange!(()=>{cur++;return cur;}(),()=>cur==5);
	static assert(isInputRange!(typeof(range)));
	assert(range.front==1);
	assert(!range.empty);
	assert(range.front==2);
	assert(!range.empty);
	assert(range.front==3);
	assert(!range.empty);
	assert(range.front==4);
	assert(!range.empty);
	assert(range.front==5);
	assert(range.empty);
}

struct OEmpty(Range,alias gempty) if(isInputRange!Range){//override empty
	Range r;
	mixin autoSave!(r);
	@property bool empty(){
		static if(is(typeof((inout int=0){
			return gempty(r);
		}))){
			return gempty(r);
		}else{
			return gempty();
		}
	}
	@property{
		auto popFront(){
			return r.popFront;
		}
		
		auto front(){
			return r.front;
		}
	}
}
template oEmpty(alias fun){
	auto oEmpty(Range)(Range r){
		return OEmpty!(Range,fun)(r);
	}
}
unittest {
	import std.stdio;
	ubyte[] mem=[0,1,2,3];
	auto range=oEmpty!(a=>a.front==2)(mem);
	static assert(isForwardRange!(typeof(range)));
	assert(range.array==[0,1]);
}
