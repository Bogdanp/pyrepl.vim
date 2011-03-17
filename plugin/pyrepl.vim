" =======================================================================
" File:        pyrepl.vim
" Version:     0.1.4
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

" Version number
let g:pyrepl_version = "0.1.3"
" }}}
" Check for +python. {{{
if !has("python")
    echo("Error: PyREPL requires vim compiled with +python.")
    finish
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
        self.block = []
        self.in_block = False
    
    def redirect_stdout(self):
        self.old_stdout = sys.stdout
        sys.stdout = self.stdout = cStringIO.StringIO()

    def restore_stdout(self):
        sys.stdout = self.old_stdout

    def update_path(self):
        if os.getcwd() not in sys.path:
            sys.path.append(os.getcwd())

    def reload_module(self):
        "Asks for the name of a module and tries to reload it."
        self.clear_lines()
        self.insert_prompt()
        vim.command("normal! i {0} = reload({0})".format(
            vim.eval("input('Module to reload: ')")
        ))
        self.read_line()

    def eval(self, string, mode="single"):
        """Compiles then evals a given string of code and redirects the
        output to the current buffer."""
        self.clear_lines()
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
        self.insert_prompt()

    def count_char(self, line, char):
        """Counts the number of occurences of char from the beginning of
        the line to the first non-char character in the line."""
        count = 0
        for i, c in enumerate(line):
            if c != char:
                break
            count += 1
        return count

    def clear_lines(self):
        "Deletes all the lines below the current one."
        vim.command("normal! jdG")

    def strip_line(self, line):
        "Strips the line of trailing whitespace."
        if self.count_char(line, " ") != len(line):
            return line.rstrip()
        return line

    def insert_prompt(self, block=False):
        "Inserts a prompt at the end of the buffer."
        vim.current.buffer.append(
            "... " if block else ">>> "
        )
        vim.command("normal! G$")

    def read_block(self, line):
        "Reads a block to a string line by line."
        try:
            if line[-1] in (":", "\\")\
            or line.startswith("@"):
                self.in_block = True
        except IndexError:
            pass
        if self.in_block:
            if not line:
                self.eval("\n".join(self.block), "exec")
                self.block = []
                self.in_block = False
                return False
            self.block.append(line)
            self.clear_lines()
            self.insert_prompt(True)
            return True
        return False

    def read_line(self):
        "Parses the current line for evaluation."
        self.redirect_stdout()
        self.update_path()
        line = self.strip_line(vim.current.line[4:])
        if not self.read_block(line) and line:
            self.eval(line)
        self.restore_stdout()

pyrepl = PyREPL()
EOF
" }}}
" Public interface. {{{
if !hasmapto("<SID>ToggleREPL")
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
    setl ft=python
    setl noai nocin nosi inde=
    map  <buffer><leader>R :python pyrepl.reload_module()<CR>
    map  <buffer><silent><CR> :python pyrepl.read_line()<CR>$
    imap <buffer><silent><CR> :python pyrepl.read_line()<CR>$
    normal! i>>> $
    echo("PyREPL started.")
endfun

fun! s:StopREPL()
    map  <buffer><silent><CR> <CR>
    imap <buffer><silent><CR> <CR>
    echo("PyREPL stopped.")
endfun

" Expose the Toggle function publicly.
command! -nargs=0 PyREPLToggle call s:ToggleREPL()
" }}}

" vim:fdm=marker
