# shared code between 2016 and 2012 results parsing
module ParseShared

  def load_csv
    CSV.read path
  end

  def select_data_rows(csv)
    from = first_data_index
    to = csv.size + last_data_index
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

  def add_columns(aa, cols)
    cols.map { |col| aa.map { |row| row[col] }.reduce(&:+) }
  end

  # expects that 2..-1 of each row have replaced x by paranoid_to_i(x)
  def add_numerics(csv)
    add_columns(csv, (2..(csv.first.size - 1)))
      #.map { |col| csv.map { |row| row[col] }.reduce(&:+) }
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

  def party_counts(totals, labels)
    count_labels = labels[2..-1]
    Hash[
      count_labels
        .zip(totals)
        .group_by { |pair| pair.first }
        .map do |label, pairs|
          [
            "#{label}#{field_suffix}",
            pairs.map { |k, v| v.to_i }.sum
          ]
        end
    ]
  end

  def loadhash_by_county_city
    # TODO add check of totals from this hash
    labels = extract_column_names load_csv
    ret = Hash[ by_county_city.map { |key, ward_results| [key, reduce_wards(ward_results)] } ]
    # mutate the values directly to add combined counts
    ret.values.each do |county_city|
      county_city[:party_counts] = party_counts(county_city[:returns], labels)
    end
    ret
  end

  def reduce_wards(hash_per_ward)
    blank_county_level = {
        ward_returns: {},
        returns: Array.new(returns_num_columns,0),
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
end
