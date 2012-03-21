# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;
use FindBin;

use Git::Repository;
use Path::Class;
use System::Command;

sub write_file
{
    my ($fname, $body) = @_;
    my $file = file($fname)->openw or die $!;
    print $file $body;
    close($file) or die $!;
}

sub blob_bin
{
    $FindBin::RealBin . '/../blib/script';
}

sub set_path
{
    my $blib_bin = blob_bin;
    $ENV{PATH} = join(':', $blib_bin, $ENV{PATH});
}

{
    my $dir;
    sub work_dir
    {
        unless ($dir) {
            $dir = dir('testunit_work');
        }
        return $dir;
    }
}

sub repo
{
    my $dir = work_dir;
    Git::Repository->new(work_tree => $dir->stringify);
}

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
    set_path;
    my $dir = work_dir;
    mkdir $dir;
    Git::Repository->run('init' => $dir->stringify);
    my $r = repo;
    my $fname = 'a.txt';
    write_file($dir->file($fname), "a\n");
    $r->run('add' => $fname);
    $r->run('commit' => '-m', 'first commit');
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
    system('rm -rf ' . work_dir);
}

done_testing;
