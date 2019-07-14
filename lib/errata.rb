
# parse the 2018 equipment by city data released from elections.wi.gov
# TODO: do we need to specially account for Douglas county rename in 2018?
module ErrataData

  JOIN_FIXES = [
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

    # "CHIPPEWA___CITY OF EAU CLAIRE"
    # https://en.wikipedia.org/wiki/Eau_Claire,_Wisconsin
    #   Eau Claire (/oʊˈklɛər/) is a city in Chippewa and Eau Claire counties in the west-central part of the U.S. state of Wisconsin. Located almost entirely in Eau Claire County, for which it is the county seat,[8] the city had a population of 65,883 at the 2010 census,[9] making it the state's ninth-largest city.
    # "CHIPPEWA___CITY OF EAU CLAIRE"
    # CHIPPEWA COUNTY - 09 CITY OF BLOOMER - 09206 Dominion (Sequoia)/Command Central- Optech Insight Dominion (Sequoia)/Command Central-Edge
    # EAU CLAIRE COUNTY - 18 CITY OF EAU CLAIRE - MAIN - 18221 ES&S DS200 ES&S ExpressVote
    # going with CHIPPEWA as both counties are internally homogenous with respect to their
    # voting equipment
    ["CHIPPEWA___CITY OF EAU CLAIRE", "CHIPPEWA___CITY OF BLOOMER"],

    # "GREEN___VILLAGE OF BELLEVILLE"
    # https://en.wikipedia.org/wiki/Belleville,_Wisconsin
    #     Belleville is a village in Dane and Green counties in the U.S. state of Wisconsin. The population was 2,385 at the 2010 census. Of this, 1,848 were in Dane County, and 537 were in Green County.
    # Green county is otherwise homogenous in its use of Dominion, eg:
    # GREEN COUNTY - 23 CITY OF BRODHEAD - MAIN - 23206 Dominion ImageCast Evolution Dominion ImageCast Evolution
    # Dane county is entirely ES&S DS200, but 1/6 use "Express Vote" for marking while the
    # remainder use ES&S Automark
    # DANE COUNTY - 13 VILLAGE OF BELLEVILLE - MAIN - 13106 ES&S DS200 ES&S Automark
    ["GREEN___VILLAGE OF BELLEVILLE", "DANE___VILLAGE OF BELLEVILLE"],


    # [252, "GREEN", "VILLAGE OF BROOKLYN"]]
    # DANE COUNTY - 13 VILLAGE OF BROOKLYN - MAIN - 13109 ES&S DS200 ES&S Automark
    # GREEN COUNTY - 23 TOWN OF BROOKLYN - 23006 Dominion ImageCast Evolution Dominion ImageCast Evolution
    # https://en.wikipedia.org/wiki/Brooklyn_(village),_Wisconsin
    #   Brooklyn is a village in Dane and Green Counties in the U.S. state of Wisconsin. At the 2000 census, 502 Brooklyn residents lived in Dane County and 414 in Green County, with a total population of 916. The 2010 census population was 1,401 inhabitants, with 936 of these in Dane County and 465 in Green County.
    # https://en.wikipedia.org/wiki/Brooklyn,_Green_County,_Wisconsin
    #   Brooklyn is a town in Green County, Wisconsin, United States. The population was 1,083 at the 2010 census. The unincorporated community of Attica is located in the town. Section one of the Town of Brooklyn contains the portion of the village of Brooklyn that lies in Green County.
    #
    # since wikipedia tells us the Green county part of the village of Brooklyn is
    # located within the town of Brooklyn in Green county, we'll map it that way,
    # assuming they use the same Dominion equipment as the rest of the town.
    #
    ["GREEN___VILLAGE OF BROOKLYN", "GREEN COUNTY___TOWN OF BROOKLYN"],


    #  [239, "COLUMBIA", "VILLAGE OF RANDOLPH"]]
    # https://en.wikipedia.org/wiki/Randolph_(town),_Wisconsin
    #   Randolph is a town in Columbia County, Wisconsin, United States. The population was 699 at the 2000 census. The Village of Randolph lies to the southeast of the town and only a tiny portion of the village is within the town.
    #
    # https://en.wikipedia.org/wiki/Randolph,_Wisconsin
    #   Randolph is a village in Columbia and Dodge Counties in the U.S. state of Wisconsin. The population was 1,811 at the 2010 census. Of this, 1,339 were in Dodge County, and 472 were in Columbia County. The village is located at the southeast corner of the Town of Randolph in Columbia County, although only a tiny portion of the village lies within the town. Most of the village lies within the Town of Westford in Dodge County. Small portions also lie within the Town of Fox Lake (also in Dodge County) to the north and the Town of Courtland in Columbia County.
    #
    # all of columbia county uses the ES&S DS200 as the scanner/tabulator.
    #
    # except for two municipalities with ES&S Express Vote all of columbia county
    # uses the ES&S Automark, eg:
    # COLUMBIA COUNTY - 11 TOWN OF RANDOLPH - 11034 ES&S DS200 ES&S Automark
    # therefore:
    ["COLUMBIA___VILLAGE OF RANDOLPH", "COLUMBIA___TOWN OF RANDOLPH"],

    # [235, "MARATHON", "CITY OF COLBY"]]
    # https://en.wikipedia.org/wiki/Colby,_Wisconsin
    #   Colby is a city in Clark and Marathon counties in the U.S. state of Wisconsin. It is part of the Wausau, Wisconsin Metropolitan Statistical Area. The population was 1,852 at the 2010 census.[6] Of this, 1,354 were in Clark County, and 498 were in Marathon County. The city is bordered by the Town of Colby, the Town of Hull, and the City of Abbotsford.
    # MARATHON COUNTY - 37	CITY OF MOSINEE - 37251	ES&S DS200	ES&S Automark
    ["MARATHON___CITY OF COLBY", "MARATHON___CITY OF MOSINEE"],

    # [148, "MARATHON", "CITY OF ABBOTSFORD"]]
    # https://en.wikipedia.org/wiki/Abbotsford,_Wisconsin
    #   Abbotsford is a city in Clark (mostly) and Marathon counties in the U.S. state of Wisconsin. The population was 2,310 at the 2010 census.[6] Of this, 1,616 were in Clark County, and 694 were in Marathon County.
    ["MARATHON___CITY OF ABBOTSFORD", "MARATHON___CITY OF MOSINEE"],

    # https://en.wikipedia.org/wiki/Dorchester,_Wisconsin
    # Dorchester is a village in Clark and Marathon counties in the U.S. state of Wisconsin, along the 45th parallel. It is part of the Wausau, Wisconsin Metropolitan Statistical Area. The population was 876 at the 2010 census.[6] Of this, 871 were in Clark County, and only 5 were in Marathon County.
    ["MARATHON___VILLAGE OF DORCHESTER", "MARATHON___CITY OF MOSINEE"],

    # https://en.wikipedia.org/wiki/Birnamwood,_Wisconsin
    # Birnamwood is a village in Marathon and Shawano counties in the U.S. state of Wisconsin. It is part of the Wausau, Wisconsin Metropolitan Statistical Area. The population was 818 at the 2010 census.[6] Of this, 802 were in Shawano County, and 16 were in Marathon County. The village is located mostly within the town of Birnamwood in Shawano County; only a small portion extends into the town of Norrie in adjacent Marathon County.
    ["MARATHON___VILLAGE OF BIRNAMWOOD", "MARATHON___CITY OF MOSINEE"],

    # [136, "CALUMET", "CITY OF KIEL"]]
    # https://en.wikipedia.org/wiki/Kiel,_Wisconsin
    #   Kiel is a city in Calumet and Manitowoc counties in the U.S. state of Wisconsin. The population was 3,738 at the 2010 census. Of this, 3,429 residents lived in Manitowoc County, and 309 residents lived in Calumet County. The city is located primarily within Manitowoc County, though a portion extends west into adjacent Calumet County and is known as "Hinzeville".[6]
    # Calumet municipalities all use Dominion, eg:
    # CALUMET COUNTY - 08 CITY OF BRILLION - 08206 Dominion (Premier)-Accuvote-OS Dominion (Premier)-Accuvote TSX
    # except for one that also uses some ES&S:
    # CALUMET COUNTY - 08 VILLAGE OF HARRISON - MAIN - 08131 Dominion (Premier)-Accuvote-OS/ES&S DS200 Dominion (Premier)-Accuvote TSX/ES&S ExpressVote
    #
    ["CALUMET___CITY OF KIEL", "CALUMET___CITY OF BRILLION"],

    # [124, "LAFAYETTE", "CITY OF CUBA CITY"]]
    # https://en.wikipedia.org/wiki/Cuba_City,_Wisconsin
    #   Cuba City is a city in Grant and partly in Lafayette counties in the U.S. state of Wisconsin. The population was 2,086 at the 2010 census. Of this, 1,877 were in Grant County, and 209 were in Lafayette County.
    #
    # All of Layayette except for the City of Darlington uses Dominion DRE as follows:
    #   LAFAYETTE COUNTY - 33 CITY OF SHULLSBURG - 33281 None  Dominion (Sequoia)/Command Central-Edge
    ["LAFAYETTE___CITY OF CUBA CITY", "LAFAYETTE___CITY OF SHULLSBURG"],

    # [10, "LAFAYETTE", "VILLAGE OF HAZEL GREEN"],
    # https://en.wikipedia.org/wiki/Hazel_Green,_Wisconsin
    #   Hazel Green is a village in Grant and Lafayette counties in the U.S. state of Wisconsin. The population was 1,256 at the 2010 census. Of this, 1,243 were in Grant County, and only 13 were in Lafayette County. The village is located mostly within the Town of Hazel Green in Grant County; only a small portion extends into the Town of Benton in Lafayette County.
    #   LAFAYETTE COUNTY - 33 TOWN OF BENTON - 33006 None  Dominion (Sequoia)/Command Central-Edge
    ["LAFAYETTE___VILLAGE OF HAZEL GREEN", "LAFAYETTE___TOWN OF BENTON"],



    #  [117, "OUTAGAMIE", "VILLAGE OF WRIGHTSTOWN"]]
    # https://en.wikipedia.org/wiki/Wrightstown,_Wisconsin
    #   Wrightstown is a village in Brown and Outagamie counties in the U.S. state of Wisconsin. The population was 2,827 at the 2010 census. Of this, 2,676 were in Brown County, and 151 were in Outagamie County. The village is surrounded mostly by the westernmost part of the Town of Wrightstown in Brown County.
    # all of outgamie county is listed as using the same ES&S configuration, eg:
    #  OUTAGAMIE COUNTY - 45 VILLAGE OF SHIOCTON - 45181 ES&S DS200 ES&S ExpressVote
    ["OUTAGAMIE___VILLAGE OF WRIGHTSTOWN", "OUTAGAMIE___VILLAGE OF SHIOCTON"],




    # [99, "WALWORTH", "VILLAGE OF MUKWONAGO"]]
    # https://en.wikipedia.org/wiki/Mukwonago,_Wisconsin
    # Mukwonago /mʌˈkwɒnəɡoʊ/ is a village in the U.S. state of Wisconsin. The population was 7,355 at the 2010 census. The village is located mostly within the Town of Mukwonago in Waukesha County, with a small portion extending into the Town of East Troy in Walworth County. Of its population, 7,254 were in Waukesha County, and 101 were in Walworth County.
    # all of Walworth county has the same equipment:
    # WALWORTH COUNTY - 65 CITY OF DELAVAN - 65216 Dominion ImageCast Evolution Dominion ImageCast Evolution
    # so...
    ["WALWORTH___VILLAGE OF MUKWONAGO", "WALWORTH___CITY OF DELAVAN"],


    # [1, "WALWORTH", "CITY OF BURLINGTON"],
    # https://en.wikipedia.org/wiki/Burlington,_Wisconsin
    # Burlington is a city in Racine and Walworth counties in the U.S. state of Wisconsin,[4] with the majority of the city located in Racine County.[5] The population of the portion of the city inside Racine County was 10,464 as of the 2010 census.
    ["WALWORTH___CITY OF BURLINGTON", "WALWORTH___CITY OF DELAVAN"],


    # [99, "VERNON", "VILLAGE OF VIOLA"],
    # https://en.wikipedia.org/wiki/Viola,_Wisconsin
    #   Viola is a village in Richland (mostly) and Vernon Counties in the U.S. state of Wisconsin, United States. The population was 699 at the 2010 census. Of this, 477 were in Richland County, and 222 were in Vernon County.
    # RICHLAND COUNTY - 53 VILLAGE OF VIOLA - MAIN - 53186 None  Dominion (Sequoia)/Command Central-Edge
    # but probably more relevant is the fact that all of Vernon county except for the
    # City of Viroqua uses the exact same Dominion config, eg:
    # VERNON COUNTY - 63 VILLAGE OF STODDARD - 63181 None  Dominion (Sequoia)/Command Central-Edge
    ["VERNON___VILLAGE OF VIOLA", "VERNON___VILLAGE OF STODDARD"],

    # [89, "SAUK", "CITY OF WISCONSIN DELLS"]
    # https://en.wikipedia.org/wiki/Wisconsin_Dells,_Wisconsin
    #   Wisconsin Dells is a city in south-central Wisconsin, with a population of 2,678 people as of the 2010 census.[8] It straddles four counties: Adams, Columbia, Juneau, and Sauk.
    #   ...
    #   Of the 2010 total population of 2,678, the population by county was:
    #     Adams County: 61
    #     Columbia County: 2,440
    #     Juneau County: 2
    #     Sauk County: 175
    #
    # all of Sauk county uses the same configuration:
    #  SAUK COUNTY - 57 CITY OF BARABOO - 57206 ES&S DS200 ES&S ExpressVote
    # so:
    ["SAUK___CITY OF WISCONSIN DELLS", "SAUK___CITY OF BARABOO"],

    # [7, "SAUK", "VILLAGE OF CAZENOVIA"],
    # https://en.wikipedia.org/wiki/Cazenovia,_Wisconsin
    #   Cazenovia is a village in Richland and Sauk Counties in the U.S. state of Wisconsin. The population was 318 at the 2010 census. Of this, 314 were in Richland County, and only 4 were in Sauk County.
    ["SAUK___VILLAGE OF CAZENOVIA", "SAUK___CITY OF BARABOO"],
  ]

end

class Errata
  extend ErrataData
  def self.join_fixes
    ErrataData::JOIN_FIXES
  end
end
