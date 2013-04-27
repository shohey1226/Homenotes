package Homenotes::Model;
use Moo;
use LWP::Protocol::Net::Curl;
use Net::Twitter::Lite;
use XML::Simple;
use Data::Dumper;
use FindBin qw($Bin);
use POSIX 'strftime';
use Homenotes::DB;
use utf8;
use Encode;
use Cache::Memcached::Fast;

has 'twitter' => (
    is => 'ro',
    builder => '_build_twitter',
); 

has 'config' => (
    is => 'ro',
    required => 1,
);

has 'db' => (
    is => 'ro',
    builder => '_build_db',
);

has 'mem' => (
    is => 'ro',
    builder => '_build_mem',
);

sub _build_mem {
    my $self = shift;
    my $server = $self->config->{memcache_server};
    my $port = $self->config->{memcache_port};
    if (defined $server && defined $port){
        return Cache::Memcached::Fast->new({ 
            servers => [ { address => "$server:$port" }],
            utf8 => 1,
        });
    }
    else {
        return undef;
    }
}

sub _build_db {
    my $self = shift;
    return Homenotes::DB->new(+{
        dsn => $self->config->{db_dsn},
        username => $self->config->{db_username},
        password => $self->config->{password}
    });
}

sub _build_twitter {
    my $self = shift;
    my $config = $self->config;
    return Net::Twitter::Lite->new(
        consumer_key => $config->{consumer_key},
        consumer_secret => $config->{consumer_secret},
        legacy_lists_api => 0,
    );
}    

sub get_login_link{
    my $self = shift;
    my $html = "<li><a href='/login'>Sigin in with Twitter</a></li>";
    return $html;
}

sub get_logoff_link {
    my ($self, $screen_name) = @_;
    my $html = "<li class='navbar-text'><span id='loginas'>Logged in as </span>$screen_name</li>";
    $html .= "<li><a href='/auth/logout'>Logout</a></li>";
    return $html;
}

sub get_submit_form {
    my $self = shift;
    my $html = '<br>KNOW <span class="count" id="know_count"></span> <textarea id="know" rows="2"></textarea><br>';
    $html .= 'HOW <span class="count" id="how_count"></span><textarea id="how" rows="2"></textarea><br>';
    $html .= 'EXAMPLE <span class="count" id="example_count"></span> <textarea id="example" rows="4"></textarea>';
    $html .= '<div id="slidebottom" class="slide">';
    $html .= '<button id="submit" class="btn btn-small btn-warning">Submit your knowledge!</button></div>';
    return $html;
}

sub get_login_button {
    my $self = shift;
    my $html = '<h4>Login with <a href="/auth/twitter/authenticate"><img src="/img/twitter_32.png">Twitter</a> or <a href="/auth/github/authenticate"><img src="/img/github_32.png">Github</a> to share your notes!</h4>';
    return $html;;
}

sub get_modal_button {
    my $html = '<div id="share_button">';
    $html .= '<a id="central_share_button" href="#myModal" role="button" class="btn btn-large btn-success" data-toggle="modal">Share your knowhow!</a>';
    $html .= '</div>';
    return $html;
}

sub insert_user {
    my ($self, $user_id, $screen_name, $token, $token_secret) = @_;
    my $db = $self->db;
    my $row = $db->single('User', {user_id => $user_id });
    if (defined $row) {
        $db->update('User', 
            {
                screen_name => $screen_name,
                oauth_token => $token,        
                oauth_token_secret => $token_secret
            },
            {user_id => $user_id}
        );
    }else {
        $db->create('User', 
            {
                screen_name => $screen_name,
                oauth_token => $token,        
                oauth_token_secret => $token_secret,
                user_id => $user_id
            }
        );
    }
}

sub insert_knowhow {
    my ($self, $params) = @_;
    my $current_datetime = strftime( "%Y-%m-%d %H:%M:%S" , localtime );
    my $db = $self->db;
    # check the user. It should be in User table
    my $row = $db->single('User', {user_id => $params->{user_id}});
    if (! defined $row){
        return "error"; 
    }

    # Get tags, insert tags if it's not available
    my @tags = $params->{know} =~ /#[0-9a-zA-Z_\-]+/g;
    my %tag_id;
    for my $tag (@tags) {
        $tag = lc $tag;
        my $ro = $db->single('Tag', {tag_name => $tag});
        if (! defined $ro ) {
            my $r = $db->create('Tag', {tag_name => $tag});
            $tag_id{$tag} = $r->get_column('tag_id');
        }
        else {
            $tag_id{$tag} = $ro->get_column('tag_id');
        }
    }

    $row = $db->create('Knowhow', 
        { user_id => $params->{user_id},
          know => $params->{know},
          how => $params->{how},
          example => $params->{example},
          created_at => $current_datetime,
        }
    );

    # Create tag link (tag to knowledge) if tag is available
    my $knowhow_record_id = $row->get_column('record_id');
    for my $tag (keys %tag_id) {
        $db->create('TagLink', {knowhow_record_id => $knowhow_record_id, tag_id => $tag_id{$tag}});
    }

    # Add it to Myknohow
    $db->create('MyKnowhow', {knowhow_record_id => $knowhow_record_id, user_id => $params->{user_id}});

    if(defined $row) {
        return $row->get_column('record_id'); 
    }else {
        return "error";
    }
}

sub search {
    my ($self, $text, $target_tables) = @_;
    my $db = $self->db;
    my $result;

    # Get user_id from @username;
    my @usernames = $text =~ /@([A-Za-z0-9_]+)/g;
    my @user_ids;
    my $prev_u ="";
    for my $u (sort @usernames) {
        next if ($prev_u eq $u); 
        my $r = $db->single('User', { screen_name => $u });
        push @user_ids, $r->get_column('user_id') if(defined $r);
        $text =~ s/\@$u//g;
        $prev_u = $u;
    }

    # If no user is specified
    # then simply search against table
    if (scalar @user_ids == 0 ){
        for my $table ( @{ $target_tables }) {
            # ''(quote) is not required in MATCH and can't be used in DBIx:Skinny's bind
            my $sql = 'SELECT * FROM Knowhow WHERE MATCH(' . $table .') AGAINST(? IN BOOLEAN MODE) limit 100';
            my @rows = $db->search_by_sql( $sql, ["*D+ $text" ]);
            for my $row (@rows) {
                my $record_id = $row->get_column('record_id');
                $result->{$record_id} = decode_utf8($row->get_column('know'));
            }
        }
        return $result;
    } else {
        my @rows = $db->search('MyKnowhow', { user_id => \@user_ids });
        my @knowhow_ids;
        for my $row (@rows) {
            push @knowhow_ids, $row->get_column('knowhow_record_id');
        }

        # After username removed, if there is no word, then search only with the user(s) 
        if ($text !~ /\S/) {
            my @ro = $db->search('Knowhow', { record_id => \@knowhow_ids }, { limit => 100 } );
            for my $r (@ro) {
                my $record_id = $r->get_column('record_id');
                $result->{$record_id} = decode_utf8($r->get_column('know'));
            }
            return $result;
        } 
        # The last is combination
        else {
            my @kh_sql;
            for my $khid (@knowhow_ids){
                push @kh_sql, "'$khid'";
            }
            my $kh_sql = join ",", @kh_sql;
            for my $table ( @{ $target_tables }) {
                my $sql = 'SELECT * FROM Knowhow WHERE MATCH(' . $table .') AGAINST(? IN BOOLEAN MODE) and record_id IN (' . $kh_sql .') limit 100';
                print Dumper $sql;
                my @rows = $db->search_by_sql( $sql, ["*D+ $text" ]);
                for my $row (@rows) {
                    my $record_id = $row->get_column('record_id');
                    $result->{$record_id} = decode_utf8($row->get_column('know'));
                }
            }
            return $result;
        }
    }
}

sub get_knowhow_api {
    my ($self, $id) = @_;
    my $mem = $self->mem;
    my $response = $mem->get("knowhowapi/$id");
    return $response if (defined $response);
    my $res = {};
    my $db = $self->db;
    my $row = $db->single('Knowhow', {record_id => $id} );
    $res->{know} = decode_utf8($row->get_column('know'));
    $res->{how} = decode_utf8($row->get_column('how'));
    $res->{example} = decode_utf8($row->get_column('example'));
    $mem->add("knowhowapi/$id", $res, 60 * 60 * 24 * 7);
    return $res;
}
    

sub get_knowhow {
    my ($self, $id, $logged_in_user_id) = @_; 

    # use memcache
    my $mem = $self->mem;
    my $uid;
    if (defined $logged_in_user_id){
        $uid = $logged_in_user_id;
    }else {
        $uid = "";
    }
    my $response = $mem->get("knowhow/$id/$uid");
    #print Dumper $response;
    return $response if (defined $response);

    my $res = {};
    my $db = $self->db;

    my $row = $db->single('Knowhow', {record_id => $id} );
    $res->{know} = decode_utf8($row->get_column('know'));
    $res->{title} = decode_utf8($row->get_column('know'));
    $res->{how} = decode_utf8($row->get_column('how'));
    $res->{example} = decode_utf8($row->get_column('example'));
    my $user_id = $row->get_column('user_id');

    for my $key (keys %{ $res }){
        $res->{$key} =~ s/&/&amp;/go;
        $res->{$key} =~ s/</&lt;/go;
        $res->{$key} =~ s/>/&gt;/go;
        $res->{$key} =~ s/"/&quot;/go;
        $res->{$key} =~ s/'/&#39;/go;
        $res->{$key} =~ s/(http:\/\/\S+)/<a href="$1">$1<\/a>/go;
    }

    # Change tag to url
    my @tags = $res->{know} =~ /#[0-9a-zA-Z_\-]+/g;
    for my $tag (@tags){
        $tag = lc $tag;
        my $r = $db->single('Tag', {tag_name => $tag});
        if (defined $r) {
            my $tag_url = '<a class="taglink" href="/tags/' . $r->get_column('tag_id') . '">' . $tag . '</a>';
            $res->{know} =~ s/$tag/$tag_url/g;
        }
    }
    #show buttons 
    #if the user logged in is the same as the user who added the knowhow 
    
    # If usr is being logged in
    if (defined $logged_in_user_id) {
        if( $logged_in_user_id eq $user_id){
            $res->{button} = '<br><button id="delete" class="btn btn-danger" value="' . $id . '">Delete this knowhow</button><br><br>'; 
        }else {
            # if it's in MyKnowhow, show remove this from my knowhow    
            my $r = $db->single('MyKnowhow', {user_id => $logged_in_user_id, knowhow_record_id => $id });
            if (defined $r) {
                $res->{button} = '<br><button id="remove_knowhow" class="btn btn-warning" value="' . $id . '">Remove this from my knowhow</button><br><br>';
            # otheriwse, show add this to my knowow 
            }else {
                $res->{button} = '<br><button id="add_knowhow" class="btn btn-success" value="' . $id . '">Add this to my knowhow</button><br><br>';
            }
        }
    }else {
        $res->{button} = ''; 
    }

    $row = $db->single('User', {user_id => $user_id });
    $res->{username} = $row->get_column('screen_name');
    $mem->add("knowhow/$id/$uid", $res, 60 * 60 * 24 * 7);
    return $res;
}

sub delete_knowhow{
    my ($self, $knowhow_id, $user_id) = @_;
    my $db = $self->db;
    my $row = $db->single('Knowhow', {record_id => $knowhow_id});
    if (defined $row){
        my $this_user_id = $row->get_column('user_id');
        my $r;
        if ( defined $this_user_id && $this_user_id eq $user_id ){
            $r = $db->delete('Knowhow', {record_id => $knowhow_id});
            my $mem = $self->mem;
            $mem->delete("knowhow/$knowhow_id/$user_id");
            $mem->delete("knowhow/$knowhow_id/");
        } else {
            return "Failed to delete. The author can only delete";
        }

        if(defined $r){
            return "The knowhow is deleted";
        }
        else {
            return "Failed to delete";
        }
    }else {
        return "Failed to delete. Not found the knowhow";
    }
}

sub add_knowhow{
    my ($self, $knowhow_id, $user_id) = @_;
    return "Please login to add" if (!defined $user_id || $user_id eq '');
    my $db = $self->db;
    my $row = $db->single('MyKnowhow', {knowhow_record_id => $knowhow_id, user_id => $user_id});
    if (!defined $row){
        my $r = $db->create('MyKnowhow', {knowhow_record_id => $knowhow_id, user_id => $user_id});
        if(defined $r){
            return "Added this knowhow";
        }else {
            return "Failed to add knowhow";
        }
    }else {
        return "This knowhow has already added";
    }
}

sub remove_knowhow{
    my ($self, $knowhow_id, $user_id) = @_;
    return "Please login to remove" if (!defined $user_id || $user_id eq '');
    my $db = $self->db;
    my $row = $db->single('MyKnowhow', {knowhow_record_id => $knowhow_id, user_id => $user_id });
    if (defined $row){
        my $r = $db->delete('MyKnowhow', {knowhow_record_id => $knowhow_id, user_id => $user_id});
        if(defined $r){
            return "removed this knowhow";
        }else {
            return "Failed to remove knowhow";
        }
    }else {
        return "This knowhow is not yours";
    }
}


# methods which is userd for test 
sub _get_user {
    my ($self, $user_id) = @_;
    my $db = $self->db;
    my $row = $db->single('User', {user_id => $user_id});
    my $result;
    $result->{user_id} = $row->get_column('user_id');
    $result->{screen_name} = $row->get_column('screen_name');
    $result->{oauth_token} = $row->get_column('oauth_token');
    $result->{oauth_token_secret} = $row->get_column('oauth_token_secret');
    return $result;
}

sub _delete_user {
    my ($self, $user_id) = @_;
    my $db = $self->db;
    my $row = $db->delete('User', {user_id => $user_id});
}

sub get_knowhow_from_tag {
    my ($self, $tag_id) = @_;
    my $db = $self->db;
    my $result;
    my $row = $db->single('Tag', { tag_id => $tag_id});
    if (defined $row) {
        my $tag_name = $row->get_column('tag_name');
        return $self->search($tag_name, ['know']);
    }else {
        return $result;
    }
} 

sub get_myknowhow_as_xml {
    my ($self, $user_id) = @_;
    my $db = $self->db;
    my @rows = $db->search('MyKnowhow', { user_id => $user_id });
    my @knowhow_ids;
    for my $row (@rows) {
        push @knowhow_ids, $row->get_column('knowhow_record_id');
    }
    my @knowhows;
    my @ro = $db->search('Knowhow', { record_id => \@knowhow_ids } );
    my $i=0;
    for my $r (@ro) {
        my $record_id = $r->get_column('record_id');
        my $entry;
        $entry->{id} = $i;
        $entry->{know} = decode_utf8($r->get_column('know'));
        $entry->{how} = decode_utf8($r->get_column('how'));
        $entry->{example} = decode_utf8($r->get_column('example'));
        push @knowhows, $entry;
        $i++;
    }
    my $xml;
    $xml = { list => { knowhow => \@knowhows } };
    return XMLout($xml, NoAttr => 1, keyattr => [], RootName => undef );
}

sub get_tags {
    my $self = shift;
    my $db = $self->db;
    my @rows = $db->search('Tag', {});
    my $html;
    for my $row (@rows) {
        $html .= '<a class="taglink" href="/tags/' . $row->get_column('tag_id') . '">' . $row->get_column('tag_name') . '</a> ';
    }
    return $html;
}

1;
