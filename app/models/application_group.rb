class ApplicationGroup
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
  include Mongoid::Paranoia
  include AASM

  auto_increment :hbx_assigned_id, seed: 9999
  field :e_case_id, type: String  # Eligibility system foreign key
  field :e_status_code, type: String
  field :is_active, type: Boolean, default: true   # ApplicationGroup active on the Exchange?

  field :renewal_consent_through_year, type: Integer  # Authorize auto-renewal elibility check through this year (CCYY format)
  field :submitted_date, type: DateTime               # Date application was created on authority system

  field :application_type, type: String
  field :aasm_state, type: String
  field :updated_by, type: String

  # All current and former members of this group
  has_many :applicants, class_name: "Person", inverse_of: :applicant

  # Person responsible for this application group
  has_one :primary_applicant, class_name: "Person"

  # Person who authorizes auto-renewal eligibility check
  has_one :consent_applicant, class_name: "Person"

  has_many :hbx_enrollment_policies, class_name: "Policy", inverse_of: :hbx_enrollment_policy
  # has_and_belongs_to_many :brokers, class_name: "Broker", inverse_of: :application_groups

  embeds_many :irs_groups, cascade_callbacks: true
  accepts_nested_attributes_for :irs_groups

  embeds_many :tax_households, cascade_callbacks: true
  accepts_nested_attributes_for :tax_households

  embeds_many :hbx_enrollments, cascade_callbacks: true
  accepts_nested_attributes_for :hbx_enrollments

  embeds_many :hbx_enrollment_exemptions, cascade_callbacks: true
  accepts_nested_attributes_for :hbx_enrollment_exemptions

  embeds_many :financial_statements
  accepts_nested_attributes_for :financial_statements

  embeds_many :eligibility_determinations, cascade_callbacks: true
  accepts_nested_attributes_for :eligibility_determinations

  embeds_many :qualifying_life_events, cascade_callbacks: true
  accepts_nested_attributes_for :qualifying_life_events, reject_if: proc { |attribs| attribs['sep_start_date'].blank? }, allow_destroy: true

  embeds_many :comments, cascade_callbacks: true
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  validates :renewal_consent_through_year, 
              presence: true,
              numericality: { only_integer: true, inclusion: 2014..2025 }


  scope :all_with_multiple_applicants, exists({ :'applicant_links.1' => true })

#  validates_inclusion_of :max_renewal_year, :in => 2013..2025, message: "must fall between 2013 and 2030"

  index({e_case_id:  1})
  index({is_active:  1})
  index({aasm_state:  1})
  index({primary_applicant_id:  1})
  index({consent_applicant_id:  1})
  index({"irs_group._id" =>  1})
  index({"hbx_enrollment._id" =>  1})
  index({submitted_date:  1})
  index({"applicant_links.applicant_id" => 1})


  aasm do
    state :enrollment_closed, initial: true
    state :open_enrollment_period
    state :special_enrollment_period
    state :open_and_special_enrollment_period

    event :open_enrollment do
      transitions from: :open_enrollment_period, to: :open_enrollment_period
      transitions from: :special_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :open_and_special_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :enrollment_closed, to: :open_enrollment_period
    end

    event :close_open_enrollment do
      transitions from: :open_enrollment_period, to: :enrollment_closed
      transitions from: :special_enrollment_period, to: :special_enrollment_period
      transitions from: :open_and_special_enrollment_period, to: :special_enrollment_period
      transitions from: :enrollment_closed, to: :enrollment_closed
    end

    event :open_special_enrollment do
      transitions from: :open_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :special_enrollment_period, to: :special_enrollment_period
      transitions from: :open_and_special_enrollment_period, to: :open_and_special_enrollment_period
      transitions from: :enrollment_closed, to: :special_enrollment_period
    end

    event :close_special_enrollment do
      transitions from: :open_enrollment_period, to: :open_enrollment_period
      transitions from: :special_enrollment_period, to: :enrollment_closed
      transitions from: :open_and_special_enrollment_period, to: :open_enrollment_period
      transitions from: :enrollment_closed, to: :enrollment_closed
     end
  end

  # single SEP with latest end date from list of active SEPs
  def current_sep
    active_seps.max { |sep| sep.end_date }
  end

  # List of SEPs active for this Application Group today, or passed date
  def active_seps(day = Date.today)
    special_enrollment_periods.find_all { |sep| (sep.start_date..sep.end_date).include?(day) }
  end

  def self.default_search_order
    [
      ["primary_applicant.name_last", 1],
      ["primary_applicant.name_first", 1]
    ]
  end

  def people_relationship_map
    map = Hash.new
    people.each do |person|      
      map[person] = person_relationships.detect { |r| r.object_person == person.id }.relationship_kind
    end
    map
  end

  def self.find_by_case_id(case_id)
    where({"e_case_id" => case_id}).first
  end

end
