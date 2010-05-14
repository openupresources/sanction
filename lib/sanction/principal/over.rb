module Sanction
  module Principal
    module Over
      def self.included(base)
        base.extend ClassMethods
        base.send(:include, InstanceMethods)    
      end
      
      module InstanceMethods
        def over(*args)
          if self.principal_roles_loaded?
            found_over = false

            if args.include? Sanction::Role::Definition::ANY_TOKEN
              found_over = true if self.principal_roles.detect {|r| r.permissionable_type != nil}
            else
              args.each do |a|
                raise Sanction::Role::Error::UnknownPermissionable.new("Unknown permissionable: #{a}") unless Sanction::Role::Definition.valid_permissionable? a 

                found_over = true if self.principal_roles.detect {|r| r.permissionable_match? a}
              end
            end

            if found_over
              Sanction::Result::SingleArray.construct(self)
            else
              Sanction::Result::BlankArray.construct(self)
            end
          else
            self.class.as_principal(self).over_scope_method(*args)
          end
        end

        def over?(*args)
          !over(*args).blank?
        end
      end
        
      module ClassMethods
        def self.extended(base)
          base.named_scope :over_scope_method, lambda {|*args|
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
