# Save-file specifications

## Header
The header holds information about the file, it's the first thing checked to see
if we are actually reading a file which we want to read. It also contains some
extra information about what all is contained in the file.

### Byte Format
```
0 ------------------ 6 ------------ 8 -------------- 9 -------------- 10 -------------- 11 --------------------------------------------- 12 ------------------------- ?
| "FATMAP" - literal | flags - bool | X Offset - int | Y Offset - int || Z Offset - int || ? Next file name length - unsigned 1-byte int || ? Next file name - string |
0 ------------------ 6 ------------ 8 -------------- 9 -------------- 10 -------------- 11 --------------------------------------------- 12 ------------------------- ?
```

Please note: In the above and all following byte formats, "int" type is based on
the whether or not the "LargeMap" or "HugeMap" flags are set (unless otherwise
stated).

No flags: 1 byte
LargeMap: 2 bytes
HugeMap : 3 bytes

The flags do not "stack" -- instead, the largest flag set is used.

#### FATMAP
This is the literal start of the file, it will contain the word "FATMAP" with no
padding.

#### Flags
Currently there are two bytes for flags, in case we may wish to add some in the
future. The following list shows what each flag does currently.

```
0:  MultiFileMap    - not yet implemented
1:  LastMap         - not yet implemented
2:  LargeMap        - not yet implemented
3:  HugeMap         - not yet implemented
4:  DetailedData    - not yet implemented
5:  IgnoreObstacles - not yet implemented
6:  Reserved for future use.
7:  Reserved for future use.
8:  Reserved for future use.
9:  Reserved for future use.
10: Reserved for future use.
11: Reserved for future use.
12: Reserved for future use.
13: Reserved for future use.
14: Reserved for future use.
15: Reserved for future use.
```

##### MultiFileMap
This flag is enabled if the map needs to be split into multiple files. The next
file will be stored as the next section in the header.

Each map file is it's own sustained map file, and as such contains its own
header section and body. You can load a single MultiFileMap map file if you want
to, but you will likely be missing strips of data.

If the loader was unable to find the next map in the chain, the return result
will be `false, <map>` instead of `true, <map>`.

##### LastMap
This flag is enabled in a MultiFileMap chain *if and only if* this is the last
map in the chain.

##### LargeMap
This flag increases each position's size from a 1-byte signed integer
(-128 to 127) to a 2-byte signed integer (-32,768 to 32,767).

Please note that this will effectively double the size of the saved map.

##### HugeMap
This flag increases each position's size from a 1-byte signed integer
(-128 to 127) to a 3-byte signed integer (-8,388,608 to 8,388,607).

Please note that this will effectively triple the size of the saved map.

##### DetailedData
This flag is more-so used for debugging purposes and should not be used in a
production environment. This will cause each run to contain a byte holding a
1 (this is an obstacle) or 0 (this is an air block).

##### IgnoreObstacles
The map save system will generate runs for both obstacles and air blocks.
However, it will only save the obstacles or the air blocks. If this flag is not
set, it means that this file should contain air blocks only. If this flag is
set, it means that this file should contain obstacle blocks only.

## Body
To save the map, we save "runs" of node types, ignoring air blocks or obstacle
blocks -- decided by what type of block there are more runs of.

### Runs
Each run contains the following information:

* Start position
* End position
* Whether this run is blocked or not (only if the DetailedData flag is set,
  otherwise it only contains the two positions).

#### Run Byte Format
This assumes we are using a normal-sized map (1-byte signed integer for each x,
y, z value).

```
0 --------- 1 --------- 2 --------- 3 --------- 4 --------- 5 --------- 6 ---------------- 7
| X-1 - int | Y-1 - int | Z-1 - int | X-2 - int | Y-2 - int | Z-2 - int | ? Obstacle? Bool
0 --------- 1 --------- 2 --------- 3 --------- 4 --------- 5 --------- 6 ---------------- 7
```
