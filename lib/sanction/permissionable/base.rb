module Sanction
  module Permissionable
    module Base
      def self.extended(base)
        base.class_eval %q{
          def permissionable_roles
            @permissionable_roles ||= Sanction::Role.over(self)
          end

          def permissionable_roles=(permissionable_roles)
            @permissionable_roles = permissionable_roles
          end

          def permissionable_roles_loaded?
            @permissionable_roles_loaded ||= false
          end

          def permissionable_roles_loaded
            @permissionable_roles_loaded = true
          end

          def self.permissionable_roles
            Sanction::Role.over(self)
          end

          def self.is_a_permissionable?
            true
          end

          has_many :specific_permissionable_roles, :as => :permissionable, :class_name => "Sanction::Role", :dependent => :destroy
        }

        base.scope :as_permissionable_self, lambda {
          where(["#{ROLE_ALIAS}.permissionable_type = ?", base.name.to_s]).distinct.joins(
          "INNER JOIN #{Sanction::Role.table_name} AS #{ROLE_ALIAS} ON (
            (#{ROLE_ALIAS}.permissionable_id = #{base.table_name}.#{base.primary_key.to_s} OR #{ROLE_ALIAS}.permissionable_id IS NULL)
            AND #{ROLE_ALIAS}.permissionable_type = '#{base.name.to_s}')"
          )
        }

        base.scope :as_permissionable, lambda {|klass_instance|
          where(["#{klass_instance.class.table_name}.#{klass_instance.class.primary_key.to_s} = ?", klass_instance.id]).distinct.joins(
          "INNER JOIN #{Sanction::Role.table_name} AS #{ROLE_ALIAS} ON
            (#{ROLE_ALIAS}.permissionable_id = '#{klass_instance.id}' OR #{ROLE_ALIAS}.permissionable_id IS NULL)
            AND #{ROLE_ALIAS}.permissionable_type = '#{klass_instance.class.name.to_s}'"
          )
        }
      end
    end
  end
end
