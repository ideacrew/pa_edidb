module Parsers::Xml::IrsReports
	class Policy

    attr_accessor :individuals

		def initialize(parser = nil)
      # Household: 540e05b0c94f63be220107ed
      # ApplicationGroup: 53e6921beb899ad9ca014fb1

      # parser = File.open(Rails.root.to_s + "/policy.xml")
      # parser = Nokogiri::XML(parser)
      @root = parser #.root
      @individuals = []
      covered_individuals
    end

    def covered_individuals
      @root.xpath("n1:enrollees/n1:subscriber/n1:individual").each do |individual|
        @individuals << individual
      end

      @root.xpath("n1:enrollees/n1:members/n1:member/n1:individual").each do |individual|
        @individuals << individual
      end
    end

    def id
      @root.at_xpath("n1:id").text
    end

    def household_aptc
    end

    def total_monthly_premium
      @root.at_xpath("n1:enrollment/n1:premium_amount_total").text
    end

    def qhp_policy_num
    end

    def qhp_issuer_ein
    end

    def qhp_id
      @root.at_xpath("n1:enrollment/n1:plan/n1:coverage_type").text
    end
  end
end