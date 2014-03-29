package Library::Build::Archive;
use strict;
use warnings;
our $VERSION = "0.001";

my %TYPE = (
    'tar.gz'  => 'tar.gz',
    'tgz'     => 'tar.gz',
    'zip'     => 'zip',
    'tar.xz'  => 'tar.xz',
    'txz'     => 'tar.xz',
    'tar.bz2' => 'tar.bz2',
    'tbz'     => 'tar.bz2',
);

my $TYPE_REGEXP = do {
    my $type = join "|", map { s/\./\\./g; $_ } keys %TYPE;
    qr/$type/;
};


sub new {
    my ($class, %opt) = @_;
    my $self;
    my $archive = $self->{archive} = $opt{archive}
        or die "missing archive";

    my $type = $opt{type};
    unless ($type) {
        if ($archive =~ /($TYPE_REGEXP)$/) {
            $type = $1;
        } else {
            die "ERROR cannot determine archive type: $archive";
        }
    }
    $self->{type} = $TYPE{$type}
        or die "ERROR invalid archive type: $type";
    bless $self, $class;
}
sub type { shift->{type} }
sub archive { shift->{archive} }

sub extract {
    my ($self, %option) = @_;
    my $to = $option{to};
    if ($to && !-d $to) {
        die "ERROR missing directory '$to'";
    }
    my $archive = $self->{archive};
    my $type    = $self->{type};
    my %original = map { $_ => 1 } glob "*";
    my @cmd;
    if ($type eq 'tar.gz') {
        push @cmd, "tar", "xzf", $archive, $to ? (-C => $to) : ();
    } elsif ($type eq 'tar.bz2') {
        push @cmd, "tar", "xjf", $archive, $to ? (-C => $to) : ();
    } elsif ($type eq 'tar.xz') {
        push @cmd, "tar", "xJf", $archive, $to ? (-C => $to) : ();
    } elsif ($type eq 'zip') {
        push @cmd, 'unzip', "-q", $archive, $to ? (-d => $to) : ();
    } else {
        die;
    }
    !system @cmd or die "ERRRO failed @cmd\n";

    my @extracted = grep { !$original{$_} } glob "*";
    die "ERROR failed to extract $archive" unless @extracted;
    if (@extracted > 1) {
        warn "WARN $archive yields not one directory but followings:\n";
        warn "  $_\n" for sort @extracted;
    }
    $self->{top_dir} = $extracted[0];
    return $self->{top_dir};
}

sub natural_name {
    my $self = shift;
    my $top_dir = $self->{top_dir}
        or die "ERROR don't invoke natural_name() method before extract()";
    my $type = $self->{type};
    "$top_dir.$type";
}



1;
