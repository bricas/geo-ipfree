#!perl

requires "Carp";
requires "ExtUtils::MakeMaker";

on "test" => sub {
    requires "Test::More";

    recommends "Test::CPAN::Meta";
    recommends "Test::Pod::Coverage";
    recommends "Test::NoTabs";
};

on "develop" => sub {

    recommends "Test::Code::TidyAll";
    recommends "Pod::Tidy";

};
