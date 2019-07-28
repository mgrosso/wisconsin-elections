require 'csv'

# parse the WI 2016 ward level presidential results
# from 'csv-inputs/results-2016/Ward-by-Ward-Recount-Canvass-Results-President.csv'
# exported from 'Ward by Ward Recount  Canvass Results- President.xlsx' with libreoffice
module Parse2016
  DIR = 'csv-inputs/results-2016/'
  FILE = 'Ward-by-Ward-Recount-Canvass-Results-President.csv'
  PATH = "#{DIR}#{FILE}"
  FIRST_DATA_INDEX = 11
  LAST_DATA_INDEX = -3
  SUBTOTALS_LABEL = "County Totals:"
  RETURNS_NUM_COLUMNS = 19
  CITY_WARD_RE = /^((?:CITY|TOWN|VILLAGE) OF (?:[\w \.-]+)) (Ward(?:s)? (?:[0-9,-ABCS]+))$/i
  FIELD_SUFFIX = "16"

  constants
    .map { |c| [c, c.to_s.downcase] }
    .each { |c, s| define_method(s) { Parse2016.const_get c } }

  def extract_column_names(csv)
    columns = csv[9].dup
    columns[0] = 'city'
    columns[1] = 'ward'
    columns[2] = 'totalvote'
    columns[7] = 'hidden'
    # see https://elections.wi.gov/node/3283 'Reporting "Scattering" Votes'
    columns[20] = csv[10][20] # 'SCATTERING'
    columns
  end

  def extract_city_and_ward(row)
    m = city_ward_re.match(row[1])
    {
      city: m[1].upcase.strip,
      ward: m[2]
    }
  end

end

class ResultsParser2016
  extend ParseShared
  extend EtlChecks
  extend Parse2016
end
