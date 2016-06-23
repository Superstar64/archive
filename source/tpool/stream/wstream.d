module tpool.stream.wstream;

import std.typetuple;
import std.range;
public import tpool.stream.common;

public import tpool.stream.wstream_containers;
public import tpool.stream.wstream_implementations;

alias WStreamTur = TypeTuple!(WStream_, TypeWStream_, DisposeWStream_, StringWStream_);

//generally you want a function that does all the flushing and closing calling the function that does all the writing

//a writeable stream
interface WStream_ { //assigning or copying may make this stream invalid
	void writeFill(const(void[]) buf); //fully write buf to output
	template IS(S) {
		enum bool IS = isWStream!S;
	}
}

template isWStream(S) {
	enum bool isWStream = is(typeof((inout int = 0) {
		S s = void;
		const void[] buf = void;
		s.writeFill(buf);
	}));
}

unittest {
	struct emp {
		uint dummy;
	}

	static assert(!isWStream!emp);
	static assert(isWStream!WStream_);
}
//typed stream, you can write spesific types
interface TypeWStream_ : WStream_ {
	void write(ubyte b); //writes b to stream
	void write(ushort b); //ditto
	void write(uint b); //ditto
	void write(ulong b); //ditto
	void write(byte b); //ditto
	void write(short b); //ditto
	void write(int b); //ditto
	void write(long b); //ditto
	void write(float b); //ditto
	void write(double b); //ditto

	void writeAr(in ubyte[] b); //ditto
	void writeAr(in ushort[] b); //ditto
	void writeAr(in uint[] b); //ditto
	void writeAr(in ulong[] b); //ditto
	void writeAr(in byte[] b); //ditto
	void writeAr(in short[] b); //ditto
	void writeAr(in int[] b); //ditto
	void writeAr(in long[] b); //ditto
	void writeAr(in float[] b); //ditto
	void writeAr(in double[] b); //ditto
	template IS(S) {
		enum IS = isTypeWStream!S;
	}
}

template isTypeWStream(S) {
	enum bool isTypeWStream = isWStream!S && is(typeof((inout int = 0) {
		S s = void;
		s.write(cast(ubyte) 0);
		s.write(cast(ushort) 0);
		s.write(cast(uint) 0);
		s.write(cast(ulong) 0);
		s.write(cast(byte) 0);
		s.write(cast(short) 0);
		s.write(cast(int) 0);
		s.write(cast(long) 0);
		s.write(cast(float) 0);
		s.write(cast(double) 0);
		void[] a = void;
		s.writeAr(cast(const ubyte[]) a);
		s.writeAr(cast(const ushort[]) a);
		s.writeAr(cast(const uint[]) a);
		s.writeAr(cast(const ulong[]) a);
		s.writeAr(cast(const byte[]) a);
		s.writeAr(cast(const short[]) a);
		s.writeAr(cast(const int[]) a);
		s.writeAr(cast(const long[]) a);
		s.writeAr(cast(const float[]) a);
		s.writeAr(cast(const double[]) a);
	}));
}

unittest {
	static assert(isTypeWStream!TypeWStream_);
	static assert(!isTypeWStream!WStream_);
}
//a stream that can flush output and close
interface DisposeWStream_ : WStream_ {
	@property void flush(); //flush buf to the output, may do nothing
	@property void close(); //close the steam may do nothing
	//on assertion mode close may make all methods of the stream throw errors
	template IS(S) {
		enum bool IS = isDisposeWStream!S;
	}
}

template isDisposeWStream(S) {
	enum bool isDisposeWStream = isWStream!S && is(typeof((inout int = 0) {
		S s = void;
		s.flush;
		s.close;
	}));
}

unittest {
	static assert(!isDisposeWStream!WStream_);
	static assert(isDisposeWStream!DisposeWStream_);
}
//write string to a stream
interface StringWStream_ : WStream_ {
	void write(char c); //writes c to the steam
	void write(wchar c); //ditto
	void write(dchar c); //ditto
	void writeAr(in char[] c); //ditto
	void writeAr(in wchar[] c); //ditto
	void writeAr(in dchar[] c); //ditto
	template IS(S) {
		enum IS = isStringWStream!S;
	}
}

template isStringWStream(S) {
	enum bool isStringWStream = isWStream!S && is(typeof((inout int = 0) {
		S s = void;
		s.write(cast(char) 0);
		s.write(cast(wchar) 0);
		s.write(cast(dchar) 0);
		void[] a = void;
		s.writeAr(cast(const char[]) a);
		s.writeAr(cast(const wchar[]) a);
		s.writeAr(cast(const dchar[]) a);
	}));
}

unittest {
	static assert(isStringWStream!StringWStream_);
	static assert(!isStringWStream!WStream_);
}

//Wraps s in a class usefull for virtual pointers
class WStreamWrap(S, Par = Object) : Par, WStreamInterfaceOf!S {
	private S raw;
	alias raw this;
	this(S s) {
		raw = s;
	}

	override {
		void writeFill(const void[] buf) {
			raw.writeFill(buf);
		}

		static if (isTypeWStream!S) {
			void write(ubyte b) {
				raw.write(b);
			}

			void write(ushort b) {
				raw.write(b);
			}

			void write(uint b) {
				raw.write(b);
			}

			void write(ulong b) {
				raw.write(b);
			}

			void write(byte b) {
				raw.write(b);
			}

			void write(short b) {
				raw.write(b);
			}

			void write(int b) {
				raw.write(b);
			}

			void write(long b) {
				raw.write(b);
			}

			void write(float b) {
				raw.write(b);
			}

			void write(double b) {
				raw.write(b);
			}

			void writeAr(in ubyte[] b) {
				raw.writeAr(b);
			}

			void writeAr(in ushort[] b) {
				raw.writeAr(b);
			}

			void writeAr(in uint[] b) {
				raw.writeAr(b);
			}

			void writeAr(in ulong[] b) {
				raw.writeAr(b);
			}

			void writeAr(in byte[] b) {
				raw.writeAr(b);
			}

			void writeAr(in short[] b) {
				raw.writeAr(b);
			}

			void writeAr(in int[] b) {
				raw.writeAr(b);
			}

			void writeAr(in long[] b) {
				raw.writeAr(b);
			}

			void writeAr(in float[] b) {
				raw.writeAr(b);
			}

			void writeAr(in double[] b) {
				raw.writeAr(b);
			}
		}
		static if (isDisposeWStream!S) {
			@property {
				void flush() {
					raw.flush();
				}

				void close() {
					raw.close();
				}
			}
		}
		static if (isStringWStream!S) {
			void write(char b) {
				raw.write(b);
			}

			void write(wchar b) {
				raw.write(b);
			}

			void write(dchar b) {
				raw.write(b);
			}

			void writeAr(in char[] b) {
				raw.writeAr(b);
			}

			void writeAr(in wchar[] b) {
				raw.writeAr(b);
			}

			void writeAr(in dchar[] b) {
				raw.writeAr(b);
			}
		}
	}
}

unittest {
	auto str = new WStreamWrap!MemWStream(MemWStream());
	str.writeFill(cast(ubyte[])[1, 2, 3]);
	str.writeFill(cast(ubyte[]) "hello");
	assert(str.array == (cast(const ubyte[])[1, 2, 3] ~ cast(const ubyte[]) "hello"));
}

unittest {
	debug (wstream_file) {
		import std.stdio;

		auto sr = new WStreamWrap!FileWStream(FileWStream(stdout));
		sr.writeFill(cast(void[]) "hello world");
		sr.flush();
	}
}

auto wstreamWrap(Par = Object, S)(S s) {
	return new WStreamWrap!(S, Par)(s);
}

unittest {
	auto a = wstreamWrap(MemWStream());
}

template WStreamInterfaceOf(S) { //return interface of all streams that S supports
	template I(A) {
		enum I = A.IS!(S);
	}

	alias WStreamInterfaceOf = interFuse!(Filter!(I, WStreamTur));
}

template hasW(S, T) { //checks if the stream supports type T
	enum bool hasW = is(typeof((inout int = 0) {
		S s = void;
		T t = void;
		s.write(t);
		const T[] z = void;
		s.writeAr(z);
	}));
}

unittest {
	BigEndianWStream!MemWStream a = void;
	static assert(hasW!(typeof(a), ubyte));
	static assert(!hasW!(typeof(a), bool));
}

auto put(WStream)(ref WStream w, void[] buf) if (isWStream!WStream) {
	return w.writeFill(buf);
}

unittest {
	auto a = MemWStream();
	a.put(cast(ubyte[])[1, 2, 3]);
	assert(cast(ubyte[])(a.array) == [1, 2, 3]);
}

auto writeFill(Range)(ref Range r, void[] buf) if (isOutputRange!(Range, void[])) {
	return std.range.put(r, buf);
}

unittest {
	import std.array;

	void func(void[] wri) {
		return;
	}

	auto a = &func;
	auto data = cast(void[])(cast(ubyte[])[5, 2]);
	static assert(isOutputRange!(typeof(a), typeof(data)));
	a(data);
	writeFill(a, data);
	a.writeFill(data);
}

mixin template walias(alias stream) {
	auto writeFill(in void[] arg) {
		return stream.writeFill(arg);
	}
}

mixin template wclose(alias stream) {
	static if (isDisposeWStream!(typeof(stream))) {
		auto flush() {
			return stream.flush;
		}

		auto close() {
			return stream.close;
		}
	}
}
