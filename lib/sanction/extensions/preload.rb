module Sanction
  module Extensions
    module Preload
      PRELOAD_ROLES                = :preload_roles
      PRELOAD_PRINCIPAL_ROLES      = :preload_principal_roles
      PRELOAD_PERMISSIONABLE_ROLES = :preload_permissionable_roles
      PRELOAD_OPTIONS = [PRELOAD_ROLES, PRELOAD_PRINCIPAL_ROLES, PRELOAD_PERMISSIONABLE_ROLES]

      def self.extended(base)
        unless base.respond_to? :find_without_preloaded_roles
          base.class_eval %Q{
            class << self
              alias_method_chain :find, :preloaded_roles
            end
          } 
        end
        base.send :include, Scope
      end

      def find_with_preloaded_roles(*args)
        if args.last.respond_to? :keys and !(args.last.keys & PRELOAD_OPTIONS).blank?
          preload = process_preload_options(args.last)
          results = find_without_preloaded_roles(*args)
          
          if preload[:roles] == true
            preload_roles_for(results)
          else
            if preload[:principal_roles] == true
              preload_principal_roles_for(results)
            end
   
            if preload[:permissionable_roles] == true
              preload_permissionable_roles_for(results)
            end
          end

          results
        else
          find_without_preloaded_roles(*args)
        end
      end

      def process_preload_options(options = {})
        preload = Hash.new(false)
 
        if options.respond_to? :keys
          if options.keys.include? PRELOAD_ROLES
            preload[:roles] = options.delete(PRELOAD_ROLES)
          end

          if options.keys.include? PRELOAD_PRINCIPAL_ROLES
            preload[:principal_roles] = options.delete(PRELOAD_PRINCIPAL_ROLES)
          end 

          if options.keys.include? PRELOAD_PERMISSIONABLE_ROLES
            preload[:permissionable_roles] = options.delete(PRELOAD_PERMISSIONABLE_ROLES)
          end
        end

        preload
      end

      def preload_roles_for(results)
        preload_principal_roles_for(results)
        preload_permissionable_roles_for(results)
      end

      def preload_principal_roles_for(results)
        if self.respond_to? :is_a_principal? and self.is_a_principal?
          roles = Sanction::Role.for(*results)

          if results.respond_to? :each
            results.each do |result|
              result.principal_roles = roles.select {|x| x.principal_match?(result)}
              result.principal_roles_loaded
            end
          elsif results
            results.principal_roles = roles.select {|x| x.principal_match?(results)}
            results.principal_roles_loaded
          end
        end
        results
      end

      def preload_permissionable_roles_for(results)
        if self.respond_to? :is_a_permissionable? and self.is_a_permissionable?
          roles = Sanction::Role.over(*results)

          if results.respond_to? :each
            results.each do |result|
              result.permissionable_roles = roles.select {|x| x.permissionable_match?(result)}
              result.permissionable_roles_loaded
            end
          elsif results
            results.permissionable_roles = roles.select {|x| x.permissionable_match?(results)}
            results.permissionable_roles_loaded
          end
        end
        results
      end

      module Scope
        def preload_scope
          @preload_scope ||= Hash.new([])
        end
  
        def preload_scope=(pscope)
          @preload_scope = pscope
        end

        def reset_preload_scope
          @preload_scope = Hash.new([])
        end

        protected
        def preload_scope_merge(pscope = Hash.new([]))
          [:preload_has, :preload_with, :preload_for, :preload_over].each do |m|
            self.preload_scope[m] = pscope[m] unless pscope[m].blank?
          end
        end

        def execute_preload_scope
          result_set = self.preload_scope.inject(nil) do |result_set, (preload_method, preload_arguments)| 
            if result_set.nil?
              result_set = self.send(preload_method, *preload_arguments)
            else 
              result_set = result_set & self.send(preload_method, *preload_arguments)
            end
          end

          if result_set.blank? 
            Sanction::Result::BlankArray.new(self)
          else
            Sanction::Result::SingleArray.new(self)
          end
        end 
      end
    end
  end
end
