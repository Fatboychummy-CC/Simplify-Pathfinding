# Format of File
### Overall Format
```
| HEADER | NAME | NUM NODES | NODEX | NODEY | NODEZ | NODESTATE | ...
0        1      ?          ?+4     ?+7     ?+10    ?+13        ?+14
```

## Header
```
| HEADER - INT LITERAL | MAP NAME - BSTRING | NUM NODES - BNUM2 |
0                      1                    ?                  ?+4
```
* `HEADER` should always equal `179`

## Node Structure
```
| NODEX - BNUM | NODEY - BNUM | NODEZ - BNUM | NODESTATE - BYTE |
0              3              6              9                  10
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

## BNUM2
```
| 32b SIGNED INT |
0                4
```
* Integers are string.pack'd into BNUM2s using `<i4`
