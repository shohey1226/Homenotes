package Homenotes::Controller::Index;
use Mojo::Base 'Mojolicious::Controller';
use Plack::Session;
use Data::Dumper;

sub callback {
    my $self = shift;
    $self->redirect_to('/');
}

sub logout {
    my $self = shift;
    my $session = Plack::Session->new( $self->req->env );
    $session->expire();
    $self->redirect_to('/');
}

sub top {
    my $self = shift;
    my $session = Plack::Session->new( $self->req->env );
    my $screen_name = $session->get('screen_name');
    if(defined $screen_name && $screen_name ne "") {
        $self->stash->{navbar_right} = $self->model->get_logoff_link($screen_name);
        $self->stash->{share_button} = $self->model->get_modal_button();
    }else {
        $self->stash->{navbar_right} = "";
        $self->stash->{share_button} = $self->model->get_login_button();
    }
    $self->render();
}
#
#sub login{
#  my $self = shift;
#  my $session = Plack::Session->new( $self->req->env );
#  my $url = $self->model->twitter->get_authorization_url(
#                callback => $self->req->url->base . '/callback' 
#            );
#  $session->set( 'token', $self->model->twitter->request_token );
#  $session->set( 'token_secret', $self->model->twitter->request_token_secret );
#  $self->redirect_to($url);
#}
#
#sub callback {
#  my $self = shift;
#  unless ( $self->req->param('denied') ) {
#      my $session = Plack::Session->new( $self->req->env );
#      $self->model->twitter->request_token( $session->get('token') );
#      $self->model->twitter->request_token_secret( $session->get('token_secret') );
#      my $verifier = $self->req->param('oauth_verifier');
#      my ( $access_token, $access_token_secret, $user_id, $screen_name ) =
#        $self->model->twitter->request_access_token( verifier => $verifier );
#      $session->set( 'access_token',        $access_token );
#      $session->set( 'access_token_secret', $access_token_secret );
#      $session->set( 'screen_name',         $screen_name );
#      $session->set( 'user_id',         $user_id );
#      $self->model->insert_user($user_id, $screen_name, $access_token, $access_token_secret);
#  }
#  $self->redirect_to('/');
#}
#
#sub logout {
#    my $self = shift;
#    my $session = Plack::Session->new( $self->req->env );
#    $session->expire();
#    $self->redirect_to('/');
#}
#
#sub submit {
#    my $self = shift;
#    my $session = Plack::Session->new( $self->req->env );
#    my $params;
#    $params->{know} = $self->param('know');
#    $params->{how} = $self->param('how');
#    $params->{example} = $self->param('example');
#    $params->{user_id} = $session->get('user_id');
#    my $result = $self->model->insert_knowhow($params);
#    $self->render(text => $result);
#}
#
#sub search {
#    my $self = shift;
#    my $session = Plack::Session->new( $self->req->env );
#    my @target_tables;
#    for my $c ('know', 'how', 'example') {
#        if ($self->param($c) == 1) {
#            push @target_tables, $c;
#        }
#    }
#    my $text = $self->param('query');
#    my $result;
#    if ($text eq ""){
#        $result = "";
#    }else {
#        $result = $self->model->search($text, \@target_tables);
#    }
#    $result = "" unless (defined $result);
#    $self->render( json => $result);
#}
#
#sub taglist {
#    my $self = shift;
#    my $session = Plack::Session->new( $self->req->env );
#    my $screen_name = $session->get('screen_name');
#    if(defined $screen_name && $screen_name ne "") {
#        $self->stash->{navbar_right} = $self->model->get_logoff_link($screen_name);
#    }else {
#        $self->stash->{navbar_right} = $self->model->get_login_link();
#    }
#    $self->stash->{title} = "Tag List - Knowhow3"; 
#    $self->stash->{tags} = $self->model->get_tags();
#    $self->render();
#}
#
#sub knowhow_api {
#    my $self = shift;
#    my $id = $self->param('id');
#    my $result = $self->model->get_knowhow_api($id);
#    $self->render( json => $result);
#}
#
#sub knowhow {
#    my $self = shift;
#    my $id = $self->param('id');
#    print Dumper $id;
#    my $session = Plack::Session->new( $self->req->env );
#    my $screen_name = $session->get('screen_name');
#    my $user_id = $session->get('user_id');
#    if(defined $screen_name && $screen_name ne "") {
#        $self->stash->{navbar_right} = $self->model->get_logoff_link($screen_name);
#        #$self->stash->{submit_form} = $self->model->get_submit_form();
#        $self->stash->{share_button} = $self->model->get_modal_button();
#    }else {
#        $self->stash->{navbar_right} = $self->model->get_login_link();
#        $self->stash->{share_button} = $self->model->get_login_button();
#    }
#    my $res = $self->model->get_knowhow($id, $user_id);
#    $self->stash->{button} = $res->{button};
#    $self->stash->{know} = $res->{know};
#    $self->stash->{how} = $res->{how};
#    $self->stash->{example} = $res->{example};
#    $self->stash->{username} = $res->{username};
#    $self->stash->{title} = $res->{title} . " - Knowhow3";
#    $self->render();
#}
#
#sub delete_knowhow {
#    my $self = shift;
#    my $knowhow_id = $self->param('id');
#    my $session = Plack::Session->new( $self->req->env );
#    my $user_id = $session->get('user_id');
#    my $result;
#    if (defined $user_id) {
#        $result = $self->model->delete_knowhow($knowhow_id, $user_id);
#    }else{
#        $result = "Failed to delete because you are not logged in?";
#    }
#    $self->render(text => $result);
#}
#
#sub handle_knowhow {
#    my $self = shift;
#    my $knowhow_id = $self->param('id');
#    my $method = $self->param('method');
#    my $session = Plack::Session->new( $self->req->env );
#    my $user_id = $session->get('user_id');
#    my $result;
#    if (defined $user_id) {
#        if($method eq 'add'){
#            $result = $self->model->add_knowhow($knowhow_id, $user_id);
#        } elsif($method eq 'remove'){
#            $result = $self->model->remove_knowhow($knowhow_id, $user_id);
#        }else {
#            return "No method to handle this";
#        }
#
#    }else{
#        $result = "Failed to delete because you are not logged in?";
#    }
#    $self->render(text => $result);
#}
#
#sub tags {
#    my $self = shift;
#    my $tag_id = $self->param('id');
#    my $result = $self->model->get_knowhow_from_tag($tag_id);
#    $self->render( json => $result);
#}
#
#sub download_xml {
#    my $self = shift;
#    my $session = Plack::Session->new( $self->req->env );
#    my $user_id = $session->get('user_id');
#    if (defined $user_id){
#        my $xml = $self->model->get_myknowhow_as_xml($user_id);
#        $self->respond_to(xml => { text => $xml });
#    }else {
#        $self->respond_to(xml => { text => '<message>Please login to download xml</message>' });
#    }
#}
#
1;
