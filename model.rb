class User < ActiveRecord::Base
  self.table_name = "users"
  belongs_to :home
end
class Home < ActiveRecord::Base
  self.table_name = "homes"
end