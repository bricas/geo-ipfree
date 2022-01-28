#!perl

requires "Carp";
requires "ExtUtils::MakeMaker";

on "test" => sub {
    requires "Test::More";

    recommends "Test::Code::TidyAll";
    recommends "Test::CPAN::Meta";
    recommends "Test::Pod::Coverage";
    recommends "Test::NoTabs";
    recommends "Test2::Bundle::Extended";
    recommends "Test2::Tools::Explain";
    recommends "Test2::Plugin::NoWarnings";
    recommends "Pod::Tidy";
};
