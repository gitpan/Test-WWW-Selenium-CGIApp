package Test::WWW::Selenium::CGIApp;

use warnings;
use strict;
use Carp;
use Alien::SeleniumRC;
use Test::WWW::Selenium;
use Test::More;

local $SIG{CHLD} = 'IGNORE';

our $DEBUG = $ENV{TWS_DEBUG} || 0;
my $app; # app name (MyApp)
my $sel_pid; # pid of selenium server
my $app_pid; # pid of myapp server

=head1 NAME

Test::WWW::Selenium::CGIApp - Test your CGIApp application with Selenium

=cut

our $VERSION = '0.10';

=head1 DEVELOPER RELEASE

This is a test release.  It depends on a Java application (SeleniumRC), which
can be unreliable. The API is still subject to change in incompatible ways in
future versions.

Please report any problems to RT, the CGIApp mailing list, or the
#cgiapp IRC channel on L<irc.perl.org>.  Thanks!

=head1 SYNOPSIS

    use Test::WWW::Selenium::CGIApp 'MyApp';
    use Test::More tests => 2;

    my $sel = Test::WWW::Selenium::CGIApp->start; 
    $sel->open_ok('/');
    $sel->is_text_present_ok('Welcome to MyApp');

=head1 USE CASES

This module could be helpful if you want to test a L<CGI::Application> based
project with Selenium B<and> you don't want to involve a traditional web server
such as Apache. It could be useful when working offline or on a personal desktop.

If you would rather test the application through a web-server, using
L<Test::WWW::Selenium> would be a better choice.

=head1 TECHNICAL OVERVIEW

This module starts the SeleniumRC server and your CGIApp app so that
you can test it with SeleniumRC.  Once you've called
C<< Test::WWW::Selenium::CGIApp->start >>, everything is just like
L<Test::WWW::Selenium|Test::WWW:Selenium>.

=head1 METHODS

=head2 start()

    my $sel = Test::WWW::Selenium::CGIApp->start(
        browser => "*firefox /usr/lib/firefox/firefox-bin",  # defaults to '*firefox'
    );


Starts the Selenium and CGIApp servers, and returns a pre-initialized, ready-to-use Test::WWW::Selenium object.
Extra args are passed to Test::WWW::Selenium->new();

[NOTE] The selenium server is actually started when you C<use> this
module, and it's killed when your test exits.

=head2 sel_pid()

Returns the process ID of the Selenium Server.

=head2 app_pid()

Returns the process ID of the CGIApp server.

=cut


sub _start_server {
    # fork off a selenium server
    my $pid;
    if(0 == ($pid = fork())){
        local $SIG{TERM} = sub {
            diag("Selenium server $$ going down (TERM)") if $DEBUG;
            exit 0;
        };

        chdir '/';

        if(!$DEBUG){
            close *STDERR;
            close *STDOUT;
            #close *STDIN;
        }

        diag("Selenium running in $$") if $DEBUG;
        Alien::SeleniumRC::start()
            or croak "Can't start Selenium server: $!";
        diag("Selenium server $$ going down") if $DEBUG;
        exit 1;
    }
    $sel_pid = $pid;
}

sub sel_pid { return $sel_pid }
sub app_pid { return $app_pid }

sub import {
    my ($class, $appname) = @_;
    croak q{Specify your app's name} if !$appname;
    $app = $appname;
    
    _start_server() or croak "Couldn't start selenium server";
    return 1;
}

sub start {
    my $class = shift;
    my %args  = @_;
    
    # start a CGIApp MyApp server
    eval("use $app");
    croak "Couldn't load $app: $@" if $@;
    
    my $pid;
    if(0 == ($pid = fork())){
	local $SIG{TERM} = sub {
	    diag("App server $$ going down (TERM)") if $DEBUG;
	    exit 0;
	};
	diag("App server running in $$") if $DEBUG;

    use CGI::Application::Dispatch::Server;
    CGI::Application::Dispatch::Server->new(
        port     => 3000,
        class    => $app,
        #    root_dir => '/home/mark/Documents/Summersault/hseller/alphasite/www',       
        root_dir => '/home/mark/Desktop',
    )->run;
	exit 1;
    }
    $app_pid = $pid;
    
    my $tries = 5;
    my $error;
    my $sel;
    while(!$sel && $tries--){ 
        sleep 1;
        diag("Waiting for selenium server to start") if $DEBUG;

        eval {
            $sel = Test::WWW::Selenium->
            new(
                host        => 'localhost',
                port        => 4444,
                browser     => '*firefox',
                browser_url => 'http://localhost:3000/',
                %args,
            );
        };
        $error = $@;
    }
    
    eval { $sel->start };
      croak "Can't start selenium: $@ (error from Test::WWW::Selenium->new(): $error)" if $@;
    
    return $sel;
}

END {
    if($sel_pid){
	diag("Killing Selenium Server $sel_pid") if $DEBUG;
	kill 15, $sel_pid or diag "Killing Selenium: $!";
	undef $sel_pid;
    }
    if($app_pid){
	diag("Killing application server $app_pid") if $DEBUG;
	kill 15, $app_pid or diag "Killing MyApp: $!";
	undef $app_pid;
    }
    diag("Waiting for forked processes to die") if $DEBUG;
    waitpid $sel_pid, 0 if $sel_pid;
    waitpid $app_pid, 0 if $app_pid;
}

=head1 ENVIRONMENT

Debugging messages are shown if C<TWS_DEBUG> is set; 

=head1 LIMITATIONS / TODOs

* This module is a fork of L<Test::WWW::Selenium::Catalyst>, but shares a lot of
code. It would be nice if they more directly shared part of the same code base.

* Having more default settings for launching various browsers on different OSes
would be nice. (And something that could be shared with Catalyst!)

* This module currently only supports dispatching through L<CGI::Application::Dispatch>.
It could be useful to support other styles.

=head1 DIAGNOSTICS

=head2 Specify your app's name

You need to pass your app's module name as the argument to the use
statement:

    use Test::WWW::Selenium::CGIApp 'MyApp';

C<MyApp> is the module name of your App.

=head1 SEE ALSO

=over 4 

=item * 

Selenium website: L<http://www.openqa.org/>

=item * 

Description of what you can do with the C<$sel> object: L<Test::WWW::Selenium>

=item * 

If you don't need a real web browser: L<Test::WWW::Mechanize::CGIApp>

=back

=head1 AUTHOR

Mark Stosberg, C<< <mark at summersault.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-www-selenium-cgiapp at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-WWW-Selenium-CGIApp>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks for Test::WWW::Selenium::Catalyst, which provided most of the code for this.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Mark Stosberg, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
