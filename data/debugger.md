# Debugger

## Introduction

Starting with eXist-db release 1.4 the database provides an facility to debug xquery code on the server. This document descibes how to build this extension, and how to configure your editor to work with the extension.

## Compile

The following steps are required to enable the debugger interface: Enable the debugger in `$EXIST_HOME/extensions/local.build.properties`: by adding *include.feature.debugger = true*. Create the document if does not exist. Download the required jar files. Recompile eXist-db: build.sh

## Setup your editor

Currently two editors can use the debugger interface: Emacs and VIM.

### Emacs

First you need to install [geben](http://code.google.com/p/geben-on-emacs/). When installed you can start geben with "Meta-x geben"

Run your XQuery script in the debug mode: `http://www.example.com/script.xql?XDEBUG_SESSION_START` or you can use the [Xdebug Helper](https://addons.mozilla.org/en-US/firefox/addon/3960) add-on for Firefox.

If every thing was done correct you should see `script.xql`. Available commands are:

spc  
step into/step over

i  
step into

o  
step over

r  
step out

b  
set a breakpoint at a line

u  
unset a breakpoint at a line

g  
run

q  
stop

### VIM

To debug with vim you have to install the [remote debugger interface](http://www.vim.org/scripts/script.php?script_id=1152) for the [DBGp](http://xdebug.org/docs-dbgp.php) protocol. In the editor you can press &lt;F5&gt; and browse xquery file in debug mode within 5 seconds
