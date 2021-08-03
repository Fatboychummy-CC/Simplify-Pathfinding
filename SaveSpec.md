# Format of File
### Overall Format
```
| HEADER | NAME | NUM NODES |  |||  | NODEX | NODEY | NODEZ | NODESTATE | ...
0        1      ?          ?+3     ?+6     ?+9     ?+12    ?+15        ?+16
```

## Header
```
| HEADER - INT LITERAL | MAP NAME - BSTRING | NUM NODES - BNUM |
0                      1                    ?                 ?+3
```
* `HEADER` should always equal `179`

## Node Structure
```
| NODEX - BNUM | NODEY - BNUM | NODEZ - BNUM | NODESTATE - 1B |
0              3              6              9                10
```
* Nodestates are as follows:
  * 0: Unknown
  * 1: Blocked
  * 2: Air

# Types

## BSTRING
```
| STRING-LENGTH | CHARS |
0               1       ?
```
* string length is max 256 due to 1 byte.

## BNUM
```
| 24b SIGNED INT |
0                3
```
* Integers are string.pack'd into BNUMs using `<i3`
