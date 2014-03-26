# NAME

Library::Build - build libraries

# SYNOPSIS

    > curl -O https://raw.githubusercontent.com/shoichikaji/Library-Build/master/library-build.fatpack
    > chmod +x library-build.fatpack
    > ./library-build.fatpack http://ftp.gnu.org/gnu/tar/tar-1.27.tar.xz

# DESCRIPTION

Library::Build may help you build libraries.

If you build autotools style libraries to your favorite directory,
you should set `LDFLAGS`, `CPPFLAGS` appropriately.
If you're tired of it, this module helps you.

The fatpacked script \`library-build.fatpack\` only requires perl 5.8.5+,
you can try it easily. See SYNOPSIS.

# LICENSE

Copyright (C) Shoichi Kaji.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shoichi Kaji <skaji@cpan.org>
