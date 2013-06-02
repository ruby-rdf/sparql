require 'linkeddata'
rep = RDF::Repository.new
rep.load("https://raw.github.com/mwkuster/eli-budabe/master/sparql/source.ttl")
query = %{
  PREFIX cdm: <http://publications.europa.eu/ontology/cdm#>

  SELECT DISTINCT ?number ?typedoc ?is_corrigendum (GROUP_CONCAT(?lang_code; separator="-") AS ?langs)
  WHERE
  {
   ?manif cdm:manifestation_official-journal_part_information_number ?number .
   ?manif cdm:manifestation_official-journal_part_typedoc_printer ?typedoc .
   ?manif cdm:manifestation_official-journal_part_is_corrigendum_printer ?is_corrigendum .
   ?manif cdm:manifestation_manifests_expression ?expr .
   ?expr cdm:expression_uses_language ?lang .
   BIND(lcase(replace(str(?lang), ".*/([A-Z]{3})", "$1")) AS ?lang_code)
  }
  GROUP BY ?number ?typedoc ?is_corrigendum
}
s = SPARQL.execute(query, rep)
