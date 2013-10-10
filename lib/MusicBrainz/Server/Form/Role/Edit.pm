package MusicBrainz::Server::Form::Role::Edit;
use HTML::FormHandler::Moose::Role;
use MusicBrainz::Server::Translation qw( l );

requires 'edit_field_names';

has 'requires_edit_note' => ( is => 'ro', default => 0 );

has_field 'edit_note' => (
    type => 'TextArea',
    label => 'Edit note:',
    localize_meth => sub { my ($self, @message) = @_; return l(@message); }
);

has_field 'as_auto_editor' => (
    type => 'Checkbox',
);

sub default_as_auto_editor
{
    my $self = shift;
    return $self->ctx->user->is_auto_editor;
};

sub edit_fields
{
    my ($self) = @_;
    return grep {
        $_->has_input || $_->has_value
    } map {
        $self->field($_)
    } $self->edit_field_names;
}

sub validate {
    my $self = shift;

    if ($self->requires_edit_note && (!defined $self->field('edit_note')->value || $self->field('edit_note')->value eq '')) {
        $self->field('edit_note')->add_error( l("You must provide an edit note"));
    }
}

1;
