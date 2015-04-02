#!/usr/bin/env python2.7

from __future__ import absolute_import, division, print_function
import cStringIO
import csv
import fileinput
import sys

import joblib
import netaddr


'''klady@klady:/data/neustar $ head v727.281_24.50_20150320.csv
"start_ip_int","end_ip_int","continent","country","country_code","country_cf","region","state","state_code","state_cf","city","city_cf","postal_code","area_code","time_zone","latitude","longitude","dma","msa","connection_type","line_speed","ip_routing_type","asn","sld","tld","organization","carrier","anonymizer_status","home","organization_type","naics_code","isic_code","geonames_id","state_ref_id","region_ref_id","city_ref_id","proxy_type","proxy_level","proxy_last_detected","hosting_facility"'''


def process_row(row, fields):
    res = []
    netblocks = netaddr.cidr_merge(list(netaddr.iter_iprange(row['start_ip_int'], row['end_ip_int'])))
    for netblock in netblocks:
        row['netblock'] = netblock
        res.append([row[field] for field in fields])

    return res


def main(argv):
    r = csv.DictReader(fileinput.input(argv[1:]))
    w = csv.writer(sys.stdout)

    fields = ('netblock', 'proxy_type', 'proxy_level')

    w.writerow(fields)
    for res_list in joblib.Parallel(n_jobs=3)(joblib.delayed(process_row)(row, fields) for row in r):
        for res in res_list:
            w.writerow(res)



if __name__ == '__main__':
    sys.exit(main(sys.argv))
