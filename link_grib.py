#!/usr/bin/env python

# Copyright 2018 M. Riechert and D. Meyer. Licensed under the MIT License.

import os
import sys
import shutil
import glob
import string
import itertools
import argparse

def link(src_path, link_path):
    assert os.path.isfile(src_path)
    if os.path.exists(link_path) or os.path.islink(link_path):
        os.remove(link_path)
    try:
        # Windows: requires admin rights, but not restricted to same drive
        os.symlink(src_path, link_path)
    except:
        # Windows: does not require admin rights, but restricted to same drive
        os.link(src_path, link_path)

def link_or_copy(src, dst):
    try:
        link(src, dst)
    except:
        # fall-back for Windows if hard/sym links couldn't be created
        shutil.copy(src, dst)

def generate_gribfile_extensions():
    letters = list(string.ascii_uppercase)
    for a, b, c in itertools.product(letters, repeat=3):
        yield a + b + c

def collect_input_files(paths):
    input_files = []
    for path in paths:
        if os.path.isdir(path):
            for filename in os.listdir(path):
                input_files.append(os.path.join(path, filename))
        else:
            input_files.append(path)
    return input_files
    
def link_grib_files(input_paths, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    for path in glob.glob(os.path.join(output_dir, 'GRIBFILE.*')):
        os.remove(path)
    paths = collect_input_files(input_paths)
    grib_exts = generate_gribfile_extensions()
    for path in paths:
        try:
            ext = next(grib_exts)
        except StopIteration:
            print('RAN OUT OF GRIB FILE SUFFIXES!', file=sys.stderr)
            sys.exit(1)
        link_path = os.path.join(output_dir, 'GRIBFILE.' + ext)
        link_or_copy(path, link_path)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='A tool that symlinks GRIB files to GRIBFILE.??? format.')
    parser.add_argument('paths', metavar='path', nargs='+', help='GRIB file or folder with GRIB files')
    parser.add_argument('-o', '--out', metavar='output_dir', help='Output folder (default is current folder)', 
                        default=os.getcwd())
    args = parser.parse_args()
    link_grib_files(args.paths, args.out)
