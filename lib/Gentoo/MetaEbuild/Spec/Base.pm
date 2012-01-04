use strict;
use warnings;

package Gentoo::MetaEbuild::Spec::Base;
BEGIN {
  $Gentoo::MetaEbuild::Spec::Base::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::MetaEbuild::Spec::Base::VERSION = '0.1.4';
}

# ABSTRACT: A Base Class for Gentoo MetaEbuild Specifications.



use Moose;
use MooseX::ClassAttribute;

use File::ShareDir qw( module_dir );
use Path::Class qw( dir file );
use MooseX::Types::Moose qw( :all );
use MooseX::Types::Perl qw( VersionObject );
use MooseX::Types::Path::Class qw( Dir File );
use Scalar::Util qw( blessed );
use MooseX::Has::Sugar;
use version;

use namespace::autoclean;

class_has '_decoder' => (
  isa => CodeRef,
  ro, lazy_build,
  traits  => [qw( Code )],
  handles => { _decode => 'execute', },
);

sub _build__decoder {
  require JSON::XS;
  my $decoder = JSON::XS->new()->utf8(1)->relaxed(1);
  return sub {
    $decoder->decode(shift);
  };
}

class_has '_spec_dir' => (
  isa => Dir,
  rw, lazy_build,
);

sub _build__spec_dir {
  my ($self) = shift;
  my $classname;
  if ( ref $self && blessed $self ) {
    $classname = blessed $self;
  }
  elsif ( ref $self ) {
    require Carp;
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    Carp::confess q{$_[0] is not a Class/Object};
  }
  else {
    $classname = $self;
  }
  return dir( module_dir($classname) );
}

class_has '_version' => (
  isa => VersionObject,
  coerce, ro, lazy, default => sub { q{0.1.0} },
);

class_has '_extension' => (
  isa => Str,
  ro, lazy, default => sub { q{.json} },
);

class_has '_schema_creator' => (
  isa => CodeRef,
  ro, lazy_build,
  traits  => [qw( Code )],
  handles => { _make_schema => 'execute', },
);

sub _build__schema_creator {
  require Data::Rx;
  my $rx = Data::Rx->new();
  return sub {
    $rx->make_schema(shift);
  };
}

sub _opt_check {
  my ( $self, $opts ) = @_;
  if ( not exists $opts->{version} ) {
    $opts->{version} = $self->_version;
  } elsif( blessed $opts->{version} ){

  } else {
    $opts->{version} = version->parse( $opts->{version} );
  }
  return $opts;
}

sub _spec_file {
  my ( $self, $opts ) = @_;
  $opts = $self->_opt_check($opts);
  return $self->_spec_dir->file( $opts->{version}->normal . $self->_extension );
}

sub _spec_data {
  my ( $self, $opts ) = @_;
  $opts = $self->_opt_check($opts);
  return $self->_decode( scalar $self->_spec_file($opts)->slurp() );
}

sub _schema {
  my ( $self, $opts ) = @_;
  $opts = $self->_opt_check($opts);
  return $self->_make_schema( $self->_spec_data($opts) );
}


sub check {
  my ( $self, $data, $opts ) = @_;
  $opts = $self->_opt_check($opts);
  return $self->_schema($opts)->check($data);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Gentoo::MetaEbuild::Spec::Base - A Base Class for Gentoo MetaEbuild Specifications.

=head1 VERSION

version 0.1.4

=head1 SYNOPSIS

    use Gentoo::MetaEbuild::Spec::Base; # or some derived class
    Gentoo::MetaEbuild::Spec::Base->check( $datastructure );

This base-class only validates the most basic of basic, that the data is a  { } using Data::Rx
and using the shipped File::ShareDir v1.0.0.json spec to do that.

This will be more practical in consuming classes as they'll override selected methods/ship different spec files,
but maintain the same useful interface.

=head1 METHODS

=head2 check

    Packagename->check( $datastructure );

    Packagename->check( $datastructure, \%opts );

    Packagename->check( $datastructure, { version => '0.1.0' });

=head1 EXTENDING

Extending should be this simple:

    package FooBarBaz;
    use Moose;
    extends 'Gentoo::MetaEbuild::Spec::Base';

    1;

and then ship a directory of Data::Rx spec files as the Module ShareDir for that module.

=head1 TESTING

The only fun thing with testing is the File::ShareDir directory hasn't been installed yet, but its simple to get around.

    use FindBin;
    use Path::Class qw( dir );
    use Gentoo::MetaEbuild::Spec::Base;

    Gentoo::MetaEbuild::Spec::Base->_spec_dir(
        dir($FindBin::Bin)->parent->subdir('share')
    );

    # Code as per usual.

    my $shareroot = dir($FindBin::Bin)->parent();

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

