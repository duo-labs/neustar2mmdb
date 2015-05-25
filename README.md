## neustar2maxmind

### Installation
See instructions in INSTALL. tl;dr: you need the Perl packages `JSON`, `YAML`,
`Refcount`, and `MaxMind::DB::Writer::Tree`.


### Conversion Example
```
klady@klady:/svn/labs/research/neustardb $ head -n 10000 /data/neustar/v727.281_24.50_20150320.csv > /tmp/nsperf.csv
klady@klady:/svn/labs/research/neustardb $ ls -lh /tmp/nsperf.csv
-rw-r--r--  1 klady  wheel   3.0M Apr  2 20:02 /tmp/nsperf.csv
klady@klady:/svn/labs/research/neustardb $ time python preprocess.py /tmp/nsperf.csv | python reduce.py | perl generate_mmdb.pl neustar > /tmp/nsperf.mmdb

real    0m36.693s
user    1m52.657s
sys     0m1.935s

klady@klady:/svn/labs/research/neustardb $ ls -lh /tmp/nsperf.mmdb
-rw-r--r--  1 klady  wheel    46K Apr  2 19:56 /tmp/nsperf.mmdb
```

## Database Usage Example
Using the [https://pypi.python.org/pypi/maxminddb](maxminddb) module:
```
In [1]: import maxminddb

In [2]: reader = maxminddb.open_database('/tmp/nsperf.mmdb')

In [3]: reader.get('1.2.3.4')

In [4]: print reader.get('1.2.3.4')
None

In [5]: reader.get('1.1.1.1')
Out[5]: {u'proxy_level': u'elite', u'proxy_type': u'web'}
```

A somewhat hacky alternative is to use the
[https://pypi.python.org/pypi/geoip2](geoip2) module. This does nothing more
than wrap the dict-style interface in a class. Internal to Duo, we use this
approach so as to maintain a similar API as when we use MaxMind GeoIP products
in a similar fashion.
```
In [1]: import geoip2.database

In [3]: reader = geoip2.database.Reader('/tmp/nsperf.mmdb')

In [6]: reader._get('Neustar-IP-Gold', '1.2.3.4')
---------------------------------------------------------------------------
AddressNotFoundError                      Traceback (most recent call last)
<ipython-input-6-4c769a7d3a8b> in <module>()
----> 1 reader._get('Neustar-IP-Gold', '1.2.3.4')

AddressNotFoundError: The address 1.2.3.4 is not in the database.

In [7]: reader._get('Neustar-IP-Gold', '1.1.1.1')
Out[7]: {u'proxy_level': u'elite\r', u'proxy_type': u'web'} 
```
NB: if you want to keep using the [https://pypi.python.org/pypi/geoip2](geoip2)
module, you have to use `Reader._get()`, as the regular functions assume a
particular MaxMind product and thus throw exceptions when you use them.

## PyPy
We've achieved a ~1.4x speedup by using PyPy on a Mid-2014 15" MBP.
```
$ head -n 10000 /data/neustar/v727.281_24.50_20150320.csv > /tmp/nsperf.csv
$ time pypy preprocess.py /tmp/nsperf.csv | pypy reduce.py | perl generate_mmdb.pl > nsperf.mmdb

real	0m0.849s
user	0m1.255s
sys	0m0.154s
$ time python preprocess.py /tmp/nsperf.csv | python reduce.py | perl generate_mmdb.pl > nsperf.mmdb

real	0m1.153s
user	0m1.525s
sys	0m0.110s
```
