package Library::Build;
use 5.008005;
use strict;
use warnings;
use Getopt::Long qw(:config gnu_getopt no_auto_abbrev no_ignore_case);
use Library::Build::Config;
use Library::Build::HTTP;
use Library::Build::Logger;
use Library::Build::Archive;
use File::Spec::Functions qw(catdir catfile);
use File::Spec;
use File::pushd 'pushd';
use File::Temp 'tempdir';
use File::Copy qw(move copy);
use File::Path qw(rmtree mkpath);
use POSIX 'strftime';

our $VERSION = "0.01";
sub help {
    print <<"...";
Usage:
    > library-build [file|url]

Example:
    > library-build http://ftp.gnu.org/gnu/bash/bash-4.3.tar.gz
    > library-build https://github.com/shoichikaji/Path-Maker/zipball/master

Options:
    --cache_dir   dir to store downloaded file, default \$HOME/.library-build/cache
    --build_dir   dir in which libraries to be built, default \$HOME/.library-build/build
    --prefix      dir to install libraries, default \$HOME/local
    --shell       your shell, default \$SHELL
    --list, -l    show list of downloaded libraries
    --help, -h    show this help message
...
}

sub new {
    my $class = shift;
    bless {}, $class;
}
sub config { shift->{config} }
sub http   { shift->{http} }
sub path   { @{ shift->{path} } }
sub shell  { shift->{shell} }

sub parse_options {
    my ($self, @argv) = @_;
    local @ARGV = @argv;
    GetOptions
        "cache_dir=s" => \(my $cache_dir),
        "build_dir=s" => \(my $build_dir),
        "prefix=s"    => \(my $prefix),
        "shell=s"     => \(my $shell),
        "l|list"      => \(my $show_list),
        "h|help"      => sub { help(); exit },
    or do { help(); exit };
    $self->{shell} = $shell || $ENV{SHELL} || "/bin/bash";
    $self->{config} = Library::Build::Config->new(
        prefix => $prefix, cache_dir => $cache_dir, build_dir => $build_dir,
    );

    if ($show_list) {
        chdir $self->config->cache_dir;
        print "pre downloaded libraries are:\n";
        for my $file (sort glob "*") {
            my $mtime = (stat $file)[9];
            printf "[%s] %s\n", strftime("%F %T", localtime($mtime)), $file;
        }
        exit;
    }

    $ENV{PATH} = catdir($self->config->prefix, "bin") . ":$ENV{PATH}";
    $self->{http} = Library::Build::HTTP->new;
    $self->{argv} = shift @ARGV;
    $self;
}

sub build {
    my $self = shift;
    my $argv = shift || $self->{argv} or croak "ERROR don't know what to do!";

    my $where = $self->where( $argv );
    my $file  = $self->get( where => $where, argv => $argv );

    $self->_build($file);
}

sub _build {
    my ($self, $file) = @_;
    $self->clean_build_dir;
    my $build_dir = catdir(
        $self->config->build_dir,
        strftime("%Y%m%d%H%M%S_$$", localtime),
    );
    mkpath $build_dir or die;
    chdir $build_dir or die;
    copy $file, ".";
    my ($archive) = glob "*";
    Library::Build::Archive->new(archive => $archive)->extract;
    my ($dir) = grep -d, glob "*";

    chdir $dir or die;
    $ENV{PREFIX}   = $self->config->PREFIX;
    $ENV{LDFLAGS}  = $self->config->LDFLAGS;
    $ENV{CPPFLAGS} = $self->config->CPPFLAGS;

    print <<"...";
----------------------------------------------
Set the following environment variables:

PREFIX   $ENV{PREFIX}
CPPFLAGS $ENV{CPPFLAGS}
LDFLAGS  $ENV{LDFLAGS}
PATH     $ENV{PATH}

How to compile, for example;
./configure --help
./configure --prefix=\$PREFIX

Now invoke new shell @{[$self->shell]} -l
---------------------------------------------
...
    exec $self->shell, "-l";
    die;
}

sub clean_build_dir {
    my $self = shift;
    my $guard = pushd $self->config->build_dir;
    my @dir = grep -d, glob "*";
    my $now = time;
    for my $dir (@dir) {
        my $mtime = (stat $dir)[9];
        if ($now - $mtime > 60 * 60 * 24 * 14) {
            info "remove 14 days before build dir $dir";
            rmtree $dir or die $!;
        }
    }
}

sub where {
    my ($self, $argv) = @_;
    if ($argv =~ /^(https?|ftp)/) {
        return "http";
    } else {
        return "cache";
    }
}

sub get {
    my ($self, %opt) = @_;
    my $where = $opt{where} or die;
    my $argv  = $opt{argv} or die;

    if ($where eq 'http') {
        $self->http_get($argv);
    } elsif ($where eq 'cache') {
        $self->cache_get($argv);
    } else {
        die;
    }
}
sub cache_get {
    my ($self, $file) = @_;
    my $guard = pushd $self->config->cache_dir;
    my ($matched) = glob "$file*";
    if ($matched) {
        return catfile($self->config->cache_dir, $matched);
    } else {
        croak "ERROR cannot find file matching $file";
    }
}

sub http_get {
    my ($self, $url) = @_;

    my $downloaded_file;
    my $tempdir = tempdir CLEANUP => 1;
    {
        my $guard = pushd $tempdir;
        xsystem($self->http->command, @{ $self->http->option }, $url);

        my ($archive) = glob "*";
        croak "ERROR missing archive" unless $archive;

        # github tweak
        if ($url =~ /github\.com/ && $archive !~ /(tgz|tar\.gz|zip)$/) {
            debug "github filename fix";
            my $type = $url =~ /(tar\.gz|tarball)/ ? "tar.gz"
                     : $url =~ /zip/               ? "zip" : die;
            debug "rename %s %s", $archive, "$archive.$type";
            move $archive, "$archive.$type" or die $!;
            $archive = "$archive.$type";
        }

        my $extracter = Library::Build::Archive->new( archive => $archive );
        $extracter->extract
            or croak "ERROR cannot determine of top dir of %s", $archive;

        my $natural_name = $extracter->natural_name;
        my $target = catfile($self->config->cache_dir, $natural_name);
        if (-e $target) {
            info "-> already exists $target, shouldn't have downloaded it...";
            unlink $target or die $!
        }
        move $archive, $target or die $!;
        $downloaded_file = $target;
        debug "downloaded file is $downloaded_file";
    }
    rmtree $tempdir;
    return $downloaded_file;
}

sub xsystem {
    my @cmd = @_;
    info "-> @cmd";
    !system @cmd or croak "=> ERROR @cmd";
}


1;
__END__

=for stopwords library-build.fatpack autotools fatpacked

=encoding utf-8

=head1 NAME

Library::Build - build libraries

=head1 SYNOPSIS

    > curl -O https://raw.githubusercontent.com/shoichikaji/Library-Build/master/library-build.fatpack
    > chmod +x library-build.fatpack
    > ./library-build.fatpack http://ftp.gnu.org/gnu/tar/tar-1.27.tar.xz

=head1 DESCRIPTION

Library::Build may help you build libraries.

If you build autotools style libraries to your favorite directory,
you should set C<LDFLAGS>, C<CPPFLAGS> appropriately.
If you're tired of it, this module helps you.

The fatpacked script `library-build.fatpack` only requires perl 5.8.5+,
you can try it easily. See SYNOPSIS.

=head1 LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

