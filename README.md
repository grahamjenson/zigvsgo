# Test Golang SQLite API vs zig SQLite API

Just a quick test to see whats up with these different libraries

`/write` will write an item `{'name': "Graham Jenson", timestamp: <timestamp>}`
`/read` will read 100 items, serialize and return them

# Tests:


|              | **   read   ** | **   write   ** | **   random   ** |
|--------------|:--------------:|:---------------:|:----------------:|
| **go**       |                |                 |                  |
| **zig safe** |                |                 |                  |
| **zig fast** |                |                 |                  |
