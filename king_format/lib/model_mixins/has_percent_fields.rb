module KingFormat
  #TODO:
  # split money / percent
  # kick numeric? only used in list helper
  module PercentFields

    def self.included(base)
      if ActiveSupport::VERSION::MAJOR == 3 && ActiveSupport::VERSION::MINOR > 0
        base.class_attribute :percent_fields
      else
        base.send :class_inheritable_accessor, :percent_fields
      end
      base.percent_fields = []
      base.extend(ClassMethods)
    end


    module ClassMethods
      #  Defines the fields returned by self.percent_fields.
      # ===== Parameter
      # fieldnames<Array[Symbol]>:: fieldnames/instance method names as symbols
      # ==== Example
      # class Invoice
      #   has_percent_fields :total, :amout, :calculated_tax
      #
      def has_percent_fields(*fieldnames)
        self.percent_fields = fieldnames
        #include InstanceMethods
      end

      # Check if a given field is declared as percent
      def is_percent_field?(fieldname)
        self.percent_fields.include?(fieldname.to_sym)
      end
    end

  end #Fields
end#KingFormat