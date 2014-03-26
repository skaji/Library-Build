package Library::Build::Logger;
use strict;
use warnings;
our $VERSION = "0.001";
use Carp ();
$Carp::Internal{ (__PACKAGE__) }++;

use Exporter 'import';
our @EXPORT = qw(info croak debug);

use constant INTERACTIVE => -t *STDOUT;

my %color = (
    red   => 31,
    green => 32,
    white => 37,
);

sub debug {
    return if !$ENV{LIBRARY_BUILD_DEBUG};
    my $format = @_ == 1 ? "%s" : shift;
    $format =~ s/\n$//;
    my $str = sprintf $format, @_;
    warn "[DEBUG] $str\n";
}

sub info {
    my $format = @_ == 1 ? "%s" : shift;
    $format =~ s/\n$//;
    my $str = sprintf $format, @_;
    if (INTERACTIVE) {
        warn "\e[1;$color{white}m$str\e[m\n";
    } else {
        warn $str, "\n";
    }
}

sub croak {
    my $format = @_ == 1 ? "%s" : shift;
    $format =~ s/\n$//;
    my $str = sprintf $format, @_;
    if (INTERACTIVE) {
        Carp::croak("\e[1;$color{red}m$str\e[m");
    } else {
        Carp::croak($str);
    }
}

1;
