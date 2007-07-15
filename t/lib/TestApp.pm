package TestApp;
use base qw( CGI::Application CGI::Application::Dispatch );

# by default CGI::App has a start run mode which calls a dump_html method.

sub dump_html {
    my $c = shift;
    return '
    <html>
    <head>
    <title>TestApp</title>
    </head>
    <body>
    <h1>TestApp</h1>
    <p>This is the TestApp.</p>
    <p><a href="BOOM">Click here</a> to <i>see</i> some words.</p>
    </body>
    </html>';    
}

1;
