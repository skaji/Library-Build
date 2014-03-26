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
    my $self = shift;
    my $archive = $self->{archive};
    my $type    = $self->{type};
    my %original = map { $_ => 1 } glob "*";
    if ($type eq 'tar.gz') {
        !system "tar", "xzf", $archive or die "ERROR tar xzf $archive faild";
    } elsif ($type eq 'tar.bz2') {
        !system "tar", "xjf", $archive or die "ERROR tar xjf $archive faild";
    } elsif ($type eq 'tar.xz') {
        !system "tar", "xJf", $archive or die "ERROR tar xJf $archive faild";
    } elsif ($type eq 'zip') {
        !system "unzip", $archive or die "ERROR unzip $archive faild";
    } else {
        die;
    }

    my ($top_dir) = grep { !$original{$_} } glob "*";
    $self->{top_dir} = $top_dir;
    return $top_dir;
}

sub natural_name {
    my $self = shift;
    my $top_dir = $self->{top_dir}
        or die "ERROR don't invoke natural_name() method before extract()";
    my $type = $self->{type};
    "$top_dir.$type";
}



1;
