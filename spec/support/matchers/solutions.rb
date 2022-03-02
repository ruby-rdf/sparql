require 'rspec/matchers'
require 'rdf/isomorphic'
require 'rdf/trig'
require 'amazing_print'

# For examining unordered solution sets
RSpec::Matchers.define :describe_solutions do |expected_solutions, info|
  match {|actual_solutions| actual_solutions.isomorphic_with?(expected_solutions)}
  
  failure_message do |actual_solutions|
    initial = info.initial.dump(:trig, standard_prefixes: true) if info.respond_to?(:initial)
    exp = expected_solutions.is_a?(RDF::Enumerable) ? expected_solutions.dump(:trig, standard_prefixes: true) : expected_solutions.to_sse
    res = actual_solutions.is_a?(RDF::Enumerable) ? actual_solutions.dump(:trig, standard_prefixes: true) : actual_solutions.to_sse
    msg = "expected solutions to be isomorphic\n" +
    (initial ? "initial:\n#{initial}" : "\n") +
    "expected:\nvars:#{expected_solutions.variable_names.inspect}\n#{exp}" +
    "\nactual:\nvars:#{actual_solutions.variable_names.inspect}\n#{res}"
    missing = (expected_solutions - actual_solutions) rescue []
    extra = (actual_solutions - expected_solutions) rescue []
    msg += "\ninfo:\n#{info.ai}"
    if info.respond_to?(:query)
      msg += "\nquery:\n#{info.query}"
    elsif info.respond_to?(:action) && info.action.respond_to?(:query_string)
      msg += "\nquery:\n#{info.action.query_string}"
    end
    msg += "\nsse:\n#{info.action.sse_string}" if info.respond_to?(:action)
    msg += "\nmissing:\n#{missing.ai}" unless missing.empty?
    msg += "\nextra:\n#{extra.ai}" unless extra.empty?
    msg
  end
end

# For examining unordered CSV solution sets (simple literals)
RSpec::Matchers.define :describe_csv_solutions do |expected_solutions|
  match do |actual_solutions|
    @simplified_solutions = RDF::Query::Solutions.new
    actual_solutions.each do |solution|
      solution = solution.dup
      actual_solutions.variable_names.each do |name|
        value = solution[name] ||= RDF::Literal("")
        solution[name] = RDF::Literal(value.to_s) if value.literal? && !value.simple?
      end
      @simplified_solutions << solution
    end
    @simplified_solutions.isomorphic_with?(expected_solutions)
  end
  
  failure_message do |actual_solutions|
    msg = "expected solutions to be isomorphic\n" +
      "expected  :\n#{expected_solutions.to_sse}" +
    "\nsimplified:\n#{@simplified_solutions.to_sse}"
    missing = (expected_solutions - actual_solutions) rescue []
    extra = (actual_solutions - expected_solutions) rescue []
    msg += "\nmissing:\n#{missing.ai}" unless missing.empty?
    msg += "\nextra:\n#{extra.ai}" unless extra.empty?
    msg
  end
end

# For examining ordered solution sets
RSpec::Matchers.define :describe_ordered_solutions do |expected_solutions|
  match do |actual_solutions|
    node_mapping = actual_solutions.bijection_to(expected_solutions)
    actual_solutions.map_nodes(node_mapping) == expected_solutions
  end
  
  failure_message do |actual_solutions|
    msg = "expected solutions to be ordered isomorphic\n" +
    "expected:\n#{expected_solutions.ai}" +
    "\nactual:\n#{actual_solutions.ai}"
    missing = (expected_solutions - actual_solutions)
    extra = (actual_solutions - expected_solutions)
    msg += "\nmissing:\n#{missing.ai}" unless missing.empty?
    msg += "\nextra:\n#{extra.ai}" unless extra.empty?
    msg
  end
end
