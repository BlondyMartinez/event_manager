require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
    if phone
        phone.gsub!(/\D/, '')
        unless phone.length == 10
            return phone.length == 11 && phone[0] == 1 ? phone.drop(1) : "Invalid phone number"
        end
        return phone
    end
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  
    begin
      civic_info.representative_info_by_address(
        address: zip,
        levels: 'country',
        roles: ['legislatorUpperBody', 'legislatorLowerBody']
      ).officials
    rescue
      'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id,form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')
  
    filename = "output/thanks_#{id}.html"
  
    File.open(filename, 'w') do |file|
      file.puts form_letter
    end
end

def get_contents
    contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
    )
end

def create_letters
    template_letter = File.read('form_letter.erb')
    erb_template = ERB.new template_letter
    
    contents = get_contents

    contents.each do |row|
        id = row[0]
        name = row[:first_name]
        zipcode = clean_zipcode(row[:zipcode])
        legislators = legislators_by_zipcode(zipcode)
    
        form_letter = erb_template.result(binding)
    
        save_thank_you_letter(id, form_letter)
    end
end

def get_phone_numbers
    contents = get_contents

    contents.each do |row|
        phone = clean_phone(row[:homephone])
        puts phone
    end
end

def get_datetimes
  contents = get_contents
  datetimes = []

  contents.each do |row|
      datetimes.push(DateTime.strptime(row[:regdate], "%m/%d/%y %H:%M"))
  end

  datetimes
end

def get_best_hours
  hours = []
  best_hours = []

  get_datetimes.each { |datetime| hours.push(datetime.hour) }
  hours.tally.each { |hour, amount| best_hours.push(hour) if amount == hours.tally.values.max }
  
  if best_hours.length > 1
    best_hours_str = best_hours.join(", ") 
  else
    best_hours_str = best_hours.to_s
  end

  puts "The hours of the day most people registered were: #{best_hours_str}"
end

def get_best_day
  days = []
  best_days = []

  get_datetimes.each { |datetime| days.push(Date::DAYNAMES[datetime.wday]) }
  days.tally.each { |wday, amount| best_days.push(wday) if amount == days.tally.values.max }

  if best_days.length > 1
    best_days_str = best_days.join(", ") 
  else 
    best_days_str = best_days[0].to_s
  end

  puts "The days of the week most people registered were: #{best_days_str}"
end
# create_letters
# get_phone_numbers
get_best_hours
get_best_day