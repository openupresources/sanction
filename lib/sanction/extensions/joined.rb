module Sanction
  module Extensions
    module Joined
      # Determine if a table (alias) has been joined against already.
      def self.already?(base, with)
        base.joins_values.include?(with)
      end
    end
  end
end
