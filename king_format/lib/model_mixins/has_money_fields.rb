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
        self.class.is_money_field?(fieldname)
      end
    end
    
  end #Fields
end#KingFormat
