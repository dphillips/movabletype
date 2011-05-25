#!/usr/bin/perl
use strict;
use warnings;
use lib qw( t/lib lib extlib ../lib ../extlib );
use MT::Test::Tags;
run_tests_by_data();
__DATA__
-
  name: test item 2
  template: <MTCGIPath>
  expected: "http://narnia.na/cgi-bin/"

-
  name: test item 3
  template: <MTCGIRelativeURL>
  expected: /cgi-bin/

-
  name: test item 4
  template: <MTStaticWebPath>
  expected: "http://narnia.na/mt-static/"

-
  name: test item 5
  template: <MTCommentScript>
  expected: mt-comments.cgi

-
  name: test item 6
  template: <MTTrackbackScript>
  expected: mt-tb.cgi

-
  name: test item 7
  template: <MTSearchScript>
  expected: mt-search.cgi

-
  name: test item 8
  template: <MTXMLRPCScript>
  expected: mt-xmlrpc.cgi

-
  name: test item 14
  template: <MTPublishCharset lower_case='1'>
  expected: utf-8

-
  name: test item 37
  template: <MTInclude module="blog-name">
  expected: none

-
  name: test item 38
  run: 0
  template: <MTInclude module="blog-name">
  expected: none

-
  name: test item 40
  template: <MTLink template="Main Index">
  expected: "http://narnia.na/nana/"

-
  name: test item 41
  template: <MTVersion>
  expected: VERSION_ID

-
  name: test item 42
  template: <MTDefaultLanguage>
  expected: en_US

-
  name: test item 44
  run: 0
  template: <MTErrorMessage>
  expected: ''

-
  name: test item 108
  run: 0
  template: <MTCGIServerPath>
  expected: CURRENT_WORKING_DIRECTORY

-
  name: test item 188
  template: "<MTEntries lastn=\"1\"><MTFileTemplate format=\"%y/%m/%d/%b\"></MTEntries>"
  expected: 1978/01/31/a_rainy_day

-
  name: test item 189
  template: <MTAdminCGIPath>
  expected: "http://narnia.na/cgi-bin/"

-
  name: test item 190
  template: <MTConfigFile>
  expected: CFG_FILE

-
  name: test item 191
  template: <MTAdminScript>
  expected: mt.cgi

-
  name: test item 192
  template: <MTAtomScript>
  expected: mt-atom.cgi

-
  name: test item 193
  template: <MTCGIHost>
  expected: narnia.na

-
  name: test item 510
  template: <MTNotifyScript>
  expected: mt-add-notify.cgi

-
  name: test item 524
  template: <MTProductName>
  expected: Movable Type

-
  name: test item 525
  template: <MTSection>Content</MTSection>
  expected: Content

-
  name: test item 528
  template: <MTStaticFilePath>
  expected: STATIC_FILE_PATH

-
  name: test item 530
  template: <MTSupportDirectoryURL>
  expected: /mt-static/support/

-
  name: test item 539
  template: <MTHTTPContentType type='application/xml'>
  expected: ''

-
  name: test item 550
  template: <MTDate ts='20101010101010'>
  expected: "October 10, 2010 10:10 AM"

-
  name: test item 567
  template: <MTIncludeBlock module='header-line'>Title</MTIncludeBlock>
  expected: <h1>Title</h1>

-
  name: test item 568
  template: <MTIncludeBlock module='header-line'>Title</MTIncludeBlock>
  expected: <h1>Title</h1>


