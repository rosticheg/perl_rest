#! /usr/bin/env perl
use strict;
use warnings;
use LWP::UserAgent;
use JSON::XS;
use File::Fetch;
use feature 'say';

use constant URL => 'http://interview.agileengine.com/';
use constant API_KEY => '';

# Receive a bearer token from a remote server
=pod
@api {post} /auth/ Request for autorisation token
@apiName authorization

@apiSuccess {String} Autorisation token
@apiError {String} Recieve 0
=cut

sub authorization {
    my $add_url = 'auth';
    my $json = {"apiKey" => API_KEY};
    my $req = HTTP::Request->new('POST', URL . $add_url);
    $req->header('Content-Type' => 'application/json');
    $req->content(encode_json $json);
    my $lwp = LWP::UserAgent->new;
    my $res = $lwp->request($req);


    if (!$res->is_success()) {
        print("An error occured: " . $res->status_line());
        return 0;
    }

    my $hash = decode_json($res->content);
    my $token = $hash->{token};

    return $token;
}

# Get information about the photo:
# {'pictures': [{'id': '1a5e86953ad5ac438130', 'cropped_picture': 'http://interview.agileengine.com/pictures/cropped/0002.jpg'}, 'page': 1, 'pageCount': 26, 'hasMore': True}
=pod
@api {get} /images/  or /images?page=(page number) Request for short photo info
@apiName fetch_photo
@apiSuccess {String} hashref [{'id': '1a5e86953ad5ac438130', 'cropped_picture': 'http://interview.agileengine.com/pictures/cropped/0002.jpg'}]
@apiError {String} Recieve 0
=cut

sub fetch_photo {
    my $page_number = shift;

    my $add_url;
    if ($page_number) {
        return 0 unless ($page_number =~ m/^[+-]?\d+$/ );
        $add_url = 'images?page=' . $page_number;
    }
    else {
        $add_url = 'images';
    }

    my $token = authorization();
    my $lwp = LWP::UserAgent->new;
    my $res = $lwp->get(
        URL . $add_url,
        "Authorization" => "Bearer " . $token,
    );

    my $hash = decode_json($res->content);

    return $hash->{pictures};
}

# Get detailed information about photo. Request to server and recieve answer like:
# {'id': 'e13a844e87c749edd2fc', 'author': 'Attentive Failure', 'camera': 'Nikon D810', 'tags': '#life ', 'cropped_picture': 'http://interview.agileengine.com/pictures/cropped/02sc003.jpg', 'full_picture': 'http://interview.agileengine.com/pictures/full_size/02sc003.jpg'}

=pod
@api {get} /images/?{id}  Request for detailed photo info
@apiName fetch_photo_details

@apiSuccess {String} hashref in caption
@apiError {String} Recieve 0
=cut

sub fetch_photo_details {
    my $photo_id = shift;

    return 0 unless $photo_id;
    return 0 unless ($photo_id =~ m/^[+-]?\d+$/ );
    my $add_url = 'images/' . $photo_id;

    my $token = authorization();
    my $lwp = LWP::UserAgent->new;
    my $res = $lwp->get(
        URL . $add_url,
        "Authorization" => "Bearer " . $token,
    );

    my $hash = decode_json($res->content);

    my %res_hash;
    foreach (keys %$hash) {
         if ($_ eq 'author' || $_ eq 'tags' || $_ eq 'full_picture') {
             $res_hash{$_} = $hash->{$_};
         }
    }

    return %res_hash;

}

# Download the required photo
sub download_photo {
    my $photo_url = shift;
    my $local_cash = shift;

    $local_cash //= 'images_cashe';

    my $fetch_file = File::Fetch->new(uri => $photo_url);
    my $file = $fetch_file->fetch(to => $local_cash) or die $fetch_file->error;

}

1;
