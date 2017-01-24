class Person < ActiveRecord::Base
  # to test for non-standard primary_key compliance
  set_primary_key 'unique_id'
end
