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
    columns[20] = csv[10][20] # 'SCATTERING'
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
    (2..(csv.first.size - 1))
      .map { |col| csv.map { |row| row[col] }.reduce(&:+) }
  end

  def etl_check
    # entering territory where R would do much better.
    calculated_totals = add_numerics filtered_and_fixed
    last_row_totals = load_csv[-1][2..-1].map { |x| paranoid_to_i x }
    deltas = (0..(calculated_totals.size - 1))
      .map { |col| calculated_totals[col] - last_row_totals[col] }
    [
      calculated_totals,
      last_row_totals,
      deltas
    ]
  end

  def etl_ok?
    etl_check.last.map { |x| x * x }.reduce(&:+) == 0
  end

  CITY_WARD_RE = /^((?:CITY|TOWN|VILLAGE) OF (?:[\w \.-]+)) (Ward(?:s)? (?:[0-9,-ABCS]+))$/i

  def extract_city_and_ward(row)
    m = CITY_WARD_RE.match(row[1])
    {
      city: m[1].upcase.strip,
      ward: m[2]
    }
  end

  def extract_county(row)
    row[0].upcase.strip
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

  def transform(row)
    obj = extract_city_and_ward row
    obj[:county] = extract_county row
    obj[:county_city_key] = "#{obj[:county]}___#{obj[:city]}"
    obj[:raw] = row
    obj
  end

  def loadhash_by_county_city
    # TODO add all wards, currently just arbitrary one wins.
    # TODO ie, group_by the key, then merge results, while preserving a ward hash.
    # TODO add check of totals from this hash
    Hash[filtered_and_fixed
      .map { |row| transform row }
      .map { |obj| [obj[:county_city_key], obj] }]
  end

end

class ResultsParser2016
  extend Parse2016
end
