module KingFormat
  module MoneyFields

    def self.included(base)
      base.send :class_inheritable_accessor, :money_fields
      base.money_fields = []
      base.extend(ClassMethods)
    end

    module ClassMethods
      #  Defines the fields returned by self.money_fields.
      # ===== Parameter
      # fieldnames<Array[Symbol]>:: fieldnames/instance method names as symbols
      # ==== Example
      # class Invoice
      #   has_money_fields :total, :amout, :calculated_tax
      #
      def has_money_fields(*fieldnames)
        self.money_fields = fieldnames
        include InstanceMethods
      end

      # Check if a given field is declared as money field
      # ==== Parameter
      # fieldname<String>:: The fieldname to check. Is be casted into a symbol.
      def is_money_field?(fieldname)
        self.money_fields.include?(fieldname.to_sym)
      end

    end #ClassMethods

    module InstanceMethods
      # Check if a given field is declared as money field
      # ==== Parameter
      # fieldname<String>:: The fieldname to check. Is casted into a symbol.
      def is_money_field?(fieldname)
        self.class.money_fields.include?(fieldname.to_sym)
      end
    end
    
  end #Fields
end#KingFormat














#
#
#
#
#
#    def self.included(base)
#      base.class_eval do
#
#        #######################################################
#        # Numbers formatted as Money like "39,80 €"
#        def self.has_money_fields(*fieldnames)
#          # Storing the array of money fields as class variable
#          cattr_accessor :money_fields
#
#          self.money_fields = []
#          fieldnames.each do |fieldname|
#
#            # Store all the given field names (as array) for later usage in "money?"
#            self.money_fields << fieldname
#
#            # Create a composed field base on the Money class
#            # The following two methods are based on the original "composed_of" from Rails. But because
#            # the original does not work well with a currency field coming from settings, it is re-implemented here.
#            # Reader method. Returns a Money object for the given fieldname. The currency is taken from the record
#            define_method(fieldname) do |*args|
#              # Get the currency from the current company settings
#              currency = Company.current.currency rescue nil
#
#              force_reload = args.first || false
#              if (instance_variable_get("@#{fieldname}").nil? || force_reload) && (not read_attribute(fieldname).nil?)
#                instance_variable_set("@#{fieldname}", Money.new(read_attribute(fieldname), currency))
#              end
#              instance_variable_get("@#{fieldname}")
#            end
#
#            # Writer method. Stores the given value into the record
#            define_method("#{fieldname}=") do |value|
#              #make sure its not empty
#              #value = 0 if value.is_a?(String) && value.blank?
#              # cast value into Money
#              value = Money.new(value) unless value.is_a?(Money)
#              write_attribute(fieldname, value.amount)
#              instance_variable_set("@#{fieldname}", value.freeze)
#            end
#          end
#        end
#
#        # Check if a given field is declared as money
#        def self.money?(fieldname)
#          self.money_fields.include?(fieldname) if self.respond_to?(:money_fields)
#        end
#
#      end#eval
#    end#included

#  end #Fields
#end#KingFormat