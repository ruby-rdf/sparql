require 'rspec/matchers'

module RSpec
  module Matchers
    class MatchArray
      private
      def safe_sort(array)
        case
          when array.all?{|item| item.respond_to?(:<=>) && !item.is_a?(Hash)}
            array.sort
          else
            array
        end
      end
    end
  end
end
