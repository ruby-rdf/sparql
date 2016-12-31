require 'rspec/matchers'

::RSpec::Matchers.define :have_result_set do |expected|
  def normalize(soln)
    soln.to_h.inject({}) do |c, (k, v)|
      c.merge(k => v.to_base)
    end
  end

  match do |result|
    @actual = result.map {|s| normalize(s)}
    @expected = expected.map {|s| normalize(s)}
    expect(@actual).to contain_exactly *@expected
  end

  failure_message do |input|
    "Expected     : #{@expected.inspect}\n" +
    "Actual       : #{@actual.inspect}\n"
  end
end
