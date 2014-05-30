#custom -version
find . -name "*.d" |xargs dmd -odbuild/obj -ofbuild/test -unittest $@