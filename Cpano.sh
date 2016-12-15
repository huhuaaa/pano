# !/bin/sh
# 已经添加python2.7软连接
# ln -s /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk/System/Library/Frameworks/Python.framework/Versions/2.7/include/python2.7 /usr/local/include/python2.7
cd Cpano
cython Cpano.pyx
gcc -c -fPIC -I/usr/local/include/python2.7 Cpano.c
gcc -shared -lpython2.7 Cpano.o -o Cpano.so
cp Cpano.so ../Cpano.so