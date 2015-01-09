module KingFormat
  # General Helper Functions to auto-format an output
  module FormattingHelper

    include ActionView::Helpers::NumberHelper

    # Get a nice formatted string for an object attribute value.
    #
    # ====
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
    #  :currency<Hash{Symbol=>String}>:: Currency settings to format string as
    #  money like found in rails I18n(see rails number_helper)
    #  Leads to money rendering when set.
    #  :format<Symbol>:: when set to :html returns string with escaped html entities
    #
    # ==== AutoDetect Types
    # A value is formatted according to its type which we try to detect.
    #   <Symbol>:: assume a value from acts_as_enum
    #   <DateTime|Time|Date>::I18n.localize -> l(value)
    #   Used if value is a Date class, field is declared in has_date_fields, or
    #   opts[:date] is set
    #   <TrueClass|FalseClass>:: translates to yes/no in sk namespace t(:'sk.yes')
    #   <PercentField|String>:: coming from a has_percent_fields, formats the
    #   number with number_to_percentage_auto_precision
    #   <MoneyField|String>:: Used if opts[:currency] is set OR field is defined
    #   via has_money_fields.
    #   Formats the value as money string using different formatting fallbacks:
    #   1. options passed in via :currency=>{..}
    #   2. if object and val are present AND the object has a method called:
    #   "fieldname"_format_opts => price_format_opts
    #   It's return value(Hash{Rails currency format opts} is used.
    #   This should be used if you have a default format for all money vals, but
    #   one differs eg. in precision
    #   3. @default_currency_format
    #   4. I18n actually resided in rails
    #   Whatever you use be aware to always pass all formatting options since rails
    #   merges unavailable keys with i18n defaults
    def strfval( object, fld, val=nil, opts={} )
      # If no value given, call fld on object to get the current value
      #return the content(a pointer) or an empty string OR  nil of field is not available
      val ||= object.respond_to?(fld) ? ( object.send(fld) || '') : nil
      # Autodetect value type
      if val.nil?
        nil
      elsif val.is_a?(Symbol) # enum value from acts_as_enum
        translated_enum_value(object, fld, val)
      elsif val.is_a?(DateTime) || val.is_a?(Time)
        I18n.localize(val)
      elsif val.is_a?(TrueClass) || val.is_a?(FalseClass)
        val ? t(:'sk.yes') : t(:'sk.no')
      elsif (object.class.is_percent_field?(fld) rescue nil)
        (val && !val.blank?) ? number_to_percentage_auto_precision(val) : ''
      elsif (object.class.is_money_field?(fld) rescue nil) || opts[:currency]
        format_method = "#{fld}_format_opts".to_sym
        # check if the object has a custom money format method => price_total_format_opts
        fopts = object && object.respond_to?(format_method) ? object.send(format_method) : opts[:currency]
        strfmoney(val, fopts, object)
      elsif ( val.is_a?(Date) || (object.class.is_date_field?(fld) rescue nil) || opts[:date] )
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

    # Formats the given value using rails number_to_currency. Get's currency
    # from options hash or @default_currency_format or i18n as fallback
    # === Params
    # val<Number>:: the number to format
    # opts<Hash{Symbol=>String}>:: Rails compatible currency formatting options,
    # when nil searches default format, last exit is rails i18n
    def strfmoney(val, opts=nil, object = nil)
      settings = opts || default_currency_format || {}
      number_to_currency(val, settings.merge({:locale => I18n.locale}).to_hash)
    end

    # Deprecated, to be dropped
    def formatted_value(object, fld, val=nil, opts={})
      ::ActiveSupport::Deprecation.warn('"formatted_value" has been deprecated, use the "strfval" instead. Func will be removed within next releases', caller)
      strfval(object, fld, val, opts)
    end
    # Formatting as Percentage, but use precision only if needed.
    # Examples:
    #   number_to_percentage_auto_precision(19)
    #   => 19%
    #   number_to_percentage_auto_precision(7.5)
    #   => 7,5%
    def number_to_percentage_auto_precision(number)
      return nil unless number
      sep =  I18n.t(:'number.format.separator')
      number_to_percentage(number,{ :separator=>sep,
                                    :precision => 4,
                                    :strip_insignificant_zeros=>true } )
    end

    # Translate the value of an enum field, as defined by act_as_enum
    # Example:
    #   client.sending_method = :fax
    #   translated_enum_value(client, :sending_method)
    #   => "activerecord.attributes.client.enum.sending_method.fax"
    def translated_enum_value(object_or_class, fieldname, value = nil)
      if object_or_class.is_a?(Class)
        klass = object_or_class
      else
        klass = object_or_class.class
        # If no value given, get the current value
        value ||= object_or_class.send(fieldname)
      end
      # Don't translate blank value
      return nil if value.blank?
      #return the translation
      defaults = klass.lookup_ancestors.map do |_klass|
        :"#{klass.i18n_scope}.attributes.#{_klass.model_name.i18n_key}.enum.#{fieldname.to_s}.#{value.to_s}"
      end

      I18n.translate(default: defaults)
    end

    # Returns the default date formatting, as string '%d.%m.%Y'
    # The returned string is passed to strftime(format)
    # Override this function or set the thread var somehere in your including
    # class
    # => scope when used in view is ActionView::Base
    # === Returns
    # <String>:: strftime compatible string
    def default_date_format
      Thread.current[:default_date_format]
    end

    # Returns the default currency formatting, in I18n style
    # The returned hash is used in rails number_to_currency helper.
    # Override this function or set the thread var somehere in your including
    # class
    # => scope when used in view is ActionView::Base
    #
    # === Returns
    # <Hash>:: number_to_currency compatible options hash
    def default_currency_format
      Thread.current[:default_currency_format]
    end

    # Formats a number to the visible decimal places. If there are more decimal
    # places than the given prescision those are used.
    #
    # === Examples
    #   auto_precision(1.2340, 2)
    #   => "1.234"
    #
    #   auto_precision(1.234500)
    #   => "1.2345"
    #
    #   auto_precision(1.2345, 5)
    #   => "1.23450"
    #
    # ====Parameter
    # number<Float>:: The number to format
    # precs<Integer>:: The precision to which to round the number
    # ==== Return
    # nil if number is nil
    # <Float> with formatted number
    def auto_precision(number, precs=2)
      return unless number
      decimals = number.to_s[/\.(.*)\z/, 1] #15.487 => 487
      precision = (decimals && decimals.length > precs) ? decimals.length : precs
      rounded_number = (Float(number) * (10 ** precision)).round.to_f / 10 ** precision
      "%01.#{precision}f" % rounded_number
    end

  end # FormattingHelper
end # KingFormat
