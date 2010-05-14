module Sanction
  module Permissionable
    module With
      def self.included(base)
        base.extend ClassMethods
        base.send(:include, InstanceMethods)
      end
      module ClassMethods
        def self.extended(base)
          base.named_scope :with_scope_method, lambda {|*role_names|  
            if role_names.include? Sanction::Role::Definition::ANY_TOKEN
              {:conditions => [ROLE_ALIAS + ".name IS NOT NULL"]} if role_names.include? :any
            else
              role_names = Sanction::Role::Definition.process_role_or_permission_names_for_permissionable(base, *role_names)

              conditions = role_names.map {|r| base.merge_conditions(["#{ROLE_ALIAS}.name = ?", r.to_s])}.join(" OR ")
              {:conditions => conditions}
            end
          }
        end

        def with(*role_names)
          self.as_permissionable_self.with_scope_method(*role_names) 
        end      
       
        def with?(*role_names)
          !with(*role_names).blank?
        end
      end
      
      module InstanceMethods
        def with(*role_names)
          role_names ||= Sanction::Role::Definition::ANY_TOKEN

          if self.permissionable_roles_loaded?
            self.preload_scope_merge({:preload_with => role_names})
            self.execute_preload_scope
          else
            self.class.as_permissionable(self).with_scope_method(*role_names)
          end
        end

        def with?(*role_names)
          !with(*role_names).blank? 
        end
       
        private
        def preload_with(*role_names)
          if role_names.include? Sanction::Role::Definition::ANY_TOKEN 
            self.permissionable_roles
          else
            p_roles = Sanction::Role::Definition.process_role_or_permission_names_for_permissionable(self.class, *role_names).map(&:to_sym)
            self.permissionable_roles.select { |r| p_roles.include? r.name.to_sym }
          end
        end
      end
    end
  end
end
