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
        my $id = $session->get('user_id');
        if ($id =~ /^g/) {
            $screen_name .= '@github';
        }elsif($id =~ /^t/) {
            $screen_name .= '@twitter';
        }
        $self->stash->{navbar_right} = $self->model->get_logoff_link($screen_name);
        $self->stash->{share_button} = $self->model->get_modal_button();
    }else {
        $self->stash->{navbar_right} = "";
        $self->stash->{share_button} = $self->model->get_login_button();
    }
    $self->render();
}

sub submit {
    my $self = shift;
    my $session = Plack::Session->new( $self->req->env );
    my $params;
    my $data = $self->req->json; # to receive Content-Type application/json
    $params->{know} = $data->{know};
    $params->{how} = $data->{how};
    $params->{example} = $data->{example};
    $params->{user_id} = $session->get('user_id');

    my $result = $self->model->insert_knowhow($params);
    print Dumper $result;
    $self->render(text => $result);
}

sub search {
    my $self = shift;
    my $session = Plack::Session->new( $self->req->env );
    my @target_tables;
    for my $c ('know', 'how', 'example') {
        if ($self->param($c) == 1) {
            push @target_tables, $c;
        }
    }
    my $text = $self->param('query');
    my $result;
    if ($text eq ""){
        $result = "";
    }else {
        $result = $self->model->search($text, \@target_tables);
    }
    $result = "" unless (defined $result);
    $self->render( json => $result);
}

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
sub knowhow {
    my $self = shift;
    my $id = $self->param('id');
    my $result = $self->model->get_knowhow($id);
    $self->render( json => $result);
}
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
sub delete_knowhow {
    my $self = shift;
    my $knowhow_id = $self->param('id');
    my $session = Plack::Session->new( $self->req->env );
    my $user_id = $session->get('user_id');
    my $result;
    if (defined $user_id) {
        $result = $self->model->delete_knowhow($knowhow_id, $user_id);
    }else{
        $result = "Failed to delete because you are not logged in?";
    }
    $self->render(json => {result => $result });
}

sub status {
    my $self = shift;
    my $knowhow_id = $self->param('id');
    my $result;
    $result->{id} = $knowhow_id;
    my $session = Plack::Session->new( $self->req->env );
    my $user_id = $session->get('user_id');
    if (defined $user_id) {
        $result->{login} = 'true';
        # mine(the knowhow you created), 
        # added(you added from others), 
        # others(others, not in your list)
        $result->{knowhow} = $self->model->whose_knowhow($knowhow_id, $user_id);
    } else {
        $result->{login} = 'false';
    }
    $self->render(json => $result);
}

sub add_to_my_knowhow {
    my $self = shift;
    my $knowhow_id = $self->param('id');
    my $session = Plack::Session->new( $self->req->env );
    my $user_id = $session->get('user_id');
    my $result;
    if (defined $user_id) {
        $result = $self->model->add_knowhow($knowhow_id, $user_id);
    }else{
        $result = "Failed because you are not logged in?";
    }
    $self->render(json => {result => $result} );
}

sub remove_added_knowhow {
    my $self = shift;
    my $knowhow_id = $self->param('id');
    my $session = Plack::Session->new( $self->req->env );
    my $user_id = $session->get('user_id');
    my $result;
    if (defined $user_id) {
        $result = $self->model->remove_knowhow($knowhow_id, $user_id);
    }else{
        $result = "Failed because you are not logged in?";
    }
    $self->render(json => {result => $result} );
}

#
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
