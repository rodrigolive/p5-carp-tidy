use strict;
use warnings;
use Test::More tests => 1;

eval {
	package Real::Long::Package::Name::That::Makes::Errors::Unreadable;
	use Carp::Tidy;
	sub foo {
		confess "Bad boy";
	}
	sub bar { foo(__PACKAGE__,{},[],{}) }
	sub baz { bar(__PACKAGE__,{},[],{}) }

	package main;
	Real::Long::Package::Name::That::Makes::Errors::Unreadable::baz()
};
print $@;

eval {
	use Carp::Tidy;
	sub foo { confess "Bad boy"; }
	sub bar { foo(__PACKAGE__,{},[],{}) }
	sub baz { bar(__PACKAGE__,{},[],{}) }

	baz()
};
print $@;

eval {
	use Carp;
	sub foo { print "\n", join"\n",caller }
	sub bar { foo(__PACKAGE__,{},[],{}) }
	sub baz { bar(__PACKAGE__,{},[],{}) }

	baz()
};
print $@;
