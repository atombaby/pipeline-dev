#!/usr/bin/env python3

list = [1,3,5,6,7,8,12,14,15,16,22]
job_array = []
i = 0
while i < len(list):
    print(job_array)
    c = list[i]
    n = list[i+1]
    print("DEBUG: at {} current is {}, next is {}".format(i,c,n))
    if n == c + 1:
        seq_start = c
        print("DEBUG: found sequence starting at {}".format(seq_start))
        while n == c + 1:
            i+=1
            c = list[i]
            n = list[i+1]
            print("DEBUG: at {} current is {}, next is {}".format(i,c,n))
        seq_end = c
        i += 1
        print("{}-{}".format(seq_start,seq_end))
        job_array.append("{}-{}".format(seq_start,seq_end))
    else:
        print(c)
        job_array.append("{}".format(c))
        i += 1

