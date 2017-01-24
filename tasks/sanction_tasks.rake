# desc "Explaining what the task does"
# task :sanction do
#   # Task goes here
# end

namespace :sanction do
  namespace :roles do
    desc "Describe your currently configured Sanction Roles. Can aggregate by :principal, :permissionable, or :token"
    task :describe => :environment do
      aggregate_by_options = [:nothing, :principal, :permissionable, :name]
      aggregate_by = aggregate_by_options.first

      if ENV['aggregate_by']
        temp = ENV['aggregate_by'].to_sym
        aggregate_by = (aggregate_by_options.include? temp) ? temp : aggregate_by_options.first
      end
    
      case aggregate_by
        when :nothing
          Sanction::Role::Definition.all.map(&:describe).map {|r| puts r}
        when :principal
          Sanction.principals.each do |principal|
            puts principal.name.to_s
            Sanction::Role::Definition.for(principal).map(&:describe).map {|r| puts r}
            puts
          end
        when :permissionable
          Sanction.permissionables.each do |permissionable|
            puts permissionable.name.to_s
            Sanction::Role::Definition.over(permissionable).map(&:describe).map {|r| puts r}
            puts
          end
        when :name
          Sanction::Role::Definition.names.each do |name|
            puts name.to_s
            Sanction::Role::Definition.with(name).map(&:describe).map {|r| puts r}
            puts
          end
      end
    end
  
    desc "Validate the current roles table by validating against the Sanction::Role::Definitions currently configured."
    task :validate => :environment do
      valid_roles, invalid_roles = (Sanction::Role.all || []).partition {|role| role.valid?}
       
      puts "#{invalid_roles.size} invalid roles."
      puts "#{valid_roles.size} valid roles."
    end

    desc "Validates the current roles table and removes invalid roles according to the Sanction::Role::Definitions currently configured."
    task :cleanse => :environment do
      valid_roles, invalid_roles = (Sanction::Role.all || []).partition {|role| role.valid?}
  
      puts "#{invalid_roles.size} invalid roles."

      if invalid_roles.size > 0
        puts "Removing invalid roles..."
        invalid_roles.map(&:destroy)
        puts "Done"
      end

      puts "#{valid_roles.size} valid roles."
    end
  end
end
