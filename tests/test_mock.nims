switch("path", "$projectDir/../src")

# switch("define", "release")
# switch("opt", "size")

switch("mm", "arc") # use "arc", "orc" or "none"
switch("deepcopy", "on")
switch("threads", "off")
switch("d", "ssl")

switch("define", "checkAbi")
switch("define", "useMalloc")
# switch("define", "nimAllocPagesViaMalloc")
# switch("define", "nimPage256")

# when using cpp backend
# see for similar issue: https://github.com/nim-lang/Nim/issues/17040
switch("d", "nimEmulateOverflowChecks")

# for futhark to work
switch("maxLoopIterationsVM", "100000000")

switch("d", "mock")

switch("nimcache", "build/nimcache")
