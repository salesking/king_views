module KingList
  module Builder
    class Show

      def initialize(object_name, object, template)
        @object_name = object_name
        @object = object
        @template = template
      end

      #
      # ==== Parameter
      #   field_name<Symbol>:: The name of the field for the current object
      #   options<Hash{:Symbol=>String}>:: A bunch of options to customize the output
      #
      # ==== Options hash:
      #   :object => record. If not set the current_current is used
      #   :value => cell content (if not set, it will be determined by object.field_name)
      #   :link => if set, the value is placed in a link_to
      #   :caption => text for dt-tag. If not set, the title is created automaticaly
      #
      # === Example haml
      #  = f.show :created_at
      #  = f.show :caption => 'Calculated', :value => 39.80
      #
      # valid html options will be applied to both dt and dd
      #   options[:class] =>will be applied to dt and dd
      #
      # TODO:
      # rename :caption to :title .. if it does not conflict
      def show(field_name, options={})
        if field_name.is_a?(Hash) && options.empty? # Short call without field_name
          options = field_name
          field_name = nil

          # Value and caption are needed
          raise ArgumentError unless options.has_key?(:caption)
          raise ArgumentError unless options.has_key?(:value)
        end

        # Use given object or current_record as default
        if options.has_key?(:object)
          object = options.delete(:object)
        else
          object = @object
        end

        dt_options = options.delete(:dt_options) if options.has_key?(:dt_options)
        dd_options = options.delete(:dd_options) if options.has_key?(:dd_options)

        # Use given caption or translate column title
        caption = options.delete(:caption) || object.class.human_attribute_name(field_name.to_s)

        # Use given value or take formatted value as default
        value = options.delete(:value) || @template.strfval(object, field_name)  || '&nbsp;'

        # if link option is set, then link to this object
        if link = options.delete(:link)
          value = @template.link_to(value, link)
        end

        # Against HTML validity warnings
        caption = '&nbsp;' if caption.blank?
        value = '&nbsp;' if value.blank?

        @template.capture_haml do
          @template.haml_tag :dt, caption, dt_options || options
          @template.haml_tag :dd, value, dd_options || options
        end
      end

    end #class
  end # module
end # module
