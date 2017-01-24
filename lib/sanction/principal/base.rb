module Sanction
  module Principal
    module Base
      def self.extended(base)
        base.class_eval %Q{
          def principal_roles
            @principal_roles ||= Sanction::Role.for(self)
          end

          def principal_roles=(principal_roles)
            @principal_roles = principal_roles
          end

          def principal_roles_loaded?
            @principal_roles_loaded ||= false
          end

          def principal_roles_loaded
            @principal_roles_loaded = true
          end

          def self.principal_roles
            Sanction::Role.for(self)
          end

          def self.is_a_principal?
            true
          end

          has_many :specific_principal_roles, :as => :principal, :class_name => "Sanction::Role", :dependent => :destroy
        }

        base.scope :as_principal_self, lambda {
          where(["#{ROLE_ALIAS}.principal_type = ?", base.name.to_s]).distinct.joins(
            "INNER JOIN #{Sanction::Role.table_name} AS #{ROLE_ALIAS} ON
              (#{ROLE_ALIAS}.principal_id = #{base.table_name}.#{base.primary_key.to_s} OR #{ROLE_ALIAS}.principal_id IS NULL)
              AND #{ROLE_ALIAS}.principal_type = '#{base.name}'"
            )
        }

        base.scope :as_principal, lambda {|klass_instance|
          where(["#{klass_instance.class.table_name}.#{klass_instance.class.primary_key.to_s} = ?", klass_instance.id]).joins(
          "INNER JOIN #{Sanction::Role.table_name} AS #{ROLE_ALIAS} ON
            (#{ROLE_ALIAS}.principal_id = '#{klass_instance.id}' OR #{ROLE_ALIAS}.principal_id IS NULL) AND
            #{ROLE_ALIAS}.principal_type = '#{klass_instance.class.name}'"
          )

        }
      end
    end
  end
end
