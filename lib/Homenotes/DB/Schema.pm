package Homenotes::DB::Schema;
use DBIx::Skinny::Schema;


install_utf8_columns qw/know how example/;
install_table Knowhow => schema {
    pk 'record_id';
    columns qw/ 
        record_id
        user_id
        know
        how
        example
        created_at
    /;
};

install_table User => schema {
    pk 'user_id';
    columns qw/ 
        user_id
        screen_name
        oauth_token
        oauth_token_secret
     /;
};

install_table Tag => schema {
    pk 'tag_id';
    columns qw/ 
        tag_id
        tag_name
    /;
};

install_table MyKnowhow => schema {
    pk 'record_id';
    columns qw/ 
        record_id
        user_id
        knowhow_record_id
    /;
};

install_table TagLink => schema {
    pk 'record_id';
    columns qw/ 
        record_id
        knowhow_record_id
        tag_id
    /;
};

1;
