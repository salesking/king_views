module KingForm
  module Builder
    module FormFields
      ##########################################################################
      # Convinience Methods for simpler template tags
      ##########################################################################

      # Generate input tag with title for text editing
      # ==== Example
      # 1) text :name
      # 2) text :name, :title => 'Your Name:', :value => @the_name, :size=>30, .maxlength=>35
      #
      # ==== Parameter
      # fieldname<Symbol, String>:: The field name of the current object
      # options<Hash{Symbol=>Sting}:: Options to customize the output
      # ==== Options
      # :title => the title for the field
      # :maxlength => the maxlength for the field, defaults to the columns limit
      # :size => the size for the field, defaults to 25 or the columns minimun length
      # :value => the value if it differs from th the fields value
      def text(fieldname, options={})
        title = options.delete(:title) || build_title(fieldname)

        if current_object.is_a?(ActiveRecord::Base)
          if column = current_object.class.columns_hash[fieldname.to_s]
            # Limit the length of input to the column capacity
            options[:maxlength] ||= column.limit
            # Limit the displayed width to 25 (or to the column capacity, if smaller)
            options[:size] ||= [25, column.limit].min
          end
          tag_wrapper title, text_field(fieldname, options)
        else
          value = options.delete(:value) || current_value(fieldname)
          tag_wrapper title, text_field_tag(fieldname, value, options)
        end
      end

      # Generate hidden field tag
      # ==== Example
      # Default usage:
      #  - dl_form_for @email do |e|
      #    = e.hidden :some_token
      #  => <input type='hidden' value='value of email.some_token' name=email[some_token]..>
      # Custom fieldname passed in as string:
      #   e.hidden 'email[attachment_ids][]', value =>' '
      #  => <input type='hidden' value=' ' name='email[attachment_ids][]'..>
      # ==== Parameter
      # fieldname<String>:: The fieldname and the value for it (on current object)
      # fieldname<Symbol>:: If there is an AR:Base Object present the fieldname and
      #                     the options are passed to hidden_field
      # options<Hash>:: default options for hidden_field and hidden_fiel_tag plus:
      #                 :value => the value to insert
      def hidden(fieldname, options={})
        if current_object.is_a?(ActiveRecord::Base) && fieldname.is_a?(Symbol)
          hidden_field(fieldname, options)
        else # not an AR object, or a custom field
          value = options.delete(:value) || current_value(fieldname)
          hidden_field_tag(fieldname, value, options)
        end
      end

      # Generate password input tag with title
      #
      # ==== Example
      #  password :password
      #  password(:pasword, :title => 'What is your password?', :value => @the_password)
      def password(fieldname, options={})
        title = options.delete(:title) || build_title(fieldname)

        if current_object.is_a?(ActiveRecord::Base)
          tag_wrapper title, password_field(fieldname, options)
        else
          value = options.delete(:value) || current_value(fieldname)
          tag_wrapper title, password_field_tag(fieldname, value, options)
        end
      end

      # Generate textarea input tag with title for multiple line text editing
      #
      # ==== Parameters
      # fieldname<Symbol>:: the name of the textarea
      # options<Hash>:: options which will be passed on to textarea helper
      # html_options<Hash>:: options which will be passed on to the wrapping element
      #
      # ==== Example
      # 1) memo(:notes)
      # 2) memo(:comment, :title => 'Comment', :value => @the_comment)
      def memo(fieldname, options={}, html_options={})
        title = options.delete(:title) || build_title(fieldname)

        if current_object.is_a?(ActiveRecord::Base)
          tag_wrapper title, text_area(fieldname, options), html_options
        else
          value = options.delete(:value) || current_value(fieldname)
          tag_wrapper title, text_area_tag(fieldname, value, options),html_options
        end
      end

      # Generate date select tags (day/month/year) with title
      #
      # ==== Example
      #   date :birthday, :title => 'Geburtstag'
      def date(fieldname, options={}, html_options={})
        title = options.delete(:title) || build_title(fieldname)
        options[:include_blank] ||= true
        css_class = options[:class] || ''
        tag_wrapper title, date_select(fieldname, options, html_options), :dd => { :class => css_class + ' dates' }, :dt => {:class => css_class}
      end

      # Generate datetime select tags (day/month/year and hour/minute) with title
      #
      # Usage:
      #   datetime :starts_at, :title => 'Beginnt um'
      def datetime(fieldname, options={})
        title = options.delete(:title) || build_title(fieldname)
        options[:include_blank] ||= true

        tag_wrapper title, datetime_select(fieldname, options), :dd => { :class => 'dates' }
      end

      # Generate select tag with title for text editing
      #
      # === Example haml
      # - dl_fields_for @user do |u|
      #   = u.selection :gender
      #   = u.selection :currency, { :choices => %w(EUR USW JPY) }, { :class => 'my-css-class' }
      #   = u.selection :status, :title => 'Invoice status', :choices => %w(draft published)
      #   = u.selection 'user[custom_field]', :title => 'Invoice status', :choices => %w(draft published)
      #
      # - dl_fields_for 'custom_obj' do |c|
      #   = c.selection :project_id, :choices => @projects, :title => 'Projects'
      #   = c.selection 'custom_obj[pills]', :choices => @red_pills, :title => "Choose your Pill", :info=>'Help text'
      #
      # ==== Parameter
      #  fieldname<String, Symbol>:: The name of the field. Used to build the translated title, find enum values.
      #  When passing a string, the field is not looked up on the current AR Object,
      #  use it to give it some custom name, which does not exist on the object
      #  options<Hash{Symbol=>String}>::options to configure the select behaviour
      #  html_options<Hash{Symbol=>String}>::options passed to the html options of the select
      #
      # ==== Options (options)
      #   :title<String>:: Field title, used in dt or label tag
      #   :choices<(Array[Strings],Array[Array[String,String]],Hash)>:: The choice for the select.
      #   :value<String>::The value of the select which will be used as selected unless selected is given. Defaults to the current objects.fieldname => value
      #   :selected<String>:: The selected value is taken from value
      #   :include_blank<Boolean>:: true/false (default is true)
      # ==== Options (html_options)
      # see select and select_tag in rails
      def selection(fieldname, options={}, html_options={})
        title   = options.delete(:title) || build_title(fieldname)
        choices = options.delete(:choices) || enum_values(fieldname) || []
        value   = options.delete(:value) || current_value(fieldname)
        options[:include_blank] = true unless options.has_key?(:include_blank)
        options[:selected] ||= value.is_a?(Array) ? value : value.to_s

        # Got an AR object so full automatic contruction should work
        if current_object.is_a?(ActiveRecord::Base) && fieldname.is_a?(Symbol)
          # try to sort by key f.ex. when transl. enum_fields
          choices = choices.to_a.sort_by{|k|k} if choices.is_a?(Hash)
          tag_wrapper title, select(fieldname, choices, options, html_options)
        else # a custom object
           # got an array of sub-arrays[[key,val]] or an array of strings(key==val)
          if choices.is_a?(Array) && (choices.first.is_a?(Array) || choices.first.is_a?(String))
            # select_tag does not support :include_blank, so do it the manual way
            choices.insert(0, '') if options.delete(:include_blank)
            option_tags = @template.options_for_select(choices, options.delete(:selected))
            # convert name to string before select_tag due to auto created info+id when it recieves a symbol
            # This prevents one from passing an empty :info=>'', when using a custom object with symbol syntax
            fld_name = fieldname.is_a?(String) ? fieldname : "#{@object_name}[#{fieldname}]"
            tag_wrapper title, select_tag(fld_name, option_tags, options.merge(html_options))
          elsif choices.is_a?(Hash)
            # select_tag does not support :include_blank, so do it the manual way
            choices[nil] = '' if options.delete(:include_blank)
            option_tags = @template.options_for_select(choices, options.delete(:selected))
            tag_wrapper title, select_tag(fieldname, option_tags, options.merge(html_options))
          else #Choices of AR Objects, value is the Obj id, shown value is the object.to_s
#            choices = choices.sort_by{|k, v|v.to_s} # sorty by object as string
            choices = choices.sort_by{|k| k.to_s} # sorty by object as string
            tag_wrapper title, collection_select(fieldname, choices, :id, :to_s, options, html_options)
          end
        end
      end

      # Generate select tag with options groups for a multiple collections of objects
      #
      # by default the :id of each object is taken as value and the :to_s method is
      # used for options text.
      #
      # if an object_group is empty it will be omitted
      #
      # === Example haml
      #
      # f.selection_group :id, :labels => %w(defaults, own), :choices =>[@objects_1, @objects_2], :title =>'my custom title'
      #
      # f.selection_group :id,  :title => 'Template',
      #                   :choices => [ @pdf_templates, @pdf_default_templates],
      #                   :labels=>[ 'User Templates', 'Default Templates']
      #
      #
      # Available options keys:
      #   :title
      #   :choices  => array of object groups, which are used for each option grouped,
      #                in their order of usage
      #   :labels   => the label for each option group, in order of usage
      #   :selected
      def selection_group(fieldname, options={})
        labels  =  options.delete(:labels)
        title   = options.delete(:title) || build_title(fieldname)
        choices = options.delete(:choices)
        selected = options.delete(:selected)

        # TODO: Uses option_groups_from_collection_for_select here!
        select_options = ''
        choices.each_with_index do |v,k| #build optiongroup for each given object group
          unless v.empty?
            select_options << "<optgroup label='#{labels[k]}'>"
            select_options << @template.options_from_collection_for_select(v, :id, :to_s, selected) #still hardcoded
            select_options << "</optgroup>"
          end
        end
        tag_wrapper title, select_tag(fieldname, select_options, options)
      end

      def time_zone_selection(fieldname, options = {}, html_options = {})
        tag_wrapper fieldname, time_zone_select("#{fieldname}", ActiveSupport::TimeZone.all, options, html_options)
      end

      def checkbox(fieldname, options={})
        title = options.delete(:title) || build_title(fieldname)
        if current_object.is_a?(ActiveRecord::Base) && fieldname.is_a?(Symbol)
          tag_wrapper title, check_box(fieldname, options)
        else # not an AR object, or a custom field
#          value =  # defaults to 1
          tag_wrapper title, check_box_tag(fieldname, options.delete(:value), options.delete(:checked), options)
        end
      end

      def radio(fieldname, tag_value, options={})
        title = options.delete(:title) || build_title(fieldname)
        tag_wrapper title, radio_button(fieldname, tag_value, options)
      end

      #file upload field
      def file(fieldname, options={})
        title = options.delete(:title) || build_title(fieldname)

        if current_object.is_a?(ActiveRecord::Base) && fieldname.is_a?(Symbol)
          tag_wrapper title, file_field(fieldname, options)
        else
          value = options.delete(:value) || current_value(fieldname)
          tag_wrapper title, file_field_tag(fieldname, options)
        end
      end

      # Display a fields value as static text
      #
      # === Example haml
      #  = f.static_text :created_at
      #  = f.static_text :updated_at, :title => 'Last change'
      #  = f.static_text :title => 'Dummy text', :value => 'I´m a loonly dumb static text .. get me outa here!'
      def static_text(fieldname, options = {})
        if fieldname.is_a?(Hash) && options.empty? # Short call without fieldname
          options = fieldname
          fieldname = nil
          # Value and title are needed
          raise ArgumentError unless options[:title]
          raise ArgumentError unless options[:value]
        end

        title = options.delete(:title) || build_title(fieldname)
        value = options.delete(:value) || @template.formatted_value(current_object, fieldname)

        if info_text = options.delete(:info) #add info tag if info test given
          value << info_tag(info_text)
        end
        #keep existing class and add class right to wrapping element if its a money field
        (options[:class] ||= '') << ' right'  if fieldname && current_class.respond_to?("is_money_field") && current_class.is_money_field?(fieldname)
        tag_wrapper title, value, options
      end

    end
  end
end