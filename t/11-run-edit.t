#!perl

use strict;
use warnings;

# Note: don't include Test::FailWarnings here as it interferes with
# Capture::Tiny.
use Capture::Tiny;
use Test::Exception;
use Test::Requires::Git;
use Test::More;

use App::GitHooks::Test qw( ok_add_files ok_setup_repository );


## no critic (RegularExpressions::RequireExtendedFormatting)

# Require git.
test_requires_git( '1.7.4.1' );

plan( tests => 6 );

my $repository = ok_setup_repository(
	cleanup_test_repository => 1,
	config                  => undef,
	hooks                   => [ 'pre-commit' ],
	plugins                 => [ 'App::GitHooks::Plugin::BlockNOCOMMIT' ],
);

# Set up test file.
ok_add_files(
	files      =>
	{
		'test.pl' => "#!perl\n\nuse strict;\n1;\n",
	},
	repository => $repository,
);

# Commit file addition.
my $stderr;
lives_ok(
	sub
	{
		$stderr = Capture::Tiny::capture_stderr(
			sub
			{
				$repository->run( 'commit', '-m', 'Test message.' );
			}
		);
		note( $stderr );
	},
	'Commit the changes.',
);

# Edit file.
ok_add_files(
	files      =>
	{
		'test.pl' => "#!perl\n\nuse strict;\n\n#NOCOMMIT\n\n1;\n",
	},
	repository => $repository,
);

# Try to commit.
lives_ok(
	sub
	{
		$stderr = Capture::Tiny::capture_stderr(
			sub
			{
				$repository->run( 'commit', '-m', 'Test message.' );
			}
		);
		note( $stderr );
	},
	'Commit the changes.',
);

# Verify that the new lines fail the #NOCOMMIT rule.
like(
	$stderr,
	qr/\Qx The file has no #NOCOMMIT tags.\E/,
	"The output matches expected results.",
);
