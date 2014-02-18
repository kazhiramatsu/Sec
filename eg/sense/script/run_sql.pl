use strict;
use warnings;
use lib '../lib';
use Sec::Util ();
use Sec::DBI;

my $sqls = Sec::Util::load_sql(${ARGV[0]}); 
my $config = Sec::Util::load_file("config/config.pl"); 
my $dbi = Sec::DBI->new(connect_info => $config->{connect_info}); 

for my $sql (@$sqls) {
    my $ret = $dbi->connect('admin_user')->do($sql);
}

