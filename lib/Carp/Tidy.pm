package Carp::Tidy;
use Carp;
use Carp::Heavy;
use Cwd;
use File::Spec;
use Exporter;

our $VERSION = '0.01';
our @ISA         = ('Exporter');
our @EXPORT      = qw(confess croak carp);
our @EXPORT_OK   = qw(cluck verbose longmess shortmess);
our @EXPORT_FAIL = qw(verbose);

*confess     = \&Carp::confess;
*croak       = \&Carp::croak;
*carp        = \&Carp::carp;
*cluck       = \&Carp::cluck;
*export_fail = \&export_fail;

use strict;
no warnings;

# hooks
our $top_mess   = \&_top_default;
our $stack_mess = \&_stack_default;
our $stack_filter = \&_stack_filter_default;
our $clan;

sub top {
	my %p = @_ == 1 ? (hook=>$_[0]) : @_;
	my $hook = $p{hook};
	$top_mess = $hook if ref $hook eq 'CODE';
}

sub import {
	my $package = shift;
	my $p = { @_ };
	$top_mess = $p->{-top} if ref $p->{-top} eq 'CODE';
	$clan     = $p->{-clan} if $p->{-clan};
	delete $p->{'-top'};
	my @a = @{ $p->{ import } || [] };
	Exporter::import( $package, @a );
}

sub stack {
	my %p = @_ == 1 ? (hook=>$_[0]) : @_;
	my $hook = $p{hook};
	$stack_mess = $hook if ref $hook eq 'CODE';
}

sub _top_default {
    my %i        = @_;
    my $file     = _to_rel( $i{file} );
	my $space    = ' ' x 3;
    return "$i{err}\nStack:\n$space$i{from_sub} ($file:$i{line}$i{tid_msg})\n";
}

sub _stack_default {
    my %i        = @_;
    my $file     = _to_rel( $i{file} );
	my $space    = ' ' x 3;
    my ( $vol, $dir, $filename ) = File::Spec->splitpath($file);
    return "$space$i{from_sub} ($filename:$i{line}$i{tid_msg})\n";
}

sub _stack_filter_default {
    my %i = @_;
	if( $Carp::Tidy::clan ) {
		my @arr = ref $Carp::Tidy::clan eq 'ARRAY'
			? @{$Carp::Tidy::clan} : ($Carp::Tidy::clan);
		OUTER: {
			$i{from_sub} =~ /$_/ and last OUTER
				for( @arr );
			return;
		}
	}
	return grep !/(eval \{)|(\(eval\))/, $i{from_sub};
}

sub _to_rel {
	return 'STDIN' if $_[0] eq '-';
    File::Spec->abs2rel( Cwd::realpath( $_[0] ) );
}

sub _from_sub {
	my $i=shift;
	my $from_sub = (caller( $i + 2 ))[3];
	( my $from_sub_name = $from_sub ) =~ s{^.*\:\:(\w+)$}{$1}g;
	return $from_sub, $from_sub_name;
}

sub Carp::ret_backtrace {
    my ( $i, @error ) = @_;
    my $mess;
    my $err = join '', @error;
    $i++;

	return $mess unless ref $Carp::Tidy::stack_mess eq 'CODE';

	# thread info
    my $tid_msg = '';
    if ( defined &threads::tid ) {
        my $tid = threads->tid;
        $tid_msg = " thread $tid" if $tid;
    }
    my %i = Carp::caller_info($i);
	$i{err} = $err;
	$i{tid_msg} = $tid_msg;
	$i{error_loc} = $i;
	( $i{from_sub}, $i{from_sub_name} ) = _from_sub( $i );

    $mess = $Carp::Tidy::top_mess->(%i);

	return $mess unless ref $Carp::Tidy::stack_mess eq 'CODE';

    while ( my %i = Carp::caller_info( ++$i ) ) {
	#use YAML; print Dump \%i;
		$i{tid_msg} = $tid_msg;
		$i{error_loc} = $i;
		( $i{from_sub}, $i{from_sub_name} ) = _from_sub( $i );
        next unless $Carp::Tidy::stack_filter->(%i);
        $mess .= $Carp::Tidy::stack_mess->(%i);
    }

    return $mess;
}

=head1 DESCRIPTION

Carp prettier. 

=head1 SYNOPSIS

	package Real::Long::Package::Name::That::Makes::Errors::Unreadable;
	use Carp;
	sub foo { confess "Bad boy"; }
	sub bar { foo(__PACKAGE__,{},[],{}) }
	sub baz { bar(__PACKAGE__,{},[],{}) }

	package main;
	Real::Long::Package::Name::That::Makes::Errors::Unreadable::baz()

=cut

1;





