# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use FindBin;
use lib qq($FindBin::RealBin);
use TestUtil;

sub setup
{
    setup_repo_and_first_commit;
}

sub teardown
{
    teardown_repo;
}

sub diff
{
    my ($r, $n, $m) = @_;
    unless (defined($m)) {
        if ($n == 1) {
            $m = '';
        } else {
            $m = $n - 1;
        }
    }
    if ($m =~ m/^\d+$/) {
        $m = '~' . $m;
    }
    $r->run('diff' => 'HEAD~' . $n, 'HEAD' . $m => '--name-only');
}

sub commit_i
{
    my ($r, $dir, $i) = @_;
    my $fname = $i . '.txt';
    write_file($dir->file($fname), $i);
    $r->run('add' => $fname);
    $r->run('nyt' => 'commit', '-m' => 'commit: ' . $i);
}

subtest 'fixup_part' => sub {
    setup;
    my $r = repo;
    my $dir = work_dir;
    foreach my $i (1..5) {
        commit_i($r, $dir, $i);
    }
    # git nyt list | tail -n 3 | git nyt fixup-part -m 'hoge hoge'
    my @output = $r->run('nyt' => 'list');
    my $targets = join("\n", @output[-3..-1]);
    $r->run('nyt' => 'fixup-part', '-m', => 'hoge hoge', {input => $targets});

    chomp(my $logs = <<EOL);
commit: 2
commit: 1
hoge hoge
first commit
EOL
    is($r->run('log' => '--pretty=%s'), $logs, 'after fixup-part : log');

    is(diff($r, 2, 3), join("\n", map {"$_.txt"} 3..5),
       'after fixup-part : diff');
    teardown;
};

sub git_now {
    my ($r) = @_;
    my $output = $r->run('diff' => '--pretty=oneline',
                         '--name-only' => '--cached');
    chomp(my $date = `LC_ALL=C date`);
    $r->run('nyt' => 'commit', '-m', join(' ',
                                          '[from now]', $date, $output));
}

subtest 'fixup_by_filename' => sub {
    setup;
    my $dir = work_dir;
    my $r = repo;
    foreach my $i (1..5) {
        my $fname = $i . '.txt';
        write_file($dir->file($fname), $i);
        $r->run('add' => $fname);
        git_now($r);
    }
    # git nyt list | grep -e '3.txt$' | git nyt fixup-part -m 'only 3'
    my $targets = join("\n", grep /3\.txt/, $r->run('nyt' => 'list'));
    $r->run('nyt' => 'fixup-part', '-m' => 'only 3', {input => $targets});
    is(diff($r, 1), '5.txt', 'diff:1');
    is(diff($r, 2), '4.txt', 'diff:2');
    is(diff($r, 3), '2.txt', 'diff:3');
    is(diff($r, 4), '1.txt', 'diff:4');
    is(diff($r, 5), '3.txt', 'diff:5');
    chomp(my $logs = <<EOL);
only 3
first commit
EOL
    is(join("\n", ($r->run('log' => '--pretty=%s', -6))[-2, -1]), $logs, 'logs');
    teardown;
};

subtest 'fixup_by_ticket' => sub {
    setup;
    my $dir = work_dir;
    my $r = repo;
    my $commit = sub {
        my ($name, $id) = @_;
        my $fname = $name . '.txt';
        write_file($dir->file($fname), $name);
        $r->run('add' => '.');
        $r->run('nyt' => 'commit', '-m' => 'refs #' . $id);
    };
    my @defs = (
        [a => 1],
        [b => 2],
        [c => 2],
        [d => 3],
        [e => 2],
    );
    foreach my $kv (@defs) {
        $commit->(@$kv);
    }

    # git nyt list | grep 'refs #2' | git nyt fixup-part -m 'refs #2'
    my $targets = join("\n", grep /refs #2/, $r->run('nyt' => 'list'));
    $r->run('nyt' => 'fixup-part', '-m' => 'refs #2', {
        input => $targets,
    });
    is(($r->run('log' => '--pretty=%s', -3))[-1], 'refs #2', 'log');
    is(diff($r, 1), 'd.txt', 'diff:1');
    is(diff($r, 2), 'a.txt', 'diff:2');
    my $list = join("\n", map {$_.='.txt'} @_=qw/b c e/);
    is(diff($r, 3), $list, 'diff:3');
    is(scalar(@{[$r->run('log' => '--pretty=oneline')]}), 4, 'size');
    teardown;
};

subtest 'fixup_stop_when_somthing_is_on_index' => sub {
    setup;
    my $r = repo;
    my $dir = work_dir;
    foreach my $i (1..5) {
        commit_i($r, $dir, $i);
    }
    write_file($dir->file('test.txt'), '');

    # git nyt list | head -n 5 | git nyt fixup-part -m 'hoge'
    my $targets = join("\n", ($r->run('nyt' => 'list'))[0..4]);
    $r->run('nyt' => 'fixup-part', '-m' => 'hoge', {
        input => $targets,
    });
    is(scalar(@{[$r->run('log' => '--pretty=oneline')]}), 6, 'size: dirty');

    # git add test.txt
    $r->run('nyt' => 'add', 'test.txt');
    # git nyt list | head -n 5 | git nyt fixup-part -m 'fuga'
    $targets = join("\n", ($r->run('nyt' => 'list'))[0..4]);
    $r->run('nyt' => 'fixup-part', '-m' => 'fuga', {
        input => $targets,
    });
    is(scalar(@{[$r->run('log' => '--pretty=oneline')]}), 6, 'size: added');

    # git nyt commit -m 'commit: test.txt'
    $r->run('nyt' => 'commit', '-m' => 'commit: test.txt');
    # git nyt list | head -n 5 | git nyt fixup-part -m 'foo'
    $targets = join("\n", ($r->run('nyt' => 'list'))[0..4]);
    $r->run('nyt' => 'fixup-part', '-m' => 'foo', {
        input => $targets,
    });
    is(scalar(@{[$r->run('log' => '--pretty=oneline')]}), 3, 'size: committed');

    teardown;
};

done_testing;
