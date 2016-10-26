$db_user		= 'root'
$db_pw			= nil
$db_host		= '127.0.0.1'
$db_schema		= 'daheim1'
$db_test_schema = 'test_daheim'
used_schema = $db_schema
if (ENV['RACK_ENV'] == 'test')
	used_schema = $db_test_schema
end
if $db_pw.nil?
	abort "Set your goddamn password in connect.rb, you fucking retard!"

end
$connect_string = 'mysql://' +$db_user+':'+$db_pw+'@'+$db_host+'/'+used_schema