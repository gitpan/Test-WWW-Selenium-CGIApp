#!/usr/bin/perl

use Test::More 'no_plan';
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::WWW::Selenium::CGIApp 'TestApp';

diag("You need to have firefox-bin in your path for this to work!");

my $sel = Test::WWW::Selenium::CGIApp->start(browser => '*firefox');

$sel->open_ok('/test-app/start');
$sel->text_is("link=Click here", "Click here");
