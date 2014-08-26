module MemberAddressChangers
  class Console
    def initialize
      @errors = []
    end

    def no_such_member(details)
      @errors << "Member #{details[:member_id]} does not exist"
    end

    def too_many_health_policies(details)
      @errors << "Member #{details[:member_id]} has too many active health policies"
    end

    def too_many_dental_policies(details)
      @errors << "Member #{details[:member_id]} has too many active dental policies"
    end

    def no_active_policies(details)
      @errors << "Member #{details[:member_id]} has no active policies"
    end

    def fail
      @errors.each do |err|
        puts err
      end
    end
  end
end