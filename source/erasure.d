import std.meta;
import std.traits;
import std.conv : to;

/++
 + Substitute σx into σ, replacing all type variables with name $(B x).
 + This function is primarily used by Π's specialize function.
 + Structs and Classes can implement $(B SubstituteImpl(σx, x)) to allow specialization.
 +/
template Substitute(σx, string x, σ)
{
    static if (staticIndexOf!(σ, Primatives) != -1)
    {
        alias Substitute = σ;
    }
    else static if (isArray!σ || isAssociativeArray!σ || isFunctionPointer!σ || isDelegate!σ)
    {
        alias Substitute = SubstituteNative!(σx, x, σ);
    }
    else static if (isPointer!σ)
    {
        alias Substitute = Substitute!(σx, x, PointerTarget!σ)*;
    }
    else static if (hasMember!(σ, "SubstituteImpl") && !isPointer!σ)
    {
        alias Substitute = σ.SubstituteImpl!(σx, x);
    }
    else
    {
        // assume σ doesn't contain any free variables by default
        alias Substitute = σ;
    }
}

///
unittest
{
    static assert(is(Substitute!(Object, "x", α!("x")*) == Object*));
    static assert(is(Substitute!(Object, "x",
            α!("x") function(α!("x"))) == Object function(Object)));
}

private alias Primatives = AliasSeq!(void, bool, byte, ubyte, short, ushort,
        int, uint, long, ulong, float, double, real, ifloat, idouble, ireal,
        cfloat, cdouble, creal, char, wchar, dchar);

private template SubstituteNative(σx, string x, _:
        τ[], τ)
{
    alias SubstituteNative = Substitute!(σx, x, τ)[];
}

private template SubstituteNative(σx, string x, _:
        τ[σ], τ, σ)
{
    alias SubstituteNative = Substitute!(σx, x, τ)[Substitute!(σx, x, σ)];
}

private template SubstituteNative(σx, string x, _:
        τ function(σ), τ, σ...)
{
    alias SubstituteNative = Substitute!(σx, x, τ) function(
            staticMap!(SubstituteCurry!(σx, x), σ));
}

private template SubstituteNative(σx, string x, _:
        τ delegate(σ), τ, σ...)
{
    alias SubstituteNative = Substitute!(σx, x, τ) delegate(
            staticMap!(SubstituteCurry!(σx, x), σ));
}

private template SubstituteCurry(σx, string x)
{
    alias SubstituteCurry(σ) = Substitute!(σx, x, σ);
}

/++
 + A Type Variable is a representation of an unknown type.
 + The only known property about a type variable is it's size $(B κ).
 + Two type variables with different names represent two different incompatible types.
 + Functions that use unbounded type variables should always be private and wrap said function with a forall type.
 +/
struct α(string x, size_t κ = Object.sizeof)
{
    private void[κ] get;

    template SubstituteImpl(σx, string x2)
    {
        static if (x == x2)
        {
            static assert(σx.sizeof == κ,
                    "Kind mismatch: size of " ~ σx.stringof ~ " is not " ~ κ.to!string);
            alias SubstituteImpl = σx;
        }
        else
        {
            alias SubstituteImpl = typeof(this);
        }
    }

    static assert(typeof(this).sizeof == κ);
}

/++
 + Forall types (called "∀" is system-f) binds a type variable $(B x) in a type $(B σ).
 + Forall's purpose is represent a type that can be specialized to something else.
---
// this can be read as
// forall types "x", x function(x)
Π!("x", α!("x") function α!("x"))
---
 +/
struct Π(string x, σ)
{
    private σ get;

    /++
	 + A forall type can be specialized into any type that has the same size as the bound type variable $(B x) in $(B σ) including other type variables.
	 +/
    Substitute!(σx, x, σ) specialize(σx)()
    {
        return *cast(Substitute!(σx, x, σ)*)(&get);
    }

    template SubstituteImpl(σx, string x2)
    {
        static if (x == x2)
        {
            alias SubstituteImpl = Π!(x, σ);
        }
        else
        {
            alias SubstituteImpl = Π!(x, Substitute!(σx, x2, σ));
        }
    }
}

/++
 + A type lambda takes a value with a free type variable $(B x) and binds it inside a Forall type.
 +/
template Λ(string x)
{
	///
    Π!(x, σ) Λ(σ)(σ bound)
    {
        return Π!(x, σ)(bound);
    }
}

///
unittest
{
    // this can be read as
    // forall types "a", such that "a" has the same size of int. x is a value of type a*  
    Π!("a", α!("a", int.sizeof)*) x = Λ!("a")(cast(α!("a", int.sizeof)*) null);
    assert(x.specialize!(int)() == null);
    assert(x.specialize!(float)() == null);
}

/++
 + N arity type lambda.
 +/
template Λ(string x, string y, xs...)
{
    auto Λ(σ)(σ bound)
    {
        return .Λ!x(.Λ!(y, xs)(bound));
    }
}

/++
 + Helper mixin template wrapping functions in a foralls.
 + Given a template $(B symbol), a list a type variables $(B Variables), and a name $(name), this mixin generates two symobls $(B underscore ~ name) and $(B name).
 + Where $(B underscore ~ name) is a private symbol with free variables and $(B name) is the former wrapped in a forall type.
---
// generic identity function in idiomatic D
A identityGeneric(A)(A x)
{
    return x;
}

// generate the symbol "_identityPtr" and the "identityPtr" wrapper
mixin Erasure!(identityGeneric, "identityPtr", α!("A", (void*).sizeof));

// redefine for clearity
enum Π!("A", α!("A", (void*).sizeof) function(α!("A", (void*).sizeof))) identity = identityPtr;

// usage
unittest
{
    int* x = new int(1);
    assert(*identity.specialize!(int*)()(x) == 1);
}
---
 +/
mixin template Erasure(alias symbol, string name, Variables...)
{
    alias impl = symbol!Variables;
    alias R = ReturnType!impl;
    alias A = Parameters!impl;

    mixin(q{ private R } ~ "_" ~ name ~ q{(A args){
		return impl(args);
	}});

    mixin(q{enum } ~ name ~ q{ = Λ!(staticMap!(αName, Variables))(&} ~ "_" ~ name ~ q{);});
}

version (unittest)
{
    // generic identity function in idiomatic D
    A identityGeneric(A)(A x)
    {
        return x;
    }

    // generate the symbol "_identityPtr" and the "identityPtr" wrapper
    mixin Erasure!(identityGeneric, "identityPtr", α!("A", (void*).sizeof));

    // redefine for clearity
    enum Π!("A", α!("A", (void*).sizeof) function(α!("A", (void*).sizeof))) identity = identityPtr;

    // usage
    unittest
    {
        int* x = new int(1);
        assert(*identity.specialize!(int*)()(x) == 1);
    }

    auto pickLeft(A, B)(A x, B y)
    {
        return x;
    }

    mixin Erasure!(pickLeft, "pickLeftObj", α!("A"), α!("B"));

    unittest
    {
        import std.range;
        import std.algorithm;

        InputRange!int range = pickLeftObj.specialize!(InputRange!int)
            .specialize!(InputRange!char)()(inputRangeObject(iota(0, 10)), null);
        assert(equal(range, iota(0, 10)));
    }
}

private template αName(σ : α!(x, κ), string x, size_t κ)
{
    enum αName = x;
}
