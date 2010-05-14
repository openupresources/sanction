module Sanction
  module Result
    class BlankArray
      def self.construct(decoy)
        @decoy = decoy

        a = []
        a.instance_variable_set(:@decoy, @decoy)
        (class << a; self; end).send(:include, MethodMissing)
        a
      end
    
      module MethodMissing 
        def method_missing(m, *args)
          if @decoy.class.respond_to? :is_a_principal? and @decoy.class.is_a_principal?
            if [:has, :over].include? m
              Sanction::Result::BlankArray.construct(@decoy)
            elsif [:has?, :over?].include? m
              false
            end
          elsif @decoy.class.respond_to? :is_a_permissionable? and @decoy.class.is_a_permissionable?
            if [:with, :for].include? m
              Sanction::Result::BlankArray.construct(@decoy)
            elsif [:with?, :for?].include? m
              false
            end
          else
            @decoy.send(m, *args)
          end
        end
      end
    end
  end
end
