# Various patches to ruby's Hash 

class Hash
  # Hash intersection - by keys only, values in self takes precedence
  def &(hsh)
    h = self.dup
    hsh.each do |k, v|
      if h[k].is_a?(Hash)
        h[k] = v & hsh[k]
      elsif !h.has_key?(k)
        h.delete(k)
      end
    end
    
    h.each do |k, v|
      if !hsh.has_key?(k)
        h.delete(k)
      elsif v.is_a?(Hash) && hsh[k].is_a?(Hash)
        h[k] = v & hsh[k]
      end
    end

    h
  end
end