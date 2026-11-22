#!/usr/bin/env python3

# A linter to warn for ASSERT macros which are separated from their argument
# list by a space, which Clang's CPP barfs on

from pathlib import Path
from linter import run_linters, RegexpLinter

# The library submodules absorbed into the tree, and nofib, keep their
# own conventions and are not linted.
ABSORBED_LIBRARIES = {
    'Cabal', 'Win32', 'array', 'binary',
    'bytestring', 'containers', 'deepseq', 'directory',
    'exceptions', 'file-io', 'filepath', 'haskeline',
    'hpc', 'mtl', 'os-string', 'parsec',
    'pretty', 'process', 'semaphore-compat', 'stm',
    'template-haskell-lift', 'template-haskell-quasiquoter', 'terminfo', 'text',
    'time', 'transformers', 'unix', 'xhtml',
}

linters = [
    RegexpLinter(r'WARN\s+\(',
                 message='CPP macros should not have a space between the macro name and their argument list'),
    RegexpLinter(r'ASSERT\s+\(',
                 message='CPP macros should not have a space between the macro name and their argument list'),
    RegexpLinter(r'ASSERT2\s+\(',
                 message='CPP macros should not have a space between the macro name and their argument list'),
    # RegexpLinter(r'#ifdef\s+',
    #              message='`#if defined(x)` is preferred to `#ifdef x`'),
    RegexpLinter(r'#if\s+defined\s+',
                 message='`#if defined(x)` is preferred to `#if defined x`'),
    # RegexpLinter(r'#ifndef\s+',
    #              message='`#if !defined(x)` is preferred to `#ifndef x`'),
]

for l in linters:
    # Need do document rules!
    l.add_path_filter(lambda path: path != Path('docs', 'coding-style.html'))
    l.add_path_filter(lambda path: path != Path('docs', 'users_guide', 'utils.rst'))
    # Don't lint vendored code
    l.add_path_filter(lambda path: not path.name == 'config.guess')
    # Don't lint files from external xxhash projects
    l.add_path_filter(lambda path: path != Path('rts', 'xxhash.h')),
    # Don't lint core spec
    l.add_path_filter(lambda path: not path.name == 'core-spec.pdf')
    # Don't lint the linter itself
    l.add_path_filter(lambda path: not path.name == 'check-cpp.py')
    # Don't lint the absorbed library submodules, nor nofib
    l.add_path_filter(lambda path: not (len(path.parts) > 1 and path.parts[0] == 'libraries'
                                        and path.parts[1] in ABSORBED_LIBRARIES)
                                   and not (len(path.parts) > 0 and path.parts[0] == 'nofib'))

if __name__ == '__main__':
    run_linters(linters)
