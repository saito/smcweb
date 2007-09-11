#! /bin/sh

DIR=`dirname $0`/../..
cd $DIR

# RSPEC
ruby script/plugin install -x svn://rubyforge.org/var/svn/rspec/tags/CURRENT/rspec
ruby script/plugin install -x svn://rubyforge.org/var/svn/rspec/tags/CURRENT/rspec_on_rails
./script/generate rspec

