# used for self tests and manual qa of results parsing
module EtlChecks
 
  def etl_check_get_deltas(our_totals, spreadsheet_totals)
    (0..(our_totals.size - 1))
      .map { |col| our_totals[col] - spreadsheet_totals[col] }
  end

  def etl_check
    our_totals = add_numerics filtered_and_fixed
    spreadsheet_sums = last_row_totals
    delta = etl_check_get_deltas(our_totals, spreadsheet_sums)
    [
      our_totals,
      spreadsheet_sums,
      delta
    ]
  end

  def etl_ok?
    no_deltas?(etl_check) && no_deltas?(by_county_city_etl_check)
  end

  def no_deltas?(check)
    check.last.map { |x| x * x }.reduce(&:+) == 0
  end

  def by_county_city_etl_check
    our_totals = county_city_derived_state_totals
    spreadsheet_sums = last_row_totals
    delta = etl_check_get_deltas(our_totals, spreadsheet_sums)
    [
      our_totals,
      spreadsheet_sums,
      delta
    ]
  end

  def county_city_derived_state_totals
    labels = extract_column_names load_csv
    aa = loadhash_by_county_city.map { |_, hsh| hsh[:returns] }
    add_columns(aa, (0..(aa.first.size - 1)))
  end

  def last_row_totals
    load_csv[-1][2..-1].map { |x| paranoid_to_i x }
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
end
