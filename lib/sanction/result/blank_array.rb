module Sanction
  module Result
    class BlankArray < BlankSlate
      def initialize(decoy)
        @decoy = decoy
      end
    
      def method_missing(m, *args)
        if [:has, :over, :with, :for, :has?, :over?, :with?, :for?].include? m
          @decoy.send(m, *args)
        else
          @decoy.reset_preload_scope
          [].send(m, *args)
        end
      end
    end
  end
end
