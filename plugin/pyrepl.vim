" =======================================================================
" File:        pyrepl.vim
" Version:     0.2.1
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
if exists("g:pyrepl_loaded") || &cp || !has("python")
    finish
endif
let g:pyrepl_loaded = 1
" }}}
" Main code in Python. {{{
python <<EOF
import cStringIO
import os
import re
import sys
import traceback
import vim

class PyREPL(object):
    def __init__(self):
        self.locals_ = {}
        self.block = []
        self.in_block = False
        self.string_block = False
        self.tq_literal = None
    
    def redirect_stdout(self):
        self.old_stdout = sys.stdout
        sys.stdout = self.stdout = cStringIO.StringIO()

    def restore_stdout(self):
        sys.stdout = self.old_stdout

    def count_char(self, line, char):
        """Counts the number of occurences of char at the beginning of
        the line."""
        count = 0
        for i, c in enumerate(line):
            if c != char:
                break
            count += 1
        return count

    def clear_lines(self):
        "Deletes all the lines below the current one."
        vim.command("normal! jdG")

    def duplicate_line(self):
        "Copies the current line to the end of the buffer."
        vim.command("normal! yyGp")

    def get_tq_literal(self, string):
        "Returns the 'type' of the first triple-quote literal in string."
        sq_pos = string.find("'''")
        dq_pos = string.find('"""')
        if sq_pos < dq_pos and sq_pos != -1:
            return "'''"
        elif dq_pos != -1:
            return '"""'
        return None

    def has_tq_literal(self, string, match=False):
        "Returns True if string contains a triple-quote literal."
        if match:
            return self.tq_literal in string
        return '"""' in string or "'''" in string

    def match_indentation(self):
        try:
            previous_line = self.block[-1]
            if not previous_line: return ""
        except IndexError:
            return ""
        indent_level = self.count_char(previous_line, " ")
        if previous_line == " " * indent_level:
            return " " * (indent_level - 1)
        elif previous_line[-1] == ":":
            return "{0}    ".format(" " * indent_level)
        else:
            return " " * indent_level

    def insert_prompt(self, block=False):
        "Inserts a prompt at the end of the buffer."
        if block:
            vim.current.buffer.append(
                "... {0} ".format(self.match_indentation())
            )
        else:
            vim.current.buffer.append(">>>  ")
        vim.command("normal! G$")
        vim.command("startinsert")

    def reload_module(self):
        "Asks for the name of a module and tries to reload it."
        if vim.current.line not in (">>>  ", "...  "):
            self.clear_lines()
            self.insert_prompt()
            vim.command("normal! i{0} = reload({0})".format(
                vim.eval("input('Module to reload: ')")
            ))
        else:
            vim.command("normal! a{0} = reload({0})".format(
                vim.eval("input('Module to reload: ')")
            ))
        self.read_line()

    def is_whitespace(self, string):
        "Returns true if the string is comprised by spaces."
        return self.count_char(string, " ") == len(string)

    def strip_line(self, line):
        """Strips the line of its prompt and any trailing whitespace
        there might be."""
        line = re.sub(r"^(>>>|\.\.\.)\s?", "", line)
        if self.is_whitespace(line) and self.in_block:
            return line
        return line.rstrip()

    def update_path(self):
        if os.getcwd() not in sys.path:
            sys.path.append(os.getcwd())

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

    def eval_block(self):
        "Evaluates the current block."
        self.eval("\n".join(self.block), "exec")
        self.block = []
        self.in_block = False
        self.string_block = False
        self.tq_literal = None

    def eval_file(self, filename):
        "Evaluates the file at the given path."
        try:
            with open(filename) as file_:
                self.redirect_stdout()
                self.eval(file_.read(), "exec")
                self.restore_stdout()
        except IOError, e:
            pass

    def block_append(self, line="", prompt=True):
        "Appends a line to the current block."
        self.block.append(line)
        self.clear_lines()
        if prompt:
            self.insert_prompt(True)

    def read_block(self, line):
        "Reads a block of code to a string line by line."
        try:
            if line[-1] in (":", "\\")\
            or line.startswith("@"):
                self.in_block = True
            if not self.in_block\
            and not self.string_block\
            and self.has_tq_literal(line):
                self.tq_literal = self.get_tq_literal(line)
                self.string_block = True
                self.in_block = True
                self.block_append(line)
                return True
        except IndexError:
            pass
        if self.string_block:
            if self.has_tq_literal(line, True):
                self.block_append(line, False)
                self.eval_block()
            else:
                self.block_append()
            return True
        if self.in_block:
            if line and line != " ":
                self.block_append(line)
            else:
                self.eval_block()
            return True
        return False

    def read_line(self):
        "Parses the current line for evaluation."
        self.redirect_stdout()
        self.update_path()
        line = self.strip_line(vim.current.line)
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
    setl buftype=nofile
    setl ft=python
    setl noai nocin nosi inde=
    map  <buffer><leader>R :python pyrepl.reload_module()<CR>
    map  <buffer><silent><S-CR> :python pyrepl.duplicate_line()<CR>$
    imap <buffer><silent><S-CR> :python pyrepl.duplicate_line()<CR>$
    map  <buffer><silent><CR> :python pyrepl.read_line()<CR>
    imap <buffer><silent><CR> :python pyrepl.read_line()<CR>
    normal! i>>>  $
    startinsert
    echo("PyREPL started.")
endfun

fun! s:StartREPLWithFile()
    let s:filename = expand('%')
    call s:StartREPL()
    python pyrepl.eval_file(vim.eval("s:filename"))
endfun

fun! s:StopREPL()
    map  <buffer><silent><S-CR> <S-CR>
    imap <buffer><silent><S-CR> <S-CR>
    map  <buffer><silent><CR> <CR>
    imap <buffer><silent><CR> <CR>
    echo("PyREPL stopped.")
endfun

" Expose the Toggle function publicly.
command! -nargs=0 PyREPLToggle call s:ToggleREPL()
command! -nargs=0 PyREPLEvalFile call s:StartREPLWithFile()
" }}}

" vim:fdm=marker
