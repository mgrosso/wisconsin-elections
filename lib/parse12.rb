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

  def load_csv
    CSV.read PATH
  end

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

  def select_data_rows(csv)
    from = FIRST_DATA_INDEX
    to = csv.size + LAST_DATA_INDEX
    csv[from..to]
  end

  def skip_subtotals(csv)
    csv
      .reject { |row| row[1] == "County Totals:" }
      .reject { |row| row[1] == "Office Totals:" }
  end

  def fixed_city_column(csv)
    cities = csv.map(&:first)
    (0..cities.size - 1)
      .to_a
      .map { |i| cities[i] = cities[i] ? cities[i] :  cities[i-1] }
  end

  def fix_city_column(csv)
    # the first column holds the city name. only the first row of a county
    # is populated because the xlsx stretched that val down over the additional
    # ward rows, and the missing cells were replaced with nil by csv export.
    fixed_column = fixed_city_column csv
    csv
      .each_with_index
      .map { |row, index|  row[1..-1].prepend fixed_column[index] }
  end

  # we want "2,345" to equal 2345, not 2.
  def paranoid_to_i(numeric)
    numeric.to_s.tr(',','').to_i
  end

  def fix_numbers(csv)
    csv.map do |row|
      suffix = row[2..-1].map { |num| paranoid_to_i num }
      [
        row[0],
        row[1],
      ] + suffix
    end
  end

  def filtered_and_fixed
    fix_numbers fix_city_column skip_subtotals select_data_rows load_csv
  end

  # expects that 2..-1 of each row have replaced x by paranoid_to_i(x)
  def add_numerics(csv)
    add_columns(csv, (2..(csv.first.size - 1)))
      #.map { |col| csv.map { |row| row[col] }.reduce(&:+) }
  end

  def add_columns(aa, cols)
    cols.map { |col| aa.map { |row| row[col] }.reduce(&:+) }
  end

  CITY_WARD_RE = /^((?:CITY|TOWN|VILLAGE) OF (?:[\w \.-]+)) ((?:Ward|WD|WARD WD)(?:s)?\s*(?:[& 0-9,-IABCSand+]*))(?:COMBINED|FIREHOUSE|TOWN HALL)?$/i
  CITY_WARD_RE_FIX_RE = /^((?:CITY|TOWN|VILLAGE) OF (?:[\w \.-]+)) WARD/

  def extract_city_and_ward(row)
    m = CITY_WARD_RE.match(row[1])
    binding.pry unless m
    city_ward = {
      city: m[1].upcase.strip,
      ward: m[2]
    }
    m = CITY_WARD_RE_FIX_RE.match city_ward[:city]
    if m
      city_ward[:city] = m[1]
    end
    city_ward
  end

  def extract_county(row)
    row[0].upcase.strip
  end

  def transform(row)
    obj = extract_city_and_ward row
    obj[:county] = extract_county row
    obj[:county_city_key] = "#{obj[:county]}___#{obj[:city]}"
    obj[:raw] = row
    obj
  end

  def by_county_city
    filtered_and_fixed
      .map { |row| transform row }
      .group_by { |hsh| hsh[:county_city_key] }
  end

  def reduce_wards(hash_per_ward)
    blank_county_level = {
        ward_returns: {},
        returns: Array.new(RETURNS_NUM_COLUMNS,0),
      }.merge!(hash_per_ward.first)
    blank_county_level.delete(:ward)
    blank_county_level.delete(:raw)
    hash_per_ward.reduce(blank_county_level) do |combined, ward_hash|
        ward_returns = ward_hash[:raw][2..-1]
        combined[:ward_returns][ward_hash[:ward]] = ward_returns
        # peicewise add in the returns of the new ward.
        combined[:returns] = combined[:returns].zip(ward_returns).map { |a, b| a + b }
        combined
    end
  end

  def loadhash_by_county_city
    # TODO add check of totals from this hash
    Hash[ by_county_city.map { |key, ward_results| [key, reduce_wards(ward_results)] } ]
  end

  #######################################################################
  # what follows is used for self tests and manual qa
  #######################################################################

  def county_city_derived_state_totals
    aa = loadhash_by_county_city.map { |_, hsh| hsh[:returns] }
    add_columns(aa, (0..(aa.first.size - 1)))
  end

  def unique_counties
    filtered_and_fixed
      .map { |row| extract_county row }
      .sort
      .uniq
  end

  def unique_cities
    filtered_and_fixed
      .map { |row| extract_city_and_ward(row) }
      .map { |extracted| extracted[:city].upcase }
      .sort
      .uniq
  end

  def last_row_totals
    load_csv[-1][2..-1].map { |x| paranoid_to_i x }
  end

  def etl_check
    # entering territory where R would do much better.
    our_totals = add_numerics filtered_and_fixed
    deltas = (0..(our_totals.size - 1))
      .map { |col| our_totals[col] - last_row_totals[col] }
    [
      our_totals,
      last_row_totals,
      deltas
    ]
  end

  def by_county_city_etl_check
    their_totals = last_row_totals
    our_totals = county_city_derived_state_totals
    deltas = (0..(our_totals.size - 1))
      .map { |col| our_totals[col] - their_totals[col] }
    [
      our_totals,
      their_totals,
      deltas
    ]
  end

  def no_deltas?(check)
    check.last.map { |x| x * x }.reduce(&:+) == 0
  end

  def etl_ok?
    no_deltas?(etl_check) && no_deltas?(by_county_city_etl_check)
  end

end

class ResultsParser2012
  extend Parse2012
end
