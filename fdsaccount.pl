#!/usr/bin/env perl
# This is a simple perl way to find 389 Directory Server users atributes. 
# Copyright (C) 2007 Wilmer Jaramillo M. <wilmer@fedoraproject.org>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use Net::LDAP;
use Net::LDAP::Control::Paged;
use Net::LDAP::Constant qw( LDAP_CONTROL_PAGED );

# FD Server information
my $fdserver = '192.168.2.2';
my $fduser = 'uid=XXXXXX,dc=example,dc=gob,dc=ve';
my $fdpass ='XXXXXX';
my @lists;

# baseDN
my $base = 'ou=migra,dc=example,dc=gob,dc=ve';
my $filter = '(&(objectClass=person)(mail=*))';
my $page = Net::LDAP::Control::Paged->new( size => 400 );
my $attrs = [ 'dn','uid', 'mail', 'givenName', 'sn', 'cn' ];

print "[+] Try connect to server $fdserver ...\n";sleep 1;
my $ldap = Net::LDAP->new($fdserver, version=>3) or die $@;
my $fds = $ldap -> bind($fduser, password => $fdpass);
$fds -> code && die my $mesg -> error;

print "==> Retrieve entries of $fdserver ...";
my @args = (
        base => $base,
		filter => $filter,
		scope  => 'sub',
		attrs =>  $attrs,
		timelimit => 60,
	 	control  => [ $page ]
        );

$fds = $ldap -> search(@args);
print "Done.\n";sleep 1;

print "==> Writing entries to file ...\n";
my $count = $fds->count;
my $numList = @lists;

for (my $i=0; $i<$count; $i++) {
    my $entry = $fds->entry($i);
	my $dn = $entry->dn; 
    my $cn = $entry->get_value('cn');
    my $uid = $entry->get_value('uid');$uid = lc($uid);
    my $sn = $entry->get_value('sn');
    my $mail = $entry->get_value('mail');
    my $givenName = $entry->get_value('givenName');

	open(zfile, ">>ldap_users.csv") or die;
	my ($primernombre,$segundonombre) = split(" ",$givenName);
	my ($primerapellido,$segundoapellido) = split(" ",$sn);
	print zfile ("$primernombre,$segundonombre,$primerapellido,$segundoapellido,$mail \n");
    # You can use this to import users on zimbra, for example:
    # print zfile (ca $mail "" givenName "$givenName" sn "$sn" displayName "$cn");
	close zfile;
}

$fds = $ldap->unbind;
print "--\nTotal LDAP entries: $count\n";

# vim: ts=4 sw=4 sts=4 et ai nu nowrap bg=dark
