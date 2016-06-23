module tpool.stream.wstream_implementations;
import tpool.stream.wstream;

///a wstream wrapper for stdio.file
struct FileWStream {
	import std.stdio;

	File file;

	void writeFill(const void[] buf) {
		file.rawWrite(buf);
	}

	@property {
		void flush() {
			file.flush();
		}

		void close() {
			file.close();
		}
	}
}

unittest {
	static assert(isWStream!FileWStream);
}

alias fileWStream = FileWStream;
///a stream that stores data into memory
struct MemWStream {
	import std.typecons;
	///
	void[] array;

	void writeFill(const void[] buf) {
		array ~= buf;
	}
}

unittest {
	static assert(isWStream!MemWStream);
	auto str = MemWStream();
	str.writeFill(cast(ubyte[])[1, 2, 3]);
	str.writeFill("hello");
	assert(str.array == (cast(const ubyte[])[1, 2, 3] ~ cast(const ubyte[]) "hello"));
}

alias memWStream = MemWStream;
///a stream that ignores all calls
struct VoidWStream {
	void opDispatch(string s, T)(T t) {
	}
}

unittest {
	static assert(isWStream!VoidWStream);
}

alias voidWStream = VoidWStream;
import std.socket;

//a stream that wraps around a socket
struct SocketWStream {
	Socket s;

	@property auto close() {
		return s.close;
	}

	void writeFill(const void[] ar) {
		s.send(ar);
	}

	@property void flush() {
	}
}

unittest {
	static assert(isWStream!SocketWStream);
	static assert(isDisposeWStream!SocketWStream);
}
