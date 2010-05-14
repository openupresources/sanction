module Sanction
  module Result
    class BlankArray < BlankSlate
      def initialize(decoy)
        @decoy = decoy
      end
    
      def method_missing(m, *args)
        if @decoy.class.respond_to? :is_a_principal? and @decoy.class.is_a_principal?
          if [:has, :over].include? m
            Sanction::Result::BlankArray.new(@decoy)
          elsif [:has?, :over?].include? m
            false
          else
            @decoy.reset_preload_scope
            [].send(m, *args)
          end
        elsif @decoy.class.respond_to? :is_a_permissionable? and @decoy.class.is_a_permissionable?
          if [:with, :for].include? m
            Sanction::Result::BlankArray.new(@decoy)
          elsif [:with?, :for?].include? m
            false
          else
            @decoy.reset_preload_scope
            [].send(m, *args)
          end
        else
          @decoy.reset_preload_scope
          [].send(m, *args)
        end
      end
    end
  end
end
