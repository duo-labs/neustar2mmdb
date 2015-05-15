#!/usr/bin/perl

# This source code is subject to the terms of the MIT License. If a
# copy of the MIT License was not distributed with this file, you can
# obtain one at http://opensource.org/licenses/MIT.

use strict;
use warnings;

use Data::Dumper;
use List::Util;
use MaxMind::DB::Writer::Tree;
use Net::Works::Network;
use Text::CSV;

# http://www.quickmeme.com/img/d6/d6a1143f571184db25f94613edd43b40af6d3a629221aba00d9efdcfef5efd84.jpg
#   --klady

# MMDB format docs: https://maxmind.github.io/MaxMind-DB/
# MaxMind::DB:Writer::Tree API docs: https://metacpan.org/pod/MaxMind::DB::Writer::Tree

my $num_args = $#ARGV + 1;
if ($num_args != 1) {
    print "Usage: generate_mmdb.pl <tor or neustar>\n";
    exit;
}

# change input record separator from default of LF to CRLF
$/ = "\r\n";

my $db_type = $ARGV[0];
my $db_name = "";
my $db_description = "";
if ($db_type eq "tor") {
    $db_name = "Tor-Project-List";
    $db_description = "Tor project exit address listing";
} elsif ($db_type eq "neustar") {
    $db_name = "Neustar-IP-Gold";
    $db_description = "Neustar IP Intelligence Gold Edition";
} else {
    print "Usage: generate_mmdb.pl <tor or neustar>\n";
    exit;
}

my %types = (
    proxy_type => 'utf8_string',
    proxy_level => 'utf8_string',
);

# record_size: there's no actual documentation as to how
# to choose a value in any of the documentation online.
# If I understand it correctly (I probably don't), it's
# the arity of each node. I chose 24 because the example
# in the docs used it, and I can't justify changing it.
# In retrospect, "chose" is a bit strong. -klady
my $tree = MaxMind::DB::Writer::Tree->new(
    ip_version            => 4,
    record_size           => 24,
    database_type         => $db_name,
    languages             => ['en'],
    description           => { en => $db_description },
    map_key_type_callback => sub { $types{ $_[0] } },
);


# I have no clue why it needs to be in binary mode,
# but it just fails to parse everything coming out of
# Python's csv module, so binary it is! -klady
my $csv = Text::CSV->new({ binary => 1 });

# grab the header row
my $header = readline(*STDIN);
$csv->parse($header);
my @fieldnames = $csv->fields();

# find the "netblock" field and splice it out
my $netblock_i = 0;
$netblock_i++ until $fieldnames[$netblock_i] eq 'netblock';
splice(@fieldnames, $netblock_i, 1);

while (my $line = <STDIN>) {
  chomp $line;

  if ($csv->parse($line)) {

      my @fields = $csv->fields();
			my $netblock = $fields[$netblock_i];
			splice(@fields, $netblock_i, 1);

      my $network = Net::Works::Network->new_from_string( string => $netblock );

			# bulk initialize a hash. I don't understand the perl type system.
			my %data = ();
			@data{@fieldnames} = @fields;

      $tree->insert_network(
        $network,
				\%data
      );

  } else {
      warn "Line could not be parsed: $line\n";
  }
}

$tree->write_tree(*STDOUT);
