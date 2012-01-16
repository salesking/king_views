module KingList
  module Builder
    class Table

      attr_accessor :mode, :current_record, :current_column_number, :number_of_columns, :sorting

      def initialize(template, collection, &block)
        @template = template
        @collection = collection
      end

      def start_row(data)
        self.current_column_number = 0
        self.current_record = data
      end

      # Build a column for a table
      #
      # ==== Parameter
      # field_name<Symbol>:: Name of the object attribute (db column) to show in this column
      # options<Hash{Hash, Symbol=>String}>:: A bunch of options to customize the th, td or content of the column
      #
      # ==== Options hash:
      #   :object   => The record to use. If not set, the current_object is used
      #   :value    => cell content (if not set, it will be determined by calling field_name on object/current_record) => @client.name
      #   :link     => if set, the value is wrapped in a link_to with the given link (if TRUE, the current object is used)
      #   :row_link => if set, the value is wrapped in a link_to with the given link (if TRUE, the current object is used)
      #   :title    => text for column title. If not set, the title is created automaticaly
      #   :sort_fields => optional fields for order_by (if the column field does not exist in the database)
      #   :sorting  => false to prevent sorting on this column
      #   :th_options{Symbol=>String}:: options for the <th>
      #       :class:: the class to set on the th
      #   :td_options{Symbol=>String}:: options for the <td>
      #     :class:: the class to set on the th
      #   :class    => class as Symbol or String used on TH and TD used f.ex. for alignment.
      def column(field_name, options = {})
        options = options.deep_clone # for not changing outer variable
        th_options = options[:th_options] || {}
        td_options = options[:td_options] || {}

        # Use given object from options (or current_record as default)
        object = options.has_key?(:object) ? options.delete(:object) : current_record

        # :class given so add to TH and TD f.ex cell alignment :class=>'rgt'
        if css_class = options.delete(:class)
          (th_options[:class] ||= '') << " #{css_class}"
          (td_options[:class] ||= '') << " #{css_class}"
        end

        self.current_column_number += 1

        case mode
          when :counter
            self.number_of_columns ||= 0
            self.number_of_columns += 1
            nil

          when :header
            # Take option or translate column title
            title_text = options[:title] || object.class.human_attribute_name(field_name.to_s)

            # whole table has sorting enabled and current column has NOT :sorting=>false
            # => put sorting link into header
            if sorting && (options.delete(:sorting) != false)
              # Use given sort_fields or try to detect them automatic
              sort_fields = options.delete(:sort_fields) || object.class.table_name + '.' + field_name.to_s
              # Convert to comma separated string if it is an array
              sort_fields = sort_fields.join(',') if sort_fields.is_a?(Array)
              # Swap ASC/DESC on every click of the same column title
              sort = (@template.params[:sort] == "ASC") ? 'DESC' : 'ASC'
              # Now build the title
              title = @template.link_to(title_text, @template.change_params(:sort_by => sort_fields, :sort => sort))
              # if current sorting use class for css up/down image
              if @template.params[:sort_by] == sort_fields
                (th_options[:class] ||= '') << ( sort=='DESC' ? ' sortup' : ' sortdown')
              end
            else
              # otherwise just plain text (no sorting link)
              title = title_text
            end
            # mark the first and last columns with css classes
            if self.current_column_number == 1
              (th_options[:class] ||= '') << ' first'
            elsif self.current_column_number == self.number_of_columns
              (th_options[:class] ||= '') << ' last'
            end
           @template.capture_haml do
            @template.haml_tag(:th, title.to_s, th_options)
          end

          when :content
            # Use given value (or formatted value as default)
            value = options.delete(:value) || @template.strfval(object, field_name, value)

            # If link option is set, then link to this
            # === Example            #
            # :link => true : uses current object show link
            # :link => nil or blank no linking
            if link = options.delete(:link)
              # link to current_oject if true given
              link = object if link == true
              # link and linked text is present else leave col text empty
              value = (!value.blank? && !link.blank?) ? @template.link_to(value, link) : ''
            end

            # If row_link option is set, then link to the current object
            if row_link = options.delete(:row_link)
              row_link = object if row_link == true
              value = @template.link_to(value, row_link) unless value.blank?

              # Set a css class for the <td>, so it can be found via JavaScript
              # and an onclick-event can be installed (TODO)
              td_options.merge!(:class => 'row_link')
            end
          @template.capture_haml do
            @template.haml_tag(:td, value.to_s, td_options)
          end
        end # case mode
      end

      #build a table column which holds action links (edit/del/show/..) for each record
      #is used for table listings ex. on index pages
      #get a block containing multiple #action_
      # ===Example haml
      # - t.action_column do
      #   = action_icon :edit, edit_path(person)
      #   = action_icon :delete, destroy_path(person)
      def action_column(options={}, &block)
        self.current_column_number += 1

        case mode
          when :counter
            self.number_of_columns ||= 0
            self.number_of_columns += 1
            nil
          when :header
            options = { :align => :left }
            if self.current_column_number == 1
              options[:class] = 'first'
            elsif self.current_column_number == self.number_of_columns
              options[:class] = 'last'
            end

            @template.haml_tag :th, options do
              @template.haml_concat I18n.t(:'link.actions')
            end
          when :content
            td_options = options[:td_options] || {}
            td_options[:class] = td_options[:class].to_a || []
            td_options[:class] << 'actions'
            @template.haml_tag :td, td_options do
              @template.haml_tag :ul, :class => 'actions' do
                @template.haml_concat @template.capture_haml(&block)
              end
            end
        end
      end

    end #TableBuilder
  end # module
end # module
