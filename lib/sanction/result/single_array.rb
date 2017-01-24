module Sanction
  module Result
    class SingleArray < BlankSlate
      def initialize(decoy)
        @decoy = decoy
      end

      def method_missing(m, *args)
        if [:has, :for, :over, :with, :has?, :for?, :over?, :with?].include? m
          @decoy.send(m, *args)
        else
          @decoy.reset_preload_scope
          [@decoy].send(m, *args)
        end
      end
    end
  end
end
