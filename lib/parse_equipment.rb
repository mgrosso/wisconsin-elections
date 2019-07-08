require 'csv'

# parse the 2018 equipment by city data released from elections.wi.gov
# TODO: do we need to specially account for Douglas county rename in 2018?
module ParseEquipment
  DIR='csv-inputs/equipment/'
  FILE='WI-Voting-Equipment-List-by-Municipality-August-2018.csv'
  PATH = "#{DIR}#{FILE}"

  def load_csv
    CSV.read PATH
  end

  def data_rows
    load_csv[1..-1]
  end

  def extract_column_names
    load_csv.first
  end

  COUNTY_RE = /^([A-Z\. -]+) COUNTY - \d+(?:.*)/
  def extract_county(row)
    m = COUNTY_RE.match row[0]
    m[1].upcase.strip
  end

  def unique_counties
    data_rows.map { |row| extract_county row }.sort.uniq
  end

  CITY_RE = /^((?:CITY|TOWN|VILLAGE) OF (?:[\w \.-]+)) - (?:[0-9]*)$/i
  CITY_MAIN_RE = /^((?:CITY|TOWN|VILLAGE) OF (?:[\w \.-]+)) - MAIN$/i
  def extract_city(row)
    m = CITY_RE.match row[1]
    city = m[1]
    city_with_main = CITY_MAIN_RE.match city
    city = if city_with_main
      city_with_main[1]
    else
      city
    end
    city.upcase.strip
  end

  def unique_cities
    data_rows.map { |row| extract_city row }.sort.uniq
  end

  def transform(row)
    obj = {
      county: extract_county(row),
      city: extract_city(row),
      raw: row
    }
    obj[:county_city_key] = "#{obj[:county]}___#{obj[:city]}"
    obj
  end

  def loadhash_by_county_city
    Hash[data_rows
      .map { |row| transform row }
      .map { |obj| [obj[:county_city_key], obj] }]
  end
end

class EquipmentParser
  extend ParseEquipment
end
