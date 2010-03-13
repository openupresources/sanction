module Sanction
  module Permissionable
    module Base
      def self.extended(base)
        base.class_eval %q{
          def permissionable_roles
            Sanction::Role.over(self)
          end
 
          def self.permissionable_roles
            Sanction::Role.over(self)
          end
 
          has_many :specific_permissionable_roles, :as => :permissionable, :class_name => "Sanction::Role", :dependent => :destroy
        }

        base.named_scope :as_permissionable_self, lambda {
          already_joined = Sanction::Extensions::Joined.already? base, ROLE_ALIAS

          returned_scope = {:conditions => ["#{ROLE_ALIAS}.permissionable_type = ?", base.name.to_s], :select => "DISTINCT #{base.table_name}.*"}
          unless already_joined
            returned_scope.merge({:joins => "INNER JOIN #{Sanction::Role.table_name} AS #{ROLE_ALIAS} ON (
              (#{ROLE_ALIAS}.permissionable_id = #{base.table_name}.#{base.primary_key.to_s} OR #{ROLE_ALIAS}.permissionable_id IS NULL)
              AND #{ROLE_ALIAS}.permissionable_type = '#{base.name.to_s}')"})
          end
        }

        base.named_scope :as_permissionable, lambda {|klass_instance|
          already_joined = Sanction::Extensions::Joined.already? base, ROLE_ALIAS
   
          returned_scope = {:conditions => ["#{klass_instance.class.table_name}.#{klass_instance.class.primary_key.to_s} = ?", klass_instance.id], :select => "DISTINCT #{klass_instance.class.table_name}.*"}
          unless already_joined
            returned_scope.merge({:joins => "INNER JOIN #{Sanction::Role.table_name} AS #{ROLE_ALIAS} ON
              (#{ROLE_ALIAS}.permissionable_id = '#{klass_instance.id}' OR #{ROLE_ALIAS}.permissionable_id IS NULL)
              AND #{ROLE_ALIAS}.permissionable_type = '#{klass_instance.class.name.to_s}'"})
          end
        }
      end
    end
  end
end
