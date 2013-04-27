package Homenotes;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Web::Auth;
use Plack::Session;
use Data::Dumper;
use FindBin qw($Bin);
use Homenotes::Model;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Config
  my $config = $self->plugin('Config', {file => "$Bin/../etc/homenotes.conf"});

 # Helper to define Model
  my $m = Homenotes::Model->new(config => $config);
  $self->helper(model => sub {$m} );

  # Twitter
  $self->plugin('Web::Auth',
      module      => 'Twitter',
      key         => $config->{twitter_consumer_key},
      secret      => $config->{twitter_consumer_secret}, 
      on_finished => sub {
          my ( $c, $access_token, $access_secret, $ref ) = @_;
          my $screen_name = $ref->{screen_name} . '@twitter';
          my $id = 't'. $ref->{id};
          my $session = Plack::Session->new( $c->req->env );
          $session->set( 'access_token',        $access_token );
          $session->set( 'access_token_secret', $access_secret );
          $session->set( 'screen_name',         $screen_name );
          $session->set( 'user_id',             $id );
          #$self->model->insert_user($user_id, $screen_name, $access_token, $access_token_secret);
      },
  );

  # Github
  $self->plugin('Web::Auth',
      module      => 'Github',
      key         => $config->{github_consumer_key}, 
      secret      => $config->{github_consumer_secret}, 
      on_finished => sub {
          my ( $c, $access_token, $ref ) = @_;
          my $screen_name = $ref->{login} . '@github';
          my $id = 'g'. $ref->{id};
          my $session = Plack::Session->new( $c->req->env );
          $session->set( 'access_token',        $access_token );
          $session->set( 'screen_name',         $screen_name );
          $session->set( 'user_id',             $id );
      },
  );

  # Router
  my $r = $self->routes;
  push @{$r->namespaces}, 'Homenotes::Controller';

  # Normal route to controller
  $r->get('/')->to('index#top');
  $r->get('/auth/*method/callback')->to('index#callback');
  $r->get('/auth/logout')->to('index#logout');
}

1;
