#!/usr/bin/perl
use strict;
use warnings;

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

# burn the header row
readline(*STDIN);

while (my $line = <STDIN>) {
  chomp $line;

  if ($csv->parse($line)) {

      my @fields = $csv->fields();
      my ($netblock, $proxy_type, $proxy_level) = @fields;

      my $network = Net::Works::Network->new_from_string( string => $netblock );

      $tree->insert_network(
        $network,
        {
          proxy_type => $proxy_type,
          proxy_level => $proxy_level,
        }
      );

  } else {
      warn "Line could not be parsed: $line\n";
  }
}

$tree->write_tree(*STDOUT);
