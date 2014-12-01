module Premiums
  class PolicyCalculator
    def initialize
    end

    def apply_calculations(policy)
      apply_premium_rates(policy)
      apply_group_discount(policy)
      apply_totals(policy)
      apply_credits(policy)
    end

    def apply_premium_rates(policy)
      plan = policy.plan
      if policy.is_shop?
        plan_year = determine_shop_plan_year(policy)
        rate_begin_date = plan_year.start_date
        policy.enrollees.each do |en|
          en.calculate_premium_using(plan, rate_begin_date)
        end
      else
        policy.enrollees.each do |en|
          en.calculate_premium_using(plan, en.coverage_start)
        end
      end
    end

    def apply_group_discount(policy)
      children_under_21 = policy.enrollees.select do |en|
        ager = Ager.new(en.member.dob)
        age = ager.age_as_of(en.coverage_start)
        (age < 21) && (en.rel_code == "child")
      end
      return(nil) unless children_under_21.length > 3
      orderly_children = (children_under_21.sort_by do |en|
        ager = Ager.new(en.member.dob)
        ager.age_as_of(en.coverage_start)
      end).reverse
      orderly_children.drop(3) do |en|
        en.pre_amt = BigDecimal.new("0.00")
      end
    end

    def apply_totals(policy)
      premium = policy.enrollees.inject(BigDecimal.new("0.00")) do |acc, en|
        prem = acc.to_f + en.pre_amt.to_f
        BigDecimal.new(sprintf("%.2f", prem))
      end
      policy.pre_amt_tot = BigDecimal.new(sprintf("%.2f", premium))
    end

    def apply_credits(policy)
      if policy.is_shop?
        plan_year = determine_shop_plan_year(policy)
        contribution_strategy = plan_year.contribution_strategy
        policy.tot_emp_res_amt = contribution_strategy.contribution_for(policy)
        policy.tot_res_amt = sprintf("%.2f", policy.pre_amt_tot - policy.tot_emp_res_amt)
      else
        policy.tot_res_amt = policy.pre_amt_tot
      end
    end

    def determine_shop_plan_year(policy)
      coverage_start_date = policy.subscriber.coverage_start
      employer = policy.employer
      employer.plan_years.detect do |py|
        (py.start_date <= coverage_start_date) &&
          (py.end_date >= coverage_start_date)
      end
    end
  end
end
