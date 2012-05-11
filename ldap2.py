import ldap

try:
	l = ldap.open("192.168.2.2")
	l.protocol_version = ldap.VERSION3	
	
	username = "CN=manager"
	password  = "PASS"
	
	l.simple_bind(username, password)
except ldap.LDAPError, e:
	print e
