use strict;
use warnings;

use Test::More 0.96;
use FindBin;
use Test::File::ShareDir
  -root  => "$FindBin::Bin/../",
  -share => { -module => { 'Gentoo::MetaEbuild::Spec::Base' => 't/fake_spec' } };

use Gentoo::MetaEbuild::Spec::Base;
use version;
ok( Gentoo::MetaEbuild::Spec::Base->check( {}, { version => version->parse('0.1.0') } ), ' {} is 0.1.0 spec' );
ok( !Gentoo::MetaEbuild::Spec::Base->check( [], { version => version->parse('0.1.0') } ), '[] is not 0.1.0 spec' );
ok( !Gentoo::MetaEbuild::Spec::Base->check( {}, { version => version->parse('0.1.1') } ), '{} is not 0.1.1 spec' );
ok( Gentoo::MetaEbuild::Spec::Base->check( [], { version => version->parse('0.1.1') } ), '[] is 0.1.1 spec' );

done_testing;
