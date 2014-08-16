# This patch overwrites aggregate functions for Sequel::Dataset to support
# custom aggregations and calculations, such as moving averages and also
# 'virtual attributes' such as 'army'.
# 
# Until all necessary calculations have been translated to Sequel, please leave
# the old DataMapper patch (patch/calculations.rb) intact as a reference.
#
# See "section 2", in lib/sequel/dataset/actions.rb
# I can't wait for Ruby 2.0 -- Sequel::Dataset.send(:prepend, ESDB::Dataset)
# Until then: monkey patching our way to glory still.

require 'sequel/dataset/actions.rb'

class Sequel::Dataset
  def virtual_columns
    {
      :army => (0..19).collect{|n| "u#{n}".to_sym}
    }
  end
  
  # Returns the array of corresponding attributes for a virtual attributes
  # if applicable.
  #
  # If attr is a qualified identifer, it also applies its qualification to
  # all columns.
  def virtual?(attr)
    if attr.is_a?(Sequel::SQL::QualifiedIdentifier)
      if virtual_columns.include?(attr.column.to_sym)
        return virtual_columns[attr.column.to_sym].collect do |col|
          Sequel::SQL::QualifiedIdentifier.new(attr.table, col)
        end
      end
    elsif virtual_columns.include?(attr.to_sym)
      return virtual_columns[attr.to_sym]
    end
    
    false
  end
  
  # Returns the average value for the given column.
  def avg(column)
    if virtual?(column)
      column = virtual?(column)
      result = Hash[*self.select(*column.collect{|col|
        Sequel.function(:AVG, col).as(col.respond_to?(:column) ? col.column : col)
      })]

      result.inject({}) {|h,v| h[v[0]] = v[1].to_f; h}
    else
      self.get{avg(column)}.to_f
    end
  end

  # Returns the moving average for a given column
  # TODO: see StatBuilder::Query for the extra hax that makes it possible
  # to pass the cap.. (tl;dr: mavg:[En])
  def mavg(column, cap = nil)
    ws = 10
    column_name = column.respond_to?(:column) ? column.column.to_sym : column.to_sym

    mavg = []

# for some mysterious reason, this produced only the distinct values,
#  rather than _all_ the values
#    selected_results = self.select(column_name).all

    values = []
    if cap.present?
      cap = cap.to_f
    end
    self.select(column).each { |row|
      val = row[column_name]

      if (cap.present? && val.present? && val > cap)
        val = nil
      end

      # FIXME: handle null values appropriately, with window average continuation
      if val.nil?
        if column_name == :win
          values << 0
        else
          values << nil
        end
      elsif val.respond_to?(:to_f)
        values << val.to_f
      else
        # true/false get turned into 1/0
        values << val.to_i
      end
    }

    last_good_value = 0
    values.count.times.each do |i|
      # i is a 0-based counter of our position in the array

      # the i-th window ends at i, and starts (ws-1) positions before
      # that, but never earlier than 0.
      rangeend = i
      rangestart = [0, i - (ws-1)].max
      rangelength = 1 + (rangeend - rangestart)
      window = values.slice(rangestart, rangelength).reject{|elm| elm.nil?}
      if window.size == 0
        mavg << last_good_value
      else
        last_good_value = (window.inject(:+).to_f / window.size).round(2)
        mavg << last_good_value
      end
    end
    
    mavg
  end

  def count(column = '*')
    column_name = column.respond_to?(:column) ? column.column.to_sym : column.to_sym

    case column_name
    when :win, :loss then
      aggregate_dataset.where(:win => (column_name == :win)).count
    else
      aggregate_dataset.get{COUNT(column_name){}.as(count)}.to_i
    end
  end

  # TODO: for both count and pct, especially pct, it can be done way more
  # elegant - these are faster, easier implementations in favor of not
  # adding unecessary complexity right now. Revisit, refactor.
    
  def pct(column)
    ((count(column).to_f / count.to_f) * 100.0).round(2)
  end
end
