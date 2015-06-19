module KingFormat
  module DateFields

    def self.included(base)
      if ActiveSupport::VERSION::MAJOR == 3 && ActiveSupport::VERSION::MINOR > 0
        base.class_attribute :date_fields
      else
        base.send :class_inheritable_accessor, :date_fields
      end
      base.date_fields = []
      base.extend(ClassMethods)
    end

    module ClassMethods
      #  Defines the fields returned by self.date_fields.
      # ===== Parameter
      # fieldnames<Array[Symbol]>:: fieldnames/instance method names as symbols
      # ==== Example
      # class Invoice
      #   has_date_fields :total, :amout, :calculated_tax
      #
      def has_date_fields(*fieldnames)
        self.date_fields = fieldnames
        include InstanceMethods
      end

      # Check if a given field is declared as date field
      # ==== Parameter
      # fieldname<String>:: The fieldname to check. Is be casted into a symbol.
      def is_date_field?(fieldname)
        self.date_fields.include?(fieldname.to_sym)
      end

    end #ClassMethods

    module InstanceMethods
      # Check if a given field is declared as date field
      # ==== Parameter
      # fieldname<String>:: The fieldname to check. Is be casted into a symbol.
      def is_date_field?(fieldname)
        self.class.date_fields.include?(fieldname.to_sym)
      end
    end

  end #Fields
end#KingFormat