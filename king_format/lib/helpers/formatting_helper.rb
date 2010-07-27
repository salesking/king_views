module KingFormat
  # General Helper Functions to auto-format an output
  module FormattingHelper

    include ActionView::Helpers::NumberHelper
    # Get a nice formatted string for an object attribute value.
    #
    # ==== Parameters
    # object<Object>:: The object on which the given fieldname will be called => object.send(fieldname), to get the value
    # fieldname<String>:: Name of the field for which to get a value
    # value<String|Symbol|Date|FalseClass|TrueClass|...>::The value to display. When set this will be used instead of asking the object for its value.
    # See types for more
    # opts<Hash{Symbol=>String}>:: Options
    #  
    # ==== Options opts
    #  currency<Hash{Symbol=>String}>:: Currency settings to format string as a money like found in rails I18n. or see rails number_helper.
    #  When set, object AND fieldname must be set and the field must be in money_fields (via: has_money_fields)
    #  Alternatively you can call the method with currency options set which will also lead to money rendering
    #  format -> defaults to :html returned html string has escaped html entities
    #
    #
    # ==== AutoDetect Types
    # A value is formatted according to its type which we try to detect.
    #   <Symbol>:: assume a value from acts_as_enum
    #   <DateTime|Time|Date>::I18n.localize -> l(value)
    #   <TrueClass|FalseClass>:: translate to yes / no
    #   <MoneyField String>:: coming from a has_percent_fields, formats the number with number_to_percentage_auto_precision
    #   <PercentField String>:: comming from has_money_fields I18n formats as money string
    #
    def formatted_value(object, fieldname, value=nil, opts={})
      # If no value given, call fieldname on object to get the current value
      value ||= if object.respond_to?(fieldname)
        #return the content(a pointer it) or an empty string.
        object.send(fieldname) || ''
      else #field is not available in object
        nil
      end

      # Autodetect value type
      if value.nil?
        nil
      elsif value.is_a?(Symbol) # enum value from acts_as_enum
        translated_enum_value(object, fieldname, value)
      elsif value.is_a?(DateTime) || value.is_a?(Time)  #|| value.is_a?(Date)
        I18n.localize(value)
      elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
        value ? t(:'sk.yes') : t(:'sk.no')
      elsif (object.class.is_percent_field?(fieldname) rescue nil)
        (value && !value.blank?) ? number_to_percentage_auto_precision(value) : ''
      elsif (object.class.is_money_field?(fieldname) rescue nil) || opts[:currency] # field is defined as money field OR currency options are passed in
        # get currency from opts or company or fallback into i18n
        settings = opts[:currency] || default_currency_format
        # display with a rounding of 2 despite precision defined in company settings .. quick and dirty
        #  .. other option would be to define such in has_money_fields via method missing or so 
        if fieldname.to_s[/_round$/] # invoice.price_total_round
          settings[:precision] = 2
        end
        number_to_currency(value, settings.merge({:locale => I18n.locale}))
      elsif ( value.is_a?(Date) || (object.class.is_date_field?(fieldname) rescue nil) || opts[:date] ) #field is defined as date field OR date options are passed in
        return value if value.blank? # blank value can occur when a is_date_field is empty
        # get date from opts or company or fallback into i18n
        format = opts[:date] || default_date_format
        format.blank? ? ::I18n.localize(value) : value.strftime(format)
      else
       if opts[:format] == :html
          # Change HTML tag characters to entities
          ERB::Util.html_escape(value)
        else
          #Copy->val.dup because obj.send(fieldname) returns pointer, and subsequent calls
          #may then alter the real value f.ex val = formatted_value(yx) + "info text"
          value.blank? ? value : value.dup
        end
      end
    end #formatted

    # Returns the default date formatting.
    # The returned string is passed to strftime(format)
    # TODO: NoGo since one cannot expect a company to be present
    # === Returns
    # <String>:: strftime compatible string
    def default_date_format
      Company.current.date_format rescue nil
    end

    # Returns the default currency formatting from Company.current => Thread var
    # TODO: NoGo since one cannot expect a company to be present
    # The returned hash is used in rails number_to_currency helper
    # === Returns
    # <Hash>:: number_to_currency compatible options hash
    def default_currency_format
      Company.current.currency rescue {}
    end

    # Formats a number to the visible decimal places if there are more than the
    # given prescision
    # 
    # ====Parameter
    # number<Float>:: The number to format
    # precs<Integer>:: The precision to which to round the number
    # ==== Return
    # nil if number is nil
    # <String> with formatted number
    def money_auto_precision(number, precs)
      return unless number
      decimals = number.to_s[/\.(.*)\z/, 1] #15.487 => 487
      precision = (decimals && decimals.length > precs) ? decimals.length : precs
      rounded_number = (Float(number) * (10 ** precision)).round.to_f / 10 ** precision
      "%01.#{precision}f" % rounded_number
    end

  end # FormattingHelper
end # KingFormat