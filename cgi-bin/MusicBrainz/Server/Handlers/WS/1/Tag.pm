#!/usr/bin/perl -w
# vi: set ts=4 sw=4 :
#____________________________________________________________________________
#
#   MusicBrainz -- the open internet music database
#
#   Copyright (C) 2004 Robert Kaye
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#   $Id: Track.pm 8966 2007-03-27 19:13:13Z luks $
#____________________________________________________________________________

use strict;

package MusicBrainz::Server::Handlers::WS::1::Tag;

use Apache::Constants qw( );
use Apache::File ();
use MusicBrainz::Server::Handlers::WS::1::Common;
use Apache::Constants qw( OK BAD_REQUEST DECLINED SERVER_ERROR NOT_FOUND FORBIDDEN);
use MusicBrainz::Server::Tag;
use Data::Dumper;

sub handler
{
	my ($r) = @_;
	# URLs are of the form:
	# POST http://server/ws/1/tag/?name=<user_name>&entity=<entity>&id=<id>&tags=<tags>

    return handler_post($r) if ($r->method eq "POST");

    $r->status(BAD_REQUEST);
	return Apache::Constants::BAD_REQUEST();
}

sub handler_post
{
    my $r = shift;

	# URLs are of the form:
	# POST http://server/ws/1/tag/?name=<user_name>&entity=<entity>&id=<id>&tags=<tags>

    my $apr = Apache::Request->new($r);
    my $user = $r->user;
    my $entity = $apr->param('entity');
    my $id = $apr->param('id');
    my $tags = $apr->param('tags');
    my $type = $apr->param('type');
    if (!defined($type) || $type ne 'xml')
    {
		return bad_req($r, "Invalid content type. Must be set to xml.");
	}

    if (!MusicBrainz::Server::Validation::IsGUID($id) || 
        ($entity ne 'artist' && $entity ne 'release' && $entity ne 'track' && $entity ne 'label'))
    {
		return bad_req($r, "Invalid MBID/entity.");
    }

    # Ensure that the login name is the same as the resource requested 
    if ($r->user ne $user)
    {
		$r->status(FORBIDDEN);
        return FORBIDDEN;
    }

    # Ensure that we're not a replicated server and that we were given a client version
    if (&DBDefs::REPLICATION_TYPE == &DBDefs::RT_SLAVE)
    {
		return bad_req($r, "You cannot submit tags to a slave server.");
    }

	my $status = eval 
    {
		# Try to serve the request from the database
		{
			my $status = serve_from_db_post($r, $user, $entity, $id, $tags);
			return $status if defined $status;
		}
        undef;
	};

	if ($@)
	{
		my $error = "$@";
        print STDERR "WS Error: $error\n";
		$r->status(SERVER_ERROR);
		$r->content_type("text/plain; charset=utf-8");
		$r->print($error."\015\012") unless $r->header_only;
		return SERVER_ERROR;
	}
    if (!defined $status)
    {
        $r->status(NOT_FOUND);
        return NOT_FOUND;
    }

	return OK;
}

sub serve_from_db_post
{
	my ($r, $user, $entity, $id, $tags) = @_;

	my $printer = sub {
		print_xml_post($user, $entity, $id, $tags);
	};

	send_response($r, $printer);
	return OK();
}

sub print_xml_post
{
	my ($user, $entity, $id, $tags) = @_;

	require MusicBrainz;
	my $mb = MusicBrainz->new;
	$mb->Login();

    require UserStuff;
    my $us = UserStuff->new($mb->{DBH});
    $us = $us->newFromName($user) or die "Cannot load user.\n";

    require Sql;
    my $sql = Sql->new($mb->{DBH});

    require Artist;
    require Album;
    require Label;
    require Track;

    my $obj;
    if ($entity eq 'artist')
    {
        $obj = Artist->new($sql->{DBH});
    }
    elsif ($entity eq 'release')
    {
        $obj = Album->new($sql->{DBH});
    }
    elsif ($entity eq 'track')
    {
        $obj = Track->new($sql->{DBH});
    }
    elsif ($entity eq 'label')
    {
        $obj = Label->new($sql->{DBH});
    }
    $obj->SetMBId($id);
    unless ($obj->LoadFromId)
    {
        die "Cannot load entity. Bad entity id given?"
    } 

    my $tag = MusicBrainz::Server::Tag->new($mb->{DBH});
    $tag->Update($tags, $us->GetId, $entity, $obj->GetId);

	print '<?xml version="1.0" encoding="UTF-8"?>';
	print '<metadata xmlns="http://musicbrainz.org/ns/mmd-1.0#"/>';
}

1;
# eof Tag.pm
