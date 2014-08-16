class Array
  def avg
    # Float will not throw an exception of divided by zero
    _avg = inject(:+).to_f / size.to_f
    
    # But we don't want it to return "NaN" or "Infinity" either here
    _avg.finite? ? _avg : 0.0
  end
  
  # Get the most common value from the array
  def most_common
    self.group_by(&:to_s).values.max_by(&:size).try(:first)
  end

  def median
    sorted = self.sort
    len = sorted.length
    return nil if len == 0
    return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end
end
