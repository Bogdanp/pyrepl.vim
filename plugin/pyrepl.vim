" ============================================================================
" File:        pyrepl.vim
" Description: Vim plugin that provides a Python REPL inside a buffer.
" Maintainer:  Bogdan Popa <popa.bogdanp@gmail.com>
" License:
" Copyright (C) 2011 Bogdan Popa
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:

" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.

" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE. 
" ============================================================================
if exists("g:loaded_pyrepl") || &cp
    finish
endif

let g:loaded_pyrepl = 1

if !has("python")
    echo("Error: PyREPL requires vim compiled with +python.")
endif

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
    set ft=python
    map <buffer><silent>o o>>> 
    map <buffer><silent>O O>>> 
    map <buffer><silent><CR> :call <SID>Eval()<CR>
    imap <buffer><silent><CR> :call <SID>Eval()<CR>G
    normal ggdGi>>> 
    python globals_, locals_ = {}, {}
    echo("PyREPL started.")
endfun

fun! s:StopREPL()
    set ft=none
    map <buffer><silent>o o
    map <buffer><silent>O O
    map <buffer><silent><CR> <CR>
    imap <buffer><silent><CR> <CR>
    python del globals_; del locals_
    echo("PyREPL stopped.")
endfun

fun! s:Eval()
    python <<EOF
import code
import cStringIO
import os
import sys
import traceback
import vim

def eval_(line):
    global globals_, locals_
    vim.command("normal jdG$")
    try:
        eval(code.compile_command(line), globals_, locals_)
    except:
        for line in traceback.format_exc().splitlines():
            vim.current.buffer.append(line)
    else:
        if stdout.getvalue():
            vim.current.buffer.append(stdout.getvalue())
    vim.command("normal Go")

sys.path.append(os.getcwd())
old_stdout = sys.stdout
sys.stdout = stdout = cStringIO.StringIO()
line = vim.current.line[3:].strip()
eval_(line)
sys.stdout = old_stdout
EOF
endfun
