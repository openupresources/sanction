module Sanction
  module Result
    class SingleArray
      def self.construct(decoy)
        a = [decoy]
        a.instance_variable_set(:@decoy, decoy)
        (class << a; self; end).send(:include, MethodMissing)
        a
      end

      module MethodMissing 
        def method_missing(m, *args)
          @decoy.send(m, *args)
        end
      end
    end
  end
end
