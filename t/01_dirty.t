# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use Path::Class;
use System::Command;

use FindBin;
use lib qq($FindBin::RealBin);
use TestUtil;

sub is_dirty
{
    my $blob_bin = blob_bin;
    my $dir = dir($blob_bin);
    my $git_nyt = $dir->file('git-nyt');
    my @cmd = ('sh', '-c', ". $git_nyt > /dev/null 2>&1; echo \$(is_dirty)");
    my @opt = {cwd => work_dir->stringify};
    my $cmd = System::Command->new(@cmd, @opt);
    my @stdout;
    {
        local $/ = "\n";
        my $stdout = $cmd->stdout;
        chomp(@stdout = <$stdout>);
    }
    return join("\n", @stdout);
}

# setup
{
    setup_repo_and_first_commit;
}

{
    my $dir = work_dir;
    my $r = repo;
    isnt(is_dirty, '0', 'not dirty');

    write_file($dir->file('b.txt'), "b\n");
    is(is_dirty, '0', 'dirty : unknown file exists');

    $r->run('add' => 'b.txt');
    is(is_dirty, '0', 'dirty : unknown file exists and is staged');

    $r->run('commit' => '-m', 'commit');
    isnt(is_dirty, '0', 'not dirty : commited');
}

# teardown
{
    teardown_repo;
}

done_testing;
