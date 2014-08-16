class ESDB::Sc2
  class Map < Sequel::Model(:esdb_sc2_maps)

    # CarrierWave Map Image Uploader
    class MapImageUploader < CarrierWave::Uploader::Base
      include CarrierWave::MiniMagick
      # storage :file
      storage :fog

      # MiniMagick has problems with converting for some reason.
      # Note: the quality processor in lib/patch/carrier_wave.rb also sets the
      # format to 'jpg', so don't use both.
      def _convert(format)
        manipulate! do |img|
          img.format(format)
          img = yield(img) if block_given?
          img
        end
      end

      process :resize_to_fill => [512, 90]
      process :quality => 80 # also converts to jpg

      def full_filename(*args)
        super.chomp(File.extname(super)) + '.jpg'
      end

      def filename
        super.downcase
      end

      def store_dir
        nil # root of the bucket on S3
      end
    end

    plugin :many_through_many

    many_to_one :matches, :class => 'ESDB::Match'

    mount_uploader :image, MapImageUploader

    # Serialize to Jbuilder
    def to_builder(options = {})
      builder = options[:builder] || jbuilder(options)
      builder.(self, :id, :name, :gateway, :s2ma_hash, :image_scale)
      builder
    end
  end
end
