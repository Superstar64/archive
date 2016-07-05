UNITTEST_SOURCES = $(shell find unittest -type f)
UNITTESTS = $(UNITTEST_SOURCES:%.cpp=build/%)
UNITTEST_FAKE = $(UNITTESTS:build/unittest/%=%.unittest)
UNITTEST_DEBUG = $(UNITTESTS:build/unittest/%=%.unittest.debug)

FORMAT = $(shell find include unittest -type f| sed -r "s/$$/\.format/")



unittests: $(UNITTEST_FAKE)
$(UNITTEST_FAKE) : 
$(UNITTEST_DEBUG) :
format: $(FORMAT)

%.format : %
	clang-format -style=LLVM -i $<


build/% : %.cpp build/unittest $(OBJECTS)
	clang++ -Iinclude -std=c++11  -fsanitize=undefined -g -o $@ $< $(OBJECTS)

%.unittest : build/unittest/%
	./$<
%.unittest.debug : build/unittest/%
	gdb ./$<


build/unittest:
	mkdir -p build/unittest
clean:
	rm -rf build libnumber.a
