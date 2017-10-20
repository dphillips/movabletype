#!/usr/bin/perl

use strict;
use warnings;

use lib qw(lib t/lib);

use MT::Test::Tag;

plan tests => 1 * blocks;

use MT;
use MT::Test qw(:db);
use MT::Test::Permission;

my $vars = {};

sub var {
    for my $line (@_) {
        for my $key ( keys %{$vars} ) {
            my $replace = quotemeta "[% ${key} %]";
            my $value   = $vars->{$key};
            $line =~ s/$replace/$value/g;
        }
    }
    @_;
}

filters {
    template => [qw( var chomp )],
    expected => [qw( var chomp )],
    error    => [qw( chomp )],
};

my $blog
    = MT::Test::Permission->make_blog( parent_id => 0, name => 'test blog' );

my $content_type_01 = MT::Test::Permission->make_content_type(
    blog_id => $blog->id,
    name    => 'test content type 01',
);

my $content_type_02 = MT::Test::Permission->make_content_type(
    blog_id => $blog->id,
    name    => 'test content type 02',
);

my $cf_category_01 = MT::Test::Permission->make_content_field(
    blog_id         => $blog->id,
    content_type_id => $content_type_01->id,
    name            => 'Category Field 01',
    type            => 'categories',
);

my $cf_category_02 = MT::Test::Permission->make_content_field(
    blog_id         => $blog->id,
    content_type_id => $content_type_02->id,
    name            => 'Category Field 02',
    type            => 'categories',
);

my $category_set_01 = MT::Test::Permission->make_category_set(
    blog_id => $blog->id,
    name    => 'test category set 01',
);

my $category_set_02 = MT::Test::Permission->make_category_set(
    blog_id => $blog->id,
    name    => 'test category set 02',
);

my $category_01 = MT::Test::Permission->make_category(
    blog_id         => $blog->id,
    category_set_id => $category_set_01->id,
    label           => 'Category 01',
);

my $category_02 = MT::Test::Permission->make_category(
    blog_id         => $blog->id,
    category_set_id => $category_set_02->id,
    label           => 'Category 02',
);

my $fields_01 = [
    {   id      => $cf_category_01->id,
        order   => 15,
        type    => $cf_category_01->type,
        options => {
            label        => $cf_category_01->name,
            category_set => $category_set_01->id,
            multiple     => 1,
            max          => 5,
            min          => 1,
        },
    },
];

my $fields_02 = [
    {   id      => $cf_category_02->id,
        order   => 15,
        type    => $cf_category_02->type,
        options => {
            label        => $cf_category_02->name,
            category_set => $category_set_02->id,
            multiple     => 1,
            max          => 5,
            min          => 1,
        },
    },
];

$content_type_01->fields($fields_01);
$content_type_01->save or die $content_type_01->errstr;

$content_type_02->fields($fields_02);
$content_type_02->save or die $content_type_02->errstr;

$vars->{category_set_01_id}        = $category_set_01->id;
$vars->{content_type_02_unique_id} = $content_type_02->unique_id;

MT::Test::Tag->run_perl_tests( $blog->id );

__END__

=== mt:CategorySets label="No ID"
--- template
<mt:CategorySets><mt:CategorySetName></mt:CategorySets>
--- expected
test category set 01test category set 02

=== mt:CategorySets label="Set ID"
--- template
<mt:CategorySets id="[% category_set_01_id %]"><mt:CategorySetName></mt:CategorySets>
--- expected
test category set 01

=== mt:CategorySets label="Set Content Type"
--- template
<mt:CategorySets content_type="[% content_type_02_unique_id %]"><mt:CategorySetName></mt:CategorySets>
--- expected
test category set 02