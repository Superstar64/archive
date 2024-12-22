/*
Boost Software License - Version 1.0 - August 17th, 2003

Copyright (c) 2015 Freddy A Cubas "Superstar64"

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/
module tagged_union;

struct TaggedUnion(Types_...)
{
    alias Types = Types_;
    private size_t index = size_t.max;
    union
    {
        private Types data;
    }

    this(T)(T type) if (IndexOf!T != -1)
    {
        this = type;
    }

    auto ref opAssign(T)(T type) if (IndexOf!T != -1)
    {
        set!T(type);
    }

    auto opEquals(const typeof(this) other) const
    {
        if (id == other.id)
        {
            foreach (c, Type; Types)
            {
                if (id == c)
                {
                    return getID!c == other.getID!c;
                }
            }
        }
        return false;
    }

    auto opEquals(T)(const T type) const if (IndexOf!T != -1)
    {
        if (id == IndexOf!T)
        {
            return type == get!T;
        }
        return false;
    }

@property:

    auto id() const
    {
        return index;
    }

    pure @trusted auto ref getID(size_t id)() inout if (id < Types.length)
    {
        assert(index == id);
        return data[id];
    }

    pure @trusted auto ref setID(size_t id)(Types[id] type) if (id < Types.length)
    {
        index = id;
        data[id] = type;
    }

    pure @safe bool isType(Type)() inout if (IndexOf!Type != -1)
    {
        return IndexOf!Type == id;
    }

    alias peek = isType;

    pure @safe auto ref get(Type)() inout if (IndexOf!Type != -1)
    {
        return getID!(IndexOf!Type);
    }

    alias get(size_t i) = getID!i;

    pure @safe auto ref set(Type)(Type type) if (IndexOf!Type != -1)
    {
        return setID!(IndexOf!Type)(type);
    }

    alias set(size_t i) = setID!i;
    auto toString()
    {
        foreach (c, Type; Types)
        {
            if (id == c)
            {
                import std.conv;

                return (getID!c).to!string;
            }
        }
        return "";
    }

    template IndexOf(Type)
    {
        import std.typetuple : staticIndexOf;

        enum IndexOf = staticIndexOf!(Type, Types);
    }
}

pure @safe unittest
{
    alias Union = TaggedUnion!(int, string);
    const Union a = 5;
    assert(a.isType!int);
    Union b = "c";
    assert(b.isType!string);
    b = a;
    assert(a == b);
    assert(a == 5);
    assert(a.id == 0);
    assert(a.getID!0 == 5);
    assert(a.get!0 == 5);
    assert(a.get!int == 5);
    b.set!1("hi");
    assert(b == "hi");
    import std.conv;

    assert((a.getID!0).to!string == (5.to!string));
    static assert(is(typeof(a.getID!0) == const));
    static assert(!is(typeof(b.getID!0) == const));

    enum ctfe = {
        Union c = 1;
        assert(c == 1);
        c = "abc";
        assert(c == "abc");
        Union d = c;
        return d == c;
    }();
}