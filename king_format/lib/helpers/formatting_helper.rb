module KingFormat
  # General Helper Functions to auto-format an output
  module FormattingHelper

    include ActionView::Helpers::NumberHelper
    # Get a nice formatted string for an object attribute value.
    #
    # ==== Parameters
    # object<Object>:: The object on which the given fld name will be called
    # => object.send(fld), to get the value
    # fld<String>:: Name of the field for which to get a value
    # val<String|Symbol|Date|FalseClass|TrueClass|...>::The value to display.
    # When set this will be used instead of asking the object for its value.
    # See types for more
    # opts<Hash{Symbol=>String}>:: Options
    #  
    # ==== Options opts
    #  currency<Hash{Symbol=>String}>:: Currency settings to format string as a money like found in rails I18n.
    #  or see rails number_helper.
    #  When set, object AND fld must be set and the field must be in money_fields (via: has_money_fields)
    #  Alternatively you can call the method with currency options set which will also lead to money rendering
    #  format -> defaults to :html returned html string has escaped html entities
    #
    # ==== AutoDetect Types
    # A value is formatted according to its type which we try to detect.
    #   <Symbol>:: assume a value from acts_as_enum
    #   <DateTime|Time|Date>::I18n.localize -> l(value)
    #   <TrueClass|FalseClass>:: translate to yes / no
    #   <MoneyField String>:: coming from a has_percent_fields, formats the number with number_to_percentage_auto_precision
    #   <PercentField String>:: comming from has_money_fields I18n formats as money string
    #
    def strfval (object, fld, val=nil, opts={})
      # If no value given, call fld on object to get the current value
      #return the content(a pointer) or an empty string OR  nil of field is not available
      val ||= object.respond_to?(fld) ? ( object.send(fld) || '') : nil
      # Autodetect value type
      if val.nil?
        nil
      elsif val.is_a?(Symbol) # enum value from acts_as_enum
        translated_enum_value(object, fld, val)
      elsif val.is_a?(DateTime) || val.is_a?(Time)  #|| val.is_a?(Date)
        I18n.localize(val)
      elsif val.is_a?(TrueClass) || val.is_a?(FalseClass)
        val ? t(:'sk.yes') : t(:'sk.no')
      elsif (object.class.is_percent_field?(fld) rescue nil)
        (val && !val.blank?) ? number_to_percentage_auto_precision(val) : ''
      elsif (object.class.is_money_field?(fld) rescue nil) || opts[:currency]
        # field is defined as money field OR currency options are passed in
        # get currency from opts or company or fallback into i18n
        settings = opts[:currency] || default_currency_format
        number_to_currency(val, settings.merge({:locale => I18n.locale}))
      elsif ( val.is_a?(Date) || (object.class.is_date_field?(fld) rescue nil) || opts[:date] )
        # field is defined as date field OR date options are passed in
        return val if val.blank? # blank value can occur when a is_date_field is empty
        # get date from opts or default or fallback into i18n
        format = opts[:date] || default_date_format
        format.blank? ? ::I18n.localize(val) : val.strftime(format)
      else
       if opts[:format] == :html
          # Change HTML tag characters to entities
          html_escape(val) # from Haml::Helpers
        else
          #Copy->val.dup because obj.send(fld) returns pointer, and subsequent calls
          #may then alter the real value f.ex val = strfval(yx) + "info text"
          # rescue for Fixnums are not dup -able, cause its a call by value
          val.blank? ? val : ( val.dup rescue val )
        end
      end
    end #strfval

    # Deprecated, to be dropped
    def formatted_value(object, fld, val=nil, opts={})
      ::ActiveSupport::Deprecation.warn('"formatted_value" has been deprecated, use the "strfval" instead. Func will be removed within next releases', caller)
      strfval(object, fld, val, opts)
    end

    # Returns the default date formatting.
    # The returned string is passed to strftime(format)
    # === Returns
    # <String>:: strftime compatible string
    def default_date_format
      @default_date_format || {}
    end
   
    # Returns the default currency formatting
    # The returned hash is used in rails number_to_currency helper
    # === Returns
    # <Hash>:: number_to_currency compatible options hash
    def default_currency_format
      @default_currency_format || {}
    end
    
    # Formats a number to the visible decimal places. If there are more decimal 
    # places than the given prescision those are used.
    #
    # === Examples
    #   money_auto_precision(1.2340, 2)
    #   => "1.234"
    #   
    #   money_auto_precision(1.234500)
    #   => "1.2345"
    #   
    #   money_auto_precision(1.2345, 5)
    #   => "1.23450"
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