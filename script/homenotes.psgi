use Mojo::Server::PSGI;
use Plack::Builder;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Homenotes; 

my $psgi = Mojo::Server::PSGI->new( app => Homenotes->new );
my $app = sub { $psgi->run(@_) };

builder {
    enable 'Session', store => 'File';
    $app;
};
