package MT::Template::Tags::Site;
use strict;
use warnings;

sub _hdlr_sites {
    my ( $ctx, $args, $cond ) = @_;
    my ( $terms, %args );
    $terms = {};

    $ctx->set_blog_load_context( $args, $terms, \%args, 'id' )
        or return $ctx->error( $ctx->errstr );

    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');

    my $current_blog = $ctx->stash('blog');

    local $ctx->{__stash}{entries} = undef
        if $args->{ignore_archive_context};
    local $ctx->{current_timestamp} = undef
        if $args->{ignore_archive_context};
    local $ctx->{current_timestamp_end} = undef
        if $args->{ignore_archive_context};
    local $ctx->{__stash}{category} = undef
        if $args->{ignore_archive_context};
    local $ctx->{__stash}{archive_category} = undef
        if $args->{ignore_archive_context};
    local $ctx->{__stash}{inside_blogs} = 1;

    require MT::Blog;
    $terms->{class} = '*' unless $terms->{class};
    if ( !exists $terms->{id} && !exists $terms->{parent_id} ) {
        if ($current_blog) {

            # website or blog scope
            $terms->{parent_id} = $current_blog->id;
        }
        else {
            # system scope
            $terms = [
                $terms,
                [ { parent_id => 0 }, '-or', { parent_id => \'IS NULL' } ],
            ];
        }
    }
    $args{'sort'} = 'name';
    $args{direction} = 'ascend';
    my @blogs = MT::Blog->load( $terms, \%args );
    my $res   = '';
    my $count = 0;
    my $vars  = $ctx->{__stash}{vars} ||= {};
    MT::Meta::Proxy->bulk_load_meta_objects( \@blogs );

    for my $blog (@blogs) {
        $count++;
        local $ctx->{__stash}{blog}    = $blog;
        local $ctx->{__stash}{blog_id} = $blog->id;
        local $vars->{__first__}       = $count == 1;
        local $vars->{__last__}        = $count == scalar(@blogs);
        local $vars->{__odd__}         = ( $count % 2 ) == 1;
        local $vars->{__even__}        = ( $count % 2 ) == 0;
        local $vars->{__counter__}     = $count;
        defined( my $out = $builder->build( $ctx, $tokens, $cond ) )
            or return $ctx->error( $builder->errstr );
        $res .= $out;
    }
    $res;
}

1;
