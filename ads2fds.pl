#!/usr/bin/env perl
# Copy/Export MS Active Directory entries to 389 Directory Server. 
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
use Net::LDAP::Constant qw(LDAP_CONTROL_PAGED);

my $base = 'dc=example,dc=gob,dc=ve';
# 389 Directory Server info
my $adserver = '192.168.1.1';
my $aduser = "cn=Administrator,cn=Users,$base";
my $adpass ='';

# MS Active Directory Server info
my $fdserver = '192.168.1.2';
my $fduser = 'uid=admin,ou=Administrators,ou=TopologyManagement,o=NetscapeRoot';
my $fdpass ='';
my $posixShell = "/bin/bash";

# baseDN
my $filter = '(&(objectCategory=person)(objectClass=user))';
my $page = Net::LDAP::Control::Paged->new( size => 400 );
my $attrs = [ 
            'company', 
            'comment',
            'description',
            'displayName',
            'givename',
            'homePhone',
            'initials',
            'mail',
            'mailNickname',
            'member',
            'memberOf',
            'mobile',
            'name',
            'sn',
            'st',
            'title',
            'physicalDeliveryOfficeName',
            'postalCode',
            'userPrincipalName',
            'initials',
            'member',
            'memberOf',
            'mail',
            'homePhone',
            'telephonenumber',
            'mobile',
            'pager',
            'givenName',
            'physicalDeliveryOfficeName',
            'postalCode',
            'company',
            'comment',
            'name',
            'mailNickname',
            'displayName',
            'userPrincipalName',
            'sAMAccountName',
            'accountExpires' 
            ];

print "[+] Try connect to MS Directory Server $adserver ...\n";sleep 1;
my $ldap = Net::LDAP->new($adserver, version=>3) or die $@;
my $ads = $ldap -> bind($aduser, password => $adpass);
$ads -> code && die my $mesg -> error;

print "==> Retrieve entries of $adserver ...";
my @args = (
        base => $base,
		filter => $filter,
		scope  => 'sub',
		attrs =>  $attrs,
		timelimit => 60,
	 	control  => [ $page ]
        );

$ads = $ldap -> search(@args);
print " Done.\n";sleep 1;

print "[+] Try connect to 389 Directory Server $fdserver ...\n";sleep 1;
$ldap = Net::LDAP->new($fdserver, version=>3) or die $@;
my $fds = $ldap -> bind($fduser, password => $fdpass);
$fds -> code && die $fds -> error;

# Date and hour timestamp for when create entries.
my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = gmtime(time);
my $year = 1900 + $yearOffset;
my $timestamp = "$year$month$dayOfMonth$hour$minute$second"."Z";

print "==> Creating OU objects ..\n"; sleep 1;
open (DATOS,"ListaOU.txt") or die $!;
while (my $ous = <DATOS>) {
    chomp $ous;
    my $result = $ldap->add( "$ous",
                 attr => [
                        "createtimestamp"   => ["$timestamp"],
                        "modifiersname"   => "$fduser",
                        "modifytimestamp" => "$timestamp",
                        "objectclass" => ["top", "organizationalunit" ],
		                ]
                    );
    $result->code && warn "Error al añadir la entrada, ", $result->error ;
}
close DATOS;

print "==> Reading entries from $adserver ...\n";
my $count = $ads->count;
my $posixNumber = 1000;
for (my $i=0; $i<$count; $i++) {
    my $entry = $ads->entry($i);
	my $dn = $entry->dn; $dn =~ s/^CN/uid/;	
    my $cn = $entry->get_value('cn');
    my $memberOf = $entry->get_value('memberOf');
    my $member = $entry->get_value('member');
    my $displayName = $entry->get_value('displayName');
    my $userPrincipalName = $entry->get_value('userPrincipalName');
    my $name = $entry->get_value('name');
    my $sn = $entry->get_value('sn');
    my $title = $entry->get_value('title');
    my $mail = $entry->get_value('mail');
    my $mailNickname = $entry->get_value('mailNickname');
    my $physicalDeliveryOfficeName = $entry->get_value('physicalDeliveryOfficeName');
    my $st = $entry->get_value('st');
    my $userPrincipalName = $entry->get_value('userPrincipalName');
    my $postalCode = $entry->get_value('postalCode');
    my $description = $entry->get_value('description');
    my $company = $entry->get_value('company');
    my $department = $entry->get_value('department');
    my $givenName = $entry->get_value('givenName');
    my $homePhone = $entry->get_value('homePhone');
    my $telephonenumber = $entry->get_value('telephonenumber');
    my $comment = $entry->get_value('comment');
    my $description = $entry->get_value('description');
    my $initials = $entry->get_value('initials');
    my $homePhone = $entry->get_value('homePhone');
    my $mobile = $entry->get_value('mobile');
    my $pager = $entry->get_value('pager');
	# Usuarios NT
    my $sAMAccountName = $entry->get_value('sAMAccountName');
	my $accountExpires = $entry->get_value('accountExpires');
	open(sAMA, ">>ListaUsuarios.txt") or die $!;
	print sAMA ("$mailNickname $mail\n");
	close sAMA;

    print "==> Copying entries to $fdserver ...\n";
    my $result = $ldap->add( "$dn",
                 attr => [
                    "cn"   => ["$displayName", ""],
                    "sn"   => "$sn",
                    "mail" => "$mail",
                    "uid" => "$sAMAccountName",
                    "uidNumber" => "$posixNumber", ## Usuario Posix
                    "gidNumber" => "$posixNumber",
                    "homedirectory" => "/home/$sAMAccountName",
                    "loginshell" => "$posixShell",
    		        "ntUserDomainId" => "$sAMAccountName", ## Usuario NT
            		"ntUserAcctExpires" => "$accountExpires",
             		"ntuserDeleteAccount" => "true",
	    	        "modifiersname" => "$fduser",
            		"modifytimestamp" => "20070727194529Z",
                    "objectclass" => ["top", "person",
                    "organizationalPerson", "inetOrgPerson",
                    "posixAccount", "ntUser"],
                    # "posixGroup"
                    # "sambaSamAccount", "shadowAccount" ],
                    ]
                );
    $posixNumber++;
    $result->code && warn "Error al añadir la entrada, ", $result->error ;
}
my $ads = $ldap->unbind;
my $fds = $ldap->unbind;

print "--\nTotal LDAP entries: $count\n";
