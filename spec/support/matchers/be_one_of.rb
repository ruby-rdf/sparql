require 'rspec/matchers'
require 'amazing_print'

::RSpec::Matchers.define :be_one_of do |expected|
  match do |actual|
    expected.include?(actual)
  end

  failure_message do |actual|
    "expected one of #{expected}, got #{actual}"
  end
end
