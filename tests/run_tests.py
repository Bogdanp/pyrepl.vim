#!/usr/bin/env python2
# Copyright (C) 2011 by Bogdan Popa <popa.bogdanp@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
from glob import glob
from os import unlink
from subprocess import call
from sys import exit
from time import time

def run_commands(filename):
    '''Runs a series of normal mode commands in VIM from a given file.'''
    # It is assumed that the format of the test files is DOS. As such,
    # the final CRLF is ignored.
    commands = open(filename).read()[:-2]
    commands += ':w output\r:bufdo bd!\r:q!\r'
    with open('commands', 'w') as file_: 
        file_.write(commands)
    call(['vim', '-s', 'commands'])
    try: output = open('output').read()
    except IOError:
        print "Error: missing output file for '{0}'.".format(filename)
        exit(1)
    unlink('commands')
    unlink('output')
    return output

def run_test(filename):
    output = run_commands(filename)
    expected_filename = '{0}_output'.format(filename.split('.vim')[0])
    expected = open(expected_filename).read()
    assert output == expected

def run_tests():
    F, status, t = [], '', time()
    for filename in glob('*.vim'):
        try: run_test(filename)
        except AssertionError: 
            F.append(filename)
            status += 'F'
        else: status += '.'
        finally: print '{0}\r'.format(status),
    else: print
    for filename in F:
        print "Test '{0}' FAILED.".format(filename)
    print 'Tests were run in {0}.'.format(time() - t)

if __name__ == '__main__':
    exit(run_tests())
