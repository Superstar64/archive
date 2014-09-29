module tpool.range;
import std.range;
import tpool.stream.common:autoSave;
version(phobos_cache){//std.range recently got a cache function, eventully this code will go away
	public import std.algorithm : cache;
}else{
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
