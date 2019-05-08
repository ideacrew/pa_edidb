class PersonScrubber
  def self.select_valid_dob(dob_day,dob_month, dob_year)
    begin
      Date.new(dob_year, dob_month, dob_day)
    rescue ArgumentError
      select_valid_dob(dob_day - 1, dob_month, dob_year)
    end
  end

  def self.scrub(person_id)
    person = Person.find(person_id)
    person.name_first = Forgery('name').first_name
    person.name_last = Forgery('name').last_name

    person.members.each do |member|
      new_dob_month = dob_month = member.dob.month
      dob_day = member.dob.day
      dob_year = member.dob.year
      loop do
        new_dob_month = rand(1..12)
        break unless new_dob_month == dob_month
      end
      member.dob = select_valid_dob(dob_day,new_dob_month,dob_year)
      member.ssn = "#{rand(100..799)}00#{rand(1000..7000)}" #00 means fake SSN
      member.valid?
      puts member.errors.full_messages
    end

    person.phones.each do |phone|
      phone.phone_number = Forgery('address').phone
    end

    person.addresses.each do |address|
      address.address_1 = Forgery('address').street_address
      address.address_2 = nil
      address.address_3 = nil
      address.city = Forgery('address').city
      address.state = "NM"
      address.zip = rand(87001..88439) #NM zips
    end

    person.emails.each do |email|
      email.email_address = Forgery('email').address
    end

    person.save
  end
end
