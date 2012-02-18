module KingList
  module Builder
    class Table

      attr_accessor :mode, :current_record, :sorting

      def initialize(template, collection, &block)
        @template = template
        @collection = collection
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
      def column(field_name, opts = {})
        opts = opts.deep_clone # for not changing outer variable
        th_options = opts[:th_options] || {}
        td_options = opts[:td_options] || {}

        # Use given object from options (or current_record as default)
        object = opts.has_key?(:object) ? opts.delete(:object) : current_record

        # :class given so add to TH and TD f.ex cell alignment :class=>'rgt'
        if css_class = opts.delete(:class)
          (th_options[:class] ||= '') << " #{css_class}"
          (td_options[:class] ||= '') << " #{css_class}"
        end

        case mode
          when :header
            # Take option or translate column title
            title_text = opts[:title] || object.class.human_attribute_name(field_name.to_s)
            # whole table has sorting enabled and current column has NOT :sorting=>false
            # => put sorting link into header
            if sorting && (opts.delete(:sorting) != false)
              # Use given sort_fields or try to detect them automatic
              sort_fields = opts.delete(:sort_fields) || object.class.table_name + '.' + field_name.to_s
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
            "<th #{ to_attr(th_options) }>#{title.to_s}</th>" #.html_safe

          when :content
            # Use given value (or formatted value as default)
            value = opts.delete(:value) || @template.strfval(object, field_name, value)
            # If link option is set, then link to this
            # === Example
            # :link => true : uses current object show link
            # :link => nil or blank no linking
            if link = opts.delete(:link)
              # link to current_object if true given
              link = object if link == true
              # link and linked text is present else leave col text empty
              value = (!value.blank? && !link.blank?) ? @template.link_to(value, link) : ''
            end
            "<td #{ to_attr(td_options) }>#{value.to_s}</td>"
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
        case mode
          when :header
            @template.concat("<th>#{I18n.t(:'link.actions')}</th>")
          when :content
            td_options = options[:td_options] || {}
            td_options[:class] = [td_options[:class]].flatten || []
            td_options[:class] << 'actions'
            @template.concat("<td #{ to_attr(td_options) }><ul class='actions'>")
            @template.concat( @template.capture_haml(&block) )
            #@template.haml_concat @template.capture_haml(&block) #yield
            @template.concat("</ul></td>")
        end
      end

      # == Param
      # opts<Hash{Symbol=>String}}>:. options used for html attributes
      def to_attr(opts)
        opts.collect{|k,v| "#{k}='#{v}'" }.join(' ')
      end

    end #TableBuilder
  end # module
end # module
