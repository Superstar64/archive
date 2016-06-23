module tpool.stream.rstream_implementations;
import tpool.stream.rstream;

struct MemRStream { //a rstream that reads from memory
	import std.c.string;

	const(void)[] arr;

	size_t readFill(void[] buf)
	out(_outLength) {
		assert(_outLength <= buf.length);
	}
	body {
		if (buf.length >= arr.length) {
			memcpy(buf.ptr, arr.ptr, arr.length);
			auto len = arr.length;
			arr = arr[0 .. 0]; //i've invented a new emoticon
			return len;
		} else {
			memcpy(buf.ptr, arr.ptr, buf.length);
			arr = arr[buf.length .. $];
			return buf.length;
		}
	}

	size_t skip(size_t len)
	out(_outLength) {
		assert(_outLength <= len);
	}
	body {
		if (len >= arr.length) {
			auto arlen = arr.length;
			arr = arr[0 .. 0];
			return arlen;
		} else {
			arr = arr[len .. $];
			return len;
		}

	}

	@property typeof(this) save() {
		return typeof(this)(arr);
	}

	@property ulong seek() {
		return arr.length;
	}
}

unittest {
	static assert(isSeekableRStream!MemRStream);
	static assert(isMarkableRStream!MemRStream);
	ubyte[7] data = [1, 5, 0, 9, 3, 10, 200];
	auto s = MemRStream(data);
	ubyte[2] temp;
	assert(2 == s.readFill(temp));
	assert(5 == s.seek);
	assert(temp == [1, 5]);
	assert(4 == s.skip(4));
	assert(1 == s.readFill(temp));
	assert(temp[0] == 200);
}

alias memRStream = MemRStream;

struct FileRStream(bool seekable = true) { //a rstream wrapper around a file
	import std.stdio;

	File file;

	size_t readFill(void[] buf)
	out(_outLength) {
		assert(_outLength <= buf.length);
	}
	body {
		if (buf.length == 0) {
			return 0;
		}
		auto s = file.rawRead(buf);
		return s.length;
	}

	@property {
		static if (seekable) {
			size_t skip(size_t size) {
				auto sz = file.size;
				auto cr = file.tell;
				if (cr + size > sz) {
					file.seek(sz);
					return cast(size_t)(size - cr);
				} else {
					file.seek(size, SEEK_CUR);
					return size;
				}
			}

			auto seek() {
				return file.size - file.tell;
			}
		} else {
			mixin readSkip;
		}
		void close() {
			file.close;
		}
	}
}

unittest {
	static assert(isDisposeRStream!(FileRStream!true));
}

debug (rstream_file) {
	void main() {
		import std.stdio;

		auto fs = new RStreamWrap!(FileRStream!false)(FileRStream!false(stdin));
		ubyte[16] buf;
		while (true) {
			writeln(fs.readFill(buf));
			writeln(buf);
			fs.skip(16);
		}
	}
}
import std.stdio;

auto fileRStream(bool seekable = true)(File f) {
	return FileRStream!(seekable)(f);
}

unittest {
	auto f = fileRStream(stdin);
}

import std.socket;

struct SocketRStream {
	Socket sock;

	@property auto close() {
		return sock.close;
	}

	mixin readSkip;
	size_t readFill(void[] buffer) {
		return sock.receive(buffer);
	}
}

unittest {
	static assert(isRStream!SocketRStream);
	static assert(isDisposeRStream!SocketRStream);
}
