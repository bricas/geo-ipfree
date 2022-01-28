#!perl

requires "Carp" => "0";
requires "Memoize" => "0";
requires "ExtUtils::MakeMaker" => "0";

on "test" => sub {
    requires "Test::More"                => "0";
};

on "recommends" => sub {
    requires "Test::CPAN::Meta"          => "0";
    requires "Test::NoTabs"              => "0";
    requires "Test2::Bundle::Extended"   => "0";
    requires "Test2::Tools::Explain"     => "0";
    requires "Test2::Plugin::NoWarnings" => "0";
};
