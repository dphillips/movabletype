<?php
# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

function smarty_function_mtcategoryid($args, &$ctx) {
    $cat = $ctx->stash('category');
    if (!$cat) return '';
    return $cat->category_id;
}
?>
