#!/usr/bin/env python

# This source code is subject to the terms of the MIT License. If a
# copy of the MIT License was not distributed with this file, you can
# obtain one at http://opensource.org/licenses/MIT.

"""
Reads a file for tor IPs max one IP per line and formats them into
the following format

kwu@kwu:/svn/labs/research/neustardb $ python one_ip_per_line_preprocess.py sample.csv | head
netblock,proxy_type,proxy_level,proxy_last_detected
1.0.0.0/32,tor,,
1.0.0.64/32,tor,,
1.0.0.96/32,tor,,
1.0.0.112/32,tor,,
1.0.0.120/32,tor,,
1.0.0.124/32,tor,,
1.0.0.126/32,tor,,
1.0.0.127/32,tor,,
1.0.0.128/32,tor,,
"""

import re
import csv
import sys

def get_ips(file_name):
    """
    Get the IPs from a file with one or zero IPs listed per line
    """
    ips = set()
    with open(file_name, "r") as blacklist:
        ip_pattern = '(?P<blacklisted_ip>\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b)'
        ip_regex = re.compile(ip_pattern)
        for line in blacklist:
            match = ip_regex.search(line)
            if match:
                ip = match.group('blacklisted_ip')
                ips.add(ip)
        blacklist.close()
    return ips

def export_preprocessed_tor_project_csv(ips):
    """
    Format data into csv like that of outputted by preprocess.py for
    the Neustar data file
    """
    w = csv.writer(sys.stdout)
    fields = ('netblock', 'proxy_type', 'proxy_level')
    w.writerow(fields)
    for ip in ips:
        row = (ip + '/32', 'tor', '')
        w.writerow(row)

def main(argv):
    if len(sys.argv) != 2:
        print "usage: python tor_project_process.py <path_to_file>"
        sys.exit()
    export_preprocessed_tor_project_csv(get_ips(argv[1]))

if __name__ == '__main__':
    sys.exit(main(sys.argv))
