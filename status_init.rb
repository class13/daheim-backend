statuses = []
statuses << "Away"
statuses << "WG"
statuses << "Elefant"



statuses.length.times do |i|
	db_index	= i+1 # DB doesnt allow zero as Primary Key
	status_name = statuses[i]
	status_obj  = Status.first_or_create :id => db_index
	status_obj.name = status_name
	status_obj.save
end