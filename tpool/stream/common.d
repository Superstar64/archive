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
