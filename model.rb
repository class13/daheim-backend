class User < ActiveRecord::Base
  self.table_name = "users"

  #belongs_to :home
end
class Home < ActiveRecord::Base
  self.table_name = "homes"
end

class HomeDetail < ActiveRecord::Base
	self.table_name = "v_home_detail"
end

class Memberstatus < ActiveRecord::Base
	self.table_name = "v_user_home_status"
end