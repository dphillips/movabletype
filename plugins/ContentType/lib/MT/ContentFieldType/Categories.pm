package MT::ContentFieldType::Categories;
use strict;
use warnings;

use MT::Category;
use MT::CategoryList;
use MT::ContentField;
use MT::ContentFieldType::Common
    qw( get_cd_ids_by_inner_join get_cd_ids_by_left_join );
use MT::Meta::Proxy;

sub field_html_params {
    my ( $app, $field_data ) = @_;
    my $value = $field_data->{value};
    $value = ''       unless defined $value;
    $value = [$value] unless ref $value eq 'ARRAY';

    my $options = $field_data->{options};

    my $multiple = '';
    if ( $options->{multiple} ) {
        my $max = $options->{max};
        my $min = $options->{min};
        $multiple = 'data-mt-multiple="1"';
        $multiple .= qq{ data-mt-max-select="${max}"} if $max;
        $multiple .= qq{ data-mt-min-select="${min}"} if $min;
    }

    my $required = $options->{required} ? 'data-mt-required="1"' : '';

    my ( $category_tree, $selected_category_loop )
        = _build_category_list( $app, $field_data );

    {   category_tree          => $category_tree,
        multiple               => $multiple,
        required               => $required,
        selected_category_loop => $selected_category_loop,
    };
}

sub _build_category_list {
    my ( $app, $field_data ) = @_;
    my $blog_id = $app->blog->id;

    my $categories = [];
    if ( my $category_list
        = MT::CategoryList->load( $field_data->{options}{category_list} || 0 )
        )
    {
        $categories = $category_list->categories;
    }

    my %value = map { $_ => 1 } @{ $field_data->{value} || [] };
    my %places = map { $_->id => 1 } grep { $value{ $_->id } } @{$categories};

    my $data = $app->_build_category_list(
        blog_id     => $blog_id,
        cat_list_id => $field_data->{options}{category_list},
        markers     => 1,
        type        => 'category',
    );

    my @sel_cats;
    my $cat_tree = [];
    foreach (@$data) {
        next unless exists $_->{category_id};
        push @$cat_tree,
            {
            id       => $_->{category_id},
            label    => $_->{category_label},
            basename => $_->{category_basename},
            path     => $_->{category_path_ids} || [],
            fields   => $_->{category_fields} || [],
            };
        push @sel_cats, $_->{category_id}
            if $places{ $_->{category_id} };
    }

    ( $cat_tree, \@sel_cats );
}

sub data_getter {
    my ( $app, $field_data ) = @_;
    my $field_id = $field_data->{id};
    [ split ',', $app->param("category-${field_id}") ];
}

sub ss_validator {
    my ( $app, $field_data, $data ) = @_;

    my $options = $field_data->{options} || {};

    my $iter
        = MT::Category->load_iter(
        { id => $data, category_list_id => $options->{category_list} },
        { fetchonly => { id => 1 } } );
    my %valid_cats;
    while ( my $cat = $iter->() ) {
        $valid_cats{ $cat->id } = 1;
    }
    if ( my @invalid_cat_ids = grep { !$valid_cats{$_} } @{$data} ) {
        my $invalid_cat_ids = join ', ', sort(@invalid_cat_ids);
        my $field_label = $options->{label};
        return $app->translate( 'Invalid Category IDs: [_1] in "[_2]" field.',
            $invalid_cat_ids, $field_label );
    }

    my $type_label        = 'category';
    my $type_label_plural = 'categories';
    MT::ContentFieldType::Common::ss_validator_multiple( @_, $type_label,
        $type_label_plural );
}

sub html {
    my $prop = shift;
    my ( $content_data, $app, $opts ) = @_;

    my $cat_ids = $content_data->data->{ $prop->content_field_id } || [];

    my %cats;
    my $iter = MT::Category->load_iter( { id => $cat_ids },
        { fetchonly => { id => 1, blog_id => 1, label => 1 } } );
    while ( my $cat = $iter->() ) {
        $cats{ $cat->id } = $cat;
    }
    my @cats = grep {$_} map { $cats{$_} } @$cat_ids;

    my @links;
    for my $cat (@cats) {
        my $label = $cat->label;
        my $edit_link = _edit_link( $app, $cat );
        push @links, qq{<a href="${edit_link}">${label}</a>};
    }

    join ', ', @links;
}

sub _edit_link {
    my ( $app, $cat ) = @_;
    $app->uri(
        mode => 'edit',
        args => {
            _type   => 'category',
            blog_id => $cat->blog_id,
            id      => $cat->id,
        },
    );
}

# similar to tag terms.
sub terms {
    my $prop = shift;
    my ( $args, $db_terms, $db_args ) = @_;

    my $label_terms = $prop->super(@_);

    my $option = $args->{option} || '';
    if ( $option eq 'not_contains' ) {
        my $string = $args->{string};
        my $field  = MT::ContentField->load( $prop->content_field_id );

        my @cat_ids;
        my $iter = MT::Category->load_iter(
            {   label => { like => "%${string}%" },
                category_list_id => $field->related_cat_list_id,
            },
            { fetchonly => { id => 1 } },
        );
        while ( my $cat = $iter->() ) {
            push @cat_ids, $cat->id;
        }

        my $join_terms = { value_integer => [ \'IS NULL', @cat_ids ] };
        my $cd_ids = get_cd_ids_by_left_join( $prop, $join_terms, undef, @_ );
        $cd_ids ? { id => { not => $cd_ids } } : ();
    }
    elsif ( $option eq 'blank' ) {
        my $join_terms = { value_integer => \'IS NULL' };
        my $cd_ids = get_cd_ids_by_left_join( $prop, $join_terms, undef, @_ );
        { id => $cd_ids };
    }
    else {
        my $cat_join
            = MT::Category->join_on( undef,
            [ { id => \'= cf_idx_value_integer' }, $label_terms ] );
        my $join_args = { join => $cat_join };
        my $cd_ids = get_cd_ids_by_inner_join( $prop, undef, $join_args, @_ );
        { id => $cd_ids };
    }
}

sub tag_handler {
    my ( $ctx, $args, $cond, $field, $value ) = @_;

    my $category_list_id = $field->{options}{category_list}
        or return $ctx->error(
        MT->translate('No category_list setting in content field type.') );

    my $cat_terms = {
        id               => $value,
        category_list_id => $category_list_id,
    };
    my $cat_args = {};

    if ( my $sort = $args->{sort} ) {
        $cat_args->{sort} = $sort;
        my $direction
            = ( $args->{sort_order} || '' ) eq 'descend'
            ? 'descend'
            : 'ascend';
        $cat_args->{direction} = $direction;
    }

    my $lastn = $args->{lastn};

    my $iter = MT::Category->load_iter( $cat_terms, $cat_args );
    my %categories;
    my @ordered_categories;
    if ( $args->{sort} ) {
        while ( my $cat = $iter->() ) {
            last
                if ( defined $lastn && scalar @ordered_categories >= $lastn );
            push @ordered_categories, $cat;
        }
    }
    else {
        while ( my $cat = $iter->() ) {
            $categories{ $cat->id } = $cat;
        }
        my @category_ids;
        if ( defined $lastn ) {
            if ( $lastn > 0 ) {
                if ( $lastn >= %categories ) {
                    @category_ids = @{$value};
                }
                else {
                    @category_ids = @{$value}[ 0 .. $lastn - 1 ];
                }
            }
        }
        else {
            @category_ids = @{$value};
        }
        @ordered_categories = map { $categories{$_} } @category_ids;
    }

    my $res     = '';
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $glue    = $args->{glue};
    local $ctx->{inside_mt_categories} = 1;
    my $i = 0;
    my $vars = $ctx->{__stash}{vars} ||= {};
    MT::Meta::Proxy->bulk_load_meta_objects( \@ordered_categories );

    foreach my $cat (@ordered_categories) {
        $i++;
        my $last = $i == scalar(@ordered_categories);

        local $ctx->{__stash}{category} = $cat;
        local $ctx->{__stash}{entries};
        local $ctx->{__stash}{contents};
        local $ctx->{__stash}{category_count};
        local $ctx->{__stash}{blog_id} = $cat->blog_id;
        local $ctx->{__stash}{blog}    = MT::Blog->load( $cat->blog_id );
        local $vars->{__first__}       = $i == 1;
        local $vars->{__last__}        = $last;
        local $vars->{__odd__}         = ( $i % 2 ) == 1;
        local $vars->{__even__}        = ( $i % 2 ) == 0;
        local $vars->{__counter__}     = $i;
        defined(
            my $out = $builder->build(
                $ctx, $tokens,
                {   %$cond,
                    ArchiveListHeader => $i == 1,
                    ArchiveListFooter => $last
                }
            )
        ) or return $ctx->error( $builder->errstr );
        $res .= $glue if defined $glue && length($res) && length($out);
        $res .= $out;
    }
    $res;
}

1;
