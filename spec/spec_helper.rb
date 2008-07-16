require 'rubygems'
require 'pathname'
require 'treetop'

#'WHERE'? space '{' space series_of_triple_patterns space '}'

# rule triples_same_subject
#   var_or_term space property_list_not_empty / triples_node space property_list
# end


class Pathname
  def /(path)
    (self + path).expand_path
  end
end # class Pathname

spec_dir_path = Pathname(__FILE__).dirname.expand_path
require spec_dir_path.parent + 'lib/sparql'



# require fixture resources
Dir[spec_dir_path + "fixtures/*.rb"].each do |fixture_file|
  require fixture_file
end
