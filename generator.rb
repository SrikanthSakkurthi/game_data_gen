#!/usr/bin/env ruby

# 
# Mocks random game data (with usernames and 4 games)
# @author: ashrith (ashrith at cloudwick dot com)
# ---

begin
  %w(rubygems fileutils benchmark parallel ruby-progressbar optparse).each do |gem|
    require gem
  end
rescue LoadError
  STDERR.puts 'Requires following gems:
  1. parallel
  2. ruby-progressbar

  Install using:

  gem install parallel --no-ri --no-rdoc
  gem install ruby-progressbar --no-ri --no-rdoc'
  abort
end

abort 'Only works with ruby 1.9' if RUBY_VERSION < '1.9'

@options = {}
option_parser = OptionParser.new do |opts|
  executable_name = File.basename($PROGRAM_NAME)
  opts.banner = "Usage: #{executable_name} [options]"

  opts.on('-l LINES', '--lines LINES', 'number of lines to generate') do |lines|
    @options[:lines] = lines.to_i
  end

  @options[:lines_per_process] = 50000
  opts.on('-c LinesPerProcess', '--lines-per-process', 'number of lines to generate per process (default: 50,000)') do |count|
    @options[:lines_per_process] = count.to_i
  end

  opts.on('-m', '--multiple-tables', 'generates data in multi-table format') do
    @multi_table = true
  end

  opts.on('-p PATH', '--output-path PATH', 'directory path where output should be written to') do |path|
    @options[:path] = path
  end

  opts.on('-e', '--extra-data', 'generates additional user information') do
    @extras = true
  end

  opts.on('-h', '--help', 'Help') do
    puts option_parser
    abort
  end
end

begin
  option_parser.parse!
rescue OptionParser::ParseError => e
  STDERR.puts e.message
  STDERR.puts option_parser
  exit 1
end

unless @options.has_key?(:lines)
  STDERR.puts 'Missing required argument --lines or -l'
  STDERR.puts option_parser
  exit 1
end

# Globals
@lines = @options[:lines]                 # No. of lines to generate
@lines_per_process = @options[:lines_per_process]
                                          # lines to gen by individual process
@num_of_processes = @lines > @lines_per_process ?
                    @lines / @lines_per_process :
                    1                     # num_of_processes required to compute
puts "processes_count: #{@num_of_processes}" if @num_of_processes > 1
@options[:path] = '/tmp' unless @options.has_key?(:path)
                                          # Output path
@cd = "\t"                                # column delimiter
@ld = "\n"                                # line delimiter
#@extras = false                          # generate extra data : name, phone_no, email, address
@cid_start = 1000                         # Customer id start int
@gender_with_probability = {              # Gender hash with probability
  :male   => 30,
  :female => 70
}
@lifetime_days = 100                      # Life time in days
@friendcount_maxrange = 100               # Friends count maximum range
@friendcount_zero_probability = 0.3       # 30% of times users dont have friends
@paid_subscriber_percent = 0.6            # 5% users are paid customers
@paid_subscriber_frndcount = 5            # users whose frnd_cnt > 5 pay
@age_with_probability = {                 # Age hash with probability
  18 => 15,
  19 => 12,
  20 => 12,
  21 => 11,
  22 => 11,
  23 => 9,
  24 => 7,
  25 => 6,
  26 => 5,
  27 => 4,
  28 => 3,
  29 => 2,
  30 => 2,
}
@countries_with_probability = {           #Countries hash with probabilities
  'USA'      => 60,
  'UK'       => 25,
  'CANADA'   => 5,
  'MEXICO'   => 5,
  'GERMANY'  => 10,
  'FRANCE'   => 10,
  'EGYPT'    => 5
}
@games_female = {
  :city       => 50,
  :pictionary => 30,
  :scramble   => 15,
  :sniper     => 5,
}
@games_male = {
  :sniper     => 70,
  :scramble   => 20,
  :pictionary => 10,
  :city       => 10,
}

# Definations & Classes

# Returns value picked from hash passed randomly based on its weight
# All the weights in the hash must be integers
# @param [Hash] weighted
# @return [Hash::Key] key from the hash
# Ex: marbles = { :black => 51, :white => 17 }
#     3.times { puts choose_weighted(marbles) }
def choose_weighted(weighted)
  #caluculate the total weight
  sum = weighted.inject(0) do |sum, item_and_weight|
    sum += item_and_weight[1]
  end
  #assign a random from total weight to target
  target = rand(sum)
  #return a value based on its weight
  weighted.each do |item, weight|
    return item if target <= weight
    target -= weight
  end
end

# Returns a random phone number
# @return [FixNum]
def gen_phone_num
  "#{rand(900) + 100}-#{rand(900) + 100}-#{rand(1000) + 1000}"
end

# Returns a random international phone number
# @return [FixNum]
def gen_int_phone_num
  "011-#{rand(100) + 1}-#{rand(100) + 10}-#{rand(1000) + 1000}"
end

# Returns a random email based on the usersname
# @param [String] name
# @return [String] email
def gen_email(name)
  firstname = name.split.first
  lastname = name.split.last
  domains = %w(yahoo.com gmail.com privacy.net webmail.com msn.com
               hotmail.com example.com privacy.net)
  return "#{(firstname + lastname).downcase}"\
         "#{rand(100)}\@#{domains[rand(domains.size)]}"
end

# Returns a random date, also can specify range to it
# @param [Float] from
# @param [Float] to
# @return [Time]
# Ex: gen_date
#     gen_date(Time.local(2010, 1, 1))
#     gen_date(Time.local(2010, 1, 1), Time.local(2010, 7, 1))
def gen_date(from=0.0, to=Time.now)
  Time.at(from + rand * (to.to_f - from.to_f))
end

class Names
  # Class that will return some random names based on gender
  @@male_first_names =
    %w(ADAM ANTHONY ARTHUR BRIAN CHARLES CHRISTOPHER DANIEL DAVID DONALD EDGAR
       EDWARD EDWIN GEORGE HAROLD HERBERT HUGH JAMES JASON JOHN JOSEPH KENNETH
       KEVIN MARCUS MARK MATTHEW MICHAEL PAUL PHILIP RICHARD ROBERT ROGER RONALD
       SIMON STEVEN TERRY THOMAS WILLIAM)

  @@female_first_names =
    %w(ALISON ANN ANNA ANNE BARBARA BETTY BERYL CAROL CHARLOTTE CHERYL DEBORAH
       DIANA DONNA DOROTHY ELIZABETH EVE FELICITY FIONA HELEN HELENA JENNIFER
       JESSICA JUDITH KAREN KIMBERLY LAURA LINDA LISA LUCY MARGARET MARIA MARY
       MICHELLE NANCY PATRICIA POLLY ROBYN RUTH SANDRA SARAH SHARON SUSAN
       TABITHA URSULA VICTORIA WENDY)

  @@lastnames = 
    %w(ABEL ANDERSON ANDREWS ANTHONY BAKER BROWN BURROWS CLARK
       CLARKE CLARKSON DAVIDSON DAVIES DAVIS DENT EDWARDS GARCIA
       GRANT HALL HARRIS HARRISON JACKSON JEFFRIES JEFFERSON JOHNSON
       JONES KIRBY KIRK LAKE LEE LEWIS MARTIN MARTINEZ MAJOR MILLER
       MOORE OATES PETERS PETERSON ROBERTSON ROBINSON RODRIGUEZ
       SMITH SMYTHE STEVENS TAYLOR THATCHER THOMAS THOMPSON WALKER
       WASHINGTON WHITE WILLIAMS WILSON YORKE)

  def self.initial
    letters_arr = ('A'..'Z').to_a
    letters_arr[rand(letters_arr.size)]
  end

  def self.lastname
    @@lastnames[rand(@@lastnames.size)]
  end

  def self.female_name
    "#{@@female_first_names[rand(@@female_first_names.size)]} #{lastname}"
  end

  def self.male_name
    "#{@@male_first_names[rand(@@male_first_names.size)]} #{lastname}"
  end
end

class Address
  # Class that will return some random based addresses now only supports USA
  # and UK addresses
  @@street_names = %w( Acacia Beech Birch Cedar Cherry Chestnut Elm Larch Laurel
    Linden Maple Oak Pine Rose Walnut Willow Adams Franklin Jackson Jefferson
    Lincoln Madison Washington Wilson Churchill Tyndale Latimer Cranmer Highland
    Hill Park Woodland Sunset Virginia 1st 2nd 4th 5th 34th 42nd
    )
  @@street_types = %w( St Ave Rd Blvd Trl Rdg Pl Pkwy Ct Circle )

  def self.address_line_1
    "#{rand(4000)} #{@@street_names[rand(@@street_names.size)]}"\
      " #{@@street_types[rand(@@street_types.size)]}"
  end

  @@line2types = %w(Apt Bsmt Bldg Dept Fl Frnt Hngr Lbby Lot Lowr Ofc Ph Pier Rear Rm Side Slip Spc Stop Ste Trlr Unit Uppr)

  def self.address_line_2
    "#{@@line2types[rand(@@line2types.size)]} #{rand(999)}"
  end

  def self.zipcode
    '%05d' % rand(99999)
  end

  def self.uk_post_code
    post_towns = %w(BM CB CV LE LI LS KT MK NE OX PL YO)
    num1 = rand(100).to_s
    num2 = rand(100).to_s
    letters_arr = ("AA".."ZZ").to_a
    letters = letters_arr[rand(letters_arr.size)]
    return "#{post_towns[rand(post_towns.size)]}#{num1} #{num2}#{letters}"
  end

  @@us_states = %w(AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH NJ NM
    NV NY OH OK OR PA RI SC SD TN TX UT VA VT WA WI WV WY)

  def self.state
    @@us_states[rand(@@us_states.size)]
  end
end

# Core
def main(num_of_lines, cid_start, proc, progress=true)
  counter = cid_start + (num_of_lines - 1)

  progressbar = ProgressBar.create(
                  :total => num_of_lines,
                  :format => '%a |%b>>%i| %p%% %t') if progress

  FileUtils.mkdir_p(@options[:path]) unless File.exists?(@options[:path])

  if @multi_table
    cust_table = "#{@options[:path]}/analytics_customer#{proc}.data"
    revn_table = "#{@options[:path]}/analytics_revenue#{proc}.data"
    fact_table = "#{@options[:path]}/analytics_facts#{proc}.data"

    cust_file_handle = File.open(cust_table, "w")
    revn_file_handle = File.open(revn_table, "w")
    fact_file_handle = File.open(fact_table, "w")
  else
    output_file = "#{@options[:path]}/analytics_#{proc}.data"
    output_file_handle = File.open(output_file, "w")
  end

  #header for the file => only generate if its not hive data
  # if @multi_table
  #   cust_file_handle.
  #     puts("cid#{@cd}name#{@cd}gender#{@cd}age#{@cd}rdate#{@cd}country#{@cd}"\
  #       "friend_count#{@cd}lifetime")
  #   revn_file_handle.puts("cid#{@cd}pdate#{@cd}usd")
  #   fact_file_handle.puts("cid#{@cd}game_played#{@cd}gdate")
  # else
  if !@multi_table
    @extras ?
    output_file_handle.puts("cid#{@cd}gender#{@cd}age#{@cd}country#{@cd}"\
    "registerdate#{@cd}name#{@cd}email#{@cd}phone#{@cd}address#{@cd}"\
    "friend_count#{@cd}lifetime"\
    "#{@cd}citygame_played#{@cd}pictionarygame_played#{@cd}scramblegame_played"\
    "#{@cd}snipergame_played#{@cd}revenue#{@cd}paid") :
    output_file_handle.puts("cid#{@cd}gender#{@cd}age#{@cd}country#{@cd}"\
    "registerdate#{@cd}friend_count#{@cd}lifetime#{@cd}citygame_played#{@cd}"\
    "pictionarygame_played#{@cd}scramblegame_played#{@cd}snipergame_played"\
    "#{@cd}revenue#{@cd}paid")
  end

  (cid_start..counter).each do |cid|
    gender        = choose_weighted(@gender_with_probability)
    register_date = gen_date(Time.local(2011, 1, 1))
    year          = register_date.year
    month         = register_date.month
    day           = register_date.day
    age           = choose_weighted(@age_with_probability)
    country       = choose_weighted(@countries_with_probability)
    name          = gender == :male ? Names.male_name : Names.female_name
    email         = gen_email(name)
    phone         = country == 'USA' ? gen_phone_num : gen_int_phone_num
    address       = case country
                    when 'USA'
                      "#{Address.address_line_1} #{Address.address_line_2}"\
                                " #{Address.state} #{Address.zipcode}"
                    when 'UK'
                      "#{Address.address_line_1} #{Address.address_line_2}"\
                                " #{Address.uk_post_code}"
                    when 'CANADA'
                      'N/A'
                    when 'MEXICO'
                      'N/A'
                    when 'GERMANY'
                      'N/A'
                    when 'FRANCE'
                      'N/A'
                    else  #egypt
                      'N/A'
                    end
    # lifetime of user
    rand < 0.6 ? total_days = rand(0..10) :
                 total_days = rand(10..@lifetime_days)
    # friends count
    if rand < @friendcount_zero_probability
      #30% of users do not have friends at all
      friend_count = 0
    else
      # 40% of users will have fried count > 5 and other will be friend < 5
      rand < 0.4 ?
        friend_count = rand(@paid_subscriber_frndcount..@friendcount_maxrange) :
        friend_count = rand(0..@paid_subscriber_frndcount)
    end
    # paid customer
    if ( friend_count > 10 and total_days > 20 )
      paid_subscriber = if rand < @paid_subscriber_percent
                          'yes'
                        else
                          'no'
                        end
    else
      paid_subscriber = 'no'
    end
    # ( friend_count > 5 and total_days > 10 ) ? paid_subscriber = "yes" :
    #                                            paid_subscriber = "no"
    
    # revenue
    if paid_subscriber == 'yes'
      rand < 0.8 ? revenue = rand(5..30) : revenue = rand(30..99)
    else
      revenue = 0
    end
    # Paid_date
    revenue == 0 ? paid_date = 0 :
                  paid_date = gen_date(Time.local(year, month, day), Time.now)
    # games_played by user
    city_counter = 0
    pictionary_counter = 0
    sniper_counter = 0
    scramble_counter = 0
    gender_game_hash = gender == :male ? @games_male : @games_female
    total_days.times do
      case choose_weighted(gender_game_hash)
      when :citygame
        city_counter += 1
      when :pictionary
        pictionary_counter += 1
      when :scramble
        scramble_counter += 1
      else
        sniper_counter += 1
      end
    end

    # build final strings
    if @multi_table
      (customer_tbl ||= "") << "#{cid}" << @cd << "#{name}" << @cd <<
                            "#{gender}" << @cd << "#{age}" << @cd <<
                            "#{register_date.strftime("%Y-%m-%d %H:%M:%S")}" <<
                             @cd << "#{country}" << @cd << "#{friend_count}" <<
                             @cd << "#{total_days}"
      (revenue_tbl ||= "") << "#{cid}" << @cd <<
                           "#{paid_date.strftime("%Y-%m-%d %H:%M:%S")}" <<
                           @cd << "#{revenue}" unless revenue == 0
      #array to store strings
      gender_game_hash = gender == :male ? @games_male : @games_female
      fact_tbl_arr = []
      # num_of_times_played = rand < 0.9 ? rand(1..100) : rand(1..300)
      total_days.times do
        # => Played_date
        played_date = gen_date(Time.local(year, month, day),
                                                      Time.local(2012, 12, 31))
        (fact_tbl ||= "") << "#{cid}" << @cd <<
                          "#{choose_weighted(gender_game_hash)}" << @cd <<
                          "#{played_date.strftime("%Y-%m-%d %H:%M:%S")}"
        fact_tbl_arr << fact_tbl
      end

    else
      if @extras
        ( final_string ||= "" ) << "#{cid}" << @cd << "#{gender}" << @cd <<
                                "#{age}" << @cd << "#{country}" << @cd <<
                                "#{register_date}" << @cd <<
                                "#{name}" << @cd << "#{email}" << @cd <<
                                "#{phone}" << @cd << "#{address}" << @cd <<
                                "#{friend_count}" << @cd << "#{total_days}" <<
                                @cd << "#{city_counter}" <<
                                @cd << "#{pictionary_counter}" << @cd <<
                                "#{scramble_counter}" << @cd <<
                                "#{sniper_counter}" << @cd << "#{revenue}" <<
                                @cd << "#{paid_subscriber}"
      else
        ( final_string ||= "" ) << "#{cid}" << @cd << "#{gender}" << @cd <<
                               "#{age}" << @cd << "#{country}" << @cd <<
                               "#{register_date}" << @cd <<
                               "#{friend_count}" << @cd << "#{total_days}" <<
                               @cd << "#{city_counter}" << @cd <<
                               "#{pictionary_counter}" << @cd <<
                               "#{scramble_counter}" << @cd <<
                               "#{sniper_counter}" << @cd << "#{revenue}" <<
                               @cd << "#{paid_subscriber}"
      end
    end
    # write out to file
    if @multi_table
      cust_file_handle.puts customer_tbl
      revn_file_handle.puts revenue_tbl unless revenue == 0
      # multiple entries for fact_table
      fact_tbl_arr.each do |fact_tbl_str|
        fact_file_handle.puts fact_tbl_str
      end
    else
      output_file_handle.puts final_string
    end
    progressbar.increment if progress
  end
  # close the file descriptors
  if @multi_table
    cust_file_handle.close
    revn_file_handle.close
    fact_file_handle.close
  else
    output_file_handle.close
  end
end # end Core

time = Benchmark.measure do
  # parallel runs to_generate lines which are > than 100k
  if @num_of_processes > 1
    puts "Parallel mode, generating data to #{@options[:path]}"
    progress = ProgressBar.create(:total => @num_of_processes,
                                  :format => '%a |%b>>%i| %p%% %t')
    results = Parallel.map(
                1..@num_of_processes,
                :finish => lambda { |i, item| progress.increment }) do |process|
      main(@lines_per_process, @cid_start + (@lines_per_process* process),
        process, false)
    end
  else
    puts "Sinle process mode, generating data to #{@options[:path]}"
    if @multi_table
      (tmp_file ||= []) << "#{@options[:path]}/analytics_customer.data" <<
                           "#{@options[:path]}/analytics_revenue.data" <<
                           "#{@options[:path]}/analytics_facts.data"
    else
      (tmp_file ||= []) << "#{@options[:path]}/analytics.data"
    end

    main(@lines, @cid_start, 0)
    tmp_file.clear
  end
end
puts "Time took to generate #{@lines} : #{time}"