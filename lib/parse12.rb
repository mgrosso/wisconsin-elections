require 'csv'

# parse the WI 2012 ward level presidential results
# from 'csv-inputs/results-2012/Ward-by-Ward-Report_1-2012-presidential.csv'
# exported from 'Ward by Ward Recount  Canvass Results- President.xlsx' with libreoffice
module Parse2012
  DIR = 'csv-inputs/results-2012/'
  FILE = 'Ward-by-Ward-Report_1-2012-presidential.csv'
  PATH = "#{DIR}#{FILE}"
  FIRST_DATA_INDEX = 11
  LAST_DATA_INDEX = -3
  SUBTOTALS_LABEL = "County Totals:"
  RETURNS_NUM_COLUMNS = 10
  FIELD_SUFFIX = "12"

  CITY_WARD_RE = /^((?:CITY|TOWN|VILLAGE) OF (?:[\w \.-]+)) ((?:Ward|WD|WARD WD)(?:s)?\s*(?:[& 0-9,-IABCSand+]*))(?:COMBINED|FIREHOUSE|TOWN HALL)?$/i
  CITY_WARD_RE_FIX_RE = /^((?:CITY|TOWN|VILLAGE) OF (?:[\w \.-]+)) WARD/

  # this metaprogramming ensures a function is available
  # call `path` that returns PATH, and so on.
  constants
    .map { |c| [c, c.to_s.downcase] }
    .each { |c, s| define_method(s) { Parse2012.const_get c } }

  def extract_column_names(csv)
    columns = csv[9].dup
    columns[0] = 'city'
    columns[1] = 'ward'
    columns[2] = 'totalvote'
    columns[7] = 'hidden'
    # see https://elections.wi.gov/node/3283 'Reporting "Scattering" Votes'
    columns[13] = 'SCATTERING'
    columns
  end

  def extract_city_and_ward(row)
    m = city_ward_re.match(row[1])
    # binding.pry unless m
    city_ward = {
      city: m[1].upcase.strip,
      ward: m[2]
    }
    m = city_ward_re_fix_re.match city_ward[:city]
    if m
      city_ward[:city] = m[1]
    end
    city_ward
  end

end

class ResultsParser2012
  extend ParseShared
  extend EtlChecks
  extend Parse2012
end
