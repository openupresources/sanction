module Sanction
  module Permissionable
    module For
      def self.included(base)
        base.extend ClassMethods
        base.send(:include, InstanceMethods)
      end
      
      module ClassMethods
        def self.extended(base)
          base.named_scope :for_scope_method, lambda {|*args| 
            if args.include? Sanction::Role::Definition::ANY_TOKEN
              {:conditions => ["#{ROLE_ALIAS}.principal_type IS NOT NULL"]}
            else
              args.map {|a| raise Sanction::Role::Error::UnknownPrincipal.new("Unknown principal: #{a}") unless Sanction::Role::Definition.valid_principal? a }

              conds = []
              args.each do |arg|
                if arg.is_a? Class
                  conds << ["#{ROLE_ALIAS}.principal_type = ?", arg.to_s]
                else
                  conds << ["#{ROLE_ALIAS}.principal_type = ? AND (#{ROLE_ALIAS}.principal_id = ? OR #{ROLE_ALIAS}.principal_id IS NULL)", arg.class.name.to_s, arg.id]
                end 
              end 
              conditions = conds.map { |c| base.merge_conditions(c) }.join(" OR ")
              {:conditions => conditions}
            end
          }
        end
        
        def for(*args)
          self.as_permissionable_self.for_scope_method(*args)
        end
      
        def for?(*args)
          !self.for(*args).blank?
        end
      end
      
      module InstanceMethods           
        def for(*args)
          args ||= Sanction::Role::Definition::ANY_TOKEN

          if self.permissionable_roles_loaded?
            self.preload_scope_merge({:preload_for => args})
            self.execute_preload_scope
          else
            self.class.as_permissionable(self).for_scope_method(*args)
          end
        end

        def for?(*args)
          !self.for(*args).blank?
        end        

        private
        def preload_for(*args)
          if args.include? Sanction::Role::Definition::ANY_TOKEN
            self.permissionable_roles.select {|r| r.principal_type != nil}
          else
            p_roles = []
            args.each do |a|
              raise Sanction::Role::Error::UnknownPrincipal.new("Unknown principal: #{a}") unless Sanction::Role::Definition.valid_principal? a 

              p_roles << self.permissionable_roles.select {|r| r.principal_match? a}
            end
            p_roles.flatten.uniq
          end
        end
      end
    end
  end
end
