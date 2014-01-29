class TimeWindow < ActiveRecord::Base

  def get_length
    case length_unit
      when 's'
        length
      when 'm'
        length * 60
      when 'h'
        length * 3600
      else
        nil
    end
  end

end