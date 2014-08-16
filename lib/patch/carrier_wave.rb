# Append the version name instead of prepending it, as per:
# https://github.com/jnicklas/carrierwave/wiki/How-To%3A-Move-version-name-to-end-of-filename,-instead-of-front

module CarrierWave
  module Uploader
    module Versions
      def full_filename(for_file)
        parent_name = super(for_file)
        ext         = File.extname(parent_name)
        base_name   = parent_name.chomp(ext)
        [base_name, version_name].compact.join('_') + ext
      end

      def full_original_filename
        parent_name = super
        ext         = File.extname(parent_name)
        base_name   = parent_name.chomp(ext)
        [base_name, version_name].compact.join('_') + ext
      end
    end
  end
end

# https://github.com/jnicklas/carrierwave/wiki/How-to%3A-Specify-the-image-quality
# Might not work due to the converting workaround in map.rb, but I'll leave 
# it here for now.

module CarrierWave
  module MiniMagick
    def quality(percentage)
      manipulate! do |img|
        img.format('jpg')
        img.quality(percentage.to_s)
        img = yield(img) if block_given?
        img
      end
    end
  end
end