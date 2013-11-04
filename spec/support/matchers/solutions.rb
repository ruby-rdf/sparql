require 'rspec/matchers'
require 'rdf/isomorphic'

# For examining unordered solution sets
RSpec::Matchers.define :describe_solutions do |expected_solutions|
  match {|actual_solutions| actual_solutions.isomorphic_with?(expected_solutions)}
  
  failure_message_for_should do |actual_solutions|
    msg = "expected solutions to be isomorphic\n" +
    "expected:\n#{expected_solutions.inspect}" +
    "\nactual:\n#{actual_solutions.inspect}"
    missing = (expected_solutions - actual_solutions) rescue []
    extra = (actual_solutions - expected_solutions) rescue []
    msg += "\nmissing:\n#{missing.inspect}" unless missing.empty?
    msg += "\nextra:\n#{extra.inspect}" unless extra.empty?
    msg
  end
end

# For examining unordered CSV solution sets (simple literals)
RSpec::Matchers.define :describe_csv_solutions do |expected_solutions|
  match do |actual_solutions|
    @simplified_solutions = RDF::Query::Solutions::Enumerator.new do |yielder|
      actual_solutions.each do |solution|
        solution = solution.dup
        actual_solutions.variable_names.each do |name|
          value = solution[name] ||= RDF::Literal("")
          solution[name] = RDF::Literal(value.to_s) if value.literal? && !value.simple?
        end
        yielder << solution
      end
    end
    @simplified_solutions.isomorphic_with?(expected_solutions)
  end
  
  failure_message_for_should do |actual_solutions|
    msg = "expected solutions to be isomorphic\n" +
      "expected  :\n#{expected_solutions.inspect}" +
    "\nsimplified:\n#{@simplified_solutions.inspect}"
    missing = (expected_solutions - actual_solutions) rescue []
    extra = (actual_solutions - expected_solutions) rescue []
    msg += "\nmissing:\n#{missing.inspect}" unless missing.empty?
    msg += "\nextra:\n#{extra.inspect}" unless extra.empty?
    msg
  end
end

# For examining ordered solution sets
RSpec::Matchers.define :describe_ordered_solutions do |expected_solutions|
  match do |actual_solutions|
    node_mapping = actual_solutions.bijection_to(expected_solutions)
    actual_solutions.map_nodes(node_mapping) == expected_solutions
  end
  
  failure_message_for_should do |actual_solutions|
    msg = "expected solutions to be ordered isomorphic\n" +
    "expected:\n#{expected_solutions.inspect}" +
    "\nactual:\n#{actual_solutions.inspect}"
    missing = (expected_solutions - actual_solutions)
    extra = (actual_solutions - expected_solutions)
    msg += "\nmissing:\n#{missing.inspect}" unless missing.empty?
    msg += "\nextra:\n#{extra.inspect}" unless extra.empty?
    msg
  end
end
