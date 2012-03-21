use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'App::gitnyt',
    VERSION_FROM => 'lib/App/gitnyt.pm',
    ABSTRACT => 'git-nyt is thing to replace git-now.',
    PREREQ_PM => {
        # test requires
        'Git::Repository' => 1.25,
        'Path::Class'     => 0.25,
        'System::Command' => 1.06,
    },
    LICENSE => 'perl',
    EXE_FILES => [ 'git-nyt' ],
);
