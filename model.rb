class User < ActiveRecord::Base
  self.table_name = "users"

  #belongs_to :home
end
class Home < ActiveRecord::Base
  self.table_name = "homes"
end

class HomeDetail < ActiveRecord::Base
	self.table_name = "home_detail"
end

class Memberstatus < ActiveRecord::Base
	self.table_name = "USER_TO_HOME"
	self.primary_key = "USER"
end