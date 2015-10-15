#! /usr/bin/perl -w
# -*- coding: utf-8 -*-

#-------------------------------------------------------------------------------------------------
# The test cases of the Perl binding
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


use lib qw(./blib/lib ./blib/arch);
use strict;
use warnings;
use ExtUtils::testlib;
use Time::HiRes qw(gettimeofday);
use Data::Dumper;
use File::Path;
use KyotoCabinet;


# implementation of the visitor
{
    package VisitorImpl;
    use base qw(KyotoCabinet::Visitor);
    sub new {
        my ($cls, $rnd) = @_;
        my $self = new KyotoCabinet::Visitor;
        $self->{rnd} = $rnd;
        $self->{cnt} = 0;
        bless $self;
        return $self;
    }
    sub visit_full {
        my ($self, $key, $value) = @_;
        $self->{cnt}++;
        my $rv = $self->NOP;
        if ($self->{rnd}) {
            my $num = int(rand(7));
            if ($num == 0) {
                $rv = $self->{cnt};
            } elsif ($num == 1) {
                $rv = $self->REMOVE;
            }
        }
        return $rv
    }
    sub visit_empty {
        my ($self, $key) = @_;
        return $self->visit_full($key, $key);
    }
}


# main routine
sub main {
    my $rv;
    scalar(@ARGV) >= 1 || usage();
    if($ARGV[0] eq "order"){
        $rv = runorder();
    } elsif($ARGV[0] eq "wicked"){
        $rv = runwicked();
    } elsif($ARGV[0] eq "misc"){
        $rv = runmisc();
    } else {
        usage();
    }
    return $rv;
}


# print the usage and exit
sub usage {
    printf STDERR ("%s: test cases of the Perl binding\n", $0);
    printf STDERR ("\n");
    printf STDERR ("usage:\n");
    printf STDERR ("  %s order [-rnd] [-etc] path rnum\n", $0);
    printf STDERR ("  %s wicked [-it num] path rnum\n", $0);
    printf STDERR ("  %s misc path\n", $0);
    printf STDERR ("\n");
    exit(1);
}


# print the error message of the database
sub dberrprint {
    my ($db, $func) = @_;
    my $err = $db->error;
    printf("%s: %s: %d: %s: %s\n", $0, $func, $err->code, $err->name, $err->message);
}


# print members of a database
sub dbmetaprint {
    my ($db, $verbose) = @_;
    if ($verbose) {
        my $status = $db->status;
        if (defined($status)) {
            while (my ($name, $value) = each(%$status)) {
                printf("%s: %s\n", $name, $value);
            }
        }
    } else {
        printf("count: %d\n", $db->count);
        printf("size: %d\n", $db->size)
    }
}


# parse arguments of order command
sub runorder {
    my $path = undef;
    my $rnum = undef;
    my $rnd = 0;
    my $etc = 0;
    for(my $i = 1; $i < scalar(@ARGV); $i++){
        if(!defined($path) && $ARGV[$i] =~ /^-/){
            if($ARGV[$i] eq "-rnd"){
                $rnd = 1;
            } elsif($ARGV[$i] eq "-etc"){
                $etc = 1;
            } else {
                usage();
            }
        } elsif(!defined($path)){
            $path = $ARGV[$i];
        } elsif(!defined($rnum)){
            $rnum = int($ARGV[$i]);
        } else {
            usage();
        }
    }
    usage() if(!defined($path) || !defined($rnum) || $rnum < 1);
    my $rv = procorder($path, $rnum, $rnd, $etc);
    return $rv
}


# parse arguments of wicked command
sub runwicked {
    my $path = undef;
    my $rnum = undef;
    my $itnum = 1;
    for(my $i = 1; $i < scalar(@ARGV); $i++){
        if(!defined($path) && $ARGV[$i] =~ /^-/){
            if($ARGV[$i] eq "-it"){
                usage() if (++$i >= scalar(@ARGV));
                $itnum = int($ARGV[$i]);
            } else {
                usage();
            }
        } elsif(!defined($path)){
            $path = $ARGV[$i];
        } elsif(!defined($rnum)){
            $rnum = int($ARGV[$i]);
        } else {
            usage();
        }
    }
    usage() if(!defined($path) || !defined($rnum) || $rnum < 1 || $itnum < 1);
    my $rv = procwicked($path, $rnum, $itnum);
    return $rv
}


# parse arguments of misc command
sub runmisc {
    my $path = undef;
    for(my $i = 1; $i < scalar(@ARGV); $i++){
        if(!defined($path) && $ARGV[$i] =~ /^-/){
            usage();
        } elsif(!defined($path)){
            $path = $ARGV[$i];
        } else {
            usage();
        }
    }
    usage() if(!defined($path));
    my $rv = procmisc($path);
    return $rv
}


# perform order command
sub procorder {
    my ($path, $rnum, $rnd, $etc) = @_;
    printf("<In-order Test>\n  path=%s  rnum=%d  rnd=%s  etc=%s\n\n", $path, $rnum, $rnd, $etc);
    my $err = 0;
    my $db = new KyotoCabinet::DB;
    printf("opening the database:\n");
    my $stime = gettimeofday();
    if (!$db->open($path, $db->OWRITER | $db->OCREATE | $db->OTRUNCATE)) {
        dberrprint($db, "DB::open");
        $err = 1;
    }
    my $etime = gettimeofday();
    printf("time: %.3f\n", $etime - $stime);
    printf("setting records:\n");
    $stime = gettimeofday();
    for (my $i = 1; !$err && $i <= $rnum; $i++) {
        my $key = sprintf("%08d", $rnd ? int(rand($rnum)) + 1 : $i);
        if (!$db->set($key, $key)) {
            dberrprint($db, "DB::set");
            $err = 1;
        }
        if ($rnum > 250 && $i % ($rnum / 250) == 0) {
            print(".");
            if ($i == $rnum || $i % ($rnum / 10) == 0) {
                printf(" (%08d)\n", $i);
            }
        }
    }
    $etime = gettimeofday();
    dbmetaprint($db, 0);
    printf("time: %.3f\n", $etime - $stime);
    if ($etc) {
        printf("adding records:\n");
        $stime = gettimeofday();
        for (my $i = 1; !$err && $i <= $rnum; $i++) {
            my $key = sprintf("%08d", $rnd ? int(rand($rnum)) + 1 : $i);
            if (!$db->add($key, $key) && $db->error != KyotoCabinet::Error::DUPREC) {
                dberrprint($db, "DB::add");
                $err = 1;
            }
            if ($rnum > 250 && $i % ($rnum / 250) == 0) {
                print(".");
                if ($i == $rnum || $i % ($rnum / 10) == 0) {
                    printf(" (%08d)\n", $i);
                }
            }
        }
        $etime = gettimeofday();
        dbmetaprint($db, 0);
        printf("time: %.3f\n", $etime - $stime);
    }
    if ($etc) {
        printf("appending records:\n");
        $stime = gettimeofday();
        for (my $i = 1; !$err && $i <= $rnum; $i++) {
            my $key = sprintf("%08d", $rnd ? int(rand($rnum)) + 1 : $i);
            if (!$db->append($key, $key)) {
                dberrprint($db, "DB::append");
                $err = 1;
            }
            if ($rnum > 250 && $i % ($rnum / 250) == 0) {
                print(".");
                if ($i == $rnum || $i % ($rnum / 10) == 0) {
                    printf(" (%08d)\n", $i);
                }
            }
        }
        $etime = gettimeofday();
        dbmetaprint($db, 0);
        printf("time: %.3f\n", $etime - $stime);
    }
    if ($etc) {
        printf("accepting visitors:\n");
        $stime = gettimeofday();
        my $visitor = new VisitorImpl($rnd);
        for (my $i = 1; !$err && $i <= $rnum; $i++) {
            my $key = sprintf("%08d", $rnd ? int(rand($rnum)) + 1 : $i);
            if (!$db->accept($key, $visitor, $rnd)) {
                dberrprint($db, "DB::accept");
                $err = 1;
            }
            if ($rnum > 250 && $i % ($rnum / 250) == 0) {
                print(".");
                if ($i == $rnum || $i % ($rnum / 10) == 0) {
                    printf(" (%08d)\n", $i);
                }
            }
        }
        $etime = gettimeofday();
        dbmetaprint($db, 0);
        printf("time: %.3f\n", $etime - $stime);
    }
    printf("getting records:\n");
    $stime = gettimeofday();
    for (my $i = 1; !$err && $i <= $rnum; $i++) {
        my $key = sprintf("%08d", $rnd ? int(rand($rnum)) + 1 : $i);
        if (!defined($db->get($key)) && $db->error != KyotoCabinet::Error::NOREC) {
            dberrprint($db, "DB::set");
            $err = 1;
        }
        if ($rnum > 250 && $i % ($rnum / 250) == 0) {
            print(".");
            if ($i == $rnum || $i % ($rnum / 10) == 0) {
                printf(" (%08d)\n", $i);
            }
        }
    }
    $etime = gettimeofday();
    dbmetaprint($db, 0);
    printf("time: %.3f\n", $etime - $stime);
    if ($etc) {
        printf("traversing the database by the inner iterator:\n");
        $stime = gettimeofday();
        my $cnt = 0;
        my $visit = sub {
            my ($key, $value) = @_;
            $cnt++;
            my $rv = KyotoCabinet::Visitor::NOP;
            if ($rnd) {
                my $num = int(rand(7));
                if ($num == 0) {
                    $rv = $cnt x 2;
                } elsif ($num == 1) {
                    $rv = KyotoCabinet::Visitor::REMOVE;
                }
            }
            if ($rnum > 250 && $cnt % ($rnum / 250) == 0) {
                print(".");
                if ($cnt == $rnum || $cnt % ($rnum / 10) == 0) {
                    printf(" (%08d)\n", $cnt);
                }
            }
            return $rv;
        };
        if (!$db->iterate($visit, $rnd)) {
            dberrprint($db, "DB::iterate");
            $err = 1;
        }
        printf(" (end)\n") if ($rnd);
        $etime = gettimeofday();
        dbmetaprint($db, 0);
        printf("time: %.3f\n", $etime - $stime);
    }
    if ($etc) {
        printf("traversing the database by the outer cursor:\n");
        $stime = gettimeofday();
        my $cnt = 0;
        my $visit = sub {
            my ($key, $value) = @_;
            $cnt++;
            my $rv = KyotoCabinet::Visitor::NOP;
            if ($rnd) {
                my $num = int(rand(7));
                if ($num == 0) {
                    $rv = $cnt x 2;
                } elsif ($num == 1) {
                    $rv = KyotoCabinet::Visitor::REMOVE;
                }
            }
            if ($rnum > 250 && $cnt % ($rnum / 250) == 0) {
                print(".");
                if ($cnt == $rnum || $cnt % ($rnum / 10) == 0) {
                    printf(" (%08d)\n", $cnt);
                }
            }
            return $rv;
        };
        my $cur = $db->cursor;
        if (!$cur->jump && $db->error != KyotoCabinet::Error::NOREC) {
            dberrprint($db, "Cursor::jump");
            $err = 1;
        }
        while ($cur->accept($visit, $rnd, 0)) {
            if (!$cur->step && $db->error != KyotoCabinet::Error::NOREC) {
                dberrprint($db, "Cursor::step");
                $err = 1;
            }
        }
        if ($db->error != KyotoCabinet::Error::NOREC) {
            dberrprint($db, "Cursor::accept");
            $err = 1;
        }
        $cur->disable if (!$rnd || int(rand(2)) == 0);
        printf(" (end)\n") if ($rnd);
        $etime = gettimeofday();
        dbmetaprint($db, 0);
        printf("time: %.3f\n", $etime - $stime);
    }
    printf("removing records:\n");
    $stime = gettimeofday();
    for (my $i = 1; !$err && $i <= $rnum; $i++) {
        my $key = sprintf("%08d", $rnd ? int(rand($rnum)) + 1 : $i);
        if (!$db->remove($key) && $db->error != KyotoCabinet::Error::NOREC) {
            dberrprint($db, "DB::set");
            $err = 1;
        }
        if ($rnum > 250 && $i % ($rnum / 250) == 0) {
            print(".");
            if ($i == $rnum || $i % ($rnum / 10) == 0) {
                printf(" (%08d)\n", $i);
            }
        }
    }
    $etime = gettimeofday();
    dbmetaprint($db, 1);
    printf("time: %.3f\n", $etime - $stime);
    printf("closing the database:\n");
    $stime = gettimeofday();
    if (!$db->close) {
        dberrprint($db, "DB::close");
        $err = 1;
    }
    $etime = gettimeofday();
    printf("time: %.3f\n", $etime - $stime);
    printf("%s\n\n", $err ? "error" : "ok");
    return $err ? 1 : 0;
}


# perform wicked command
sub procwicked {
    my ($path, $rnum, $itnum) = @_;
    printf("<Wicked Test>\n  path=%s  rnum=%d  itnum=%d\n\n", $path, $rnum, $itnum);
    my $err = 0;
    my $db = new KyotoCabinet::DB;
    for (my $itcnt = 1; $itcnt <= $itnum; $itcnt++) {
        printf("iteration %d:\n", $itcnt) if ($itnum > 1);
        my $stime = gettimeofday();
        my $mode = $db->OWRITER | $db->OCREATE;
        $mode |= $db->OTRUNCATE if ($itcnt == 1);
        if (!$db->open($path, $mode)) {
            dberrprint($db, "DB::open");
            $err = 1;
        }
        my $cur = $db->cursor;
        for (my $i = 1; !$err && $i <= $rnum; $i++) {
            my $tran = int(rand(100)) == 0;
            if ($tran && !$db->begin_transaction(int(rand($rnum) == 0))) {
                dberrprint($db, "DB::begin_transaction");
                $tran = 0;
                $err = 1;
            }
            my $key = sprintf("%08d", int(rand($rnum)) + 1);
            my $cmd = int(rand(12));
            if ($cmd == 0) {
                if (!$db->set($key, $key)) {
                    dberrprint($db, "DB::set");
                    $err = 1;
                }
            } elsif ($cmd == 1) {
                if (!$db->add($key, $key) && $db->error != KyotoCabinet::Error::DUPREC) {
                    dberrprint($db, "DB::add");
                    $err = 1;
                }
            } elsif ($cmd == 2) {
                if (!$db->replace($key, $key) && $db->error != KyotoCabinet::Error::NOREC) {
                    dberrprint($db, "DB::replace");
                    $err = 1;
                }
            } elsif ($cmd == 3) {
                if (!$db->append($key, $key)) {
                    dberrprint($db, "DB::append");
                    $err = 1;
                }
            } elsif ($cmd == 4) {
                if (int(rand(2)) == 0) {
                    if (!defined($db->increment($key, rand(10))) &&
                        $db->error != KyotoCabinet::Error::LOGIC) {
                        dberrprint($db, "DB::increment");
                        $err = 1;
                    }
                } else {
                    if (!defined($db->increment_double($key, rand(10))) &&
                        $db->error != KyotoCabinet::Error::LOGIC) {
                        dberrprint($db, "DB::increment");
                        $err = 1;
                    }
                }
            } elsif ($cmd == 5) {
                if (!$db->cas($key, $key, $key) && $db->error != KyotoCabinet::Error::LOGIC) {
                    dberrprint($db, "DB::cas");
                    $err = 1;
                }
            } elsif ($cmd == 6) {
                if (!$db->remove($key) && $db->error != KyotoCabinet::Error::NOREC) {
                    dberrprint($db, "DB::remove");
                    $err = 1;
                }
            } elsif ($cmd == 7) {
                my $visitor = new VisitorImpl(1);
                if (!$db->accept($key, $visitor, 1)) {
                    dberrprint($db, "DB::accept");
                    $err = 1;
                }
            } elsif ($cmd == 8) {
                if (int(rand(10)) == 0) {
                    if (int(rand(4)) == 0) {
                        if (!$cur->jump_back($key) &&
                            $db->error != KyotoCabinet::Error::NOIMPL &&
                            $db->error != KyotoCabinet::Error::NOREC) {
                            dberrprint($db, "Cursor::jump_back");
                            $err = 1;
                        }
                    } else {
                        if (!$cur->jump($key) && $db->error != KyotoCabinet::Error::NOREC) {
                            dberrprint($db, "Cursor::jump");
                            $err = 1;
                        }
                    }
                } else {
                    $cmd = int(rand(6));
                    if ($cmd == 0) {
                        if (!$cur->get_key && $db->error != KyotoCabinet::Error::NOREC) {
                            dberrprint($db, "Cursor::get_key");
                            $err = 1;
                        }
                    } elsif ($cmd == 1) {
                        if (!$cur->get_value && $db->error != KyotoCabinet::Error::NOREC) {
                            dberrprint($db, "Cursor::get_value");
                            $err = 1;
                        }
                    } elsif ($cmd == 2) {
                        if (!$cur->get && $db->error != KyotoCabinet::Error::NOREC) {
                            dberrprint($db, "Cursor::get");
                            $err = 1;
                        }
                    } elsif ($cmd == 3) {
                        if (!$cur->remove && $db->error != KyotoCabinet::Error::NOREC) {
                            dberrprint($db, "Cursor::remove");
                            $err = 1;
                        }
                    } else {
                        my $visitor = new VisitorImpl(1);
                        if (!$cur->accept($visitor, 1, rand(2) == 0) &&
                            $db->error != KyotoCabinet::Error::NOREC) {
                            dberrprint($db, "Cursor::accept");
                            $err = 1;
                        }
                    }
                    if (int(rand(2)) == 0) {
                        if (!$cur->step && $db->error != KyotoCabinet::Error::NOREC) {
                            dberrprint($db, "Cursor::step");
                            $err = 1;
                        }
                    }
                    if (int(rand($rnum / 50 + 1)) == 0) {
                        my $prefix = substr($key, 0, -1);
                        if (!defined($db->match_prefix($prefix, int(rand(10))))) {
                            dberrprint($db, "DB::match_prefix");
                            $err = 1;
                        }
                    }
                    if (int(rand($rnum / 50 + 1)) == 0) {
                        my $regex = substr($key, 0, -1);
                        if (!defined($db->match_regex($regex, int(rand(10)))) &&
                            $db->error != KyotoCabinet::Error::LOGIC) {
                            dberrprint($db, "DB::match_regex");
                            $err = 1;
                        }
                    }
                    if (int(rand($rnum / 50 + 1)) == 0) {
                        my $origin = substr($key, 0, -1);
                        if (!defined($db->match_similar($origin, 3, int(rand(2)) == 0,
                                                        int(rand(10))))) {
                            dberrprint($db, "DB::match_similar");
                            $err = 1;
                        }
                    }
                    if (int(rand(10)) == 0) {
                        my $paracur = $db->cursor;
                        $paracur->jump($key);
                        my $visitor = new VisitorImpl(1);
                        if (!$paracur->accept($visitor, 1, int(rand(2)) == 0) &&
                            $db->error != KyotoCabinet::Error::NOREC) {
                            dberrprint($db, "Cursor::accept");
                            $err = 1;
                        }
                        $paracur->disable;
                    }
                }
            } else {
                if (!$db->get($key) && $db->error != KyotoCabinet::Error::NOREC) {
                    dberrprint($db, "DB::get");
                    $err = 1;;
                }
            }
            if ($tran && !$db->end_transaction(int(rand(10) > 0))) {
                dberrprint($db, "DB::end_transaction");
                $err = 1;
            }
            if ($rnum > 250 && $i % ($rnum / 250) == 0) {
                print(".");
                if ($i == $rnum || $i % ($rnum / 10) == 0) {
                    printf(" (%08d)\n", $i);
                }
            }
        }
        $cur->disable;
        dbmetaprint($db, $itcnt == $itnum);
        if (!$db->close) {
            dberrprint($db, "DB::close");
            $err = 1;
        }
        my $etime = gettimeofday();
        printf("time: %.3f\n", $etime - $stime);
    }
    printf("%s\n\n", $err ? "error" : "ok");
    return $err ? 1 : 0;
}


# perform misc command
sub procmisc {
    my ($path) = @_;
    printf("<Miscellaneous Test>\n  path=%s\n\n", $path);
    my $err = 0;
    printf("calling utility functions:\n");
    KyotoCabinet::atoi("123.456mikio");
    KyotoCabinet::atoix("123.456mikio");
    KyotoCabinet::atof("123.456mikio");
    KyotoCabinet::hash_murmur($path);
    KyotoCabinet::hash_fnv($path);
    KyotoCabinet::levdist($path, "casket");
    printf("opening the database by tying hash:\n");
    my $db = tie(my %db, "KyotoCabinet::DB", $path, KyotoCabinet::DB::OWRITER |
                 KyotoCabinet::DB::OCREATE | KyotoCabinet::DB::OTRUNCATE);
    if ("$db\n" eq "") {
        dberrprint($db, "DB::string");
        $err = 1;
    }
    my $rnum = 10000;
    printf("setting records:\n");
    for (my $i = 0; $i < $rnum; $i++) {
        $db{$i} = $i;
    }
    if ($db->count != $rnum) {
        dberrprint($db, "DB::count");
        $err = 1;
    }
    printf("checking records:\n");
    while (my ($key, $value) = each(%db)) {
        if ($db{$key} ne $value) {
            dberrprint($db, "DB::FETCH");
            $err = 1;
        }
        if (!exists($db{$key})) {
            dberrprint($db, "DB::EXISTS");
            $err = 1;
        }
    }
    printf("deploying cursors:\n");
    my @dcurs;
    for (my $i = 1; $i <= 100; $i++) {
        my $cur = $db->cursor;
        if (!$cur->jump($i)) {
            dberrprint($db, "Cursor::jump");
            $err = 1;
        }
        my $num = int(rand(3));
        if ($num == 0) {
            push(@dcurs, $cur);
        } elsif ($num == 1) {
            $cur->disable;
        }
    }
    printf("getting records:\n");
    foreach my $cur (@dcurs) {
        if (!$cur->get_key) {
            dberrprint($db, "Cursor::get_key");
            $err = 1
        }
    }
    printf("accepting visitor:\n");
    for (my $i = 0; $i < $rnum * 2; $i++) {
        if (!$db->accept($i, "::miscvisit", 1)) {
            dberrprint($db, "DB::access");
            $err = 1;
        }
    }
    printf("accepting visitor by iterator:\n");
    if (!$db->iterate("::miscvisit", 1)) {
        dberrprint($db, "DB::iterate");
        $err = 1;
    }
    printf("accepting visitor with a cursor:\n");
    my $cur = $db->cursor;
    if ($cur->jump_back) {
        while ($cur->accept(\&miscvisit, 1)) {
            $cur->step_back;
        }
    } elsif ($cur->jump) {
        while ($cur->accept(\&miscvisit, 1)) {
            $cur->step;
        }
    } else {
        dberrprint($db, "Cursor::jump");
        $err = 1;
    }
    undef($cur);
    printf("accepting visitor in bulk:\n");
    my @keys;
    for (my $i = 1; $i <= 10; $i++) {
        push(@keys, $i);
    }
    my $visitor = new VisitorImpl(0);
    if (!$db->accept_bulk(\@keys, $visitor)) {
        dberrprint($db, "DB::accept_bulk");
        $err = 1;
    }
    my %recs;
    for (my $i = 1; $i <= 10; $i++) {
        $recs{$i} = sprintf("[%d]", $i);
    }
    if ($db->set_bulk(\%recs) < 0) {
        dberrprint($db, "DB::set_bulk");
        $err = 1;
    }
    if (!$db->get_bulk(\@keys)) {
        dberrprint($db, "DB::get_bulk");
        $err = 1;
    }
    if ($db->remove_bulk(\@keys) < 0) {
        dberrprint($db, "DB::remove_bulk");
        $err = 1;
    }
    printf("synchronizing the database:\n");
    if (!$db->synchronize(0, "::miscfproc") ||
        !$db->synchronize(0, \&miscfproc)) {
        dberrprint($db, "DB::synchronize");
        $err = 1;
    }
    if (!$db->occupy(0, "::miscfproc") ||
        !$db->occupy(0, \&miscfproc)) {
        dberrprint($db, "DB::occupy");
        $err = 1;
    }
    printf("performing transaction:\n");
    if (!$db->transaction(
             sub {
                 my ($db) = @_;
                 $db->set("tako", "ika");
                 1;
             })) {
        dberrprint($db, "DB::transaction");
        $err = 1;
    }
    if ($db{"tako"} ne "ika") {
        dberrprint($db, "DB::transaction");
        $err = 1;
    }
    delete $db{"tako"};
    my $cnt = $db->count;
    if (!$db->transaction(
             sub {
                 my ($db) = @_;
                 $db->set("tako", "ika");
                 $db->set("kani", "ebi");
                 0;
             })) {
        dberrprint($db, "DB::transaction");
        $err = 1;
    }
    if (defined($db{"tako"}) || defined($db{"kani"}) || $db->count != $cnt) {
        dberrprint($db, "DB::transaction");
        $err = 1;
    }
    printf("closing the database:\n");
    undef($db);
    untie(%db);
    printf("accessing dead cursors:\n");
    foreach my $cur (@dcurs) {
        $cur->get_key;
    }
    undef(@dcurs);
    printf("re-opening the database with functor:\n");
    my $dberr = KyotoCabinet::DB->process(
        sub {
            my ($db) = @_;
            printf("removing records by cursor:\n");
            my $cur = $db->cursor;
            if (!$cur->jump && $db->error != KyotoCabinet::Error::NOREC) {
                dberrprint($db, "Cursor::jump");
                $err = 1;
            }
            my $cnt = 0;
            while (defined(my $key = $cur->get_key(1))) {
                if ($cnt % 10 != 0) {
                    if (!$db->remove($key)) {
                        dberrprint($db, "DB::remove");
                        $err = 1;
                    }
                }
                $cnt++;
            }
            if ($db->error != KyotoCabinet::Error::NOREC) {
                dberrprint($db, "Cursor::get_key");
                $err = 1;
            }
            $cur->disable;
            printf("dumping records into snapshot:\n");
            my $snappath = $db->path;
            if ($snappath =~ /.(kch|kct)$/) {
                $snappath = $snappath . ".kcss";
            } else {
                $snappath = "kctest.kcss";
            }
            if (!$db->dump_snapshot($snappath)) {
                dberrprint($db, "DB::dump_snapshot");
                $err = 1;
            }
            $cnt = $db->count;
            printf("clearing the database:\n");
            if (!$db->clear) {
                dberrprint($db, "DB::clear");
                $err = 1;
            }
            printf("loading records from snapshot:\n");
            if (!$db->load_snapshot($snappath)) {
                dberrprint($db, "DB::load_snapshot");
                $err = 1;
            }
            if ($db->count != $cnt) {
                dberrprint($db, "DB::load_snapshot");
                $err = 1;
            }
            unlink($snappath);
            my $copypath = $db->path;
            my $suffix = undef;
            if ($copypath =~ /\.kch$/) {
                $suffix = ".kch";
            } elsif ($copypath =~ /\.kct$/) {
                $suffix = ".kct";
            } elsif ($copypath =~ /\.kcd$/) {
                $suffix = ".kcd";
            } elsif ($copypath =~ /\.kcf$/) {
                $suffix = ".kcf";
            }
            if (defined($suffix)) {
                printf("performing copy and merge:\n");
                my @copypaths = ();
                for (my $i = 0; $i < 2; $i++) {
                    push(@copypaths, sprintf("%s.%d%s", $copypath, $i + 1, $suffix));
                }
                my @srcary = ();
                foreach my $copypath (@copypaths) {
                    if (!$db->copy($copypath)) {
                        dberrprint($db, "DB::copy");
                        $err = 1;
                    }
                    my $srcdb = new KyotoCabinet::DB;
                    if (!$srcdb->open($copypath, $db->OREADER)) {
                        dberrprint($srcdb, "DB::open");
                        $err = 1;
                    }
                    push(@srcary, $srcdb);
                }
                if (!$db->merge(\@srcary, $db->MAPPEND)) {
                    dberrprint($db, "DB::merge");
                    $err = 1;
                }
                foreach my $srcdb (@srcary) {
                    if (!$srcdb->close) {
                        dberrprint($srcdb, "DB::close");
                        $err = 1;
                    }
                }
                foreach my $copypath (@copypaths) {
                    rmtree($copypath);
                }
            }
            printf("closing the database:\n");
        }, $path, KyotoCabinet::DB::OWRITER);
    if (defined($dberr)) {
        printf("%s: DB::process: %s\n", $0, $dberr);
        $err = 1;
    }
    printf("%s\n\n", $err ? "error" : "ok");
    return $err ? 1 : 0;
}


# visitor function for misc command
sub miscvisit {
    my ($key, $value) = @_;
    my $rv = KyotoCabinet::Visitor::NOP;
    my $num = int($key) % 3;
    if ($num == 0) {
        $rv = sprintf("%s:%s", defined($value) ? "full" : "empty", $key);
    } elsif ($num == 1) {
        $rv = KyotoCabinet::Visitor::REMOVE;
    }
    return $rv
}


# file processor function for misc command
sub miscfproc {
    my ($path, $count, $size) = @_;
    return 1;
}


# execute main
$| = 1;
$0 =~ s/.*\///;
exit(main());



# END OF FILE
