package Dist::Zilla::Plugin::RemovePrereqsMatching;

# ABSTRACT: A more flexible prereq remover

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;

with 'Dist::Zilla::Role::PrereqSource';

# debugging...
#use Smart::Comments '###';

has remove_matching => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => 1,

    handles => {
        has_prereqs_to_remove => 'count',
    },
);
sub _build_remove_matching { [ ] }

sub mvp_multivalue_args { 'remove_matching' }

=method register_prereqs

We implement this method to scan the list of prerequisites assembled to date,
and remove any tat match any of the expressions given to us.

=cut

sub register_prereqs {
    my ($self) = @_;

    my $prereqs = $self->zilla->prereqs;
    my $raw     = $prereqs->as_string_hash;

    my $regexes = $self->remove_matching;

    for my $p (keys %$raw) {
        for my $t (keys %{$raw->{$p}}) {
            for my $mod (keys %{$raw->{$p}->{$t}}) {

                RX:
                for my $rx (@$regexes) {

                    next RX unless $mod =~ /$rx/;

                    $prereqs
                        ->requirements_for($p, $t)
                        ->clear_requirement($mod)
                        ;
                    last RX;
                }
            }
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;
!!42;
__END__

=for Pod::Coverage mvp_multivalue_args

=head1 SYNOPSIS

    ; in your dist.ini
    [RemovePrereqsMatching]
    remove_matching = ^Template::Whatever::.*$
    remove_matching = ^Dist::Zilla.*$

=head1 DESCRIPTION

This plugin builds on L<Dist::Zilla::Plugin::RemovePrereqs> to allow
prerequisites to be removed by regular expression, rather than string
equality.  This can be useful when you have a C<DPAN> package consisting of a
bunch of modules under a common namespace, whose installation can be handled
by one common prerequisite specification.

=head1 OPTIONS

=head2 remove_matching

This option defines a regular expression that will be used to test
prerequisites for removal.  We may be specified multiple times to define
multiple expressions to test prerequisites against; a prerequisite needs to
match at least one expression to be excluded.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::RemovePrereqs>

=cut
