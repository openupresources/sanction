module Sanction
  class Role::Definition
      #--------------------------------------------------#
      #                   Exceptions                     #
      #--------------------------------------------------#
      class Duplicate < Exception; end
      class InvalidRoleConstruction < Exception; end

      #--------------------------------------------------#
      #                   Public API                     #
      #--------------------------------------------------#
      public

      #--------------------------------------------------#
      #                   Initialize                     #
      #--------------------------------------------------#
      attr_accessor :name, :principals, :permissionables, :global, :wildcard, :permissions, :includes

      def initialize(name, relationship_and_options)
        self.name = name

        relationship, options = extract_options(relationship_and_options)

        resolve_relationship(relationship)
        assign_options(options)
        cache!
      end

      #--------------------------------------------------#
      #                   Accessors                      #
      #--------------------------------------------------#
      def self.all
        all_roles
      end

      def self.globals
        global_roles
      end

      def self.wildcards
        wildcard_roles
      end

      def global?
        !!self.global
      end

      def wildcard?
        !!self.wildcard
      end

      def self.for(principal)
        roles_by_principal[principal.to_s] || []
      end

      def self.over(permissionable)
        roles_by_permissionable[permissionable.to_s] || []
      end

      def self.with(name)
        roles_by_name[name.to_sym] || []
      end

      def self.with_permission(permission_name)
        (roles_by_permission[permission_name] || []) + (wildcard_roles || [])
      end

      def self.process_role_or_permission_names_for_permissionable(permissionable, *role_or_permission_names)
        role_or_permission_names.map do |role_or_permission|
          roles_to_look_for = []
          potential_permission_to_roles = Sanction::Role::Definition.permission_to_roles_for_permissionable(role_or_permission, permissionable)
          roles_to_look_for << potential_permission_to_roles.map(&:name) unless potential_permission_to_roles.blank?

          # Globals are removed from permissionable candidates
          potential_roles = Sanction::Role::Definition.with(role_or_permission) & (Sanction::Role::Definition.over(permissionable) | Sanction::Role::Definition.globals)
          roles_to_look_for << potential_roles.map(&:name) unless potential_roles.blank?

          roles_to_look_for << role_or_permission if roles_to_look_for.blank?
          roles_to_look_for
        end.flatten.uniq
      end

      def self.process_role_or_permission_names_for_principal(principal, *role_or_permission_names)
        role_or_permission_names.map do |role_or_permission|
          roles_to_look_for = []
          potential_permission_to_roles = Sanction::Role::Definition.permission_to_roles_for_principal(role_or_permission, principal)
          roles_to_look_for << potential_permission_to_roles.map(&:name) unless potential_permission_to_roles.blank?

          potential_roles = Sanction::Role::Definition.with(role_or_permission) & Sanction::Role::Definition.for(principal)
          roles_to_look_for << potential_roles.map(&:name) unless potential_roles.blank?

          roles_to_look_for << role_or_permission if roles_to_look_for.blank?
          roles_to_look_for
        end.flatten.uniq
      end

      def self.permission_to_roles_for_principal(permission_name, principal)
        self.with_permission(permission_name) & self.for(principal)
      end

      def self.permission_to_roles_for_permissionable(permission_name, permissionable)
        # Globals are removed from permissionable candidates
        self.with_permission(permission_name) & (self.over(permissionable) | self.globals)
      end

      def self.match(principal_options, name, permissionable_options)
        matches = []
        self.with(name).each do |potential|
          matches << potential if potential.principals == principal_options and potential.permissionables == permissionable_options
        end
        if matches.size > 1
          raise Sanction::Role::Definition::Duplicate.new("Multiple Roles defined with: #{matches.first.describe}")
        else
          matches.first
        end
      end

      #--------------------------------------------------#
      #                 Validations                      #
      #--------------------------------------------------#
      def self.valid_role_instance?(role_instance)
        self.valid_role?(role_instance.principal_klass, role_instance.name, role_instance.permissionable_klass)
      end

      def self.valid_role?(principal, role_name, permissionable = nil)
        principal      = principal.class      unless (principal.nil?      or principal.is_a? Class)
        permissionable = permissionable.class unless (permissionable.nil? or permissionable.is_a? Class)


        if valid_principal?(principal) and (permissionable.nil? or valid_permissionable?(permissionable)) and valid_role_name?(role_name)
          if permissionable
            !(self.for(principal) & self.with(role_name) & self.over(permissionable)).blank?
          else
            !(self.for(principal) & self.with(role_name)).blank?
          end
        else
          false
        end
      end

      def self.valid_principal?(principal_klass)
        if (not principal_klass.is_a? Class) and principal_klass.respond_to?( :new_record? ) and principal_klass.new_record?
          false
        else
          principal_klass = principal_klass.class unless principal_klass.is_a? Class

          !self.for(principal_klass).blank?
        end
      end

      def self.valid_permissionable?(permissionable_klass)
        if (not permissionable_klass.is_a? Class) and permissionable_klass.respond_to?( :new_record? ) and permissionable_klass.new_record?
          false
        else
          permissionable_klass = permissionable_klass.class unless permissionable_klass.is_a? Class

          !self.over(permissionable_klass).blank?
        end
      end

      def self.valid_role_name?(role_name)
       !self.with(role_name).blank?
      end

      def self.valid_permission_name?(permission_name)
       !self.with_permission(permission_name).blank?
      end

      def self.valid_permission_name_for_principal?(permission_name, principal)
        !(self.with_permission(permission_name) & self.for(principal)).blank?
      end

      def self.valid_permission_name_for_permissionable?(permission_name, permissionable)
        !(self.with_permission(permission_name) & self.over(permissionable)).blank?
      end

      #--------------------------------------------------#
      #                 Convenience                      #
      #--------------------------------------------------#
      def describe
        prefix = principals.map(&:to_s).map(&:pluralize).join(", ")
        suffix = global ? "" : " for #{permissionables.map(&:to_s).map(&:pluralize).join(", ")}"
        suffix << (permissions.blank? ? "" : " implying #{permissions.join(", ")}")

        "#{prefix} can have #{name.to_s.titleize}#{suffix}"
      end

      def self.first
         self.all_roles.first
       end

       def self.last
         self.all_roles.last
       end

       # Make the class behave like a sensible collection!
       extend Enumerable
       def self.each
         self.all_roles.each do |x|
           yield x
         end
       end

      #--------------------------------------------------#
      #                  Private API                     #
      #--------------------------------------------------#
      private
      #--------------------------------------------------#
      #                   Class Vars                     #
      #--------------------------------------------------#
      cattr_accessor :roles_by_name, :roles_by_principal, :roles_by_permissionable, :global_roles, :names, :roles_by_permission, :all_roles, :wildcard_roles

      self.all_roles               = []
      self.wildcard_roles          = []
      self.roles_by_name          = {}
      self.roles_by_principal      = {}
      self.roles_by_permissionable = {}
      self.roles_by_permission     = {}
      self.global_roles            = []
      self.names                  = []

      #--------------------------------------------------#
      #                   Constants                      #
      #--------------------------------------------------#
      ANY_TOKEN         = :any
      ALL_TOKEN         = :all
      ANYTHING_TOKEN    = :anything
      GLOBAL_TOKEN      = :global
      RESERVED_TOKENS   = [ANY_TOKEN, ALL_TOKEN, ANYTHING_TOKEN, GLOBAL_TOKEN]
      OPTION_KEYS       = [:having, :includes]

      #--------------------------------------------------#
      #            Initialize Helpers                    #
      #--------------------------------------------------#
      def extract_options(relationship_and_options)
        relationship = relationship_and_options.slice!(*OPTION_KEYS)

        if relationship.keys.size > 1
          raise Sanction::Role::Definition::InvalidRoleConstruction.new("Role::Definitions only accept one relationship along with #{OPTION_KEYS.join(", ")} optional parameters.")
        end

        [relationship, relationship_and_options]
      end

      def resolve_relationship(relationship)
        attribute_principals(relationship.keys.first)
        attribute_permissionables(relationship.values.first)
      end

      def attribute_principals(arr)
        self.principals = arr
        if(arr == :all)
          self.principals = Sanction.principals.dup
        end

        if self.principals.is_a? Array
          self.principals.map!(&:name)
        else
          self.principals = [self.principals.name]
        end
      end

      def attribute_permissionables(arr)
        self.permissionables = arr
        if(arr == :all)
          self.permissionables = Sanction.permissionables.dup
        elsif(arr == :global)
          self.global = true
          self.permissionables = []
        end

        if self.permissionables.is_a? Array
          self.permissionables.map!(&:name)
        else
          self.permissionables = [self.permissionables.name]
        end
      end

      def establish_permissions(permission_options)
        permission_options ||= []
        self.permissions   ||= []

        permission_options = [permission_options] unless permission_options.is_a? Array

        self.permissions += permission_options unless permission_options.blank?
      end

      def establish_includes(include_options)
        include_options ||= []
        self.includes   ||= []

        include_options = [include_options] unless include_options.is_a? Array

        self.includes += include_options unless include_options.blank?
      end

      def establish_inheritance
        inherited_permissions = []
        self.includes.each do |inc|
          matched = Sanction::Role::Definition.match(self.principals, inc, self.permissionables)
          if matched.respond_to? :permissions
            inherited_permissions += (matched.permissions + [inc])
          end
        end
        inherited_permissions.compact!
        inherited_permissions.uniq!

        self.permissions += inherited_permissions unless inherited_permissions.blank?
      end

      def assign_options(options)
        establish_permissions(options.delete(:having))
        establish_includes(options.delete(:includes))
        establish_inheritance

        self.permissions = self.permissions.map(&:to_sym)

        self.wildcard = true if self.permissions.include? :anything
      end

      #--------------------------------------------------#
      #                   Caching                        #
      #--------------------------------------------------#
      def cache!
        cache_all!
        cache_name!
        cache_global!
        cache_wildcards!

        cache_roles_by_name!
        cache_roles_by_principal!
        cache_roles_by_permissionable!
        cache_roles_by_permission!
      end

      def cache_roles_by_principal!
        self.principals.each do |p|
          roles_by_principal[p] ||= []
          roles_by_principal[p] << self
        end
      end

      def cache_roles_by_permissionable!
        self.permissionables.each do |p|
          roles_by_permissionable[p] ||= []
          roles_by_permissionable[p] << self
        end
      end

      def cache_roles_by_permission!
        self.permissions.each do |permission|
          roles_by_permission[permission] ||= []
          roles_by_permission[permission] << self
        end
      end

      def cache_roles_by_name!
        roles_by_name[self.name.to_sym] ||= []
        roles_by_name[self.name.to_sym] << self
      end

      def cache_all!
        all_roles << self
      end

      def cache_name!
        names    << self.name unless names.include? self.name
      end

      def cache_global!
        if self.global?
          global_roles << self
        end
      end

      def cache_wildcards!
        if self.wildcard?
          wildcard_roles << self
        end
      end
  end
end
