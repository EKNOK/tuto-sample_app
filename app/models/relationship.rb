class Relationship < ApplicationRecord
  belongs_to :followe, class_name: "User"
  belongs_to :followed, class_name: "User"
end
