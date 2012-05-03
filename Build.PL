#!/usr/bin/perl

use warnings;
use strict;
use Module::Build;
my $build = Module::Build->new(
    dist_name => q|Catalyst-Model-PayPal-API|,
    dist_author => q|Dean Hamstead <dean@fragfest.com.au>|,
    license => q|perl|,
    module_name => q|Catalyst::Model::PayPal::API|,
    requires    => {
        'Business::PayPal::API' => 0,
        'Catalyst::Model' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
);
$build->create_build_script();
