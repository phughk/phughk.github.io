---
layout: post
title: arch-surrealdb
date: 2023-06-10 08:54:03+0100
comments: true
---

Community arch user

Show error they were getting.
Describe how I understood what was going on - point to Rushmore's thread that I found via Discord search.
https://discord.com/channels/902568124350599239/1047608812208668782/1047619270235926548

The issue is with building surrealdb locally, as the user wants to use a nightly build as a dependency, and so they need to build as they are linking to git instead of dist repo.

## Setup LXC to get arch

I dont have arch and I dont have time for that.
Here is lxc

```bash
ubuntu@ns3225533:~$ lxc image copy images:archlinux local:
Image copied successfully!

ubuntu@ns3225533:~$ lxc image list
+-------+--------------+--------+---------------------------------------------+--------------+-----------+----------+------------------------------+
| ALIAS | FINGERPRINT  | PUBLIC |                 DESCRIPTION                 | ARCHITECTURE |   TYPE    |   SIZE   |         UPLOAD DATE          |
+-------+--------------+--------+---------------------------------------------+--------------+-----------+----------+------------------------------+
|       | c430c1a86e11 | no     | Archlinux current amd64 (20230609_04:18)    | x86_64       | CONTAINER | 181.23MB | Jun 10, 2023 at 8:40am (UTC) |
+-------+--------------+--------+---------------------------------------------+--------------+-----------+----------+------------------------------+
|       | f7061e028d28 | no     | ubuntu 22.04 LTS amd64 (release) (20230606) | x86_64       | CONTAINER | 444.83MB | Jun 10, 2023 at 8:28am (UTC) |
+-------+--------------+--------+---------------------------------------------+--------------+-----------+----------+------------------------------+

ubuntu@ns3225533:~$ lxc image alias create archlinux c430c1a86e11
```

And now we can launch and start untangling this

```
ubuntu@ns3225533:~$ lxc launch archlinux bash
```

## Configure Arch Linux

I am just going to provide the commands here, because the output is tedious

```bash
pacman -Sy git make clang base-devel
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

## Reproduce

```
git clone https://github.com/RustForum/api.git
cd api
cargo build
```

This emits a rather scary error
```
   Compiling uuid v1.3.3
   Compiling http-range-header v0.3.0
   Compiling sync_wrapper v0.1.2
   Compiling tower-http v0.4.0
The following warnings were emitted during compilation:

warning: In file included from rocksdb/table/block_based/data_block_hash_index.cc:5:
warning: rocksdb/table/block_based/data_block_hash_index.h:65:7: error: ‘uint8_t’ does not name a type
warning:    65 | const uint8_t kNoEntry = 255;
warning:       |       ^~~~~~~
warning: rocksdb/table/block_based/data_block_hash_index.h:12:1: note: ‘uint8_t’ is defined in header ‘<cstdint>’; did you forget to ‘#include <cstdint>’?
warning:    11 | #include "rocksdb/slice.h"
warning:   +++ |+#include <cstdint>
warning:    12 |
warning: rocksdb/table/block_based/data_block_hash_index.h:66:7: error: ‘uint8_t’ does not name a type
warning:    66 | const uint8_t kCollision = 254;
warning:       |       ^~~~~~~
warning: rocksdb/table/block_based/data_block_hash_index.h:66:7: note: ‘uint8_t’ is defined in header ‘<cstdint>’; did you forget to ‘#include <cstdint>’?
warning: rocksdb/table/block_based/data_block_hash_index.h:67:7: error: ‘uint8_t’ does not name a type
warning:    67 | const uint8_t kMaxRestartSupportedByHashIndex = 253;
warning:       |       ^~~~~~~

(... about 800 lines of ommitted output ...)

  cargo:warning=rocksdb/table/block_based/data_block_hash_index.cc:46:22: error: ‘end’ was not declared in this scope; did you mean ‘std::end’?
  cargo:warning=   46 |   for (auto& entry : hash_and_restart_pairs_) {
  cargo:warning=      |                      ^~~~~~~~~~~~~~~~~~~~~~~
  cargo:warning=      |                      std::end
  cargo:warning=/usr/include/c++/13.1.1/bits/range_access.h:116:37: note: ‘std::end’ declared here
  cargo:warning=  116 |   template<typename _Tp> const _Tp* end(const valarray<_Tp>&) noexcept;
  cargo:warning=      |                                     ^~~
  cargo:warning=rocksdb/table/block_based/data_block_hash_index.cc:54:27: error: ‘kCollision’ was not declared in this scope
  cargo:warning=   54 |       buckets[buck_idx] = kCollision;
  cargo:warning=      |                           ^~~~~~~~~~
  cargo:warning=rocksdb/table/block_based/data_block_hash_index.cc: In member function ‘void rocksdb::DataBlockHashIndexBuilder::Reset()’:
  cargo:warning=rocksdb/table/block_based/data_block_hash_index.cc:73:27: error: request for member ‘clear’ in ‘((rocksdb::DataBlockHashIndexBuilder*)this)->rocksdb::DataBlockHashIndexBuilder::hash_and_restart_pairs_’, which is of non-class type ‘int’
  cargo:warning=   73 |   hash_and_restart_pairs_.clear();
  cargo:warning=      |                           ^~~~~
  cargo:warning=rocksdb/table/block_based/data_block_hash_index.cc: At global scope:
  cargo:warning=rocksdb/table/block_based/data_block_hash_index.cc:76:6: error: no declaration matches ‘void rocksdb::DataBlockHashIndex::Initialize(const char*, uint16_t, uint16_t*)’
  cargo:warning=   76 | void DataBlockHashIndex::Initialize(const char* data, uint16_t size,
  cargo:warning=      |      ^~~~~~~~~~~~~~~~~~
  cargo:warning=rocksdb/table/block_based/data_block_hash_index.h:120:8: note: candidate is: ‘void rocksdb::DataBlockHashIndex::Initialize(const char*, int, int*)’
  cargo:warning=  120 |   void Initialize(const char* data, uint16_t size, uint16_t* map_offset);
  cargo:warning=      |        ^~~~~~~~~~
  cargo:warning=rocksdb/table/block_based/data_block_hash_index.h:116:7: note: ‘class rocksdb::DataBlockHashIndex’ defined here
  cargo:warning=  116 | class DataBlockHashIndex {
  cargo:warning=      |       ^~~~~~~~~~~~~~~~~~
  cargo:warning=rocksdb/table/block_based/data_block_hash_index.cc:86:9: error: no declaration matches ‘uint8_t rocksdb::DataBlockHashIndex::Lookup(const char*, uint32_t, const rocksdb::Slice&) const’
  cargo:warning=   86 | uint8_t DataBlockHashIndex::Lookup(const char* data, uint32_t map_offset,
  cargo:warning=      |         ^~~~~~~~~~~~~~~~~~
  cargo:warning=rocksdb/table/block_based/data_block_hash_index.cc:86:9: note: no functions named ‘uint8_t rocksdb::DataBlockHashIndex::Lookup(const char*, uint32_t, const rocksdb::Slice&) const’
  cargo:warning=rocksdb/table/block_based/data_block_hash_index.h:116:7: note: ‘class rocksdb::DataBlockHashIndex’ defined here
  cargo:warning=  116 | class DataBlockHashIndex {
  cargo:warning=      |       ^~~~~~~~~~~~~~~~~~
  exit status: 1
  running: "c++" "-O0" "-ffunction-sections" "-fdata-sections" "-fPIC" "-gdwarf-4" "-fno-omit-frame-pointer" "-m64" "-I" "rocksdb/include/" "-I" "rocksdb/" "-I" "rocksdb/third-party/gtest-1.8.1/fused-src/" "-I" "snappy/" "-I" "/root/api/target/debug/build/lz4-sys-b364ddb0b93330e0/out/include" "-I" "/root/.cargo/registry/src/index.crates.io-6f17d22bba15001f/zstd-sys-2.0.8+zstd.1.5.5/zstd/lib" "-I" "/root/api/target/debug/build/libz-sys-69ff68125312b666/out/include" "-I" "/root/api/target/debug/build/bzip2-sys-78b9fd09964b1c12/out/include" "-I" "." "-Wall" "-Wextra" "-std=c++17" "-Wsign-compare" "-Wshadow" "-Wno-unused-parameter" "-Wno-unused-variable" "-Woverloaded-virtual" "-Wnon-virtual-dtor" "-Wno-missing-field-initializers" "-Wno-strict-aliasing" "-Wno-invalid-offsetof" "-msse2" "-std=c++17" "-DSNAPPY=1" "-DLZ4=1" "-DZSTD=1" "-DZLIB=1" "-DBZIP2=1" "-DNDEBUG=1" "-DOS_LINUX" "-DROCKSDB_PLATFORM_POSIX" "-DROCKSDB_LIB_IO_POSIX" "-DROCKSDB_SUPPORT_THREAD_LOCAL" "-o" "/root/api/target/debug/build/librocksdb-sys-c79d90d2583a9c52/out/rocksdb/table/block_based/full_filter_block.o" "-c" "rocksdb/table/block_based/full_filter_block.cc"
  exit status: 0
  exit status: 0
  exit status: 0
  exit status: 0
  exit status: 0
  exit status: 0
  exit status: 0
  exit status: 0
  exit status: 0
  exit status: 0
  exit status: 0
  exit status: 0

  --- stderr


  error occurred: Command "c++" "-O0" "-ffunction-sections" "-fdata-sections" "-fPIC" "-gdwarf-4" "-fno-omit-frame-pointer" "-m64" "-I" "rocksdb/include/" "-I" "rocksdb/" "-I" "rocksdb/third-party/gtest-1.8.1/fused-src/" "-I" "snappy/" "-I" "/root/api/target/debug/build/lz4-sys-b364ddb0b93330e0/out/include" "-I" "/root/.cargo/registry/src/index.crates.io-6f17d22bba15001f/zstd-sys-2.0.8+zstd.1.5.5/zstd/lib" "-I" "/root/api/target/debug/build/libz-sys-69ff68125312b666/out/include" "-I" "/root/api/target/debug/build/bzip2-sys-78b9fd09964b1c12/out/include" "-I" "." "-Wall" "-Wextra" "-std=c++17" "-Wsign-compare" "-Wshadow" "-Wno-unused-parameter" "-Wno-unused-variable" "-Woverloaded-virtual" "-Wnon-virtual-dtor" "-Wno-missing-field-initializers" "-Wno-strict-aliasing" "-Wno-invalid-offsetof" "-msse2" "-std=c++17" "-DSNAPPY=1" "-DLZ4=1" "-DZSTD=1" "-DZLIB=1" "-DBZIP2=1" "-DNDEBUG=1" "-DOS_LINUX" "-DROCKSDB_PLATFORM_POSIX" "-DROCKSDB_LIB_IO_POSIX" "-DROCKSDB_SUPPORT_THREAD_LOCAL" "-o" "/root/api/target/debug/build/librocksdb-sys-c79d90d2583a9c52/out/rocksdb/table/block_based/data_block_hash_index.o" "-c" "rocksdb/table/block_based/data_block_hash_index.cc" with args "c++" did not execute successfully (status code exit status: 1).
```


Thrilling!

## How to debug

First things first... Search.
Very strong "this is pretty standard, someone has seen this" vibes.

We have a community discord - I used this to search for suspect terms.
I don't think anything showed up in particular, besides some installation tips from Rushmore Mushambi, our resident Rust guru.

```
surrealdb = { version = "1.0.0-beta.9", features = ["kv-rocksdb"] }
```

So I check version 
```
[root@helped-zebra api]# c++ --version
```

So its an issue with rocksdb so i check devel dependencies
https://archlinux.org/packages/extra/x86_64/rocksdb/
```
pacman -Sy bzip2 jemalloc liburing lz4 snappy tbb zlib zstd python 
```

didnt solve :(

## Compiling rocksdb
Since this is an issue with rocksdb being compiled, perhaps I can try building rocksdb outside surrealdb to see what the issue is there

```
git clone https://github.com/facebook/rocksdb.git
cd rocksdb
make static_lib
...
  AR       librocksdb.a
/usr/sbin/ar: creating librocksdb.a
```

Wut. It works.

Go back to Rushmore dependencies.
Paste apt-get directly into pacman to find differences
```
[root@helped-zebra api]# pacman -Sy \
>         curl \
        llvm \
        cmake \
        binutils \
        clang-11 \
        qemu-user \
        musl-tools \
        libssl-dev \
        pkg-config \
        build-essential
:: Synchronizing package databases...
 core                                                                                                                                         132.2 KiB   230 KiB/s 00:01 [#########################################################################################################] 100%
 extra                                                                                                                                          8.3 MiB  4.03 MiB/s 00:02 [#########################################################################################################] 100%
warning: curl-8.1.2-1 is up to date -- reinstalling
warning: binutils-2.40-6 is up to date -- reinstalling
error: target not found: clang-11
error: target not found: musl-tools
error: target not found: libssl-dev
warning: pkgconf-1.8.1-1 is up to date -- reinstalling
error: target not found: build-essential
```

Now figure out replacements from https://archlinux.org/packages

musl-tools
```
pacman -Sy musl rust-musl
```

libssl-dev
```
pacman -Sy openssl
```

Still not solved

```
[root@helped-zebra api]# rm `which c++`
[root@helped-zebra api]# cp `which clang++` /usr/sbin/c++
```

Still same issue.

Build surrealdb
```
sudo pacman -S protobuf
git clone https://github.com/surrealdb/surrealdb.git
cd surrealdb
make build
```

Doesnt build

```
```
