use strict;
use warnings;
use inc::Module::Install;

name('Test-WWW-Selenium-CGIApp');
author('Mark Stosberg <mark@summersault.com>');
version_from('lib/Test/WWW/Selenium/CGIApp.pm');
abstract_from('lib/Test/WWW/Selenium/CGIApp.pm');
license('Perl');
include('ExtUtils::AutoInstall');
requires(
	 'Alien::SeleniumRC'                  => 0,
	 'CGI::Application::Dispatch::Server' => 0,
	 'Test::WWW::Selenium'                => 0,
	 'Test::More'                         => 0,
	);
auto_install();
WriteAll();
