# PyREPL

VIM plugin that allows you to run a Python REPL inside a VIM buffer.

# Preview

Screenshot:

![Version 0.2.1](http://farm7.static.flickr.com/6001/5934187654_5dd8e5ca28_z.jpg)

[Videos](http://www.youtube.com/user/nadgobp#p/u).

# Installation

Use [pathogen](https://github.com/tpope/vim-pathogen) and clone this
repository into your `~/.vim/bundle` directory or copy the `plugin`
folder to `~/.vim` and you're set.

# Usage

Inside any buffer use `:PyREPLToggle` or `\r` to toggle the REPL on or
off. Toggling it on will create a new empty buffer every single time.
Toggling the REPL off will _not_ close the buffer.

If you're working on a Python file and would like to evaluate it inside
the REPL you can run `:PyREPLEvalFile` on the buffer in which that file
is open.

# Requirements

* VIM 7.0+ compiled with +python
* Python 2.6+
