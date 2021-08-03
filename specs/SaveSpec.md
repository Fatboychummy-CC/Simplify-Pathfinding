# Format of File
### Overall Format
```
| HEADER | NAME | OFFSETX | OFFSETY | OFFSETZ | NUM NODE RUNS | NODE RUN | ...
0        1      ?        ?+3       ?+6       ?+9             ?+13      ?+13+?
```

## Header
```
| HEADER - INT LITERAL | MAP NAME - BSTRING | OFFSETX | OFFSETY | OFFSETZ | NUM NODES - BNUM2 |
0                      1                    ?        ?+3       ?+6       ?+9                 ?+13
```
* `HEADER` should always equal `179`

## Node Run Structure
```
| NODEX - BNUM | NODEY - BNUM | NODEZ - BNUM | NODEZ-END | NODESTATE - BYTE |
0              1              2              3           4                  10
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
* string length is max 256 due to 1 byte. Should be way more than enough.
