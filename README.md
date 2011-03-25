PyREPL
======

PyREPL is a Vim plugin that provides a way to run something similar to a
Python REPL inside a Vim buffer.

Preview
=======

Screenshot:

<a href="http://www.flickr.com/photos/22536064@N03/5508894391/" title="PyREPL.vim 0.1.2 screenshot by popa.bogdanp, on Flickr"><img src="http://farm6.static.flickr.com/5213/5508894391_e96d256550_z.jpg" width="640" height="400" alt="PyREPL.vim 0.1.2 screenshot" /></a>

Screencasts:

[http://www.youtube.com/user/nadgobp#p/u](http://www.youtube.com/user/nadgobp#p/u)

Installation
============

Use [pathogen](https://github.com/tpope/vim-pathogen) and clone this
repo to your `~/.vim/bundle` directory or copy the `plugin` folder to
`~/.vim` and you're set.

Usage
=====

Inside any buffer use `\r` to toggle the REPL on or off. Toggling it on
will create a new empty buffer every single time.

Requirements
============

* VIM 7.0+ compiled with +python
* Python 2.6+

Todo
====

    [*] Make the thing work with blocks.
    [*] Add support for nested blocks.
    [*] Add support for decorators.
    [*] Add support for multiline strings.
