module tpool.stream.rstream_containers;
import tpool.stream.rstream;
import tpool.stream.common;
import std.exception : enforce;
import std.algorithm;
import std.range;

///
class EofBadFormat : Exception {
	this() {
		this("Found eof when expecting Number");
	}

	this(string s) {
		super(s);
	}
}

struct BigEndianRStream(S, bool check = true) if (isRStream!S) { //if check is true then it check if readFill a aligned amount of data
	S stream;
	mixin ralias!stream;
	mixin autoSave!stream;
	mixin rclose!stream;
	mixin rseek!stream;
	mixin reof!stream;

	@property T read(T)() if (isDataType!T) {
		ubyte[T.sizeof] buf;
		auto sz = stream.readFill(buf);
		static if (check) {
			if (sz != T.sizeof) {
				throw new EofBadFormat();
			}
		}
		static if (T.sizeof != 1) {
			version (LittleEndian) {
				buf.reverse;
			}
		}
		return *(cast(T*) buf.ptr);
	}

	size_t readAr(T)(T[] buf) if (isDataType!T) {
		auto sz = stream.readFill(buf);
		static if (T.sizeof != 1) {
			static if (check) {
				if (sz % T.sizeof != 0) {
					throw new EofBadFormat();
				}
			}
			version (LittleEndian) {
				auto temp = cast(ubyte[]) buf; //templates errors are scary
				uint count;
				for (uint i = 0; i < temp.length; i += T.sizeof) {
					temp[i .. i + T.sizeof].reverse;
				}
			}
		}
		return sz / T.sizeof;
	}
}

unittest {
	ubyte[12] buf = [0, 0, 1, 0, 1, 5, 0, 1, 2, 0, 1, 3];
	auto stream = bigEndianRStream(MemRStream(buf));
	static assert(isTypeRStream!(typeof(stream)));
	assert(stream.read!int == 256);
	assert(stream.read!ushort == 261);
	ushort[3] buf2;
	assert(stream.readAr(buf2) == 3);
	assert(buf2 == [1, 512, 259]);
}

///a typed rstream wrapper around a sub rstream
auto bigEndianRStream(bool check = true, S)(S s) {
	return BigEndianRStream!(S, check)(s);
}

struct LittleEndianRStream(S, bool check = true) if (isRStream!S) { //if check is true then it check if readFill a aligned amount of data
	S stream;
	mixin ralias!stream;
	mixin autoSave!stream;
	mixin rclose!stream;
	mixin rseek!stream;
	mixin reof!stream;

	@property T read(T)() if (isDataType!T) {
		ubyte[T.sizeof] buf;
		auto sz = stream.readFill(buf);
		static if (check) {
			if (sz != T.sizeof) {
				throw new EofBadFormat();
			}
		}
		static if (T.sizeof != 1) {
			version (BigEndian) {
				buf.reverse;
			}
		}
		return *(cast(T*) buf.ptr);
	}

	size_t readAr(T)(T[] buf) if (isDataType!T) {
		auto sz = stream.readFill(buf);
		static if (T.sizeof != 1) {
			static if (check) {
				if (sz % T.sizeof != 0) {
					throw new EofBadFormat();
				}
			}
			version (BigEndian) {
				auto temp = cast(ubyte[]) buf; //templates errors are scary
				uint count;
				for (uint i = 0; i < temp.length; i += T.sizeof) {
					temp[i .. i + T.sizeof].reverse;
				}
			}
		}
		return sz / T.sizeof;
	}

}

unittest {
	ubyte[12] buf = [0, 1, 0, 0, 5, 1, 1, 0, 0, 2, 3, 1];
	auto stream = littleEndianRStream(MemRStream(buf));
	static assert(isTypeRStream!(typeof(stream)));
	assert(stream.read!int == 256);
	assert(stream.read!ushort == 261);
	ushort[3] buf2;
	assert(stream.readAr(buf2) == 3);
	assert(buf2 == [1, 512, 259]);
}

///a typed rstream wrapper around a sub rstream
auto littleEndianRStream(bool check = true, S)(S s) {
	return LittleEndianRStream!(S, check)(s);
}

class EofBeforeLength : Exception {
	this(ulong read) {
		import std.conv;

		super("Eof reached before limit " ~ to!string(read) ~ " bytes expected");
	}
}

struct LimitRStream(S, bool excepOnEof = true) if (isRStream!S) {
	S stream;
	ulong limit;
	mixin autoSave!(stream, limit);
	mixin rclose!stream;
	mixin reof!stream;

	size_t readFill(void[] buf)
	out(_outLength) {
		assert(_outLength <= buf.length);
	}
	body {
		if (buf.length > limit) {
			auto len = stream.readFill(buf[0 .. cast(size_t) limit]);
			static if (excepOnEof) {
				if (len != limit) {
					throw new EofBeforeLength(cast(size_t) limit);
				}
			}
			limit = 0;
			return len;
		} else {
			auto len = stream.readFill(buf);
			static if (excepOnEof) {
				if (len != buf.length) {
					throw new EofBeforeLength(len);
				}
			}
			limit -= len;
			return len;
		}
	}

	size_t skip(size_t amount)
	out(_outLength) {
		assert(_outLength <= amount);
	}
	body {
		if (amount > limit) {
			auto len = stream.skip(cast(size_t) limit);
			static if (excepOnEof) {
				if (len != limit) {
					throw new EofBeforeLength(cast(size_t) limit);
				}
			}
			limit = 0;
			return len;
		} else {
			auto len = stream.skip(amount);
			static if (excepOnEof) {
				if (len != amount) {
					throw new EofBeforeLength(amount);
				}
			}
			limit -= len;
			return len;
		}
	}

	@property {
		static if (excepOnEof) {
			auto seek() {
				return limit;
			}
		} else static if (isSeekableRStream!(S)) {
			auto seek() {
				import std.math;

				return min(limit, stream.seek);
			};
		}
	}

}

unittest { //readFill test
	ubyte[12] buf = [0, 1, 0, 0, 5, 1, 1, 0, 0, 2, 3, 1];
	auto stream = limitRStream(MemRStream(buf), 4);
	static assert(isRStream!(typeof(stream)));
	static assert(isSeekableRStream!(typeof(stream)));
	static assert(isMarkableRStream!(typeof(stream)));
	assert(stream.seek == 4);
	ubyte[3] temp;
	auto len = stream.readFill(temp);
	assert(len == 3);
	len = stream.readFill(temp);
	assert(len == 1);
}

unittest { //skip test
	ubyte[12] buf = [0, 1, 0, 0, 5, 1, 1, 0, 0, 2, 3, 1];
	auto stream = LimitRStream!MemRStream(MemRStream(buf), 4);
	static assert(isRStream!(typeof(stream)));
	static assert(isSeekableRStream!(typeof(stream)));
	static assert(isMarkableRStream!(typeof(stream)));
	assert(stream.seek == 4);
	assert(stream.skip(3) == 3);
	assert(stream.skip(5) == 1);
}

///limiting stream, return eof when limit bytes are read//if excepOnEof is true, it throws if eof is reached before limit
auto limitRStream(bool excepOnEof = true, S)(S s, ulong limit) {
	return LimitRStream!(S, excepOnEof)(s, limit);
}

struct NonLazyRangeRStream(S, BufType = ubyte) if (isRStream!S) {
	S stream;
	BufType[] _buf;
	bool _eof;
	static assert(BufType.sizeof == 1);
	this(S s, BufType[] buf_) {
		stream = s;
		_buf = buf_;
		popFront();
	}

	@property {
		auto front() {
			return cast(const(BufType)[]) _buf;
		}

		void popFront() {
			auto len = stream.readFill(_buf);
			if (len != _buf.length) {
				_buf = _buf[0 .. len];
			}
			if (len == 0) {
				_eof = true;
			}
		}

		bool empty() {
			return _eof;
		}
	}
}

struct LazyRangeRStream(S, BufType = ubyte) if (isMarkableRStream!S) {
	S stream;
	BufType[] _buf;
	bool _eof;
	mixin autoSave!(stream, _buf, _eof);

	static assert(BufType.sizeof == 1);
	this(S s, BufType[] buf_) {
		stream = s;
		_buf = buf_;
	}

	this(S s, BufType[] buf_, bool eof) {
		stream = s;
		_buf = buf_;
		_eof = eof;
	}

	@property {
		auto front() {
			auto str = stream.save;
			auto len = str.readFill(_buf);
			return _buf[0 .. len];
		}

		void popFront() {
			_eof = stream.skip(_buf.length) != _buf.length;
		}

		bool empty() {
			return _eof;
		}
	}
}

template RangeRStream(S, BufType = ubyte) if (isRStream!S) {
	static if (isMarkableRStream!S) {
		alias RangeRStream = LazyRangeRStream!(S, BufType);
	} else {
		alias RangeRStream = NonLazyRangeRStream!(S, BufType);
	}
}

unittest {
	ubyte[11] array = [0, 0, 1, 0, 1, 5, 0, 1, 2, 0, 1];
	ubyte[4] buf = void;
	auto chunker = rangeRStream(MemRStream(array), buf);
	static assert(isInputRange!(typeof(chunker)));
	assert(!chunker.empty);
	assert(chunker.front == [0, 0, 1, 0]);
	chunker.popFront;
	assert(chunker.front == [1, 5, 0, 1]);
	chunker.popFront;
	assert(!chunker.empty);
	assert(chunker.front == [2, 0, 1]);
	chunker.popFront;
	assert(chunker.empty);
}

///streams chunks as a range, tries to be lazy (when saveable) if possible
auto rangeRStream(Btype = ubyte, S)(S stream, Btype[] buf) {
	return RangeRStream!(S, Btype)(stream, buf);
}

unittest {
	ubyte[1] buf;
	auto a = rangeRStream(MemRStream(), buf);
}

deprecated struct AllRStream(S) if (isRStream!S) { //a stream that throws a exception when a buffer is not fully filled
	S stream;
	mixin autoSave!stream;

	size_t readFill(void[] buf)
	out(_outLength) {
		assert(_outLength <= buf.length);
	}
	body {
		enforce(stream.readFill(buf) == buf.length);
		return buf.length;
	}

	size_t skip(size_t si)
	out(_outLength) {
		assert(_outLength <= si);
	}
	body {
		enforce(stream.skip(si) == si);
		return si;
	}
}

deprecated auto allRStream(S)(S s) {
	return AllRStream!S(s);
}

struct RawRStream(S, T, bool check = true) if (isRStream!S) {
	S stream;
	mixin ralias!stream;
	mixin autoSave!stream;
	mixin rclose!stream;
	mixin rseek!stream;
	mixin reof!stream;

	@property T read(T)() {
		ubyte[T.sizeof] buf;
		auto len = stream.readFill(buf);
		static if (check) {
			enforce(len == T.sizeof);
		}
		return *(cast(T*)(buf.ptr));
	}

	size_t readAr(T[] t) {
		auto a = stream.readFill(cast(void[]) t);
		static if (check) {
			if (a % T.sizeof != 0) {
				throw new EofBadFormat("Eof when expecting " ~ T.stringof);
			}
		}
		return a / T.sizeof;
	}
}

unittest {
	char[] a = ['a', 'b', 'c'];
	auto s = rawRStream!char(MemRStream(a));
	assert(s.read!char == 'a');
	char[2] b2;
	s.readAr(b2);
	assert(b2 == "bc");
}
///reads typed data exactly from memory
auto rawRStream(Type, bool check = true, S)(S stream) {
	return RawRStream!(S, Type, check)(stream);
}

import etc.c.zlib;

struct ZlibIRangeRStream(R) if (isInputRange!R) {
	R range;
	z_stream zstream;
	bool empt;
	mixin readSkip;
	mixin autoSave!(range, zstream);

	@property bool eof() {
		return empt;
	}

	static typeof(this) ctor(alias init = inflateInit)(R range_) {
		typeof(this) t;
		with (t) {
			range = range_;
			assert(range.front.ptr == range.front.ptr); //sanity test
			assert(range.front.length == range.front.length);
			zstream.next_in = cast(typeof(zstream.next_in)) range.front.ptr;
			zstream.avail_in = cast(typeof(zstream.avail_in)) range.front.length;
			init(&zstream);
		}
		return t;
	}

	this(R range_, z_stream z) { //raw constructer plese ignore
		range = range_;
		enforce(inflateCopy(&zstream, &z) == Z_OK);
		zstream.next_in = cast(typeof(zstream.next_in)) range.front.ptr;
		zstream.avail_in = cast(typeof(zstream.avail_in)) range.front.length;
	}

	private auto refill() {
		range.popFront();
		if (range.empty) {
			return true;
		}
		assert(range.front.ptr);
		assert(range.front.length != 0);
		zstream.next_in = cast(typeof(zstream.next_in)) range.front.ptr;
		zstream.avail_in = cast(typeof(zstream.avail_in)) range.front.length;
		return false;
	}

	size_t readFill(void[] buf)
	out(_outLength) {
		assert(_outLength <= buf.length);
	}
	body {
		if (empt || buf.length == 0) {
			return 0;
		}
		zstream.next_out = cast(typeof(zstream.next_out)) buf.ptr;
		zstream.avail_out = cast(typeof(zstream.avail_out)) buf.length;
	start:
		auto ret = inflate(&zstream, Z_SYNC_FLUSH);
		if (ret == Z_STREAM_END) {
			return buf.length - zstream.avail_out;
		}
		enforce(ret == Z_OK);
		if (zstream.avail_in == 0) {
			if (zstream.avail_out == 0) {
				empt = refill;
				return buf.length;
			}
			if (refill()) {
				empt = true;
				return buf.length - zstream.avail_out;
			}
			goto start;
		} else {
			assert(zstream.avail_out == 0);
			return buf.length;
		}
	}

	@property void close() {
		inflateEnd(&zstream);
	}
}
///generates a rstream that reads compressed data from a Inputrange of void[]
auto zlibIRangeRStream(alias init = inflateInit, R)(R range) {
	return ZlibIRangeRStream!(R).ctor!init(range);
}

struct ZlibRStream(S) if (isRStream!S) { //buffers, reads more than needed
	ZlibIRangeRStream!(RangeRStream!(S, void)) stream;
	alias stream this;
	mixin autoSave!(stream);
	mixin reof!stream;

	void close(bool sub = true) {
		stream.close;
		static if (isDisposeRStream!S) {
			if (sub) {
				stream.close;
			}
		}
	}
}
///a rstream that reads compressed data from a sub rstream
auto zlibRStream(alias init = inflateInit, S)(S s, void[] buf) {
	auto str = ZlibRStream!(S)();
	str.stream = zlibIRangeRStream!(init)(rangeRStream(s, buf));
	return str;
}

unittest {
	ubyte[1] buf;
	auto a = zlibRStream(MemRStream(), buf);
}

unittest {
	import std.zlib;
	import std.stdio;

	ubyte[2 ^^ 8] buf; //input buf
	auto input = compress("hello world"); //data
	ubyte[10] buf2; //output buf
	auto zs = zlibRStream(MemRStream(input), buf);

	scope (exit)
		zs.close;

	static assert(isRStream!(typeof(zs)));
	static assert(isDisposeRStream!(typeof(zs)));
	static assert(isMarkableRStream!(typeof(zs)));
	auto aaa = zs.save;

	scope (exit)
		aaa.close;

	assert(5 == zs.readFill(buf2[0 .. 5]));
	assert(buf2[0 .. 5] == "hello");
	assert(5 == aaa.readFill(buf2[0 .. 5]));
	assert(buf2[0 .. 5] == "hello");
	assert(6 == zs.readFill(buf2[0 .. 6]));
	assert(buf2[0 .. 6] == " world");
}

unittest {
	import std.zlib;
	import std.stdio;

	ubyte[2 ^^ 8] buf; //input buf
	auto input = compress("hello world"); //data
	input ~= cast(ubyte[])[4, 1]; //test for ZlibRStream!true
	ubyte[10] buf2; //output buf
	auto zs = zlibRStream(MemRStream(input), buf);

	scope (exit)
		zs.close;

	static assert(isDisposeRStream!(typeof(zs)));
	static assert(isMarkableRStream!(typeof(zs)));
	auto aaa = zs.save;

	scope (exit)
		aaa.close;

	assert(5 == zs.readFill(buf2[0 .. 5]));
	assert(buf2[0 .. 5] == "hello");
	assert(5 == aaa.readFill(buf2[0 .. 5]));
	assert(buf2[0 .. 5] == "hello");
	assert(6 == zs.readFill(buf2[0 .. 6]));
	assert(buf2[0 .. 6] == " world");
}

struct Crc32RStream(S) if (isRStream!S) {
	import etc.c.zlib;

	S stream;
	uint crc;
	mixin readSkip;
	mixin autoSave!(stream, crc);
	mixin rclose!stream;
	mixin rseek!stream;
	mixin reof!stream;

	@property auto readFill(void[] arr)
	out(_outLength) {
		assert(_outLength <= arr.length);
	}
	body {
		import std.zlib;

		auto len = stream.readFill(arr);
		assert(len <= arr.length);
		crc = crc32(crc, arr[0 .. len]);
		return len;
	}
}

unittest {
	import std.zlib;

	enum ubyte[] source = [3, 4, 5, 9, 0];
	auto str = crc32RStream(MemRStream(source));
	static assert(isRStream!(typeof(str)));
	auto res = crc32(0, source);
	str.skip(1000);
	assert(str.crc == res);
}

///generates crc32 around data read
auto crc32RStream(S)(S s) {
	return Crc32RStream!(S)(s);
}

struct Adler32RStream(S) if (isRStream!S) {
	import etc.c.zlib;

	S stream;
	uint adler;
	mixin readSkip;
	mixin autoSave!(stream, adler);
	mixin rclose!stream;
	mixin rseek!stream;
	mixin reof!stream;

	@property auto readFill(void[] arr)
	out(_outLength) {
		assert(_outLength <= arr.length);
	}
	body {
		import std.zlib;

		auto len = stream.readFill(arr);
		assert(len <= arr.length);
		adler = adler32(adler, arr[0 .. len]);
		return len;
	}
}

unittest {
	import std.zlib;

	enum ubyte[] source = [3, 4, 5, 9, 0];
	auto str = adler32RStream(MemRStream(source));
	static assert(isRStream!(typeof(str)));
	auto res = adler32(0, source);
	str.skip(1000);
	assert(str.adler == res);
}
///generates crc32 around data read
auto adler32RStream(S)(S s) {
	return Adler32RStream!(S)(s);
}

struct LRStream(S1, S2) if (isRStream!S1 && isRStream!S2) {
	S1 stream1;
	S2 stream2;
	bool remain = true;

	size_t readFill(void[] buf)
	out(_outLength) {
		assert(_outLength <= buf.length);
	}
	body {
		if (remain) {
			auto read = stream1.readFill(buf);
			assert(read <= buf.length);
			if (read != buf.length) {
				remain = false;
				return read + readFill(buf[read .. $]);
			} else {
				return buf.length;
			}
		} else {
			return stream2.readFill(buf);
		}
	}

	size_t skip(size_t size)
	out(_outLength) {
		assert(_outLength <= size);
	}
	body {
		if (remain) {
			auto read = stream1.skip(size);
			assert(read <= size);
			if (read != size) {
				remain = false;
				return read + skip(size - read);
			} else {
				return size;
			}
		} else {
			return stream2.skip(size);
		}
	}

	static if (isMarkableRStream!S1 && isMarkableRStream!S2) {
		@property auto save() {
			return typeof(this)(stream1.save, stream2.save, remain);
		}
	}
	static if (isSeekableRStream!S1 && isSeekableRStream!S2) {
		@property auto seek() {
			return stream1.seek + stream2.seek;
		}
	}
	static if (isDisposeRStream!S1 || isDisposeRStream!S2) {
		@property void close() {
			static if (isDisposeRStream!S1) {
				stream1.close;
			}
			static if (isDisposeRStream!S2) {
				stream2.close;
			}
		}
	}
	static if (isEofRStream!S1 && isEofRStream!S2) {
		@property bool eof() {
			return stream1.eof && stream2.eof;
		}
	}

}

unittest {
	ubyte[] i = [1, 2, 3];
	auto str = lrStream(MemRStream(i), MemRStream(i));
	static assert(isMarkableRStream!(typeof(str)));
	ubyte[6] o;
	assert(str.readFill(o[0 .. 1]) == 1);
	assert(o[0] == 1);
	auto str2 = str.save;
	assert(str2.readFill(o[0 .. 4]) == 4);
	assert(o[0 .. 4] == [2, 3, 1, 2]);

	assert(str.readFill(o[0 .. 4]) == 4);
	assert(o[0 .. 4] == [2, 3, 1, 2]);

	assert(str.readFill(o[0 .. 1]) == 1);

	assert(o[0] == 3);
}

unittest {
	ubyte[] i = [1, 2, 3];
	auto str = lrStream(MemRStream(i), MemRStream(i));
	static assert(isMarkableRStream!(typeof(str)));
	ubyte[6] o;
	assert(str.skip(1) == 1);

	auto str2 = str.save;
	assert(str2.skip(4) == 4);

	assert(str.skip(4) == 4);

	assert(str.skip(1) == 1);
}

/** a stream that reads from the first until it's empty then reads from the second
	you can chain these together eg: LRStream!(MemRStream,LRStream(MemRStream,MemRStream))
*/
auto lrStream(S1, S2)(S1 s1, S2 s2) {
	return LRStream!(S1, S2)(s1, s2);
}

struct JoinRStream(R, bool allowsave = false) if (isInputRange!R && isRStream!(ElementType!R)) {
	R range;
	bool eof_;

	size_t readFill(void[] buf)
	out(_outLength) {
		assert(_outLength <= buf.length);
	}
	body {
		if (eof_) {
			return 0;
		}
		auto sz = range.front.readFill(buf);
		if (sz == buf.length) {
			return sz;
		}
		range.popFront();
		if (range.empty) {
			eof_ = true;
			return sz;
		} else {
			return sz + readFill(buf[sz .. $]);
		}
	}

	size_t skip(size_t length)
	out(_outLength) {
		assert(_outLength <= length);
	}
	body {
		if (eof_) {
			return 0;
		}
		auto sz = range.front.skip(length);
		if (sz == length) {
			return sz;
		}
		range.popFront();
		if (range.empty) {
			eof_ = true;
			return sz;
		} else {
			return sz + skip(length - sz);
		}
	}

	static if (isForwardRange!(R) && isSeekableRStream!(ElementType!(R))) {
		@property ulong seek() {
			auto iter = range.save;
			ulong sum;
			foreach (strem; iter) {
				sum += strem.seek;
			}
			return sum;
		}
	}
	static if (isForwardRange!R && isSeekableRStream!(ElementType!R)) {
		@property bool eof() {
			auto iter = range.save;
			bool eof;
			foreach (strem; iter) {
				if (strem.eof) {
					return true;
				}
			}
			return false;
		}
	}

	static if (isDisposeRStream!(ElementType!(R))) {
		@property void close() {
			while (!r.empty) {
				r.front.close;
				r.popFront;
			}
		}
	}
	static if (allowsave && isForwardRange!R) {
		mixin autoSave!(range, eof_);
	}
}

unittest {
	ubyte[5] data = [1, 2, 3, 4, 5];
	auto range = [MemRStream(data), MemRStream(data), MemRStream(data)];
	auto stream = joinRStream(range);
	static assert(isRStream!(typeof(stream)));

	assert(stream.seek == 15);

	ubyte[6] buf;
	assert(stream.readFill(buf) == 6);
	assert(buf == [1, 2, 3, 4, 5, 1]);

	assert(stream.readFill(buf[0 .. 1]) == 1);
	assert(buf[0 .. 1] == [2]);
	assert(stream.skipRest == 8);
}
///joins a range of rstreams into a single rstream
auto joinRStream(R)(R r) {
	return JoinRStream!(R, false)(r);
}

unittest {
	auto a = joinRStream([MemRStream()]);
}

///saveable join stream, MAKE SURE R.save CALLS R.front.save
///maybe use sjoinRStream(cache(map!(a=>a.save)(your_range_varible_here)))
auto sjoinRStream(R)(R r) {

	return JoinRStream!(R, true)(r);
}

unittest {
	import tpool.range;

	auto a = sjoinRStream([MemRStream()].map!(a => a.save).cache);
}
