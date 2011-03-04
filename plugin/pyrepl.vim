" =======================================================================
" File:        pyrepl.vim
" Version:     0.1.2
" Description: Vim plugin that provides a Python REPL inside a buffer.
" Maintainer:  Bogdan Popa <popa.bogdanp@gmail.com>
" License:     Copyright (C) 2011 Bogdan Popa
"
"              Permission is hereby granted, free of charge, to any
"              person obtaining a copy of this software and associated
"              documentation files (the "Software"), to deal in
"              the Software without restriction, including without
"              limitation the rights to use, copy, modify, merge,
"              publish, distribute, sublicense, and/or sell copies
"              of the Software, and to permit persons to whom the
"              Software is furnished to do so, subject to the following
"              conditions:
"
"              The above copyright notice and this permission notice
"              shall be included in all copies or substantial portions
"              of the Software.
"
"              THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
"              ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
"              TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
"              PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
"              THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
"              DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
"              CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
"              CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
"              IN THE SOFTWARE.
" ======================================================================

" Exit if already loaded or compatible mode is set. {{{
if exists("g:pyrepl_version") || &cp
    finish
endif
" }}}

" Version number
let g:pyrepl_version = "0.1.2"

" Check for +python. {{{
if !has("python")
    echo("Error: PyREPL requires vim compiled with +python.")
endif
" }}}

" Main code in Python. {{{
python <<EOF
import cStringIO
import os
import sys
import traceback
import vim

class PyREPL(object):
    def __init__(self):
        self.locals_ = {}
        self.block = ""
        self.in_block = []
    
    def redirect_stdout(self):
        self.old_stdout = sys.stdout
        sys.stdout = self.stdout = cStringIO.StringIO()

    def restore_stdout(self):
        sys.stdout = self.old_stdout

    def eval(self, string, mode="single"):
        """Compiles then evals a given string of code and redirects the
        output to the current buffer."""
        vim.command("normal jdG$")
        try:
            eval(compile(string, "<string>", mode), self.locals_, self.locals_)
        except:
            for i, line in enumerate(traceback.format_exc().splitlines()):
                # Skip over the first line of the traceback since it will
                # always refer to this file and we don't want that.
                if i == 1:
                    continue
                vim.current.buffer.append(line)
        else:
            value = self.stdout.getvalue()
            for line in self.stdout.getvalue().splitlines():
                vim.current.buffer.append(line)
        vim.command("normal Go")

    def count_char(self, line, char):
        """Counts the number of occurences of char from the beginning of
        the line to the first non-char character in the line."""
        count = 0
        for i, c in enumerate(line):
            if c != char:
                break
            count += 1
        return count

    def get_level(self, line):
        "Returns the level of indentation of a given line."
        if line[0] == " ":
            return self.count_char(line, " ")
        elif line[0] == "\t":
            return self.count_char(line, "\t")
        return 0

    def end_of_block(self, line):
        "Checks if the end of a code block was reached."
        if not line:
            return True
        try:
            last_line = self.block.splitlines()[-1]
        except IndexError:
            return False
        return self.get_level(last_line) > self.get_level(line)

    def read_block(self, line):
        "Reads a block to a string line by line."
        try:
            lastc = line[-1]
        except IndexError:
            lastc = None
        if lastc in (":", "\\"):
            self.in_block.append(True)
        if self.in_block and self.end_of_block(line):
            self.in_block.pop()
            if not self.in_block:
                self.eval(self.block, "exec")
                self.block = ""
                return False
        if lastc in (":", "\\") or self.in_block:
            self.block += "\n{}".format(line)
            vim.command("normal jdG")
            vim.command("normal! oI... ")
            return True

    def readline(self):
        "Parses the current line for evaluation."
        self.redirect_stdout()
        if not os.getcwd() in sys.path:
            sys.path.append(os.getcwd())
        line = vim.current.line[4:].rstrip()
        if not self.read_block(line) and line:
            self.eval(line)
        self.restore_stdout()

pyrepl = PyREPL()
EOF
" }}}

" Public interface. {{{
if !hasmapto("<plug>ToggleREPL")
    map <unique><leader>r :call <SID>ToggleREPL()<CR>
endif

fun! s:ToggleREPL()
    if exists("s:repl_started")
        call s:StopREPL()
        unlet! s:repl_started
    else
        call s:StartREPL()
        let s:repl_started = 1
    endif
endfun

fun! s:StartREPL()
    enew
    set ft=python
    map <buffer><silent>o o>>> 
    map <buffer><silent>O O>>> 
    map <buffer><silent><CR> :python pyrepl.readline()<CR>
    imap <buffer><silent><CR> :python pyrepl.readline()<CR>G
    normal ggdGi>>> 
    " Disable autoindenting in the repl buffer
    setl noai nocin nosi inde=
    echo("PyREPL started.")
endfun

fun! s:StopREPL()
    map <buffer><silent>o o
    map <buffer><silent>O O
    map <buffer><silent><CR> <CR>
    imap <buffer><silent><CR> <CR>
    echo("PyREPL stopped.")
endfun
" }}}

" vim:fdm=marker
