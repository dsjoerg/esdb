# ESDB Base Model Class
#
# Not in use, because Sequel has massive problems with inheritance.. denying
# me, like many other ruby libraries, one of the best features of ruby. again.
#
# Meanwhile, we use this file to load plugins on Sequel::Model

Sequel.extension :pretty_table

# Changes the *_to_many association method to return a proxy instead of an array of objects.
Sequel::Model.plugin :association_proxies

# Adds association methods to datasets that return datasets of associated objects.
# e.g.: Identity.entities
Sequel::Model.plugin :dataset_associations

Sequel::Model.plugin :tactical_eager_loading

# http://sequel.rubyforge.org/rdoc-plugins/classes/Sequel/Plugins/JsonSerializer.html
Sequel::Model.plugin :json_serializer

# http://sequel.rubyforge.org/rdoc/files/doc/validations_rdoc.html
Sequel::Model.plugin :validation_helpers

# http://sequel.rubyforge.org/rdoc-plugins/classes/Sequel/Plugins/AssociationPks.html
Sequel::Model.plugin :association_pks

# Added for compatibility with FactoryGirl (calls AR style save!)
# TODO: is there ..a gem for this?
class Sequel::Model
  def jbuilder(options = {})
    builder = Jbuilder.new
    builder.filter = options[:filter] if options[:filter]
    builder.provider = options[:provider] if options[:provider]
    builder
  end

  def save!
    raise "Error!" if !save
  end
end


# http://comments.gmane.org/gmane.comp.lang.ruby.sequel/6205
ESDB::Model = Class.new(Sequel::Model)
class ESDB::Model
  include ESDB::Logging

  # I couldn't find ANY documentation for this ..what the fuck?
  plugin :many_through_many

  # Play some magic when we're inherited, like setting the dataset.
  # Note: if using the STI plugin, we need to set the dataset before loading
  # the plugin AND might have problems with STI overwriting the inherited
  # callback. It works as it is currently set up but might be a problem later
  def self.inherited(base)
    # Derive dataset (table name) from class name

    table_name = base.to_s.gsub('::', '_').underscore.pluralize.to_sym
    begin
      base.dataset
    rescue Sequel::Error
      base.set_dataset(table_name)
    end
    
    super
  end
end
