#!/usr/bin/env python3

import sys
import re
import csv

from itertools import groupby
from operator import itemgetter
from argparse import ArgumentParser

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
    print(args.slurm_opts)

    dharma_ids = []
    with open( args.report ) as report:
        report_reader = csv.DictReader( report )
        for line in report_reader:
            dharma_ids.append(int(line['dharma_id']))

    print(dharma_ids)

    job_array_indexes = format_for_sbatch( group_index( dharma_ids ))
    slurm_opts = ' '.join(args.slurm_opts)
    print("sbatch -a {} {} --wrap=\"{}\"".format(job_array_indexes, slurm_opts, args.script))

