import ldap

try:
	l = ldap.open("192.168.2.2")
 next line appropriately
	
except ldap.LDAPError, error_message:
	print errot_message

baseDN = "OU=People,DC=vzla,DC=gob,DC=ve"
searchScope = ldap.SCOPE_SUBTREE
# retrieve all attributes
retrieveAttributes = None 
searchFilter = "uid=*"
count = 0
timeout = 0

try:
	ldap_result_id = l.search(baseDN, searchScope, searchFilter, retrieveAttributes)
	result_set = []
	while 1:
		result_type, result_data = l.result(ldap_result_id, 0)
		if (result_data == []):
			break
		else:
			if result_type == ldap.RES_SEARCH_ENTRY:
				result_set.append(result_data)
		if len(result_set) == 0:
			print "No Results."
		for i in range(len(result_set)):
			for entry in result_set[i]: 
				try:
					name=entry[1]['cn'][0] 
					
except ldap.LDAPError, error_message:
	print error_message
