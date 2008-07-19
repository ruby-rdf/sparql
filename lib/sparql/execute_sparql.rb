# This file is part of Sparql.rb.
# 
# Sparql.rb is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Sparql.rb is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with Sparql.rb.  If not, see <http://www.gnu.org/licenses/>.


require 'rubygems'
require 'treetop'

Treetop.load "lib/sparql/primitives"
Treetop.load "lib/sparql/prefixed_names"
Treetop.load "lib/sparql/variables"
Treetop.load "lib/sparql/iri"
Treetop.load "lib/sparql/logical_expressions"
Treetop.load "lib/sparql/graph"
Treetop.load "lib/sparql/series"
Treetop.load "lib/sparql/sparql"