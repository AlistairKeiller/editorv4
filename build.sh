git clone https://github.com/llvm/llvm-project
rm -r llvm-project/build

CXXFLAGS="-Dwait4=__syscall_wait4" \
LDFLAGS="-sEXPORTED_RUNTIME_METHODS=FS,callMain -sINVOKE_RUN=0 -sEXPORT_ES6 -sMODULARIZE -sALLOW_MEMORY_GROWTH -sINITIAL_MEMORY=64MB -sSTACK_SIZE=16MB --embed-file $(pwd)/wasi-sysroot" \
emcmake cmake -S llvm-project/llvm -B llvm-project/build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_HOST_TRIPLE=wasm32-unknown-wasi \
  -DCMAKE_SYSTEM_NAME=wasm32-unknown-wasi \
  -DLLVM_TARGETS_TO_BUILD=WebAssembly \
  -DLLVM_CCACHE_BUILD=ON \
  -DLLVM_CCACHE_DIR=/tmp/ccache
ninja -C llvm-project/build -- clang lld
# /build/lib/clang/18/include
