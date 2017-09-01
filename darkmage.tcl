# $Arch: darkmage.tcl,v 1.037 2017/09/01 11:35:50 kyau Exp $

set dmver "1.037"
set releasedate "2017.09.01"
# CONFIGURATION {{{
set notify-newusers { "kyau" }		;# users to notify of new users and bots.
logfile 5 * "logs/darkMAGE.log"		;# darkMAGE logfile
set local_control "A"							;# botattr for local bots
set bn_control "*"								;# default botnet control (* is all)
set modes-per-line 4							;# irc network modes-per-line (EFnet: 4)
set partylinelist 1								;# display partyline users on dcc connection (0/1)
set bop_opkey "magicmonkey"				;# key used for encrypted ops verification
set bop_modeop 1									;# requests ops when others get ops (0/1)
set bop_linkop 1									;# requests ops from other linked bots (0/1)
set bop_icheck 1									;# perform invite check to get in channels (0/1)
set bop_delay 10									;# delay between requests for ops
set bop_maxreq 2									;# maximum simultaneous op requests to send
set bop_osync 0										;# skip op check when opping
set bop_addhost 0									;# automatically add hosts to bots to gain ops
set bop_log 2										  ;# 0 = no logging
																	 # 1 = log: invite/limit/key/unban
																	 # 2 = log: invite/limit/key/ops/unban
# }}}
# ----- DO NOT EDIT BELOW HERE! ----------------------------------------------- {{{
# }}}
# LOADING TEXT {{{
loadmodule filesys
putlog "\00311darkMAGE\003 \00314v$dmver\003 - \00315kyau\003 \0037<kyau@kyau.net>\003"
# }}}
# BINDS AND UNBINDS {{{
catch {unbind dcc o|o +ban *dcc:+ban}
catch {unbind dcc o act *dcc:act}
catch {unbind dcc o msg *dcc:msg}
catch {unbind dcc o say *dcc:say}
catch {unbind dcc - whom *dcc:whom}
catch {unbind dcc - op *dcc:op}
catch {unbind dcc - bots *dcc:bots}
catch {unbind msg - addhost *msg:addhost}
catch {unbind msg - op *msg:op}
bind bot - botnet botnet_proc
bind bot - botnet_chans botnet_channels
bind bot - these_chans these_chans
bind bot - vBOTNET_CHECK_EGGDROP_EXT bot_extcheck
bind bot - vBOTNET_CHECK_EGGDROP_EXT_ACK bot_extcheckack
bind chon - * dcc_chat
bind ctcp - CLIENTINFO bx_ctcp
bind ctcp - USERINFO bx_ctcp
bind ctcp - VERSION bx_ctcp
bind ctcp - FINGER bx_ctcp
bind ctcp - ERRMSG bx_ctcp
bind ctcp - ECHO bx_ctcp
bind ctcp - INVITE bx_ctcp
bind ctcp - WHOAMI bx_ctcp
bind ctcp - OP bx_ctcp
bind ctcp - OPS bx_ctcp
bind ctcp - UNBAN bx_ctcp
bind ctcp - PING bx_ctcp
bind ctcp - TIME bx_ctcp
bind dcc o|o +ban ban:+ban
bind dcc t|- +bot dcc:+bot
bind dcc m|- +user dcc:+user
bind dcc p about dcc_about
bind dcc n act *dcc:act
bind dcc m|m adduser dcc:adduser
bind dcc m autoaway dcc:autoaway
bind dcc n bitchx bx_dccbitchx
bind dcc n botnick dcc_botnick
bind dcc n botnet botnetmsg_proc
bind dcc n bots dcc_bots
bind dcc n botstat dcc_bots
bind dcc n channels cmd_channels
bind dcc - darkmage dm_help
bind dcc - dmhelp dm_help
bind dcc n dolimit dm:dcc:dolimit
bind dcc m|m hostcheck dcc:hostcheck
bind dcc n kill dcc_kill
bind dcc n msg *dcc:msg
bind dcc - op dcc_op
bind dcc n say *dcc:say
bind dcc p sv dcc_about
bind dcc o|o userlist dcc_userlist
bind dcc n vcheck dcc_extcheck
bind dcc p version dcc_about
bind dcc p whom dcc:whomall
bind msg - op msg_op
bind raw - MODE encrypted_opverify
bind time - "57 * * * *" time:keeplinked
bind raw - 001 bx_serverjoin
# }}}
# DEFAULT PROCS {{{
proc putbotdcc {idx dcctxt} {
	set sysTime [clock seconds]
	set dmtime [clock format $sysTime -format %H:%M:%S]
	putdcc $idx "\[$dmtime\] \00311darkMAGE\003\00314\037:\037\003 $dcctxt"
}
proc putbotdcclog {logtxt} {
	putlog "\00311darkMAGE\003\00314\037:\037\003 $logtxt"
}
proc putbotdccerr {idx errtxt} {
	set sysTime [clock seconds]
	set dmtime [clock format $sysTime -format %H:%M:%S]
	putdcc $idx "\[$dmtime\] \00304ERROR\003\00314\037:\037\003 $errtxt"
}
proc xindex {xr xr1} {
	return [join [lrange [split $xr] $xr1 $xr1]]
}
proc xrange {xr xr1 xr2} {
	return [join [lrange [split $xr] $xr1 $xr2]]
}
proc xstrcmp {str1 str2} {
	if {[string compare [string tolower $str1] [string tolower $str2]] == 0} {
		return 1
	} else {
		return 0
	}
}
proc putbotlog {logtxt} {
	putloglev 5 "*" "darkMAGE\037:\037 $logtxt"
}
if { [info vars botnet-nick] == "" } {
	set bnnick $nick
}
if { [info vars botnet-nick] != "" } {
	set bnnick ${botnet-nick}
}
# Encrypted Hash
proc bop_encrypted {thost tnick} {
	global bop_opkey
	set sysTime [clock seconds]
	set thour [clock format $sysTime -gmt true -format %H]
	set tbin "md5sum"
	if {[exec uname -s] == "OpenBSD"} {
		set tbin "md5"
	}
	#putlog "\00306DEBUG:\003 tbin:{$tbin} thour:{$thour} thost:{$thost} tnick:{$tnick}"
	catch {exec echo -n "$thour$thost$tnick$bop_opkey" | $tbin | cut -f 1 -d " "} result
	return $result
}
proc time:keeplinked {min hour day month year} {
 foreach b [userlist b] {
  if {([string match "*h*" "[getuser $b BOTFL]"] || [string match "*a*" "[getuser $b BOTFL]"]) && (![string match "*r*" "[getuser $b BOTFL]"] && ![islinked $b])} {
   putbotlog "Keeplinked linking: \002\ $b ...\002\ "
   link "$b" 
  }
 }
}
# }}}
# HELP {{{
proc dm_help {hand idx arg} {
	global dmver
	if {[matchattr $hand n]} {
		putdcc $idx "darkMAGE v$dmver"
		putdcc $idx "-------------------------------------------------------"
		putdcc $idx "commands\037:\037"
		putdcc $idx "- autoaway bitchx botnick botstat channels"
		putdcc $idx "- dolimit hostcheck kill sv userlist vcheck"
		putdcc $idx "- whom"
		putdcc $idx "-------------------------------------------------------"
		putdcc $idx "botnet commands\037:\037"
		putdcc $idx "- act channels chanset control join"
		putdcc $idx "- masskick massop massopall massvoice"
		putdcc $idx "- massdevoice part rehash save say"
		putdcc $idx "- takeover"
		putdcc $idx "-------------------------------------------------------"
		return 0
	} elseif {[matchattr $hand m]} {
		putdcc $idx "darkMAGE v$dmver"
		putdcc $idx "-------------------------------------------------------"
		putdcc $idx "commands\037:\037"
		putdcc $idx "- adduser autoaway hostcheck sv userlist"
		putdcc $idx "- whom"
		putdcc $idx "-------------------------------------------------------"
		return 0
	} elseif {[matchattr $hand o]} {
		putdcc $idx "darkMAGE v$dmver"
		putdcc $idx "-------------------------------------------------------"
		putdcc $idx "commands\037:\037"
		putdcc $idx "- sv userlist whom"
		putdcc $idx "-------------------------------------------------------"
		return 0
	} elseif {[matchattr $hand p]} {
		putdcc $idx "darkMAGE v$dmver"
		putdcc $idx "-------------------------------------------------------"
		putdcc $idx "commands\037:\037"
		putdcc $idx "- sv whom"
		putdcc $idx "-------------------------------------------------------"
		return 0
	}
}
# }}}
# TAKEOVER {{{
proc bot_takeover {hand idx arg} {
	if {$arg == 0} { return 0 }
	set hand2 [xindex $arg 0]
	set chan [xindex $arg 1]
	if {([validchan $chan]) && ([botonchan $chan]) && ([botisop $chan])} {
		putbotlog "taking over $chan ($hand2@$hand)"
		putbotdcc $idx "taking over $chan ($hand2@$hand)"
		takeover $chan
	}
}
proc takeover {chan} {
	global modes-per-line
	set nicklist [randomize_nicks $chan]
	set nicks ""
	foreach nick $nicklist {
		if {(![isbotnick $nick]) && ([isop $nick $chan]) && (![matchattr [nick2hand $nick $chan] n|n $chan]) && (![matchattr [nick2hand $nick $chan] b])} {
			lappend nicks $nick
			if {[llength $nicks] >= ${modes-per-line}} {
				putquick "MODE $chan -oooo $nicks"
				set nicks ""
			}
		}
	}
	if {$nicks != ""} {
		putquick "MODE $chan -oooo $nicks"
	}
}
proc randomize_nicks {chan} {
	set nicklist ""
	set nicklist2 [chanlist $chan]
	while {$nicklist2 != ""} {
		set i [rand [llength $nicklist2]]
		lappend nicklist [xindex $nicklist2 $i]
		set nicklist2 [lreplace $nicklist2 $i $i]
	}
	return $nicklist
}
# }}}
# MASS COMMANDS {{{
proc masskick {chan} {
	if {![botisop $chan]} {
		return 0
	}
	set nicklist [randomize_nicks $chan]
	putquick "MODE $chan +im"
	foreach nick $nicklist {
		if {(![isbotnick $nick]) && (![isop $nick $chan]) && (![matchattr [nick2hand $nick $chan] n|n $chan]) && (![matchattr [nick2hand $nick $chan] b])} {
			putquick "KICK $chan $nick :mass kick"
		}
	}
}
proc massop {chan} {
	global modes-per-line
	if {![botisop $chan]} {
		return 0
	}
	set nicklist [randomize_nicks $chan]
	set nicks ""
	foreach nick $nicklist {
		if {(![isop $nick $chan]) && ([onchan $nick $chan]) && ([matchattr [nick2hand $nick $chan] o|o $chan]) && (![matchattr [nick2hand $nick $chan] d|d $chan])} {
			lappend nicks $nick
			if {[llength $nicks] >= ${modes-per-line}} {
				putquick "MODE $chan +oooo $nicks"
				set nicks ""
			}
		}
	}
	if {$nicks != ""} {
		putquick "MODE $chan +oooo $nicks"
	}
}
proc massopall {chan} {
	global modes-per-line
	if {![botisop $chan]} {
		return 0
	}
	set nicklist [randomize_nicks $chan]
	set nicks ""
	foreach nick $nicklist {
		if {(![isop $nick $chan]) && ([onchan $nick $chan])} {
			lappend nicks $nick
			if {[llength $nicks] >= ${modes-per-line}} {
				putquick "MODE $chan +oooo $nicks"
				set nicks ""
			}
		}
	}
	if {$nicks != ""} {
		putquick "MODE $chan +oooo $nicks"
	}
}
proc massvoice {chan} {
	global modes-per-line
	if {![botisop $chan]} {
		return 0
	}
	set nicklist [randomize_nicks $chan]
	set nicks ""
	foreach nick $nicklist {
		if {(![isop $nick $chan]) && ([onchan $nick $chan]) && (![isvoice $nick $chan])} {
			lappend nicks $nick
			if {[llength $nicks] >= ${modes-per-line}} {
				putquick "MODE $chan +vvvv $nicks"
				set nicks ""
			}
		}
	}
	if {$nicks != ""} {
		putquick "MODE $chan +vvvv $nicks"
	}
}
proc massdevoice {chan} {
	global modes-per-line
	if {![botisop $chan]} {
		return 0
	}
	set nicklist [randomize_nicks $chan]
	set nicks ""
	foreach nick $nicklist {
		if {(![isop $nick $chan]) && ([onchan $nick $chan]) && ([isvoice $nick $chan])} {
			lappend nicks $nick
			if {[llength $nicks] >= ${modes-per-line}} {
				putquick "MODE $chan -vvvv $nicks"
				set nicks ""
			}
		}
	}
	if {$nicks != ""} {
		putquick "MODE $chan -vvvv $nicks"
	}
}
# }}}
# .BOTNET {{{
proc botnetmsg_proc {handle idx args} {
	global botnick 
	set channels [channels]
	set bot_count [countbots]
	set args [lindex $args 0]
	set s_flags [lindex $args 2]
	set whattodo [lindex $args 0]
	set botmsg [lindex $args 1]
	switch -exact $whattodo {
		"channels" {
			putbots "botnet_chans $idx $args "
			putbotdcc $idx "$botnick is on chans: $channels"
		}
		"control" {
			botnet_control $idx $botmsg $s_flags
			return
		}
		"takeover" {
			set channame [lindex $args 1]
			putbots "botnet $args $handle"
			putbotlog "doing takeover on $channame with $bot_count bots "
			putbotdcc $idx "doing takeover on $channame with $bot_count bots "
			if {[control_mybot $botnick]} {
				takeover $channame
			}
		}
		"masskick" {
			set channame [lindex $args 1]
			putbots "botnet $args $handle"
			putbotlog "masskicking on $channame using $bot_count bots "
			putbotdcc $idx "masskicking on $channame using $bot_count bots "
			if {[control_mybot $botnick]} {
				utimer [rand 10] "masskick $channame"
			}
		}
		"massop" {
			set channame [lindex $args 1]
			putbots "botnet $args $handle"
			putbotlog "massopping on $channame using $bot_count bots "
			putbotdcc $idx "massopping on $channame using $bot_count bots "
			if {[control_mybot $botnick]} {
				utimer [rand 10] "massop $channame"
			}
		}
		"massopall" {
			set channame [lindex $args 1]
			putbots "botnet $args $handle"
			putbotlog "massopping on $channame using $bot_count bots "
			putbotdcc $idx "massopping all on $channame using $bot_count bots "
			if {[control_mybot $botnick]} {
				utimer [rand 10] "massopall $channame"
			}
		}
		"massvoice" {
			set channame [lindex $args 1]
			putbots "botnet $args $handle"
			putbotlog "massvoice on $channame using $bot_count bots "
			putbotdcc $idx "massvoice on $channame using $bot_count bots "
			if {[control_mybot $botnick]} {
				utimer [rand 10] "massvoice $channame"
			}
		}
		"massdevoice" {
			set channame [lindex $args 1]
			putbots "botnet $args $handle"
			putbotlog "massdevoice on $channame using $bot_count bots "
			putbotdcc $idx "massdevoice on $channame using $bot_count bots "
			if {[control_mybot $botnick]} {
				utimer [rand 10] "massdevoice $channame"
			}
		}
		"join" {
			set channame [lindex $args 1]
			putbots "botnet $args $handle"
			putbotlog "joining $channame with $bot_count bots"
			putbotdcc $idx "joining $channame with $bot_count bots"
			if {[control_mybot $botnick]} {
				channel add $channame
			}
		}
		"chanset" {
			set channame [lindex $args 1]
			set settings [lrange $args 2 end]
			putbots "botnet $args $handle"
			putbotlog "setting $settings on $bot_count bots on channel $channame "
			putbotdcc $idx "setting $settings on $bot_count bots on channel $channame "
			if {[control_mybot $botnick]} {
				catch {eval chanset $channame $settings}
			}
		}
		"part" {
			set channame [lindex $args 1]
			putbots "botnet $args $handle"
			putbotlog "parting $channame with $bot_count bots "
			putbotdcc $idx "parting $channame with $bot_count bots "
			if {[control_mybot $botnick]} {
				catch {channel remove $channame}
			}
		}
		"save" {
			putbots "botnet $args $handle"
			putbotlog "telling $bot_count bots to save "
			putbotdcc $idx "telling $bot_count bots to save "
			if {[control_mybot $botnick]} {
				save
			}
		}
		"rehash" {
			putbots "botnet $args $handle"
			putbotlog "telling $bot_count bots to rehash "
			putbotdcc $idx "telling $bot_count bots to rehash "
			if {[control_mybot $botnick]} {
				rehash
			}
		}
		default {
			dm_help $handle $idx $args
			return
		}
	}
}
proc botnet_channels {bot cmd args} {
	set idx [lindex $args 0]
	set channels [channels]
	putbot $bot "these_chans $idx $channels"
}
proc these_chans {bot cmd args} {
	set args [lindex $args 0]
	set idx [lindex $args 0]
	set channels [lrange $args 2 end]
	putbotdcc $idx "$bot is on chans: $channels"
}
proc countbots {} {
	global bn_control botnick
	set bot_count 0
	if {$bn_control == "*"} {
		foreach s_bot [userlist b] {
			if {([islinked $s_bot]) || ([string tolower $s_bot] == [string tolower $botnick])} {
				set bot_count [expr $bot_count+1]
			}
		}
	} else {
		foreach s_bot $bn_control {
			if {([islinked $s_bot]) || ([string tolower $s_bot] == [string tolower $botnick])} {
				set bot_count [expr $bot_count+1]
			}
		}
	}
	return $bot_count
}
proc control_mybot {bot} {
	global botnick bn_control
	if {$bn_control == "*" } {
		return 1
	}
	if {[lsearch $bn_control $bot] != -1} {
		return 1
	}
	return 0
}
proc putbots {cmd args} {
	global bn_control
	if {$bn_control == "*"} {
		putallbots "$cmd $args"
		return
	} else {
		foreach s_bot $bn_control {
			if {[islinked $s_bot]} {
				putbot $s_bot "$cmd $args"
			}
		}
		return
	}
}
# }}}
# .BOTNET CONTROL {{{
proc botnet_control {idx args s_flags} {
	global bn_control local_control botnick
	set what [lindex $args 0]
	if { $what == "-all"} {
		set bn_control "*"
		putbotdcc $idx "now controling all bots"
		return 1
	} elseif {$what == "-flags"} {
		set x 0
		set bn_control ""
		foreach s_bot [userlist $s_flags] {
			if {([islinked $s_bot]) || ([string tolower $s_bot] == [string tolower $botnick])} {
				lappend bn_control $s_bot
				set x [expr $x+1]
			}
		}
		if {$bn_control == ""} {
			set bn_control "*"
			putbotdcc $idx "Illegal flag or no bots selected.  Resetting to default control"
			return 1
		}
		putbotdcc $idx "now controlling $x bots"
		return 1
	} elseif {$what == "-local"} {
		set bn_control [userlist $local_control]
		putbotdcc $idx "control set to local bots only "
		return 1
	} elseif {$what == "-list"} {
		putbotdcc $idx "currently controlling $bn_control "
		return 1
	} else {
		putdcc $idx "Usage: botnet control <-all | -flags <flags> | -local | -list>"
	}
}
# }}}
# BOTNET PROC {{{
proc botnet_proc {bot cmd args} {
	set args [lindex $args 0]
	set hand [lindex $args end]
	set blah [lindex $args 0]
	if { ![matchattr $bot b] } {
		putbotlog "\002error\002 \037::\037 unknown bot $hand@$bot asked for me to do $cmd $args (ignored)"
		return 0
	}
	switch -exact $blah {
		"takeover" {
			set channame [lindex $args 1]
			if {![validchan $channame]} {
				return 0
			}
			takeover $channame
			putbotlog "$hand@$bot asked me to takeover $channame "
		}
		"masskick" {
			set channame [lindex $args 1]
			if {![validchan $channame]} {
				return 0
			}
			utimer [rand 10] "masskick $channame"
			putbotlog "$hand@$bot asked me to masskick on $channame "
		}
		"massop" {
			set channame [lindex $args 1]
			if {![validchan $channame]} {
				return 0
			}
			utimer [rand 10] "massop $channame"
			putbotlog "$hand@$bot asked me to massop on $channame "
		}
		"massopall" {
			set channame [lindex $args 1]
			if {![validchan $channame]} {
				return 0
			}
			utimer [rand 10] "massopall $channame"
			putbotlog "$hand@$bot asked me to massop all on $channame "
		}
		"massvoice" {
			set channame [lindex $args 1]
			if {![validchan $channame]} {
				return 0
			}
			utimer [rand 10] "massvoice $channame"
			putbotlog "$hand@$bot asked me to massvoice on $channame "
		}
		"massdevoice" {
			set channame [lindex $args 1]
			if {![validchan $channame]} {
				return 0
			}
			utimer [rand 10] "massdevoice $channame"
			putbotlog "$hand@$bot asked me to massdevoice on $channame "
		}
		"join" {
			set channame [lindex $args 1]
			channel add $channame
			putbotlog "$hand@$bot asked me to join $channame "
		}
		"part" {
			set channame [lindex $args 1]
			if {![validchan $channame]} {
				return 0
			}
			catch {channel remove $channame}
			putbotlog "$hand@$bot asked me to part $channame "
		}  
		"save" {
			save
			putbotlog "$hand@$bot asked me to save"
		}  
		"rehash" {
			rehash
			putbotlog "$hand@$bot asked me to do a rehash"
		}
		"chanset" {
			set channame [lindex $args 1]
			if {![validchan $channame]} {
				return 0
			}
			set arglist [llength $args]
			set settings [lrange $args 2 [expr $arglist-2]]
			catch {eval chanset $channame $settings}
			putbotlog "$hand@$bot asked me to set $settings on $channame "
		}
	}
}
proc dcc_bots {hand idx arg} {
	global nick
	set upbots [bots]
	regsub -all " " $upbots ", " upbots
	set downbots ""
	foreach i [userlist b] {
		if {(![islinked $i]) && ([string tolower $i] != [string tolower $nick])} {
			lappend downbots $i
		}
	}
	regsub -all " " $downbots ", " downbots
	if {$upbots != ""} {
		putbotdcc $idx "Bots up: $upbots"
		putbotdcc $idx "(total: [llength $upbots])"
	} else {
		putbotdcc $idx "No bots linked"
	}
	if {$downbots != ""} {
		putbotdcc $idx "Bots down: $downbots"
		putbotdcc $idx "(total: [llength $downbots])"
	} else {
		putbotdcc $idx "All botes linked."
	}
	return 1
}
# }}}
# WHOIS: WHO ADDED USER FIELD {{{
if {![info exists whois-fields]} {
	set whois-fields ""
}
set ffound 0
foreach f2 [split ${whois-fields}] {
	if {[string tolower $f2] == [string tolower "Added"]} {
		set ffound 1
		break
	}
}
if {$ffound == 0} {
	append whois-fields " " "Added"
}
# }}}
# MSG: OP {{{
proc msg_op {nick uhost hand arg} {
	global botnick
	set pw [xindex $arg 0]
	set chan [string tolower [xindex $arg 1]]
	if {[xstrcmp $nick $botnick]} {
		return 0
	}
	if {[passwdok $hand ""]} {
		putbotdcclog "($nick!$uhost) $hand failed OP!"
		return 0
	}
	if {[passwdok $hand $pw]} {
		if {$chan != ""} {
			if {![validchan $chan] || ![onchan $botnick $chan] || ![isop $botnick $chan]} {
				putbotdcclog "($nick!$uhost) $hand failed OP!"
				return 0
			}
			if {[onchan $nick $chan] && ![isop $nick $chan] && [matchattr [nick2hand $nick $chan] (o|#o)&-d&#-d $chan]} {
				set thost [getchanhost $nick $chan]
				set trandom [bop_encrypted $thost $nick]
				putquick "MODE $chan +o-b $nick *!$nick@$trandom"
				putbotdcclog "\00307#op#\003 \002$nick\002!$uhost \00314($hand)\0003"
			}
			return 0		
		}
		foreach chan [channels] {
			set chan [string tolower $chan]
			if {[onchan $nick $chan] && ![isop $nick $chan] && [matchattr [nick2hand $nick $chan] (o|#o)&-d&#-d $chan]} {
				set thost [getchanhost $nick $chan]
				set trandom [bop_encrypted $thost $nick]
				putquick "MODE $chan +o-b $nick *!$nick@$trandom"
			}
		}
		putbotdcclog "\00307#op#\003 \002$nick\002!$uhost \00314($hand)\003"
		return 0
	}
	putbotdcclog "($nick!$uhost) $hand failed OP!"
	return 0
}
# }}}
# DCC: .+BOT {{{
proc dcc:+bot {hand idx paras} {
	set user [lindex $paras 0]
	if {[validuser $user]} {
		*dcc:+bot $hand $idx $paras
	} else {
		*dcc:+bot $hand $idx $paras
		if {[validuser $user]} {
			setuser $user xtra Added "by $hand as $user ([strftime %Y-%m-%d@%H:%M])"
			tellabout $hand $user
		}
	}
}
proc tellabout {hand user} {
	global nick notify-newusers
	foreach ppl ${notify-newusers} {
		sendnote $nick $ppl "introduced to $user by $hand"
	}
}
# }}}
# DCC: .+USER {{{
proc dcc:+user {hand idx paras} {
	set user [lindex $paras 0]
	if {[validuser $user]} {
		*dcc:+user $hand $idx $paras
	} else {
		*dcc:+user $hand $idx $paras
		if {[validuser $user]} {
			setuser $user xtra Added "by $hand as $user ([strftime %Y-%m-%d@%H:%M])"
			tellabout $hand $user
		}
	}
}
# }}}
# DCC: .ABOUT {{{
proc dcc_about {hand idx args} {
	global dmver
	putbotdcc $idx "\0037#about#\003"
	putbotdcc $idx "darkMAGE v$dmver - kyau <kyau@kyau.net>"
}
# }}}
# DCC: .ADDUSER {{{
proc dcc:adduser {hand idx paras} {
	set user [lindex $paras 1]
	if {$user == ""} {
		if {[string index $paras 0] == "!"} {
			set user [string range [lindex $paras 0] 1 end]
		} else {
			set user [lindex $paras 0]
		}
	}
	if {[validuser $user]} {
		*dcc:adduser $hand $idx $paras
	} else {
		*dcc:adduser $hand $idx $paras
		if {[validuser $user]} {
			setuser $user xtra Added "by $hand as $user ([strftime %Y-%m-%d@%H:%M])"
			tellabout $hand $user
		}
	}
}
# }}}
# DCC: .CHANNELS {{{
proc cmd_channels {hand idx args} {
	putbotdcc $idx "\0037#channels#\003"
	set chans {}
	foreach chan [channels] {
		if {![botisop $chan]} {
			#putdcc $idx "$chan"
			lappend chans "\00305$chan\003"
		} else {
			#putdcc $idx "@$chan"
		  lappend chans "$chan"
		}
	}
 	putbotdcc $idx "$chans"
}
# }}}
# DCC: .OP {{{
proc dcc_op {hand idx arg} {
	global botnick
	set nick [xindex $arg 0]
	if {$nick == ""} {
		putbotdcc $idx "\002usage:\002 op \[nickname\] \[#channel\]"
		return 0
	}
	set chan [xindex $arg 1]
	if {$chan != ""} {
		putlog "moo1"
		if {![matchattr [set hand [nick2hand $nick $chan]] o|o $chan]} { return 0 }
	} else {
		set chan {}
		set tnum 0
		foreach ichan [channels] {
			putlog "$tnum:chan:$ichan"
			if {[botisop $ichan] && [matchattr [set hand [nick2hand $nick $ichan]] o|o $ichan] && ![isop $nick $ichan]} {
				lappend chan $ichan
			}
			incr tnum
		}
		if {$chan == ""} { return 0 }
	}
	if {[llength $chan] == 1} {
		if {![onchan $nick [join $chan]]} {
			putbotdccerr $idx "$nick is not on [join $chan]."
			return 0
		}
		putlog "moo2"
		if {![isop $botnick [join $chan]]} {
			putbotdccerr $idx "I can't help you now because I'm not a chan op on [join $chan]."
			return 0
		}
		if {![matchattr [nick2hand $nick [join $chan]] o|#o [join $chan]]} {
			putbotdccerr $idx "$nick is not a channel op on [join $chan]."
			return 0
		}
		set thost [getchanhost $nick [join $chan]]
		set trandom [bop_encrypted $thost $nick]
		putquick "MODE [join $chan] +o-b $nick *!$nick@$trandom"
		return 1
	} else {
		putlog "made it!"
		foreach ichan $chan {
			if {[onchan $nick $ichan] && [isop $botnick $ichan] && [matchattr [nick2hand $nick $ichan] o|#o $ichan]} {
				set thost [getchanhost $nick $ichan]
				set trandom [bop_encrypted $thost $nick]
				putquick "MODE $ichan +o-b $nick *!$nick@$trandom"
			}
		}
		return 1
	}
}
# }}}
# DCC: .USERLIST {{{
proc dcc_userlist {hand idx arg} {
	if {[string tolower [xindex $arg 0]] == "help"} {
		putbotdcc $idx "\002\usage:\002\ userlist \[flags\] \[#channel\]"
	} else {
		if {[xindex $arg 0] != ""} {
			set flags [xindex $arg 0]
			if {[xindex $arg 1] != ""} {
				set chan [xindex $arg 1]
				if {![validchan $chan]} {
					putbotdcc $idx "ERROR: No such channel"
					return 0
				}
				if {[string match *|* $flags]} {
					set flags [xindex [split $flags |] 0]&[xindex [split $flags |] 1]
				} else {
					set flags "&$flags"
				}
				set userlist [userlist $flags $chan]
			} else {
				set userlist [userlist $flags]
			}
		} else {
			set userlist [userlist]
		}
		putbotdcc $idx "Searching..."
		set i2 0
		foreach i $userlist {
			if {[passwdok $i ""]} {
				putbotdcc $idx "!$i ([xindex [getuser $i hosts] 0]) <[chattr $i]>"
			} else {
				putbotdcc $idx "$i ([xindex [getuser $i hosts] 0]) <[chattr $i]>"
			}
			incr i2
		}
		putbotdcc $idx "Found $i2 person(s) out of [countusers] matching specified flag"
	}
	return 1
}
# }}}
# DCC: .WHOM {{{
proc dcc:whomall {hand idx arg} {
	if {$arg != "*"} {
		*dcc:whom $hand $idx $arg
		return 
	}
	putbotdcc $idx "\00315whom all\003"
	putbotdcc $idx " Nick      Chanl Bot       Idle   Away Host"
	putbotdcc $idx " --------- ----- --------- ------ ---- ------------------------------"
	foreach person [whom *] {
		set nck [lindex $person 0]
		set bot [lindex $person 1]
		set hst [lindex $person 2]
		set sts [lindex $person 3]
		set idl [lindex $person 4]
		set awy [lindex $person 5]
		set chn [lindex $person 6]
		if {$sts == "-"} {set sts " "}
		if {$chn > 99999} {set chn "local"}
		if {$chn == "-1"} {set chn "off"}
		set d [expr $idl / 1440]
		set h [expr [expr $idl % 1440] / 60]
		set m [expr [expr $idl % 1440] % 60]
		set nid "${d}d${h}h"
		if {$d == "0" && $h == "0"} {set nid "${m} min"}
		if {$d == "0" && $h != "0"} {set nid "${h}h${m}m"}
		if {[lindex $hst 1] == $bot} {set hst [lindex $hst 0]}
		if {$awy != ""} {set aws "YES"} {set aws "NO"}
		 putbotdcc $idx [format "%-10s %-5s %-9s %-6s %-4s %-1s" ${sts}$nck $chn $bot $nid $aws $hst]
	}
}
# }}}
# EVENT: DCC CHAT (MOTD) {{{
proc dcc_chat {hand idx} {
	global botnick server nick partylinelist uptime version
	dccsimul $idx ".echo off"
	putdcc $idx "\00311▄▄▄▄▄▄  ▄▄▄▄▄▄  ▄▄▄▄▄▄  ▄▄ \003\00314▄ \003\00311▄▄ ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄  ▄▄▄▄▄▄\003\00310▄ \003\00311▄▄▄▄▄▄▄\003"
	putdcc $idx "\00311,10▓▀\003 \00314▄ \003\00311,10▓█\003 \00311,10▓▀\003\00314░  \003\00311,10▓█\003 \00311,10██\003\00314░▄ \003\00311,10▓█\003 \00311,10▓▀\003\00314 ▀ \003\00311,10▓\00311,01█ \003\00311,10▓▀\003\00314░▄ \003\00311,10▓▀\003\00314░▄ \003\00311,10▓█\003 \00311,10▓▀\003\00314░  \003\00311,10▓█\003 \00311,10▓▀\003 \00310▄\003\00311▄▄▄ \003\00311,10▓▀\003\00310▄▄ \003\00311▀▀\003"
	putdcc $idx "\00311,10▒\003\00310█ \003\00314▀\003\00310▄\003\00311,10▒\003\00310█ \003\00311,10░\003\00310▓\003\00311▀▀▀\003\00311,10▒▀\003 \00311▓\003\00310▓ \003\00314▓ \003\00311,10░▀\003 \00311,10░\003\00310▓\003\00311▀▀\003\00311,10▀\003\00311,01█▄ \003\00311,10░\003\00310▓ \003\00314▓ \003\00311,10░\003\00310▓ \003\00314▓ \003\00311,10▒▀\003 \00311,10░\003\00310▓\003\00311▀▀▀\003\00311,10▒▀\003 \00311,10▒\003\00310█▄  \00311,10▒▀\003 \00311,10▒\003\00310▓▄\003\00314░ \003\00311,10▓▀\003"
	putdcc $idx "\00310▀▀▀▀▀▀\003\00314░ \003\00310▀▀ \003\00314▀ \003\00311,10░\003\00310█ ▀▀\003\00314░     \003\00310▀▀ \003\00314▀ \003\00311,10░\003\00310█ ▀▀ \003\00314▀ \003\00310▀▀ \003\00314▀ \003\00311,10░\003\00310█ ▀▀ \003\00314▀ \003\00311,10░\003\00310█ \003\00314░\003\00310▀▀▀▀▀▀  ▀▀▀▀▀▀\003"
	putdcc $idx " "
 	putdcc $idx "        Bot: \00300$botnick\003   Users: \00300[countusers]\003"
	putdcc $idx "        Server: \00300$server\003"
	putdcc $idx "        OS: \00300[exec uname -sr]\003"
	set ver [split $version " "]
 	putdcc $idx "        Running: \00300eggdrop v[lindex $ver 0] (ssl+ipv6)\003"
	putdcc $idx "        Uptime: \00300$uptime\003"
	putdcc $idx "        Channels:"
	set chans {}
	foreach chan [channels] {
		if {![botisop $chan]} {
			#putdcc $idx "$chan"
			lappend chans "\0034$chan\003"
		} else {
			#putdcc $idx "@$chan"
		  lappend chans "\00310$chan\003"
		}
	}
 	putdcc $idx "          $chans"
	putdcc $idx " "
	putdcc $idx "        Use \002\00300.help\003\002 for basic help."
	putdcc $idx "        Usr \002\00300.darkmage\003\002 for botnet help."
	if {$partylinelist == 1} {
		set tmpcount [whom 0]
		if {[llength $tmpcount] != 0} {
			putdcc $idx "        Partyline Users:"
			foreach dcclist1 [whom 0] {
				set thehand [lindex $dcclist1 0]
				if {[matchattr $thehand n]} {
					set pcw "\00304(owner)\003"
				} elseif {[matchattr $thehand m]} {
					set pcw "\00306(master)\003"
				} elseif {[matchattr $thehand o]} {
					set pcw "(op)"
				} else {
					set pcw "(user)"
				}
				putdcc $idx "          $pcw \002\00300$thehand\003\002 on \00310[lindex $dcclist1 1]\003"
			}
		}
	}
	putdcc $idx " "
}
# }}}
# EVENT: BAN {{{
proc ban:+ban {handle idx arg} {
	if {$arg == ""} {
		*dcc:+ban $handle $idx $arg
		return 0
	}
	set date [strftime %d/%m/%y]
	*dcc:+ban $handle $idx "$arg ($handle@$date)"
}
# }}}
# BOTNET: BOT WANTS OP {{{
if {$numversion < 1032500} {
	proc islinked {bot} {
		if {[lsearch -exact [string tolower [bots]] [string tolower $bot]] == -1} {return 0}
		return 1
	}
	if {$numversion < 1032400} {
		proc botonchan {chan} {
			global botnick
			if {![validchan $chan]} {
				error "illegal channel: $chan"
			} elseif {![onchan $botnick $chan]} {
				return 0
			}
			return 1
		}
	}
}
proc bop_jointmr {nick uhost hand chan} {
	global bop_asktmr bop_delay botnick numversion
	if {$nick != $botnick} {
		if {![matchattr $hand b] || ![matchattr $hand o|o $chan] || [matchattr $hand d|d $chan]} {return 0}
		set stlchan [string tolower $chan]
		if {[info exists bop_asktmr($hand:$stlchan)]} {return 0}
		set bop_asktmr($hand:$stlchan) 1
		if {!$bop_delay || [bop_lowbots $chan]} {
			utimer 5 [split "bop_askbot $hand $chan"]
		} else {
			utimer [expr [rand $bop_delay] + 5] [split "bop_askbot $hand $chan"]
		}
	} else {
		bop_setneed $chan
	}
	return 0
}
proc bop_linkop {bot via} {
	global botnet-nick
	if {$bot == ${botnet-nick} || $via == ${botnet-nick}} {
		if {![string match *bop_linkreq* [utimers]]} {
			utimer 2 bop_linkreq
		}
	}
	return 0
}
proc bop_linkreq {} {
	foreach chan [channels] {
		if {![botisop $chan]} {
			bop_reqop $chan op
		}
	}
	return
}
proc bop_reqop {chan need} {
	global bop_needi
	if {![info exists bop_needi([string tolower $chan])]} {
		bop_setneed $chan
	}
	if {$need == "op"} {
		foreach bot [chanlist $chan b] {
			if {[isop $bot $chan] && [matchattr [set hand [nick2hand $bot $chan]] o|o $chan] && [islinked $hand]} {
				putbot $hand "reqops $chan"
			}
		}
	} else {
		bop_letmein $chan $need
	}
	return 0
}
if {$bop_modeop} {
	proc bop_modeop {nick uhost hand chan mode opped} {
		global botnick
		if {$mode == "+o" && ![botisop $chan] && $nick != $botnick && $opped != $botnick && [matchattr [set obot [nick2hand $opped $chan]] b] && [matchattr $obot o|o $chan] && [islinked $obot]} {
			putbot $obot "reqops $chan"
		}
		return
	}
}
proc bop_reqtmr {frombot cmd arg} {
	global bop_asktmr bop_delay
	set chan [lindex [split $arg] 0]
	if {![validchan $chan]} {return 0}
	if {![matchattr $frombot b] || ![matchattr $frombot o|o $chan] || [matchattr $frombot d|d $chan]} {return 0}
	set stlchan [string tolower $chan]
	if {[info exists bop_asktmr($frombot:$stlchan)]} {return 0}
	set bop_asktmr($frombot:$stlchan) 1
	if {!$bop_delay || [bop_lowbots $chan]} {
		utimer 2 [split "bop_askbot $frombot $chan"]
	} else {
		utimer [expr [rand $bop_delay] + 2] [split "bop_askbot $frombot $chan"]
	}
	return 0
}
proc bop_askbot {hand chan} {
	global botnick bop_asktmr
	set stlchan [string tolower $chan]
	if {[info exists bop_asktmr($hand:$stlchan)]} {
		unset bop_asktmr($hand:$stlchan)
	}
	if {![validchan $chan] || ![botonchan $chan] || ![botisop $chan]} {return 0}
	if {![matchattr $hand b] || ![matchattr $hand o|o $chan] || [matchattr $hand d|d $chan]} {return 0}
	if {![islinked $hand]} {return 0}
	putbot $hand "doyawantops $chan $botnick"
	return 0
}
proc bop_doiwantops {frombot cmd arg} {
	global bop_log bop_maxreq bop_opreqs botname botnick
	set chan [lindex [split $arg] 0] ; set fromnick [lindex [split $arg] 1]
	if {![validchan $chan] || ![botonchan $chan] || [botisop $chan]} {return 0}
	set stlchan [string tolower $chan]
	if {$bop_maxreq && $bop_opreqs($stlchan) >= $bop_maxreq} {return 0}
	if {![onchan $fromnick $chan] || [onchansplit $fromnick $chan] || ![isop $fromnick $chan]} {return 0}
	if {![matchattr [nick2hand $fromnick $chan] o|o $chan]} {return 0}
	if {![islinked $frombot]} {return 0}
	putbot $frombot "yesiwantops $chan $botnick [string trimleft [lindex [split $botname !] 1] "~+-^="]"
	incr bop_opreqs($stlchan)
	if {$bop_maxreq} {
		bop_killutimer "bop_opreqsreset $stlchan"
		utimer 30 [split "bop_opreqsreset $stlchan"]
	}
	if {$bop_log >= 2} {
		putlog "darkMAGE: requested ops from $frombot on $chan"
	}
	return 0
}

proc bop_botwantsops {frombot cmd arg} {
	global bop_addhost bop_log bop_osync numversion strict-host
	set chan [lindex [split $arg] 0] ; set fromnick [lindex [split $arg] 1] ; set fromhost [lindex [split $arg] 2]
	if {![botonchan $chan] || ![botisop $chan]} {return 0}
	if {![onchan $fromnick $chan] || [onchansplit $fromnick $chan]} {return 0}
	if {![matchattr $frombot b] || ![matchattr $frombot o|o $chan] || [matchattr $frombot d|d $chan]} {return 0}
	if {$fromhost != "" && $fromhost != [string trimleft [getchanhost $fromnick $chan] "~+-^="]} {return 0}
	if {![matchattr [nick2hand $fromnick $chan] o|o $chan]} {
		if {$fromhost == "" || !$bop_addhost} {return 0}
		if {${strict-host} == 0} {
			set host *![string trimleft [getchanhost $fromnick $chan] "~+-^="]
		} else {
			set host *![getchanhost $fromnick $chan]
		}
		setuser $frombot HOSTS $host
		putlog "darkMAGE: added host $host to $frombot"
	}
	set trandom [bop_encrypted $fromhost $fromnick]
	if {$bop_osync} {
		if {$numversion < 1040000} {
			#putlog "moo0"
			putquick "MODE $chan +o-b $fromnick *!$frombot@$trandom"
		} else {
			#putlog "moo1"
			putquick "MODE $chan +o-b $fromnick *!$frombot@$trandom"
		}
	} else {
		if {[isop $fromnick $chan]} {return 0}
		#putlog "moo2"
		putquick "MODE $chan +o-b $fromnick *!$frombot@$trandom"
	}
	if {$bop_log >= 2} {
		if {$fromnick != $frombot} {
			putlog "darkMAGE: gave ops to $frombot (using nick $fromnick) on $chan"
		} else {
			putlog "darkMAGE: gave ops to $frombot on $chan"
		}
	}
	return 0
}
# }}}
# BOTNET: BOT WANTS IN (BAN/INVITE/KEY/LIMIT) {{{
proc bop_letmein {chan need} {
	global botname botnick bop_log bop_needk bop_needi bop_needl bop_needu
	if {[bots] == "" || [botonchan $chan]} {return 0}
	set stlchan [string tolower $chan]
	switch -exact -- $need {
		"key" {
			if {$bop_needk($stlchan)} {return 0}
			set reqlist ""
			foreach bot [bots] {
				if {![matchattr $bot b] || ![matchattr $bot o|o $chan]} {continue}
				putbot $bot "wantkey $chan $botnick"
				lappend reqlist $bot
			}
			if {$bop_log >= 1 && $reqlist != ""} {
				regsub -all -- " " [join $reqlist] ", " reqlist
				putlog "darkMAGE: requested key for $chan from $reqlist"
			}
			set bop_needk($stlchan) 1
			utimer 30 [split "set bop_needk($stlchan) 0"]
		}
		"invite" {
			if {$bop_needi($stlchan)} {return 0}
			set reqlist ""
			foreach bot [bots] {
				if {![matchattr $bot b] || ![matchattr $bot o|o $chan]} {continue}
				if {$botname != ""} {
					putbot $bot "wantinvite $chan $botnick [string trimleft [lindex [split $botname !] 1] "~+-^="]"
				} else {
					putbot $bot "wantinvite $chan $botnick"
				}
				lappend reqlist $bot
			}
			if {$bop_log >= 1 && $reqlist != ""} {
				regsub -all -- " " [join $reqlist] ", " reqlist
				putlog "darkMAGE: requested invite to $chan from $reqlist"
			}
			set bop_needi($stlchan) 1
			utimer 30 [split "set bop_needi($stlchan) 0"]
		}
		"limit" {
			if {$bop_needl($stlchan)} {return 0}
			set reqlist ""
			foreach bot [bots] {
				if {![matchattr $bot b] || ![matchattr $bot o|o $chan]} {continue}
				putbot $bot "wantlimit $chan $botnick"
				lappend reqlist $bot
			}
			if {$bop_log >= 1 && $reqlist != ""} {
				regsub -all -- " " [join $reqlist] ", " reqlist
				putlog "darkMAGE: requested limit raise on $chan from $reqlist"
			}
			set bop_needl($stlchan) 1
			utimer 30 [split "set bop_needl($stlchan) 0"]
		}
		"unban" {
			if {$bop_needu($stlchan)} {return 0}
			set reqlist ""
			foreach bot [bots] {
				if {![matchattr $bot b] || ![matchattr $bot o|o $chan]} {continue}
				putbot $bot "wantunban $chan $botnick $botname"
				lappend reqlist $bot
			}
			if {$bop_log >= 1 && $reqlist != ""} {
				regsub -all -- " " [join $reqlist] ", " reqlist
				putlog "darkMAGE: requested unban on $chan from $reqlist"
			}
			set bop_needu($stlchan) 1
			utimer 30 [split "set bop_needu($stlchan) 0"]
		}
	}
	return 0
}

proc bop_botwantsin {frombot cmd arg} {
	global bop_icheck bop_log bop_who
	set chan [lindex [split $arg] 0]
	if {![validchan $chan] || ![botisop $chan]} {return 0}
	if {![matchattr $frombot b] || ![matchattr $frombot fo|fo $chan]} {return 0}
	set fromhost [lindex [split $arg] 2]
	switch -exact -- $cmd {
		"wantkey" {
			if {[string match *k* [lindex [split [getchanmode $chan]] 0]]} {
				putbot $frombot "thekey $chan [lindex [split [getchanmode $chan]] 1]"
				if {$bop_log >= 1} {
					putlog "darkMAGE: gave key for $chan to $frombot"
				}
			}
		}
		"wantinvite" {
			set fromnick [lindex [split $arg] 1]
			if {$bop_icheck && $fromhost != ""} {
				if {![info exists bop_who($fromnick)]} {
					set bop_who($fromnick) "$chan $frombot $fromhost"
					utimer 60 [split "bop_whounset $fromnick"]
				}
				putserv "WHO $fromnick"
			} else {
				putserv "INVITE $fromnick $chan"
				if {$bop_log >= 1} {
					if {$fromnick != $frombot} {
						putlog "darkMAGE: invited $frombot (using nick $fromnick) to $chan"
					} else {
						putlog "darkMAGE: invited $frombot to $chan"
					}
				}
			}
		}
		"wantlimit" {
			pushmode $chan +l [expr [llength [chanlist $chan]] + 1]
			if {$bop_log >= 1} {
				putlog "darkMAGE: raised limit on $chan as requested by $frombot"
			}
		}
		"wantunban" {
			foreach ban [chanbans $chan] {
				if {[string match [string tolower [lindex $ban 0]] [string tolower $fromhost]]} {
					pushmode $chan -b [lindex $ban 0]
					if {$bop_log >= 1} {
						putlog "darkMAGE: unbanned $frombot on $chan"
					}
				}
			}
		}
	}
	return 0
}
proc bop_who {from keyword arg} {
	global bop_log bop_who
	set fromnick [lindex [split $arg] 5]
	if {[info exists bop_who($fromnick)]} {
		set chan [lindex [split $bop_who($fromnick)] 0] ; set frombot [lindex [split $bop_who($fromnick)] 1] ; set fromhost [lindex [split $bop_who($fromnick)] 2]
		unset bop_who($fromnick)
		if {$fromhost == [string trimleft [lindex [split $arg] 2]@[lindex [split $arg] 3] "~+-^="]} {
			putserv "INVITE $fromnick $chan"
			if {$bop_log >= 1} {
				if {$fromnick != $frombot} {
					putlog "darkMAGE: invited $frombot (using nick $fromnick) to $chan"
				} else {
					putlog "darkMAGE: invited $frombot to $chan"
				}
			}
		}
	}
	return 0
}
proc bop_whounset {fromnick} {
	global bop_who
	if {[info exists bop_who($fromnick)]} {
		unset bop_who($fromnick)
	}
	return
}
proc bop_joinkey {frombot cmd arg} {
	global bop_kjoin
	set chan [lindex [split $arg] 0] ; set stlchan [string tolower $chan]
	if {[botonchan $chan] || $bop_kjoin($stlchan)} {return 0}
	putserv "JOIN $chan [lindex [split $arg] 1]"
	set bop_kjoin($stlchan) 1
	utimer 10 [split "set bop_kjoin($stlchan) 0"]
	return 0
}
proc bop_lowbots {chan} {
	global botnick
	set bots 1
	foreach bot [chanlist $chan b] {
		if {$bot != $botnick && [isop $bot $chan]} {
			incr bots
		}
	}
	if {$bots < 3} {return 1}
	return 0
}
proc bop_opreqsreset {stlchan} {
	global bop_opreqs
	set bop_opreqs($stlchan) 0
	return
}
proc bop_setneed {chan} {
	global bop_kjoin bop_needk bop_needi bop_needl bop_needu bop_opreqs numversion
	set stlchan [string tolower $chan]
	set bop_opreqs($stlchan) 0 ; set bop_kjoin($stlchan) 0
	set bop_needk($stlchan) 0 ; set bop_needi($stlchan) 0
	set bop_needl($stlchan) 0 ; set bop_needu($stlchan) 0
	if {$numversion < 1060000} {
		channel set $chan need-op [split "bop_reqop $chan op"]
		channel set $chan need-key [split "bop_letmein $chan key"]
		channel set $chan need-invite [split "bop_letmein $chan invite"]
		channel set $chan need-limit [split "bop_letmein $chan limit"]
		channel set $chan need-unban [split "bop_letmein $chan unban"]
	}
	return
}
proc bop_unsetneed {nick uhost hand chan {msg ""}} {
	global bop_kjoin bop_needk bop_needi bop_needl bop_needu bop_opreqs botnick
	if {$nick == $botnick && ![validchan $chan]} {
		set stlchan [string tolower $chan]
		catch {unset bop_opreqs($stlchan)} ; catch {unset bop_kjoin($stlchan)}
		catch {unset bop_needk($stlchan)} ; catch {unset bop_needi($stlchan)}
		catch {unset bop_needl($stlchan)} ; catch {unset bop_needu($stlchan)}
	}
	return 0
}
proc bop_clearneeds {} {
	foreach chan [channels] {
		channel set $chan need-op ""
		channel set $chan need-invite ""
		channel set $chan need-key ""
		channel set $chan need-limit ""
		channel set $chan need-unban ""
	}
	bop_settimer
	return
}
proc bop_settimer {} {
	foreach chan [channels] {
		bop_setneed $chan
	}
	if {![string match *bop_settimer* [timers]]} {
		timer 5 bop_settimer
	}
	return 0
}
proc bop_killutimer {cmd} {
	set n 0
	regsub -all -- {\[} $cmd {\[} cmd ; regsub -all -- {\]} $cmd {\]} cmd
	foreach tmr [utimers] {
		if {[string match $cmd [join [lindex $tmr 1]]]} {
			killutimer [lindex $tmr 2]
			incr n
		}
	}
	return $n
}
if {$numversion >= 1060000} {
	bind need - * bop_reqop
}
utimer 2 bop_clearneeds
bind mode - * bop_modeop
if {!$bop_modeop} {unbind mode - * bop_modeop}
bind link - * bop_linkop
if {!$bop_linkop} {unbind link - * bop_linkop}
bind bot - doyawantops bop_doiwantops
bind bot - yesiwantops bop_botwantsops
bind bot - reqops bop_reqtmr
bind bot - wantkey bop_botwantsin
bind bot - wantinvite bop_botwantsin
bind bot - wantlimit bop_botwantsin
bind bot - wantunban bop_botwantsin
bind bot - thekey bop_joinkey
bind join - * bop_jointmr
bind part - * bop_unsetneed
bind raw - 352 bop_who
# }}}
# ENCRYPTED OP: VERIFY {{{
proc encrypted_opverify {from key text} {
	global botnick bop_opkeys
	set chan [xindex $text 0]
	set modes [string tolower [xindex $text 1]]
	set opnick [lindex [split $from "!"] 0]
	set text [xrange $text 2 end]
	set nick [lindex $text 0]
	if {![string match "*+o*" $modes]} { return 0 }
	if {([string index $chan 0] != "#") && ([string index $chan 0] != "&") && ([string index $chan 0] != "!")} {
		return 0
	}
	if {$modes == "+o-b"} {
		set thost [getchanhost $nick $chan]
		set trandom [lindex [bop_encrypted $thost $nick] 0]
		set hash [lindex [split $text "@"] 1]
		#putlog "\00306DEBUG:\003 hash:{$hash}"
		#putlog "\00306DEBUG:\003 checked:{$trandom}"
		if {$trandom == $hash} {
			putbotdcclog "OP Hash: \00315$hash\003\00309  \003"
		} else {
			putbotdcclog "OP Hash: \00315$hash\003\00304  \003"
			putquick "MODE $chan -oo-b $nick $opnick *!$botnick@ERR_INVALID_HASH"
		}
	}
}
# }}}
# ANTIIDLE {{{
set idle.1 10
set idle.w billgates:)
set idle.m "."
if {![info exists idle.l]} {
	global idle.w idle.m idle.1
	set idle.l 0
	timer ${idle.1} {idle.a}
}
proc idle.a {} {
	global idle.w idle.m idle.1
	putserv "PRIVMSG ${idle.w} ${idle.m}"
	putserv "PRIVMSG [lindex ${idle.w} 0] :\001PING [unixtime]\001"
	timer ${idle.1} {idle.a}
}
# }}}
# PARTYLINE AUTOAWAY {{{
set pl_auto_away(time) 10
set pl_auto_away(msg) "auto away after $pl_auto_away(time) minutes. (since [ctime [unixtime]])"
set pl_auto_away(active) 1
proc dcc:autoaway {h idx var} {
	global pl_auto_away
	set var2 [lindex $var 1];set var [string tolower [lindex $var 0]]
	if {$var=="on"} {if {$pl_auto_away(active)} {putdcc $idx "Auto Away is already ON"; return 0} {set pl_auto_away(active) 1;putdcc $idx "Auto Away enabeled.";timer 1 party:autoaway;return 1} }
	if {$var=="off"} {if {!$pl_auto_away(active)} {putdcc $idx "Auto Away is already OFF"; return 0} {set pl_auto_away(active) 0;putdcc $idx "Auto Away disabeled.";foreach t [timers] {if {[lindex $t 1]=="party:autoaway"} {killtimer [lindex $t 2]} };return 1} }
	if {$var==""} {if {$pl_auto_away(active)} {putdcc $idx "Auto Away currently ON"} {putdcc $idx "Auto Away currently OFF"};return 1}
	putdcc $idx "Usage: autoaway <on/off>";return 0
}
proc party:autoaway {} {
	global pl_auto_away
	if {!$pl_auto_away(active)} {return 0}
	foreach a [dcclist] {
		if {([lindex $a 3] == "CHAT") && ([getdccaway [lindex $a 0]] == "") && ([expr [getdccidle [lindex $a 0]].0 / 60] > $pl_auto_away(time))} {
			setdccaway [lindex $a 0] "$pl_auto_away(msg)"
		}
	}
	timer 1 party:autoaway
}
foreach t [timers] {if {[lindex $t 1]=="party:autoaway"} {killtimer [lindex $t 2]} }
timer 1 party:autoaway
# }}}
# AUTO-LIMIT {{{
set dm:limit 5
set dm:timer 10
set dm:grace 2
setudef flag limit
bind mode - "* ?l" dm:user:limit:check
foreach t [timers] {if {[lindex $t 1]=="dm:checklimit"} {killtimer [lindex $t 2]} }
timer ${dm:timer} dm:checklimit
proc dm:user:limit:check {nick uhost hand chan mode victim} {
	if {![botisop $chan]} {return 0}
	if {![validchan $chan]} {return 0}
	if {[matchattr [nick2hand $nick $chan] b|b]} {return 0}
	if {[matchattr [nick2hand $nick $chan] n|n]} {return 0}
	if {[string match "*+limit*" [channel info $chan]]} {
		utimer [rand 25] "dm:dolimit $chan"
	}
	return 1
}
proc dm:dcc:dolimit {hand idx args} {
	if {($args == "") || ([llength $args] > 1)} {
		putdcc $idx "Usage: limit \[channel\]"
		return 0
	}
	if {![validchan $args]} {
		putbotdcc $idx "error: invalid channel"
		return 0
	}
	if {![botonchan $args]} {
		putbotdcc $idx "error: not on $args"
		return 0
	}
	if {![botisop $args]} {
		putbotdcc $idx "error: not opped on $args"
		return 0
	}
	if {[string match "*-limit*" [channel info $args]]} {
		putdcc $idx "$args is set to -limit.  Please type .chanset $args +limit to enable limitting."
		return 0
	}
	dm:dolimit $args
	return 1
}
proc dm:checklimit {} {
	global dm:timer
	foreach chan [channels] {
		if {[string match "*+limit*" [channel info $chan]]} {
			utimer [rand 30] "dm:dolimit $chan"
		}
	}
	foreach t [timers] {if {[lindex $t 1]=="dm:checklimit"} {killtimer [lindex $t 2]} }
	timer ${dm:timer} dm:checklimit
}
proc dm:dolimit {chan} {
	global dm:limit dm:grace
	set cusers [llength [chanlist $chan]]
	set cmodes [getchanmode $chan]
	set cflags [lindex $cmodes 0]
	if {![validchan $chan]} { return 0 }
	if {![botisop $chan]} { return 0 } 
	if {[string match "*l*" "$cflags"]} {
		if {[string match "*k*" "$cflags"]} {
			set climit [lindex $cmodes 2]
		} else {
			set climit [lindex $cmodes 1]
		}
	} else {
		set dolimit [expr $cusers+${dm:limit}]
		putquick "MODE $chan +l $dolimit"
		return 1
	}
	if {$cusers <= $climit} { set diff [expr $climit-$cusers] }
	if {$cusers > $climit} { set diff [expr $climit-$cusers] }
	if {$diff > [expr ${dm:limit}+${dm:grace}] || $diff < [expr ${dm:limit}-${dm:grace}]} {
		set dolimit [expr $cusers+${dm:limit}]
		putquick "MODE $chan +l $dolimit"
		return 1
	}
	return 1
}
# }}}
# BITCHX CLONING {{{
set bx_flood 5:30:120
set bx_away 1
set bx_jointime [unixtime]
set bx_system "FreeBSD 6.2-RELEASE"
set bx_whoami $username
set bx_machine "bitchx.nl"
set bx_version "1.1-final+"
proc bx_ctcp {nick uhost hand dest key arg} {
	global bx_flood bx_flooded bx_floodqueue bx_jointime bx_machine bx_onestack bx_system bx_version bx_whoami realname
	if {$bx_flooded} {return 1}
	incr bx_floodqueue
	utimer [lindex $bx_flood 1] {incr bx_floodqueue -1}
	if {$bx_floodqueue >= [lindex $bx_flood 0]} {
		set bx_flooded 1
		utimer [lindex $bx_flood 2] {set bx_flooded 0}
		putbotlog "bitchx: CTCP flood detected - stopped responding to CTCPs for [lindex $bx_flood 2] seconds."
		return 1
	}
	if {$bx_onestack} {return 1}
	set bx_onestack 1
	utimer 2 {set bx_onestack 0}
	switch -exact -- $key {
		"CLIENTINFO" {
			set bxcmd [string toupper $arg]
			switch -exact -- $bxcmd {
				"" {putserv "NOTICE $nick :\001CLIENTINFO SED UTC ACTION DCC CDCC BDCC XDCC VERSION CLIENTINFO USERINFO ERRMSG FINGER TIME PING ECHO INVITE WHOAMI OP OPS KICK BAN UNBAN IDENT XLINK UPTIME  :Use CLIENTINFO <COMMAND> to get more specific information\001"}
				"SED" {putserv "NOTICE $nick :\001CLIENTINFO SED contains simple_encrypted_data\001"}
				"UTC" {putserv "NOTICE $nick :\001CLIENTINFO UTC substitutes the local timezone\001"}
				"ACTION" {putserv "NOTICE $nick :\001CLIENTINFO ACTION contains action descriptions for atmosphere\001"}
				"DCC" {putserv "NOTICE $nick :\001CLIENTINFO DCC requests a direct_client_connection\001"}
				"CDCC" {putserv "NOTICE $nick :\001CLIENTINFO CDCC checks cdcc info for you\001"}
				"BDCC" {putserv "NOTICE $nick :\001CLIENTINFO BDCC checks cdcc info for you\001"}
				"XDCC" {putserv "NOTICE $nick :\001CLIENTINFO XDCC checks cdcc info for you\001"}
				"VERSION" {putserv "NOTICE $nick :\001CLIENTINFO VERSION shows client type, version and environment\001"}
				"CLIENTINFO" {putserv "NOTICE $nick :\001CLIENTINFO CLIENTINFO gives information about available CTCP commands\001"}
				"USERINFO" {putserv "NOTICE $nick :\001CLIENTINFO USERINFO returns user settable information\001"}
				"ERRMSG" {putserv "NOTICE $nick :\001CLIENTINFO ERRMSG returns error messages\001"}
				"FINGER" {putserv "NOTICE $nick :\001CLIENTINFO FINGER shows real name, login name and idle time of user\001"}
				"TIME" {putserv "NOTICE $nick :\001CLIENTINFO TIME tells you the time on the user's host\001"}
				"PING" {putserv "NOTICE $nick :\001CLIENTINFO PING returns the arguments it receives\001"}
				"ECHO" {putserv "NOTICE $nick :\001CLIENTINFO ECHO returns the arguments it receives\001"}
				"INVITE" {putserv "NOTICE $nick :\001CLIENTINFO INVITE invite to channel specified\001"}
				"WHOAMI" {putserv "NOTICE $nick :\001CLIENTINFO WHOAMI user list information\001"}
				"OP" {putserv "NOTICE $nick :\001CLIENTINFO OP ops the person if on userlist\001"}
				"OPS" {putserv "NOTICE $nick :\001CLIENTINFO OPS ops the person if on userlist\001"}
				"KICK" {putserv "NOTICE $nick :\001 CLIENTINFO KICK kick the person from channel\001"}
				"BAN" {putserv "NOTICE $nick :\001 CLIENTINFO BAN ban a damn user from channel\001"}
				"UNBAN" {putserv "NOTICE $nick :\001CLIENTINFO UNBAN unbans the person from channel\001"}
				"IDENT" {putserv "NOTICE $nick :\001CLIENTINFO IDENT change userhost of userlist\001"}
				"XLINK" {putserv "NOTICE $nick :\001CLIENTINFO XLINK x-filez rule\001"}
				"UPTIME" {putserv "NOTICE $nick :\001CLIENTINFO UPTIME my uptime\001"}
				"default" {putserv "NOTICE $nick :\001ERRMSG CLIENTINFO: $arg is not a valid function\001"}
			}
			return 1
		}
		"VERSION" {
			putserv "NOTICE $nick :\001VERSION \002BitchX-$bx_version\002 by panasync - $bx_system :\002 Keep it to yourself!\002\001"
			return 1
		}
		"USERINFO" {
			putserv "NOTICE $nick :\001USERINFO \001"
			return 1
		}
		"FINGER" {
			putserv "NOTICE $nick :\001FINGER $realname ($bx_whoami@$bx_machine) Idle [expr [unixtime] - $bx_jointime] seconds\001"
			return 1
		}
		"PING" {
			putserv "NOTICE $nick :\001PING $arg\001"
			return 1
		}
		"ECHO" {
			if {[validchan $dest]} {return 1}
			putserv "NOTICE $nick :\001ECHO [string range $arg 0 59]\001"
			return 1
		}
		"ERRMSG" {
			if {[validchan $dest]} {return 1}
			putserv "NOTICE $nick :\001ERRMSG [string range $arg 0 59]\001"
			return 1
		}
		"INVITE" {
			if {(($arg == "") || ([validchan $dest]))} {return 1}
			set chanarg [lindex [split $arg] 0]
			if {((($bx_version == "1.0c18") && ([string trim [string index $chanarg 0] "#+&"] == "")) || (($bx_version == "1.0c18+") && ([string trim [string index $chanarg 0] "#+&!"] == ""))|| (($bx_version == "1.1-final+") && ([string trim [string index $chanarg 0] "#+&!"] == "")))} {
				if {[validchan $chanarg]} {
					putserv "NOTICE $nick :\002BitchX\002: Access Denied"
				} else {
					putserv "NOTICE $nick :\002BitchX\002: I'm not on that channel"
				}
			}
			return 1
		}
		"WHOAMI" {
			if {[validchan $dest]} {return 1}
			putserv "NOTICE $nick :\002BitchX\002: Access Denied"
			return 1
		}
		"OP" -
		"OPS" {
			if {(($arg == "") || ([validchan $dest]))} {return 1}
			putserv "NOTICE $nick :\002BitchX\002: I'm not on [lindex [split $arg] 0], or I'm not opped"
			return 1
		}
		"UNBAN" {
			if {(($arg == "") || ([validchan $dest]))} {return 1}
			if {[validchan [lindex [split $arg] 0]]} {
				putserv "NOTICE $nick :\002BitchX\002: Access Denied"
			} else {
				putserv "NOTICE $nick :\002BitchX\002: I'm not on that channel"
			}
			return 1
		}
	}
	return 0
}
proc bx_serverjoin {from keyword arg} {
	global botnick bx_jointime bx_isaway
	set bx_jointime [unixtime]
	set bx_isaway 0
	return 0
}
proc bx_away {} {
	global bx_jointime bx_isaway
	if {!$bx_isaway} {
		puthelp "AWAY :is away: (Auto-Away after 10 mins) \[\002BX\002-MsgLog [lindex {On Off} [rand 2]]\]"
		set bx_isaway 1
	} else {
		puthelp "AWAY"
		set bx_isaway 0
		set bx_jointime [unixtime]
	}
	if {![string match *bx_away* [timers]]} {
		timer [expr [rand 300] + 10] bx_away
	}
	return 0
}
proc bx_dccbitchx {hand idx arg} {
	global bx_away bx_flood bx_isaway bx_version dmver
	putcmdlog "#$hand# bitchx"
	putidx $idx "Currently simulating: BitchX-$bx_version"
	if {[string match *bx_away* [timers]]} {
		if {$bx_isaway} {
			putidx $idx "- simulating away mode (currently set away)"
		} else {
			putidx $idx "- simulating away mode (currently not away)"
		}
	} else {
		putidx $idx "- not simulating away mode."
	}
	putidx $idx "- flood is [lindex $bx_flood 0] ctcps in [lindex $bx_flood 1] seconds (disable for [lindex $bx_flood 2] seconds)."
	return 0
}
set bx_flood [split $bx_flood :]
if {![info exists bx_flooded]} {
	set bx_flooded 0
}
if {![info exists bx_floodqueue]} {
	set bx_floodqueue 0
}
if {![info exists bx_onestack]} {
	set bx_onestack 0
}
if {![info exists bx_version]} {
	set bx_version [lindex {1.0c18} [rand 2]]
}
catch {set bx_system "FreeBSD 6.2-RELEASE"}
catch {set bx_whoami [exec id -un]}
catch {set bx_machine "bitchx.nl"}
if {$bx_away} {
	if {![info exists bx_isaway]} {
		set bx_isaway 0
	}
	if {![string match *bx_away* [timers]]} {
		timer [expr [rand 300] + 10] bx_away
	}
}
if {$numversion >= 1032500} {
	set ctcp-mode 0
}
# }}}

# vim: ft=tcl ts=2 sw=2 noet :
