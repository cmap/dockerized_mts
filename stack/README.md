## Stack

Merge two or more builds. Used in pipeline to merge assays with different cell lines.

Usage
```
docker run -it -v /path_to/test_files:/data  prismcmap:stack --build_paths /data/PR300/build/,/data/PR500/build/ -n TEST -o /data/TEST_BUILD/build
```

`--build_paths` is a comma-separated list (no whitespace) of build paths. 
