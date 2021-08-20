# CPU usage monitor

## TL;DR

* shows CPU usage percentage
* needs systemd (kinda)
* made for i3blocks

# Description

Intended for use on systemd systems. Maybe uncomment line 9 and comment out
line 10 if you're not using systemd. (At the expense of a ridiculously slim
chance of a hypothetical symlink attack)

This tool will output the CPU usage percentage to stdout and then exit. The
first run will produce the output "nan%" but the rest will be fine. Designed
for i3blocks as a drop-in replacement for the existing script. The existing one
lingers around for a short moment and shows CPU usage between program start and
finish, but this one shows CPU usage between invocations instead, which means
that all you need to do to change the resolution in i3blocks is to change the
i3blocks "interval" as with any other program.

This program outputs the usage since last invocation, so if this tool is being
invoked by multiple programs, the output may apply to an unacceptably short
period of time.

# How to build

1. install dune (the ocaml build tool)
2. `dune build`
