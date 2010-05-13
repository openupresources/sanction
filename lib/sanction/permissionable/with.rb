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
                
        def with_all?(*role_names)
          result = nil
          role_names.each do |role|
            if result.nil?
              result = self.with(role)
            else
              result = result & self.with(role)
            end
          end

          !result.blank?
        end
      end
      
      module InstanceMethods
        def with(*role_names)
          if self.permissionable_roles_loaded?
            blank_result = true
            if role_names.include? Sanction::Role::Definition::ANY_TOKEN 
              blank_result = false unless self.permissionable_roles.blank?
            else
              p_roles = Sanction::Role::Definition.process_role_or_permission_names_for_permissionable(self.class, *role_names).map(&:to_sym)
              blank_result = false unless self.permissionable_roles.detect { |r| p_roles.include? r.name.to_sym }.blank?
            end

            if blank_result
              Sanction::Result::BlankArray.construct(self)
            else
              Sanction::Result::SingleArray.construct(self)
            end
          else
            self.class.as_permissionable(self).with_scope_method(*role_names)
          end
        end

        def with?(*role_names)
          !with(*role_names).blank? 
        end
        
        def with_all?(*role_names)
          !role_names.map {|r| with(r)}.inject(&:&).blank? 
        end         
      end
    end
  end
end
