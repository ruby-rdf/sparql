require 'rubygems'
require 'pathname'

class Pathname
  def /(path)
    (self + path).expand_path
  end
end # class Pathname

dir = Pathname(__FILE__).dirname.expand_path / 'sparql'

require dir / 'execute_sparql'