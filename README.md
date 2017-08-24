    Arch: README.md,v 1.002 2017/08/24 15:27:15 kyau Exp $

### About
This botnet script has been around for longer than I can remember. While I know 
the original author was German, past this I know nothing (the script in its 
original form was given to me by a friend long ago). It has had three major 
iterations since, evolving originally from a clone of netbots that I called 
`tribe9`, these two scripts were merged together to form `blackmajick` which 
also gained a few external module scripts and channel limit control (imported 
from a script called dolimit) along with a BitchX clone mode (makes the eggdrop 
appear as if it is a BitchX client). Around 2006 I started getting back into TCL 
coding and IRC in general and modified the script quite a bit, only to once 
again rename the script to `darkMAGE`.

### Usage
In order to use this script with your botnet, add the script to your eggdrop config 
and restart/rehash your eggdrop. Linking bots is relatively easy.

```shell
"On the HUB"
> .+bot leafbot 1.2.3.4 +9999
> .+host leafbot *!ident@1.2.3.4
> .chattr leafbot +bfopA
> .botattr leafbot +gs
```

```shell
"On Each Connecting Bot"
> .+bot hub 1.2.3.4 +9999
> .+host hub *!ident@1.2.3.4
> .chattr hub +bfopA
> .botattr hub +ghp
```

### Attribution
If anyone has any information as to the original author or authors, please let me know!
