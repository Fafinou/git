#!/bin/sh
#
# Copyright (C) 2012
#     Charles Roussel <charles.roussel@ensimag.imag.fr>
#     Simon Cathebras <simon.cathebras@ensimag.imag.fr>
#     Julien Khayat <julien.khayat@ensimag.imag.fr>
#     Guillaume Sasdy <guillaume.sasdy@ensimag.imag.fr>
#     Simon Perrat <simon.perrat@ensimag.imag.fr>
#
# License: GPL v2 or later


test_description='Test the Git Mediawiki remote helper: git clone'

. ./test-gitmw-lib.sh
. $TEST_DIRECTORY/test-lib.sh

TRASH_DIR=$CURR_DIR/trash\\\ directory.t9360-git-mediawiki


if ! test_have_prereq PERL
then
	skip_all='skipping gateway git-mw tests, '\
		'perl not available'
	test_done
fi

if [ ! -f $GIT_BUILD_DIR/git-remote-mediawiki ];
then
	skip_all='skipping gateway git-mw tests,' \
		' no remote mediawiki for git found'
	test_done
fi

if [ ! -d "$WIKI_DIR_INST/$WIKI_DIR_NAME" ] ;
then
	skip_all='skipping gateway git-mw tests, no mediawiki found'
	test_done
fi


test_expect_success 'git clone create the git log expected with one file' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	wiki_editpage foo "this is not important" false -c cat -s "this must be the same" &&
	git clone mediawiki::http://localhost/wiki mw_dir &&
	cd mw_dir &&
	git log --format=%s HEAD^..HEAD > log.tmp &&
	echo "this must be the same" > msg.tmp &&
	diff -b log.tmp msg.tmp &&
	cd .. &&
	rm -rf mw_dir
'

test_expect_success 'git clone create the git log expected with multiple files' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	wiki_editpage daddy "this is not important" false -s="this must be the same" &&
	wiki_editpage daddy "neither is this" true -s="this must also be the same" &&
	wiki_editpage daddy "neither is this" true -s="same same same" &&
	wiki_editpage dj "dont care" false -s="identical" &&
	wiki_editpage dj "dont care either" true -s="identical too" &&
	git clone mediawiki::http://localhost/wiki mw_dir &&
	cd mw_dir &&
	git log --format=%s Daddy.mw  > logDaddy.tmp &&
	git log --format=%s Dj.mw > logDj.tmp &&
	echo "same same same" > msgDaddy.tmp &&
	echo "this must also be the same" >> msgDaddy.tmp &&
	echo "this must be the same" >> msgDaddy.tmp &&
	echo "identical too" > msgDj.tmp &&
	echo "identical" >> msgDj.tmp &&
	diff -b logDaddy.tmp msgDaddy.tmp &&
	diff -b logDj.tmp msgDj.tmp &&
	cd .. &&
	rm -rf mw_dir
'


test_expect_success 'git clone only creates Main_Page.mw with an empty wiki' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	git clone mediawiki::http://localhost/wiki mw_dir &&
	test_contains_N_files mw_dir 1 &&
	test -e mw_dir/Main_Page.mw &&
	rm -rf mw_dir
'

test_expect_success 'git clone only create Main_Page.mw with a wiki with no other pages ' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	wiki_editpage foo "this page must be deleted before the clone" false &&
	wiki_delete_page foo &&
	git clone mediawiki::http://localhost/wiki mw_dir &&
	test_contains_N_files mw_dir 1 &&
	test -e mw_dir/Main_Page.mw &&
	test ! -e mw_dir/Foo.mw &&
	rm -rf mw_dir
'

test_expect_success 'git clone works with page added' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	wiki_editpage foo " I will be cloned" false &&
	wiki_editpage bar "I will be cloned" false &&
	git clone mediawiki::http://localhost/wiki mw_dir &&
	wiki_getallpage ref_page &&
	test_diff_directories mw_dir ref_page &&
	wiki_delete_page foo &&
	rm -rf mw_dir &&
	rm -rf ref_page &&
	wiki_delete_page bar
'


test_expect_success 'git clone works with an edited page ' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	rm -rf ref_page &&

	wiki_editpage foo "this page will be edited" \
		false -s "first edition of page foo"&&
	wiki_editpage foo "this page has been edited and must be on the clone " true &&
	git clone mediawiki::http://localhost/wiki mw_dir &&
	test -e mw_dir/Foo.mw &&
	test -e mw_dir/Main_Page.mw &&
	wiki_getallpage mw_dir/page_ref &&
	test_diff_directories mw_dir mw_dir/page_ref &&
	cd mw_dir &&
	git log --format=%s HEAD^ Foo.mw > ../Foo.log &&
	cd .. &&
	echo "first edition of page foo" > FooExpect.log &&
	rm -rf mw_dir &&
	diff FooExpect.log Foo.log
'

test_expect_success 'git clone works with several pages and some deleted ' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	wiki_editpage foo "this page will not be deleted" false &&
	wiki_editpage bar "I must not be erased" false &&
	wiki_editpage namnam "I will not be there at the end" false &&
	wiki_editpage nyancat "nyan nyan nyan delete me" false &&
	wiki_delete_page namnam &&
	wiki_delete_page nyancat &&
	git clone mediawiki::http://localhost/wiki mw_dir &&
	test -e mw_dir/Foo.mw &&
	test -e mw_dir/Bar.mw &&
	test ! -e mw_dir/Namnam.mw &&
	test ! -e mw_dir/Nyancat.mw &&
	wiki_getallpage mw_dir/page_ref &&
	test_diff_directories mw_dir mw_dir/page_ref &&
	rm -rf mw_dir
'




test_expect_success 'git clone works one specific page cloned ' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	wiki_editpage foo "I will not be cloned" false &&
	wiki_editpage bar "Do not clone me" false &&
	wiki_editpage namnam "I will be cloned :)" false  -s="this log must stay" &&
	wiki_editpage nyancat "nyan nyan nyan you cant clone me" false &&
	git clone -c remote.origin.pages=namnam mediawiki::http://localhost/wiki mw_dir &&
	test_contains_N_files mw_dir 1 &&
	test -e mw_dir/Namnam.mw &&
	test ! -e mw_dir/Main_Page.mw &&
	cd mw_dir &&
	echo "this log must stay" > msg.tmp &&
	git log --format=%s > log.tmp &&
	diff -b msg.tmp log.tmp &&
	cd .. &&
	wiki_check_content mw_dir/Namnam.mw Namnam &&
	rm -rf mw_dir
'


test_expect_success 'git clone works multiple specific page cloned ' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	wiki_editpage foo "I will be there" false &&
	wiki_editpage bar "I will not disapear" false &&
	wiki_editpage namnam "I be erased" false &&
	wiki_editpage nyancat "nyan nyan nyan you will not erase me" false &&
	wiki_delete_page namnam &&
	git clone -c remote.origin.pages='"'foo bar nyancat namnam'"' mediawiki::http://localhost/wiki mw_dir &&
	test_contains_N_files mw_dir 3 &&
	test ! -e mw_dir/Namnam.mw &&
	test -e mw_dir/Foo.mw &&
	test -e mw_dir/Nyancat.mw &&
	test -e mw_dir/Bar.mw &&
	wiki_check_content mw_dir/Foo.mw Foo &&
	wiki_check_content mw_dir/Bar.mw Bar &&
	wiki_check_content mw_dir/Nyancat.mw Nyancat &&
	rm -rf mw_dir
'  

test_expect_success 'mediawiki-clone of several specific pages on wiki' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	wiki_editpage foo "foo 1" false &&
	wiki_editpage bar "bar 1" false &&
	wiki_editpage dummy "dummy 1" false &&
	wiki_editpage cloned_1 "cloned_1 1" false &&
	wiki_editpage cloned_2 "cloned_2 2" false &&
	wiki_editpage cloned_3 "cloned_3 3" false &&
	mkdir -p ref_page &&
	wiki_getpage cloned_1 ref_page &&
	wiki_getpage cloned_2 ref_page &&
	wiki_getpage cloned_3 ref_page &&
	git clone -c remote.origin.pages="cloned_1 cloned_2 cloned_3" mediawiki::http://localhost/wiki mw_dir_spage &&
	test_diff_directories mw_dir_spage ref_page &&
	rm -rf mw_dir_spage &&
	rm -rf ref_page
'


test_expect_success 'git clone works with the shallow option' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir_s_page &&
	rm -rf ref_page &&
	wiki_editpage foo "1st revision, should be cloned" false &&
	wiki_editpage bar "1st revision, should be cloned" false &&
	wiki_editpage nyan "1st revision, should not be cloned" false &&
	wiki_editpage nyan "2nd revision, should be cloned" false &&
	git -c remote.origin.shallow=true clone mediawiki::http://localhost/wiki/ mw_dir &&
	test_contains_N_files mw_dir 4 &&
	test -e mw_dir/Nyan.mw &&
	test -e mw_dir/Foo.mw &&
	test -e mw_dir/Bar.mw &&
	test -e mw_dir/Main_Page.mw &&
	cd mw_dir &&
	test `git log --oneline Nyan.mw | wc -l` -eq 1 &&
	test `git log --oneline Foo.mw | wc -l` -eq 1 &&
	test `git log --oneline Bar.mw | wc -l` -eq 1 &&
	test `git log --oneline Main_Page.mw | wc -l ` -eq 1 &&
	cd .. &&
	wiki_check_content mw_dir/Nyan.mw Nyan &&
	wiki_check_content mw_dir/Foo.mw Foo &&
	wiki_check_content mw_dir/Bar.mw Bar &&
	wiki_check_content mw_dir/Main_Page.mw Main_Page &&
	rm -rf mw_dir
'

test_expect_success 'git clone works with the shallow option with a delete page' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	wiki_editpage foo "1st revision, will be deleted" false &&
	wiki_editpage bar "1st revision, should be cloned" false &&
	wiki_editpage nyan "1st revision, should not be cloned" false &&
	wiki_editpage nyan "2nd revision, should be cloned" false &&
	wiki_delete_page foo &&
	git -c remote.origin.shallow=true clone mediawiki::http://localhost/wiki/ mw_dir &&
	test_contains_N_files mw_dir 3 &&
	test -e mw_dir/Nyan.mw &&
	test ! -e mw_dir/Foo.mw &&
	test -e mw_dir/Bar.mw &&
	test -e mw_dir/Main_Page.mw &&
	cd mw_dir &&
	test `git log --oneline Nyan.mw | wc -l` -eq 1 &&
	test `git log --oneline Bar.mw | wc -l` -eq 1 &&
	test `git log --oneline Main_Page.mw | wc -l ` -eq 1 &&
	cd .. &&
	wiki_check_content mw_dir/Nyan.mw Nyan &&
	wiki_check_content mw_dir/Bar.mw Bar &&
	wiki_check_content mw_dir/Main_Page.mw Main_Page &&
	rm -rf mw_dir
'


test_expect_success 'test of fetching a category' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	wiki_editpage Foo "I will be cloned" false -c=Category &&
	wiki_editpage Bar "Meet me on the repository" false -c=Category &&
	wiki_editpage Dummy "I will not come" false &&
	wiki_editpage BarWrong "I will stay online only" false -c=NotCategory &&
	git clone -c remote.origin.categories="Category" mediawiki::http://localhost/wiki mw_dir &&
	wiki_getallpage ref_page Category &&
	test_diff_directories mw_dir ref_page
	rm -rf mw_dir &&
	rm -rf ref_page
'

test_expect_success 'test of resistance to modification of category on wiki for clone' '
	wiki_reset &&
	cd '"$TRASH_DIR"' &&
	rm -rf mw_dir &&
	rm -rf ref_page &&
	wiki_editpage Tobedeleted "this page will be deleted" false -c=Catone &&
	wiki_editpage Tobeedited "this page will be modified" false -c=Catone &&
	wiki_editpage Normalone "this page wont be modified and will be on git" false -c=Catone &&
	wiki_editpage Notconsidered "this page will not appears on local" false &&
	wiki_editpage Othercategory "this page will not appears on local" false -c=Cattwo &&
	wiki_editpage Tobeedited "this page have been modified" true -c=Catone &&
	wiki_delete_page Tobedeleted
	git clone -c remote.origin.categories="Catone" mediawiki::http://localhost/wiki mw_dir &&
	wiki_getallpage ref_page Catone &&
	test_diff_directories mw_dir ref_page &&
	rm -rf mw_dir &&
	rm -rf ref_page 
'

test_done
