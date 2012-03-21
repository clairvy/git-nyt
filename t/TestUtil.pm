package TestUtil;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
                    blob_bin
                    set_path
                    work_dir
                    repo
                    write_file
                    setup_repo
                    setup_repo_and_first_commit
                    teardown_repo
               );

use FindBin;
use Path::Class;
use Git::Repository;

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

sub write_file
{
    my ($fname, $body) = @_;
    my $file = file($fname)->openw or die $!;
    print $file $body;
    close($file) or die $!;
}

sub setup_repo
{
    set_path;
    my $dir = work_dir;
    mkdir $dir;
    Git::Repository->run('init' => $dir->stringify);
    repo;
}

sub setup_repo_and_first_commit
{
    my $r = setup_repo;
    my $dir = work_dir;
    my $fname = 'a.txt';
    my $body = "a\n";
    write_file($dir->file($fname), $body);
    $r->run('add' => $fname);
    my $message = 'first commit';
    $r->run('commit' => '-m', $message);
}

sub teardown_repo
{
    system('rm -rf ' . work_dir);
}

1;
