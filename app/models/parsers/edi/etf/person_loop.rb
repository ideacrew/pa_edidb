module Parsers
  module Edi
    module Etf
      class PersonLoop
        def initialize(l2000)
          @loop = l2000
        end

        def member_id
          @member_id ||= (@loop["REFs"].detect do |r|
              r[1] == "17"
            end)[2]            
        end

        def carrier_member_id
          # TODO: Memoize this, but account for nil
          get_carrier_member_id
        end

        def get_carrier_member_id
            c_member_seg = (@loop["REFs"].detect do |r|
              r[1] == "23"
            end)
            c_member_seg.nil? ? nil : c_member_seg[2]
        end

        def rel_code
          @rel_code ||= @loop["INS"][2]
        end

        def ben_stat
          @ben_stat ||= @loop["INS"][5]
        end

        def emp_stat
          @emp_stat ||= @loop["INS"][8]
        end

        def subscriber?
          @subscriber ||= (@loop["INS"][2].strip == "18")
        end
      end
    end
  end
end
