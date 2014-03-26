package Library::Build::HTTP;
use strict;
use warnings;
our $VERSION = "0.001";

use File::Spec;

sub new {
    my $class = shift;
    my $self = bless { command => "", option => [] }, $class;
    $self->build;
}

sub command { shift->{command} }
sub option  { shift->{option} }

sub build {
    my $self = shift;
    if ($self->which("curl")) {
        $self->{command} = "curl";
        $self->{option}  = ["-skLO"];
    } elsif ($self->which("wget")) {
        $self->{command} = "wget";
        $self->{option}  = ["--no-check-certificate"];
    } elsif ($self->which("fetch")) {
        $self->{command} = "fetch";
        $self->{option}  = [];
    } else {
        die "ERROR cannot find curl, wget, nor fetch!\n";
    }
    $self;
}
sub which {
    my ($self, $cmd) = @_;
    for my $path (File::Spec->path) {
        my $try = File::Spec->catfile($path, $cmd);
        return $try if -x $try && !-d $try;
    }
    return;
}


1;
