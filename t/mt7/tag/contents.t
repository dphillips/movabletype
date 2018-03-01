#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";    # t/lib
use Test::More;
use MT::Test::Env;
our $test_env;

BEGIN {
    $test_env = MT::Test::Env->new;
    $ENV{MT_CONFIG} = $test_env->config_file;
}

use MT::Test::Tag;

# plan tests => 2 * blocks;
plan tests => 1 * blocks;

use MT;
use MT::Test;
use MT::Test::Permission;

use MT::ContentStatus;

my $app = MT->instance;

my $blog_id = 1;

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

$test_env->prepare_fixture(
    sub {
        MT::Test->init_db;

        # Content Type
        my $ct = MT::Test::Permission->make_content_type(
            name    => 'test content type 1',
            blog_id => $blog_id,
        );
        my $cf_single_line_text = MT::Test::Permission->make_content_field(
            blog_id         => $ct->blog_id,
            content_type_id => $ct->id,
            name            => 'single line text',
            type            => 'single_line_text',
        );
        my $category_set = MT::Test::Permission->make_category_set(
            blog_id => $blog_id,
            name    => 'test category set',
        );
        my $cf_category = MT::Test::Permission->make_content_field(
            blog_id            => $blog_id,
            content_type_id    => $ct->id,
            name               => 'categories',
            type               => 'categories',
            related_cat_set_id => $category_set->id,
        );
        my $category1 = MT::Test::Permission->make_category(
            blog_id         => $blog_id,
            category_set_id => $category_set->id,
            label           => 'category1',
        );
        my $category2 = MT::Test::Permission->make_category(
            blog_id         => $blog_id,
            category_set_id => $category_set->id,
            label           => 'category2',
        );
        my $cf_tag = MT::Test::Permission->make_content_field(
            blog_id         => $ct->blog_id,
            content_type_id => $ct->id,
            name            => 'tags',
            type            => 'tags',
        );
        my $tag1 = MT::Test::Permission->make_tag( name => 'tag1' );
        my $tag2 = MT::Test::Permission->make_tag( name => 'tag2' );
        my $fields = [
            {   id        => $cf_single_line_text->id,
                order     => 1,
                type      => $cf_single_line_text->type,
                options   => { label => $cf_single_line_text->name },
                unique_id => $cf_single_line_text->unique_id,
            },
            {   id      => $cf_category->id,
                order   => 2,
                type    => $cf_category->type,
                options => {
                    label        => $cf_category->name,
                    category_set => $category_set->id,
                    multiple     => 1,
                    max          => 5,
                    min          => 1,
                },
            },
            {   id      => $cf_tag->id,
                order   => 3,
                type    => $cf_tag->type,
                options => {
                    label    => $cf_tag->name,
                    multiple => 1,
                    max      => 5,
                    min      => 1,
                },
            },
        ];
        $ct->fields($fields);
        $ct->save or die $ct->errstr;

        # Content Data
        MT::Test::Permission->make_content_data(
            blog_id         => $blog_id,
            content_type_id => $ct->id,
            status          => MT::ContentStatus::RELEASE(),
            data            => {
                $cf_single_line_text->id => 'test single line text ' . $_,
                (   $_ == 2
                    ? ( $cf_category->id =>
                            [ $category2->id, $category1->id ] )
                    : ()
                ),
                $cf_tag->id => [ $tag2->id, $tag1->id ],
            },
        ) for ( 1 .. 5 );
    }
);

my $ct = MT::ContentType->load( { name => 'test content type 1' } );
my $cf1 = MT::ContentField->load( { name => 'single line text' } );
my $cf2 = MT::ContentField->load( { name => 'categories' } );

$vars->{ct_id}   = $ct->id;
$vars->{ct_uid}  = $ct->unique_id;
$vars->{cf1_uid} = $cf1->unique_id;
$vars->{cf2_uid} = $cf2->unique_id;

MT::Test::Tag->run_perl_tests($blog_id);

# MT::Test::Tag->run_php_tests($blog_id);

__END__

=== MT::Contents without modifier
--- template
<mt:Contents>a</mt:Contents>
--- expected
aaaaa

=== MT::Contents
--- template
<mt:Contents blog_id="1" name="test content type 1">a</mt:Contents>
--- expected
aaaaa

=== MT::Contents with content_type_id modifier
--- template
<mt:Contents content_type_id="[% ct_id %]">a</mt:Contents>
--- expected
aaaaa

=== MT::Contents with ct_unique_id modifier
--- SKIP
--- template
<mt:Contents ct_unique_id="[% ct_uid %]">a</mt:Contents>
--- expected
aaaaa

=== MT::Contents with name modifier
--- template
<mt:Contents name="test content type 1">a</mt:Contents>
--- expected
aaaaa

=== MT::Contents with name modifier and wrong blog_id
--- template
<mt:Contents name="test content type 1" blog_ids="2">a</mt:Contents>
--- error
No Content Type could be found.

=== MT::ContentsCount with limit
--- template
<mt:Contents blog_id="1" name="test content type 1" limit="3">a</mt:Contents>
--- expected
aaa

=== MT::ContentsCount with sort_by content field
--- template
<mt:Contents blog_id="1" name="test content type 1" sort_by="field:single line text">
<mt:ContentField label="single line text"><mt:ContentFieldValue></mt:ContentField>
</mt:Contents>
--- expected
test single line text 5

test single line text 4

test single line text 3

test single line text 2

test single line text 1


=== MT::ContentsCount with sort_by content field
--- template
<mt:Contents blog_id="1" field:[% cf1_uid %]="test single line text 3" sort_by="field:single line text">
<mt:ContentField label="single line text"><mt:ContentFieldValue></mt:ContentField>
</mt:Contents>
--- expected
test single line text 3


=== MT::ContentsCount with category
--- template
<mt:Contents blog_id="1" field:[% cf2_uid %]="category1" sort_by="field:[% cf1_uid %]">
<mt:ContentField label="single line text"><mt:ContentFieldValue></mt:ContentField>
</mt:Contents>
--- expected
test single line text 2
