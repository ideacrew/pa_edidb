member_ids_to_keep = %w(
19754010
19754015
19972591
19974272
18839136
18839137
18772833
18772834
19776212
19746705
19746709
19746710
19746711
20036596
176027
168245
168246
168247
19755088
18828575
18825992
19754881
19985318
20035283
20035284
20035285
20035286
20042470
19756609
20034525
20053686
)

kept_policies = Policy.where("enrollees" => {
  "$elemMatch" => {
    "m_id" => {
      "$in" => member_ids_to_keep
    }
  }
})

kept_person_ids = Person.where({
  "members" => {
    "$elemMatch" => {
      "hbx_member_id" => {"$in" => member_ids_to_keep}
    }
  }
}).map(&:id)

policy_ids_to_keep = kept_policies.map(&:id)

puts "Found #{policy_ids_to_keep.length} policies to keep."
puts "Found #{kept_person_ids.length} people to keep."

transmissions_to_keep = Protocols::X12::TransactionSetHeader.where({
  :policy_id => {
    "$in" => policy_ids_to_keep
  },
  "_type" => "Protocols::X12::TransactionSetEnrollment"
}).map(&:transmission_id)

PremiumPayment.where({
  :policy_id => {
    "$nin" => policy_ids_to_keep
  }
}).delete_all

remaining_premium_payment_ids = PremiumPayment.all.map(&:_id)

payment_transmissions_to_keep = Protocols::X12::TransactionSetHeader.where({
  :"_id"=> {
    "$in" => remaining_premium_payment_ids
  },
  "_type" => "Protocols::X12::TransactionSetPremiumPayment"
}).map(&:transmission_id)

remaining_transmission_ids = (transmissions_to_keep + payment_transmissions_to_keep).uniq

puts "Found #{remaining_transmission_ids.length} transmissions to keep."

tsh_to_remove = Protocols::X12::TransactionSetHeader.where(
  :transmission_id => {
    "$nin" => remaining_transmission_ids
  }
)

puts "Found #{tsh_to_remove.count} TSH to remove."
tsh_to_remove.delete_all

Protocols::X12::Transmission.where(
  "_id" => {
    "$nin" => remaining_transmission_ids
  }
).delete_all

Policy.where("_id" => {
  "$nin" => policy_ids_to_keep
}).delete_all

Person.where("_id" => { "$nin" => kept_person_ids }).delete_all

total_trans = Protocols::X12::TransactionSetHeader.count

puts "Redacting the EDI content of #{total_trans} transactions..."

db = Mongoid::Sessions.default


all_body_names = Array.new
tsh_col = db["protocols_x12_transaction_set_headers"]
tsh_col.find.each do |doc|
  body_val = doc['body']
  unless body_val.blank?
    all_body_names << ("uploads/" + body_val)
  end
end

db["fs.files"].find({
"filename" => {
"$nin" => all_body_names
}}).remove_all


=begin
pb = ProgressBar.create(
:title => "Redacting...",
:total => total_trans,
:format => "%t %a %e |%B| %P%%"
)
Protocols::X12::TransactionSetHeader.all.each do |tse|
  if tse.body.present?
    body_path = tse.body.file.path
    tse.body.remove!
    tse.update_attributes!(:body => FileString.new(body_path.gsub(/uploads\//, ""), "-----REDACTED-----"))
  end
  pb.increment
end
pb.finish
=end
