package Test::Stream::Plugin::Context;
use strict;
use warnings;

use Test::Stream::Context qw/context release/;

use Test::Stream::Exporter;
exports qw/release/;
default_exports qw/context/;
no Test::Stream::Exporter;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Stream::Plugin::Context - Plugin to expose the context function.

=head1 EXPERIMENTAL CODE WARNING

B<This is an experimental release!> Test-Stream, and all its components are
still in an experimental phase. This dist has been released to cpan in order to
allow testers and early adopters the chance to write experimental new tools
with it, or to add experimental support for it into old tools.

B<PLEASE DO NOT COMPLETELY CONVERT OLD TOOLS YET>. This experimental release is
very likely to see a lot of code churn. API's may break at any time.
Test-Stream should NOT be depended on by any toolchain level tools until the
experimental phase is over.

=head1 DESCRIPTION

This plugin exposes the C<context()> function. This function is used by tools
to mark/find the context of a test. It is also the primary interface for
generating test events.

=head1 SYNOPSIS

    use Test::Stream qw/-V1 Context/;

    sub my_tool {
        my $ctx = context();
        ...
        $ctx->release;
    }

=head1 SOURCE

The source code repository for Test::Stream can be found at
F<http://github.com/Test-More/Test-Stream/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
