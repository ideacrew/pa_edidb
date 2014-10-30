require 'net/http'

module Parsers::Xml::Reports
  class Individual

    def initialize(data_xml = nil)
      
      # xml_file = File.open(Rails.root.to_s + "/individual_address.xml")
      # # parser = Net::HTTP.get(URI.parse('http://localhost:3000/api/v1/people/53e6921beb899ad9ca014faf?user_token=1LGx9y5uvcsR-syqzTob'))
      # parser = Nokogiri::XML(xml_file)
      # @root = parser.root

      @root = data_xml
    end

    def id
      @root.at_xpath("n1:person/n1:id").text.match(/\w+$/)[0] 
    end

    def name_first
      @root.at_xpath("n1:person/n1:name/n1:name_first").text
    end

    def name_middle
      @root.at_xpath("n1:person/n1:name/n1:name_middle").text
    end

    def name_last
      @root.at_xpath("n1:person/n1:name/n1:name_last").text
    end

    def name_suffix
      @root.at_xpath("n1:person/n1:name/n1:name_suffix").text
    end

    def ssn
      @root.at_xpath("n1:hbx_roles/n1:qhp_roles/n1:qhp_role/n1:ssn").text
    end

    def dob
      Date.parse(@root.at_xpath("n1:hbx_roles/n1:qhp_roles/n1:qhp_role/n1:dob").text)
    end

    def age
      Ager.new(dob).age_as_of(Date.parse("2015-1-1"))
    end

    def addresses
      addresses = []
      @root.xpath("n1:person/n1:addresses/n1:address").each do |ele|
        address = {
          address_type: ele.at_xpath('n1:address_type').text,
          address_1: ele.at_xpath('n1:address_1').text,
          city: ele.at_xpath('n1:city').text,
          state: ele.at_xpath('n1:state').text,
          postal_code: ele.at_xpath('n1:postal_code').text
        }
        address.merge!({address_2: (ele.at_xpath('n1:address_2').text if ele.at_xpath('n1:address_2'))})
        addresses << address
      end
      addresses
    end

    def employers
      employers = []
      @root.xpath("n1:hbx_roles/n1:employee_roles/n1:employee_role").each do |ele|
         employers << ele.at_xpath('n1:employer/n1:id').text
      end
      employers
    end

    def incarcerated
      return "No" if @root.at_xpath("n1:incarcerated_flag").nil?
      @root.at_xpath("n1:incarcerated_flag").text == "false" ? "No" : "Yes"
    end

    def projected_income
      nil # @root.at_xpath("n1:financial/n1:incomes/n1:income/n1:amount").text
    end

    # Can we use is_state_resident flag?
    def residency
      return if addresses[0].nil?
      addresses[0][:state].strip == "DC" ? "D.C. Resident" : "Not a D.C. Resident"
    end

    def citizenship
      us_citizen = %W(us_citizen naturalized_citizen indian_tribe_member)
      lawfully_present = %W(alien_lawfully_present lawful_permanent_resident) 
      not_lawfully_present = %W(undocumented_immigrant not_lawfully_present_in_us)

      if @root.at_xpath("n1:citizenship_status").nil?
        raise "Citizenship status missing for person #{self.name_first} #{self.name_last}"
      end

      citizenship_status = @root.at_xpath("n1:citizenship_status").text.split("#")[1]
      return "U.S. Citizen" if us_citizen.include?(citizenship_status)
      return "Lawfully Present" if lawfully_present.include?(citizenship_status)
      return "Not Lawfully Present" if not_lawfully_present.include?(citizenship_status)
    end

    def assistance_eligibility
      @root.xpath("n1:assistance_eligibilities/n1:assistance_eligibility")[0]
    end

    def mec
      benefits = "No"
      es_coverage = assistance_eligibility.at_xpath("n1:is_enrolled_for_es_coverage").text
      if es_coverage == "true"
        return "Yes"
      end
      assistance_eligibility.xpath("n1:alternate_benefits/n1:alternate_benefit").each do |benefit|
        if Date.strptime(benefit.at_xpath("n1:end_date"), "%Y%m%d") <= Date.parse("2015-1-1")
          benefits = "Yes"
          break
        end
      end
      return benefits  
    end

    def yearwise_incomes(year)
      incomes = {}
      assistance_eligibility.xpath("n1:total_incomes/n1:total_income").each do |income|
        amount = income.at_xpath("n1:total_income").text.to_f
        incomes[income.at_xpath("n1:calendar_year").text] = sprintf("%.2f", amount)
      end
      incomes[year]
    end

    def tax_status
      tax_status = assistance_eligibility.at_xpath("n1:tax_filing_status").text

      case tax_status
      when "non_filer"
        "Non-filer"
      when "tax_dependent"
        "Tax Dependent"
      when "tax_filer"
        if relationships.detect{|relationship| ["spouse","life partner"].include?(relationship)}
          tax_filing_together? ? "Married Filing Jointly" : "Married Filing Separately"
        else
          "Single" 
        end
      else
      end
    end

    def relationships
      return [] if @root.at_xpath("n1:relationships/n1:relationship/n1:relationship_uri").nil?
      relationships = []
      @root.xpath("n1:relationships/n1:relationship").each do |relation|
        relationships << relation.at_xpath("n1:relationship_uri").text.split("#")[1]
      end
      relationships
    end

    def tax_filing_together?
      assistance_eligibility.at_xpath("n1:is_tax_filing_together").text
    end

    def policies
      policies = []
      @root.xpath("n1:hbx_roles/n1:qhp_roles/n1:qhp_role/n1:policies/n1:policy").each do |policy|
        policies << policy
      end
      policies
    end

    def health_plan
      if policy = policy_by_type("health")
        policy.at_xpath("n1:plan/n1:name").text
      end
    end

    def dental_plan
      if policy = policy_by_type("dental")
        policy.at_xpath("n1:plan/n1:name").text
      end
    end

    private

    def policy_by_type(type)
      policies.each do |policy|
        coverage = policy.at_xpath("n1:plan/n1:coverage_type").text
        return policy if coverage.split("#")[1] == type
      end
      nil
    end        
  end
end