package Library::Build::Config;
use strict;
use warnings;
our $VERSION = "0.001";
use File::Spec::Functions qw(catdir catfile);
use File::Spec;
use File::Path qw(mkpath);

sub new {
    my ($class, %opt) = @_;
    my $home = $ENV{HOME} or die "ERROR cannot determine prefix direcotry";
    my $prefix = $opt{prefix} || catdir($home, "local");
    unless (-d $prefix) {
        mkpath $prefix or die "ERROR cannot mkpath $prefix: $!";
    }
    my $cache_dir = $opt{cache_dir} || catdir($home, ".library-build/cache");
    my $build_dir = $opt{build_dir} || catdir($home, ".library-build/build");
    for my $dir (grep !-d, $cache_dir, $build_dir) {
        mkpath $dir or die "ERROR cannot mkpath $dir: $!";
    }
    s{/$}{} for $prefix, $cache_dir, $build_dir;
    bless {
        prefix => $prefix,
        cache_dir => $cache_dir,
        build_dir => $build_dir,
    }, $class;
}

sub prefix { shift->{prefix} }
sub PREFIX { shift->{prefix} }
sub build_dir { shift->{build_dir} }
sub cache_dir { shift->{cache_dir} }
sub PATH {
    my $prefix = shift->prefix;
    "$prefix/bin";
}
sub LDFLAGS {
    my $prefix = shift->prefix;
    "-L$prefix/lib -Wl,-rpath,$prefix/lib";
}
sub CPPFLAGS {
    my $prefix = shift->prefix;
    "-I$prefix/include";
}

1;
