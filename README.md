```
▄▄▄  ▄▄▄▄ ▄▄▄▄ ▄▄ ▄ ▄▄ ▄▄▄▄▄▄ ▄▄▄▄ ▄▄▄▄▄ ▄▄▄▄
██ █ ██ █ ██ █ ██ █ ██ ██ █ █ ██ █ ██    ██ ▀
██ █ ██▄█ ██▄▀ ██▄▀ ██ ██ █ █ ██▄█ ██ ▄▄ ██▀
██ █ ██ █ ██ █ ██ █ ▀▀ ██ █ █ ██ █ ██ ▀█ ██ █
▀▀▀▀ ▀▀ ▀ ▀▀ ▀ ▀▀ ▀ ▀▀ ▀▀ ▀ ▀ ▀▀ ▀ ▀▀▀▀▀ ▀▀▀▀
```
<a href="irc://irc.efnet.org:+9999/kyaulabs">irc://irc.efnet.org:+9999/kyaulabs</a>

[![](https://img.shields.io/badge/coded_in-vim-green.svg?logo=vim&logoColor=brightgreen&colorB=brightgreen&longCache=true&style=flat)](https://vim.org) &nbsp; [![](https://img.shields.io/badge/license-AGPL_v3-blue.svg?style=flat)](https://raw.githubusercontent.com/kyau/darkmage/master/LICENSE) &nbsp; [![](https://img.shields.io/badge/eggdrop-1.8+-C85000.svg?style=flat)](https://github.com/eggheads/eggdrop) &nbsp; [![](https://img.shields.io/badge/tcl-8.5+-C85000.svg?style=flat)](https://www.tcl.tk/)

[![](https://img.shields.io/badge/pkg:http->=_2.9.0-8E68AC.svg?style=flat)](https://core.tcl.tk/tcllib/) &nbsp; [![](https://img.shields.io/badge/pkg:tls->=_1.7.11-8E68AC.svg?style=flat)](https://core.tcl.tk/tcltls/)

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
> .+bot leafbot 1.2.3.4 +9900/9901
> .+host leafbot *!ident@1.2.3.4
> .+host leafbot *!ident@hostname
> .chattr leafbot +bfopA
> .botattr leafbot +gs
```

```shell
"On Each Connecting Bot"
> .+bot hub 1.2.3.4 +9900/9901
> .+host hub *!ident@1.2.3.4
> .+host hub *!ident@hostname
> .chattr hub +bfopA
> .botattr hub +ghp
```

Keep in mind the `A` flag is set by default as the "control all bots" flag. Also do not forget to change the value of `bop_opkey`.

### Attribution
If anyone has any information as to the original author or authors, please let me know!
* [Tcllib](https://core.tcl.tk/tcllib/)
* [TclTLS](https://core.tcl.tk/tcltls/)
