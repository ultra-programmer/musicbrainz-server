package MusicBrainz::Server::WebService::Serializer::XML::1::Recording;
use Moose;

extends 'MusicBrainz::Server::WebService::Serializer::XML::1';
with 'MusicBrainz::Server::WebService::Serializer::XML::1::Role::GID';
with 'MusicBrainz::Server::WebService::Serializer::XML::1::Role::ArtistCredit';
with 'MusicBrainz::Server::WebService::Serializer::XML::1::Role::Tags';

use aliased 'MusicBrainz::Server::WebService::Serializer::XML::1::List';

sub element { 'track'; }

before 'serialize' => sub
{
    my ($self, $entity, $inc, $opts) = @_;

    $self->add( $self->gen->title($entity->name) );
    $self->add( $self->gen->duration($entity->length) ) if $entity->length;

    $self->add( List->new->serialize($entity->isrcs) )
        if $inc && $inc->isrcs;

    $self->add( List->new->serialize($entity->puids) )
        if $inc && $inc->puids;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2010 MetaBrainz Foundation

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut

