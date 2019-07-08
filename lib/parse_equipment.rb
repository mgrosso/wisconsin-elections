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

  RESULT_VS_EQUIPMENT_TOWN_NAMES = [
    # see https://en.wikipedia.org/wiki/Windsor,_Wisconsin
    # it went from TOWN to VILLAGE in 2015, but not every spreadsheet was
    # updated at the same time, it would seem.
    ["DANE___VILLAGE OF WINDSOR", "DANE___TOWN OF WINDSOR"],

    # https://en.wikipedia.org/wiki/River_Falls,_Wisconsin
    #   River Falls is a city in Pierce and St. Croix counties in the U.S. state of Wisconsin. It is adjacent to the Town of River Falls in Pierce County and the Town of Kinnickinnic in St. Croix County. River Falls is the most populous city in Pierce county. The population was 15,000 at the 2010 census, with 11,851 residing in Pierce County, and 3,149 in St. Croix County.
    # so results are broken out separately for the PEIRCE vs ST. CROIX county residents, but
    # there is no entry in the equipment spreadsheet for ST. CROIX CITY OF RIVER FALLS. Every
    # other ST. CROIX county uses the ES&S DS200 scanner and the ES&S ExpressVote machine.
    # eg: # ST. CROIX COUNTY - 56 CITY OF GLENWOOD CITY - 56231 ES&S DS200 ES&S ExpressVote
    # meanwhile the PIERCE county bulk of River Falls also uses the same combination. that
    # record looks like this:
    # PIERCE COUNTY - 48 CITY OF RIVER FALLS - MAIN - 48276 ES&S DS200 ES&S ExpressVote
    # So need to reach out for confirmation, but in the meantime work with the assumption that
    # "ST. CROIX___CITY OF RIVER FALLS" looks like "PIERCE___CITY OF RIVER FALLS"
    ["ST. CROIX___CITY OF RIVER FALLS", "PIERCE___CITY OF RIVER FALLS"],

    # https://en.wikipedia.org/wiki/Menasha,_Wisconsin
    # Menasha is a city in Calumet and Winnebago counties in the U.S. state of Wisconsin. The population was 17,353 at the 2010 census. Of this, 15,144 were in Winnebago County, and 2,209 were in Calumet County. The city is located mostly in Winnebago County; only a small portion is in the Town of Harrison in Calumet County.
    #
    # *ALL* of calumet county looks like :
    # CALUMET COUNTY - 08 CITY OF BRILLION - 08206 Dominion (Premier)-Accuvote-OS Dominion (Premier)-Accuvote TSX
    # (except for the VILLAGE OF HARRISON which also has the ES&S DS200/ES&S ExpressVote combo)
    #
    # *ALL* of Winnebago county uses the same Dominion combo, including the city of Menasha,
    # which looks like:
    # WINNEBAGO COUNTY - 71 CITY OF MENASHA - MAIN - 71251 Dominion ImageCast Evolution Dominion ImageCast Evolution
    # So need to reach out for confirmation, but in the meantime work with the assumption that
    # the CALUMET, CITY OF MENASHA machines are owned administered at the county level, so...
    ["CALUMET___CITY OF MENASHA", "CALUMET___CITY OF BRILLION"],
    # NOT ["CALUMET___CITY OF MENASHA", "WINNEBAGO___CITY OF BRILLION"],

    # ok MARARATHON COUNTY has VILLAGE OF MAINE, population 2337 in 2010
    # and OUTAGAMIE COUNTY has TOWN OF MAINE, population 831 in 2000
    # sooo, what's this?
    # MARATHON COUNTY - 37 TOWN OF MAINE - 37052 ES&S DS200 ES&S Automark
    # since there is also this:
    # OUTAGAMIE COUNTY - 45 TOWN OF MAINE - 45030 ES&S DS200 ES&S ExpressVote
    # I'm assuming 
    # MARATHON COUNTY - 37 TOWN OF MAINE  meant VILLAGE OF MAIN
    ["MARATHON___VILLAGE OF MAINE", "MARATHON___TOWN OF MAINE"],

    # "JEFFERSON___CITY OF WHITEWATER"
    # https://en.wikipedia.org/wiki/Whitewater,_Wisconsin
      # Whitewater is a city in Walworth (mostly) and Jefferson counties in the U.S. state of Wisconsin. ... As of the 2010 census, the city's population was 14,390.[6] Of this, 11,150 were in Walworth County, and 3,240 were in Jefferson County.
    #
    # Jefferson county is all ES&S DS22/ExpressVote, like this one:
    # JEFFERSON COUNTY - 28	TOWN OF WATERTOWN - 28032	ES&S DS200	ES&S ExpressVote
    # vs
    # WALWORTH COUNTY - 65 CITY OF WHITEWATER - MAIN - 65291 Dominion ImageCast Evolution Dominion ImageCast Evolution
    # since both counties are straight shot one county or another, we'll assume that
    # JEFFERSON county CITY OF WHITEWATER follows the county not the city and uses the
    # ES&S equipment.
    ["JEFFERSON___CITY OF WHITEWATER", "JEFFERSON___CITY OF WATERTOWN"],

    # "OUTAGAMIE___CITY OF NEW LONDON"
    # https://en.wikipedia.org/wiki/New_London,_Wisconsin
    # New London is a city in Outagamie and Waupaca Counties in the U.S. state of Wisconsin. Founded in 1851,[6] the population was 7,295 at the 2010 census. Of this, 5,685 were in Waupaca County, and 1,640 were in Outagamie County.
    # OUTGAMIE is consistently ES&S but WAUPACA has couple different Dominion combinations.
    # OUTAGAMIE COUNTY - 45 CITY OF SEYMOUR - 45281 ES&S DS200 ES&S ExpressVote
    # WAUPACA COUNTY - 69 CITY OF NEW LONDON - MAIN - 69261 Dominion ImageCast Evolution Dominion ImageCast Evolution
    # We're assuming the 1640 Outgamie county residents who also reside in the City of
    # New London are using Outgamie county machines, thus:
    ["OUTAGAMIE___CITY OF NEW LONDON", "OUTAGAMIE___CITY OF SEYMOUR"],

    # "MARATHON___CITY OF MARSHFIELD"
    # https://en.wikipedia.org/wiki/Marshfield,_Wisconsin
    #   Marshfield is a city in Wood County and Marathon County in the U.S. state of Wisconsin. It is located at the intersection of U.S. Highway 10, Highway 13 and Highway 97. The largest city in Wood County, its population was 19,118 at the 2010 census.[6] Of this, 18,218 were in Wood County, and 900 were in Marathon County.
    # Marathon county uses ES&S, eg:
    # MARATHON COUNTY - 37 CITY OF MOSINEE - 37251 ES&S DS200 ES&S Automark
    # so does Wood county, so either way it's the same ES&S combo.
    # WOOD COUNTY - 72 CITY OF MARSHFIELD - MAIN - 72251 ES&S DS200 ES&S Automark
    ["MARATHON___CITY OF MARSHFIELD", "MARATHON___CITY OF MOSINEE"],

    # "DODGE___CITY OF WATERTOWN"
    # https://en.wikipedia.org/wiki/Watertown,_Wisconsin
    #   Watertown is a city in Dodge and Jefferson counties in the U.S. state of Wisconsin. Most of the city's population is in Jefferson County. Division Street, several blocks north of downtown, marks the county line. The population of Watertown was 23,861 at the 2010 census.[6] Of this, 15,402 were in Jefferson County, and 8,459 were in Dodge County.
    # "DODGE___CITY OF WATERTOWN"
    #           DODGE COUNTY - 14 CITY OF BEAVER DAM - 14206 ES&S DS200 ES&S ExpressVote
    # JEFFERSON COUNTY - 28 CITY OF WATERTOWN - MAIN - 28291 ES&S DS200 ES&S ExpressVote
    # Both counties are straight line ES&S so there is little risk in assuming that for now.
    ["DODGE___CITY OF WATERTOWN", "JEFFERSON___CITY OF WATERTOWN"],

    # "WINNEBAGO___CITY OF APPLETON"
    # "CALUMET___CITY OF APPLETON"
    # https://en.wikipedia.org/wiki/Appleton,_Wisconsin
    #   Appleton is a city in Outagamie (mostly), Calumet, and Winnebago counties in the U.S. state of Wisconsin.
    #   The population was 72,623 at the 2010 census. Of this figure, 60,045 resided in Outagamie County, 11,088 in Calumet County, and 1,490 in Winnebago County.
    # "WINNEBAGO___CITY OF APPLETON"
    # WINNEBAGO is all Dominion, one combination, eg:
    # WINNEBAGO COUNTY - 71	CITY OF MENASHA - MAIN - 71251	Dominion ImageCast Evolution	Dominion ImageCast Evolution
    # OUTAGAMIE is all ES&S, all DS200 and ExpressVote
    # OUTAGAMIE COUNTY - 45 CITY OF APPLETON - MAIN - 45201 ES&S DS200 ES&S ExpressVote
    # CALUMET is all Dominion, except for one village that also used ES&S. example:
    # CALUMET COUNTY - 08 CITY OF BRILLION - 08206 Dominion (Premier)-Accuvote-OS Dominion (Premier)-Accuvote TSX
    ["CALUMET___CITY OF APPLETON", "CALUMET___CITY OF BRILLION"],
    ["WINNEBAGO___CITY OF APPLETON", "WINNEBAGO___CITY OF MENASHA"],

    # more to come.
  ]

  def loadhash_by_county_city
    Hash[data_rows
      .map { |row| transform row }
      .map { |obj| [obj[:county_city_key], obj] }]
  end

  def fixup_join_keys(source_hash)
    Hash[
      RESULT_VS_EQUIPMENT_TOWN_NAMES.each do |result_key, equipment_key|
        [result_key, source_hash[equipment_key]]
      end
    ]
  end
end

class EquipmentParser
  extend ParseEquipment
end
