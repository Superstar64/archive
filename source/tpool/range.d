module tpool.range;
import std.range;
import tpool.stream.common:autoSave;
public import std.algorithm : cache;
	
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

auto until(alias fun,alias emp)(){
	alias type=typeof(fun());
	struct InnerUntil{
		private type f;
		auto front(){
			return f;
		}
		@property auto popFront(){
			f=fun();
		}
		
		@property auto empty(){
			return emp(f);
		}
	}
	return InnerUntil(fun());
}
unittest{
	uint cur;
	auto inc(){
		return cur++;
	}
	auto range=until!(inc,a=>a==5);
	static assert(isInputRange!(typeof(range)));
}
