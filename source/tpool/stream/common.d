module tpool.stream.common;
import std.typetuple;
template interFuse(T...){//fuse interfaces
	interface interFuse:T{}
}

alias DataTypes=TypeTuple!(ubyte,ushort,uint,ulong,byte,short,int,long,float,double);
template isDataType(T){//allSatisfy didn't compile for some reason,
	enum bool isDataType= is(T==ubyte)||
		is(T==ushort)||
		is(T==uint)||
		is(T==ulong)||
		is(T==byte)||
		is(T==short)||
		is(T==int)||
		is(T==long)||
		is(T==float)||
		is(T==double);
}

alias StringTypes=TypeTuple!(char,wchar,dchar);

template isStringType(T){
	enum bool isStringType=is(T==char)||
	is(T==wchar)||
	is(T==dchar);
}

mixin template autoSave(alias sub,Args...){//provides a default save, calling the constructer with the args provided, STREAM TYPE SHOULD BE THE FIRST IN THE CONSTRUCTER AND THE FIRST TYPE IN THIS LIST
	import std.traits;
	static if(is(typeof((inout int=0){
			typeof(sub) a=sub.save;
	}))){			
		@property auto save(){
			return typeof(this)(sub.save,Args);
		}
	}
}
