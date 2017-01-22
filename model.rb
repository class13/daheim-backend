class User < ActiveRecord::Base
  self.table_name = "users"
end
class Home < ActiveRecord::Base
  self.table_name = "homes"
end

class HomeDetail < ActiveRecord::Base
	self.table_name = "home_detail"
end