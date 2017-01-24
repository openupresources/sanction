module Sanction
  module Principal
    module Over
      def self.included(base)
        base.extend ClassMethods
        base.send(:include, InstanceMethods)    
      end
      
      module InstanceMethods
        def over(*args)
          args ||= Sanction::Role::Definition::ANY_TOKEN

          if self.principal_roles_loaded?
            self.preload_scope_merge({:preload_over => args})
            self.execute_preload_scope
          else
            self.class.as_principal(self).over_scope_method(*args)
          end
        end

        def over?(*args)
          !over(*args).blank?
        end

        private
        def preload_over(*args)
          if args.include? Sanction::Role::Definition::ANY_TOKEN
            self.principal_roles.select {|r| r.permissionable_type != nil}
          else
            p_roles = []
            args.each do |a|
              raise Sanction::Role::Error::UnknownPermissionable.new("Unknown permissionable: #{a}") unless Sanction::Role::Definition.valid_permissionable? a 

              p_roles << self.principal_roles.select {|r| r.permissionable_match? a}
            end
            p_roles.flatten.uniq
          end
        end
      end
        
      module ClassMethods
        def self.extended(base)
          base.scope :over_scope_method, lambda {|*args|
            if args.include? Sanction::Role::Definition::ANY_TOKEN
              {:conditions => ["#{ROLE_ALIAS}.permissionable_type IS NOT NULL"]}
            else
              args.map {|a| raise Sanction::Role::Error::UnknownPermissionable.new("Unknown permissionable: #{a}") unless Sanction::Role::Definition.valid_permissionable? a }

              conds = []
              args.each do |arg|
                if arg.is_a? Class
                  conds << ["#{ROLE_ALIAS}.permissionable_type = ?", arg.name.to_s] 
                else 
                  conds << ["#{ROLE_ALIAS}.permissionable_type = ? AND (#{ROLE_ALIAS}.permissionable_id = ? OR #{ROLE_ALIAS}.permissionable_id IS NULL)", arg.class.name.to_s, arg.id]
                end 
              end
              conditions = conds.map { |c| base.merge_conditions(c) }.join(" OR ")
              {:conditions => conditions}
            end
          }
        end
  
        def over(*args)
          self.as_principal_self.over_scope_method(*args) 
        end
        
        def over?(*args)
          !over(*args).blank?
        end
      end
    end
  end
end
