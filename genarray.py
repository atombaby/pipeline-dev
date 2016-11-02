#!/usr/bin/env python3

import sys
from itertools import groupby
from operator import itemgetter

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
    print(l)
    for g in l:
        print(g)
        if g[0] == g[-1]:
            out.append(str(g[0]))
        else:
            out.append("{}-{}".format( g[0], g[-1] ))

    return ','.join(out)

if __name__ == "__main__":
    numbers = sys.argv[1].split(',')
    try:
        numbers = [ int(n) for n in numbers ]
    except ValueError:
        print("ERROR: non-integer found in your list of numbers")
        sys.exit(1)

    numbers = sorted( numbers )
    a = group_index( numbers )
    print(format_for_sbatch( a ))

