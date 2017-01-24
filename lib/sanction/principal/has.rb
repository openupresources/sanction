module Sanction
  module Principal
    module Has
      def self.included(base)
        base.extend ClassMethods
        base.send(:include, InstanceMethods)
      end

      module ClassMethods
        def self.extended(base)
          base.scope :has_scope_method, lambda {|*role_names|
            if role_names.include? Sanction::Role::Definition::ANY_TOKEN
              where("#{ROLE_ALIAS}.name IS NOT NULL")
            else
              role_names = Sanction::Role::Definition.process_role_or_permission_names_for_principal(base, *role_names)
              where(["#{ROLE_ALIAS}.name IN (?)", role_names])
            end
          }
        end

        def has(*role_names)
          self.as_principal_self.has_scope_method(*role_names)
        end

        def has?(*role_names)
          !has(*role_names).blank?
        end
      end

      module InstanceMethods
        def has(*role_names)
          role_names ||= Sanction::Role::Definition::ANY_TOKEN

          if self.principal_roles_loaded?
            self.preload_scope_merge({:preload_has => role_names})
            self.execute_preload_scope
          else
            self.class.as_principal(self).has_scope_method(*role_names)
          end
        end

        def has?(*role_names)
          !has(*role_names).blank?
        end

        private
        def preload_has(*role_names)
          if role_names.include? Sanction::Role::Definition::ANY_TOKEN
            self.principal_roles
          else
            p_roles = Sanction::Role::Definition.process_role_or_permission_names_for_principal(self.class, *role_names).map(&:to_sym)
            self.principal_roles.select { |r| p_roles.include? r.name.to_sym }
          end
        end
      end
    end
  end
end
