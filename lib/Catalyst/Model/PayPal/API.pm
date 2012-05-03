package Catalyst::Model::PayPal::API;

use strict;
use warnings;

use Business::PayPal::API;

use parent 'Catalyst::Model';

#__PACKAGE__->config(
#            Username   => 'your paypal username',
#            Password   => 'ABCDEF',  ## supplied by PayPal
#            Signature  => 'xyz',  ## ditto
#            sandbox    => 0 || 1,
#            subclasses => [qw( ExpressCheckout GetTransactionDetails )],
#);

sub new {

    my ( $class, $c, $config ) = @_;

    my $self = $class->next::method($c);

    die(q|No configured subclasses|)
      unless $self->{subclasses};

    # try to import the subclasses
    # this is somewhat nasty so blame it on Business::PayPal::API ...
    Business::PayPal::API::import(
        '',    # fake $self
        ref $self->{subclasses}
        ? @{ $self->{subclasses} }
        : $self->{subclasses}
    );

    # try to guess whats wanted
    die q|Username required| unless $self->{Username};
    die q|Password required| unless $self->{Password};

    my %options;

    ## try 3-token (Signature) authentication
    $options{Signature} = $self->{Signature}
      if $self->{Signature};

    ## try PEM certificate authentication
    if ( $self->{CertFile} or $self->{KeyFile} ) {

        die q|Multiple auth types attempted| if %options;
        die q|CertFile missing| unless $self->{CertFile};
        die q|KeyFile missing|  unless $self->{KeyFile};

        $options{CertFile} = $self->{CertFile};
        $options{KeyFile}  = $self->{KeyFile};

    }

    ## try certificate authentication
    if ( $self->{PKCS12File} or $self->{PKCS12Password} ) {

        die q|Multiple auth types attempted| if %options;
        die q|PKCS12File missing|     unless $self->{PKCS12File};
        die q|PKCS12Password missing| unless $self->{PKCS12Password};

        $options{PKCS12File}     = $self->{PKCS12File};
        $options{PKCS12Password} = $self->{PKCS12Password};

    }

    die q|No auth values given in config|
      unless %options;

    # drop in username, password, sandbox etc
    %options = (
        Username => $self->{Username},
        Password => $self->{Password},
        sandbox  => $self->{sandbox} || 0,
        %options,
    );

    my $paypal = Business::PayPal::API->new(%options);

    $self->{paypal} = $paypal;

    return $self;
}

# pass stuff on through to PayPal
# we need to strip some crap but thats ok
sub AUTOLOAD {

    my $self = shift;
    my %args = @_;

    our $AUTOLOAD;

    my $program = $AUTOLOAD;
    $program =~ s/.*:://;

    # pass straight through to our paypal object

    return $self->{paypal}->$program(%args);

}

sub redirect_url {

    my $self = shift;

    return 'https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token='
      unless $self->{sandbox};

    return
'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=';

}
