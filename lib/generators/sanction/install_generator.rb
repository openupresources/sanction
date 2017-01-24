require 'rails/generators/base'
require 'rails/generators/migration'

module Sanction
  module Generators
    
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path("../../templates", __FILE__) 
    
      desc "Installs a sanction initializer and migration file to your application"

      def copy_initializer
        template "initializer.rb", "config/initializers/sanction.rb"
      end
      
      def copy_migration
        migration_template "migrate/create_roles.rb", "db/migrate/sanction_create_roles.rb"
      end
      
      def self.next_migration_number(path)
        @migration_number = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i.to_s
      end
    end
  end
end


#
# class SanctionGenerator < Rails::Generators::Base
#   def manifest
#    record do |m|
#      m.file 'initializer.rb', "config/initializers/sanction.rb"
#
#      m.migration_template "migrate/create_roles.rb", "db/migrate", :migration_file_name => "create_roles"
#    end
#  end
#end
