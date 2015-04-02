#!/usr/bin/env python2.7

from __future__ import absolute_import, division, print_function
import csv
import fileinput
import sys

import joblib
import netaddr


'''klady@klady:/svn/labs/research/neustardb $ python preprocess.py /data/neustar/v727.281_24.50_20150320.csv | head
netblock,proxy_type,proxy_level,proxy_last_detected
1.0.0.0/26,,,
1.0.0.64/27,,,
1.0.0.96/28,,,
1.0.0.112/29,,,
1.0.0.120/30,,,
1.0.0.124/31,,,
1.0.0.126/32,,,
1.0.0.127/32,tor,elite,2015-03-09
1.0.0.128/25,,,'''

def netblock_reduce(key, netblocks):
    return (key, list(netaddr.IPSet(netblocks).iter_cidrs()))

def main(argv):
    r = csv.DictReader(fileinput.input(argv[1:]))
    w = csv.writer(sys.stdout)

    data_cidrs = {}
    netblock_i = r.fieldnames.index('netblock')
    data_fieldnames = list(r.fieldnames)
    data_fieldnames.remove('netblock')

    no_data_data = tuple(['',] * len(data_fieldnames))

    for row in r:
        # get everything in the row except the netblock
        data = tuple([row[field] for field in data_fieldnames])


        # special case: if the data is that there is no data, skip this one
        if data == no_data_data:
            continue

        netblock = netaddr.IPNetwork(row['netblock'])

        try:
            data_cidrs[data].append(netblock)
        except KeyError:
            data_cidrs[data] = [netblock,]


    w.writerow(r.fieldnames)
    for data,cidrs in joblib.Parallel(n_jobs=3)(joblib.delayed(netblock_reduce)(key, netblocks) for key, netblocks in data_cidrs.iteritems()):
        row = list(data)

        # amortize the mid-list insertion cost by doing it outside the loop
        row.insert(netblock_i, None)

        for cidr in cidrs:
            row[netblock_i] = cidr
            w.writerow(row)



if __name__ == '__main__':
    sys.exit(main(sys.argv))
