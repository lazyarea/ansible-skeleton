#-------------------------------------------------------------------------------------------------
# Perl binding of Kyoto Cabinet
#                                                                Copyright (C) 2009-2010 FAL Labs
# This file is part of Kyoto Cabinet.
# This program is free software: you can redistribute it and/or modify it under the terms of
# the GNU General Public License as published by the Free Software Foundation, either version
# 3 of the License, or any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.
#-------------------------------------------------------------------------------------------------


package KyotoCabinet;

use strict;
use warnings;

require Exporter;
require XSLoader;
use base qw(Exporter);
our $VERSION = '1.20';
XSLoader::load('KyotoCabinet', $VERSION);



package KyotoCabinet::Error;

use overload q("") => \&string;
use overload "<=>" => \&compare;


sub new {
    my ($cls, $code, $message) = @_;
    my $self = [SUCCESS(), "error"];
    if (defined($code) && defined($message)) {
        $self->[0] = $code;
        $self->[1] = $message;
    }
    bless $self;
    return $self;
}


sub set {
    my ($self, $code, $message) = @_;
    $self->[0] = $code;
    $self->[1] = $message;
    return undef;
}


sub code {
    my ($self) = @_;
    return $self->[0];
}


sub name {
    my ($self) = @_;
    return err_codename($self->[0]);
}


sub message {
    my ($self) = @_;
    return $self->[1];
}


sub string {
    my ($self) = @_;
    return sprintf("%s: %s", $self->name, $self->message);
}


sub compare {
    my ($self, $right) = @_;
    $right = $right->code if (ref($right) eq __PACKAGE__);
    return $self->code <=> $right;
}



package KyotoCabinet::Visitor;


sub new {
    my ($cls) = @_;
    my $self = {};
    bless $self;
    return $self;
}


sub visit_full {
    my ($self, $key, $value) = @_;
    return $self->NOP;
}


sub visit_empty {
    my ($self, $key) = @_;
    return $self->NOP;
}



package KyotoCabinet::FileProcessor;

sub new {
    my ($cls) = @_;
    my $self = {};
    bless $self;
    return $self;
}


sub process {
    my ($self, $path, $count, $size) = @_;
    return 1;
}



package KyotoCabinet::Cursor;

use overload q("") => \&string;


sub new {
    my ($cls, $db) = @_;
    my $self = [0, undef];
    $self->[0] = cur_new($db->[0]);
    $self->[1] = $db;
    bless $self;
    return $self;
}


sub DESTROY {
    my ($self) = @_;
    cur_delete($self->[0]);
    return undef;
}


sub disable {
    my ($self) = @_;
    cur_disable($self->[0]);
    $self->[0] = 0;
    return undef;
}


sub accept {
    my ($self, $visitor, $writable, $step) = @_;
    $writable = 1 if (!defined($writable));
    $step = 0 if (!defined($step));
    return cur_accept($self->[0], $visitor, $writable, $step);
}


sub set_value {
    my ($self, $value, $step) = @_;
    return cur_set_value($self->[0], $value, $step);
}


sub remove {
    my ($self) = @_;
    return cur_remove($self->[0]);
}


sub get_key {
    my ($self, $step) = @_;
    $step = 0 if (!defined($step));
    return cur_get_key($self->[0], $step);
}


sub get_value {
    my ($self, $step) = @_;
    $step = 0 if (!defined($step));
    return cur_get_value($self->[0], $step);
}


sub get {
    my ($self, $step) = @_;
    $step = 0 if (!defined($step));
    return cur_get($self->[0], $step);
}


sub seize {
    my ($self) = @_;
    return cur_seize($self->[0]);
}


sub jump {
    my ($self, $key) = @_;
    return cur_jump($self->[0], $key);
}


sub jump_back {
    my ($self, $key) = @_;
    return cur_jump_back($self->[0], $key);
}


sub step {
    my ($self) = @_;
    return cur_step($self->[0]);
}


sub step_back {
    my ($self) = @_;
    return cur_step_back($self->[0]);
}


sub db {
    my ($self) = @_;
    return $self->[1];
}


sub error {
    my ($self) = @_;
    return $self->[1]->error;
}


sub string {
    my ($self) = @_;
    my $db = $self->[1];
    my $path = $db->path;
    $path = "(undef)" if (!defined($path));
    my $key = $self->get_key;
    $key = "(undef)" if (!defined($key));
    return sprintf("%s: %s", $path, $key);
}



package KyotoCabinet::DB;

use overload q("") => \&string;


sub new {
    my ($cls) = @_;
    my $self = [0, undef, undef];
    $self->[0] = db_new();
    bless $self;
    return $self;
}


sub DESTROY {
    my ($self) = @_;
    db_delete($self->[0]);
    return undef;
}


sub error {
    my ($self) = @_;
    my ($code, $message) = db_error($self->[0]);
    return KyotoCabinet::Error->new($code, $message);
}


sub open {
    my ($self, $path, $mode) = @_;
    $path = ":" if (!defined($path));
    $mode = OWRITER() | OCREATE() if (!defined($mode) || $mode < 1);
    return db_open($self->[0], $path, $mode);
}


sub close {
    my ($self) = @_;
    return db_close($self->[0]);
}


sub accept {
    my ($self, $key, $visitor, $writable) = @_;
    $writable = 1 if (!defined($writable));
    return db_accept($self->[0], $key, $visitor, $writable);
}


sub accept_bulk {
    my ($self, $keys, $visitor, $writable) = @_;
    return 0 if (ref($keys) ne 'ARRAY');
    $writable = 1 if (!defined($writable));
    foreach my $key (@$keys) {
        return 0 if (!db_accept($self->[0], $key, $visitor, $writable));
    }
    return 1;
}


sub iterate {
    my ($self, $visitor, $writable) = @_;
    $writable = 1 if (!defined($writable));
    return db_iterate($self->[0], $visitor, $writable);
}


sub set {
    my ($self, $key, $value) = @_;
    return db_set($self->[0], $key, $value);
}


sub add {
    my ($self, $key, $value) = @_;
    return db_add($self->[0], $key, $value);
}


sub replace {
    my ($self, $key, $value) = @_;
    return db_replace($self->[0], $key, $value);
}


sub append {
    my ($self, $key, $value) = @_;
    return db_append($self->[0], $key, $value);
}


sub increment {
    my ($self, $key, $num, $orig) = @_;
    $num = 0 if (!defined($num));
    $orig = 0 if (!defined($orig));
    return db_increment($self->[0], $key, $num, $orig);
}


sub increment_double {
    my ($self, $key, $num, $orig) = @_;
    $num = 0 if (!defined($num));
    $orig = 0 if (!defined($orig));
    return db_increment_double($self->[0], $key, $num, $orig);
}


sub cas {
    my ($self, $key, $oval, $nval) = @_;
    return db_cas($self->[0], $key, $oval, $nval);
}


sub remove {
    my ($self, $key) = @_;
    return db_remove($self->[0], $key);
}


sub get {
    my ($self, $key) = @_;
    return db_get($self->[0], $key);
}


sub check {
    my ($self, $key) = @_;
    return db_check($self->[0], $key);
}


sub seize {
    my ($self, $key) = @_;
    return db_seize($self->[0], $key);
}


sub set_bulk {
    my ($self, $recs) = @_;
    return -1 if (ref($recs) ne 'HASH');
    my $rv = 0;
    while (my ($key, $value) = each(%$recs)) {
        return -1 if (!db_set($self->[0], $key, $value));
        $rv++;
    }
    return $rv;
}


sub remove_bulk {
    my ($self, $keys) = @_;
    return -1 if (ref($keys) ne 'ARRAY');
    my $rv = 0;
    foreach my $key (@$keys) {
        $rv++ if (db_remove($self->[0], $key));
    }
    return $rv;
}


sub get_bulk {
    my ($self, $keys) = @_;
    return -1 if (ref($keys) ne 'ARRAY');
    my %recs;
    foreach my $key (@$keys) {
        my $value = db_get($self->[0], $key);
        $recs{$key} = $value if (defined($value));
    }
    return \%recs;
}


sub clear {
    my ($self) = @_;
    return db_clear($self->[0]);
}


sub synchronize {
    my ($self, $hard, $proc) = @_;
    return db_synchronize($self->[0], $hard, $proc);
}


sub occupy {
    my ($self, $writable, $proc) = @_;
    return db_occupy($self->[0], $writable, $proc);
}


sub copy {
    my ($self, $dest) = @_;
    return db_copy($self->[0], $dest);
}


sub begin_transaction {
    my ($self, $hard) = @_;
    $hard = 0 if (!defined($hard));
    return db_begin_transaction($self->[0], $hard);
}


sub end_transaction {
    my ($self, $commit) = @_;
    $commit = 1 if (!defined($commit));
    return db_end_transaction($self->[0], $commit);
}


sub transaction {
    my ($self, $proc, $hard) = @_;
    return 0 if (!$self->begin_transaction($hard));
    my $commit = 0;
    eval {
        $commit = &$proc($self);
    };
    return 0 if (!$self->end_transaction($commit));
    return 1;
}


sub dump_snapshot {
    my ($self, $dest) = @_;
    return db_dump_snapshot($self->[0], $dest);
}


sub load_snapshot {
    my ($self, $src) = @_;
    return db_load_snapshot($self->[0], $src);
}


sub count {
    my ($self) = @_;
    return db_count($self->[0]);
}


sub size {
    my ($self) = @_;
    return db_size($self->[0]);
}


sub path {
    my ($self) = @_;
    return db_path($self->[0]);
}


sub status {
    my ($self) = @_;
    my $ststr = db_status($self->[0]);
    return undef if (!defined($ststr));
    my %stmap;
    my @lines = split(/\n/, $ststr);
    foreach my $line (@lines) {
        my @fields = split(/\t/, $line);
        $stmap{$fields[0]} = $fields[1] if (scalar(@fields) > 1);
    }
    return \%stmap;
}


sub match_prefix {
    my ($self, $prefix, $max) = @_;
    $max = -1 if (!defined($max));
    return db_match_prefix($self->[0], $prefix, $max);
}


sub match_regex {
    my ($self, $regex, $max) = @_;
    $max = -1 if (!defined($max));
    return db_match_regex($self->[0], $regex, $max);
}


sub match_similar {
    my ($self, $origin, $range, $utf, $max) = @_;
    $range = 1 if (!defined($range));
    $utf = 0 if (!defined($utf));
    $max = -1 if (!defined($max));
    return db_match_similar($self->[0], $origin, $range, $utf, $max);
}


sub merge {
    my ($self, $srcary, $mode) = @_;
    $mode = MSET() if (!defined($mode));
    return db_merge($self->[0], $srcary, $mode);
}


sub cursor {
    my ($self) = @_;
    return KyotoCabinet::Cursor->new($self);
}


sub cursor_process {
    my ($self, $proc) = @_;
    my $cur = $self->cursor;
    eval {
        &$proc($cur);
    };
    $cur->disable;
    return undef;
}


sub string {
    my ($self) = @_;
    my $path = $self->path;
    $path = "(undef)" if (!defined($path));
    return sprintf("%s: %ld: %ld", $path, $self->count, $self->size);
}


sub process {
    my ($cls, $proc, $path, $mode) = @_;
    my $db = $cls->new;
    return $db->error if (!$db->open($path, $mode));
    &$proc($db);
    return $db->error if (!$db->close);
    return undef;
}


sub TIEHASH {
    my ($cls, $path, $mode) = @_;
    my $db = $cls->new;
    return undef if (!$db->open($path, $mode));
    my $cur = $db->cursor;
    undef($cur->[1]);
    $db->[1] = $cur;
    return $db;
}


sub UNTIE {
    my ($self) = @_;
    return $self->close;
}


sub FETCH {
    return db_get($_[0]->[0], $_[1]);
}


sub STORE {
    return db_set($_[0]->[0], $_[1], $_[2]);
}


sub DELETE {
    return db_remove($_[0]->[0], $_[1]);
}


sub CLEAR {
    return db_clear($_[0]->[0]);
}


sub EXISTS {
    return defined(db_get($_[0]->[0], $_[1]));
}


sub FIRSTKEY {
    my $cur = $_[0]->[1];
    $cur->jump;
    my $key = $cur->get_key(1);
    $_[0]->[2] = $key;
    return $key;
}


sub NEXTKEY {
    my $cur = $_[0]->[1];
    my $key = $cur->get_key(1);
    return undef if (!defined($key));
    if ($key eq $_[0]->[2]) {
        undef($_[0]->[2]);
        return undef;
    }
    return $key;
}



1;

# END OF FILE
