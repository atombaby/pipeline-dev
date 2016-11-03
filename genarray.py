#!/usr/bin/env python3

import sys
import re
import csv
import subprocess

from itertools import groupby
from operator import itemgetter
from argparse import ArgumentParser

def flatten(l, ltypes=(list, tuple)):
    # from http://basicproperty.sourceforge.net/
    ltype = type(l)
    l = list(l)
    i = 0
    while i < len(l):
        while isinstance(l[i], ltypes):
            if not l[i]:
                l.pop(i)
                i -= 1
                break
            else:
                l[i:i + 1] = l[i]
        i += 1
    return ltype(l)

def group_index( l ):
    # for list of ints in `l`, return list of grouped indexes
    out = []
    for k, g in groupby(enumerate(l), lambda x : x[1] - x[0]):
        out.append(list(map(itemgetter(1), g)))
    return out

def format_for_sbatch( l ):
    # take a list of grouped numbers and format for `sbatch -a <>`
    # [[1],[3,4,5,6],[9,10],[12]]
    out = []
    for g in l:
        if g[0] == g[-1]:
            out.append(str(g[0]))
        else:
            out.append("{}-{}".format( g[0], g[-1] ))

    return ','.join(out)

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument( "-r", "--report", dest="report",
                        required=True,
                        help="path to redcap report" )
    parser.add_argument( "-s", "--script", dest="script",
                        required=True,
                        help="path to pipeline script" )
    parser.add_argument( "-o", "--slurm-opts", dest="slurm_opts",
                      action="append",
                      help="slurm options to add to job submission" )
    
    args = parser.parse_args()

    dharma_ids = []
    with open( args.report ) as report:
        report_reader = csv.DictReader( report )
        for line in report_reader:
            dharma_ids.append(int(line['dharma_id']))

    job_array_indexes = format_for_sbatch( group_index( dharma_ids ))
    wrap_script = "{} {}".format( args.script, args.report )

    # Slurm options need to be split for use in subprocess
    slurm_opts = [ optarg.split() for optarg in args.slurm_opts ]
    slurm_opts = flatten( slurm_opts )

    cmd = [
        'sbatch',
        '-a',
        job_array_indexes
    ] + slurm_opts + ['--wrap', wrap_script ]

    # execute the command
    print( ' '.join(cmd) )
    result = subprocess.check_output( cmd )
    print(result)
