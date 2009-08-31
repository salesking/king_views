module KingForm
  module Builder
    # Base Form Helper Class overrides most of rails build in form / field methods.
    # This class is used in conjunction with haml and makes your templates ultra clean.
    #
    # To further specify the resulting html for form fields and their wrappers,
    # subclass KingForm::Builder::Base.
    #
    # Subclasses must define the following methods:
    #
    # ==== def section
    # Definition of a section inside a form. A section is a wrapper around fields
    # which belong together. The topmost element should be(most of the time) a fieldset
    # followed by a legend and the openeing definition list.
    #         fieldset-> legend -> div -> ....
    #         fieldset-> legend -> dl -> ...
    # See child class Labeled and DefinitionList for examples.
    #
    # ==== def tag_wrapper
    # Wrapping/display of field descriptions(labels) and input tags
    #   => wrapped with div. actually no wrapping(see above):
    #     fieldset-> div -> label -> input
    #   => wrapped with dt / dd
    #     fieldset-> dl -> dd -> dt -> input
    #
    #
    # ==== def bundle
    # handle fields which are displayed toghether inside a wrapper
    class Base < ActionView::Helpers::FormBuilder
#      include ActiveSupport::CoreExtensions::String::Inflections
      def initialize(object_name, object, template, options, proc)
        # Store builder configuration data (only used by "render_associated_form")
        @config = options.delete(:config) || {}

        super(object_name, object, template, options, proc)
      end

      # Create a section(fieldset) within a form
      # A section is a group of related object information with name/value pairs,
      # like all dates of an object or the users name fields(last/first/title/nick).
      def section(title = nil, options = {}, &block)
        #must be overwritten in ineritance
      end

      # Show multiple inputs as bundle
      def bundle(title = nil, options = {}, &block)
      #must be redefined in subclass
      end

      # For using with nested forms with associated records => contact => addresses
      # Another Builder instance will be created. Make sure it's also a DefinitionsListsFormBuilder
      #  and configuration data is available for the new created instance
      def render_nested_form(associated, opts = {})
        opts[:fields_for] = { :builder =>  KingForm::Builder::DefinitionList, :config => @config }
        super(associated, opts)
      end

      ##########################################################################
      # Convinience Methods for simpler template tags
      ##########################################################################

      # Generate input tag with title for text editing
      # 1) text(:name)
      # 2) text(:name, :title => 'Your Name:', :value => @the_name)
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
      #   dl_form_for @email do |e|
      #     e.hidden :some_token
      #     => <input type='hidden' value='value of email.some_token' name=email[some_token]..>
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
        options[:selected] ||= value.to_s

        # Got an AR object so full automatic contruction should work
        if current_object.is_a?(ActiveRecord::Base) && fieldname.is_a?(Symbol)
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
        tag_wrapper title, check_box(fieldname, options)
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

      # Create a submit button
      # due to better formating the default button call is wrapped in a span.
      #
      # === Example (haml)
      # - f.actions do
      #   = f.submit t('form.save')
      #
      #   = f.submit "save", :span => {:class=>'custom class'}
      #
      #   = f.submit 'Submit Me', :name => 'save', nowrap=>true
      #   = f.submit t('form.save'), :name => 'refresh', nowrap=>true
      #   = f.submit 'Print', :name => 'print', :class=>'print, nowrap=>true
      #
      # => <div class="actions">
      #       <span class='input big'>
      #         <input id="invoice_save" class="submit" type="submit" value="Save" name="save" />
      #       </span>
      #
      #       <span class='custom class'>
      #         <input id="invoice_save" class="submit" type="submit" value="Save" name="save" />
      #       </span>
      #
      #       <input id="invoice_save" class="submit" type="submit" value="Speichern" name="save" />
      #       <input id="invoice_refresh" class="submit" type="submit" value="Aktualisieren" name="refresh" />
      #       <input id="invoice_print" class="print" type="submit" value="Print" name="print" />
      #     </div>
      #
      #===Params
      #Options Hash:
      # :name is only needed if you have more than one button on the form
      # :id is calculated based on the :name
      # :class defaults to "submit"
      def submit(value, options = {})
        options[:id] ||= build_id(options[:name] || 'submit')
        options[:class] ||= 'submit'

        if !options.delete(:nowrap) #wrap submit in span so button can be formated with css
          span_options = options.delete(:span) || {:class=>'input big'}
          @template.haml_tag :span, span_options do
            @template.haml_concat(super(value, options))
          end
        else #display field without span wrapping
          super value, options
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

      # wraps a list of action links/buttons in a td od div
      # those wrappers can then be formated with css td.actions
      # also see #ListHelper
      #
      # ===Example haml
      # f.actions do
      #   my_actions
      #
      #  <div class="actions">my actions</div>
      #  <td class="actions">my actions</td>
      #
      def actions(options = {}, &block)
        options[:class] ||= 'actions'
        if @config[:table]
          @template.haml_tag :td, @template.capture_haml(&block), options
        else
          @template.haml_tag :div, @template.capture_haml(&block), options
        end
      end

      #build a table
      def table(title, options = {}, &block)
        # Capture the block (with analyzing the header titles)
        @config[:table] = true
        @config[:column_header] = []
        @config[:row_number] = 0
        content = @template.capture_haml(&block)

        # Now build the whole table tag
        result = @template.haml_tag :table, options.reverse_merge({ :summary => title }) do
          @template.haml_tag :thead do
            @template.haml_tag :tr do
              @config[:column_header].each do |c|
                c[:options][:class] ||= ''
                if c == @config[:column_header].first
                  c[:options][:class] << ' first'
                elsif c == @config[:column_header].last
                  c[:options][:class] << ' last'
                end

                @template.haml_tag :th, c[:title], c[:options]
              end
            end
          end
          @template.haml_tag :tbody, content
        end
        @config[:table] = false

        return result
      end

      #build a single table row
      def table_row(options = {}, &block)
        @config[:row_number] += 1
        @template.haml_tag :tr, options do
          @template.haml_concat @template.capture_haml(&block)
        end
      end

      def one_column(options = {}, &block)
        @template.haml_concat @template.capture_haml(&block)
      end

     private
      #  returns the current object
      def current_object
        # check for fields made with attribute_fu
        if @object_name.to_s.match(/\[\w+_attributes\]/)
          #field was constructed via attribute_fu: user[address_attributes][atLE1aPLKr3j9zabTJhScS]
          @object
        else
          # Instance-Variable of the templates
          @template.instance_variable_get("@#{@object_name}")
        end
      end

      # returns the class of the current object
      def current_class
        current_object.class
      end

      # returns the stringified and downcased class of the current object
      #so it can be uses in id´s and name fields
      def current_class_s
        current_class.to_s.downcase
      end

      # returns the value of an attribute belonging to the current object
      def current_value(fieldname)
        if current_object.is_a?(Hash)
          current_object[fieldname]
        else
          current_object.send(fieldname) rescue nil
        end
      end


      # Shortcut for using "content_tag", which exists in the context of the template
      def content_tag(*args)
        @template.content_tag(*args)
      end

      # Translate acts_as_enum dropdown field values either with I18n
      # A key must be lokated in the language file under:
      # "activerecord.attributes.client.enum.sending_methods.fax"
      # "activerecord.attributes.client.enum.sending_methods.email"
      # ==== Parameter
      # fieldname<String,Symbol>:: The fieldname in the model which holds enum values from acts_as_enum plugin
      def enum_values(fieldname)
        # Check if there is a const in the class defined by acts_as_enum
        return unless current_class.const_defined?(fieldname.to_s.upcase)
        # Get Array with the values from this constant
        values = current_class.const_get(fieldname.to_s.upcase)
        # values are symbols as defined by "acts_as_enum"
        if values && values.first.is_a?(Symbol)
          values_with_translated_keys = {}
          values.each do |value|
            key = current_class.human_attribute_name("enum.#{fieldname.to_s}.#{value.to_s}")
            values_with_translated_keys[key] = value.to_s
          end
          return values_with_translated_keys
        else
          #values are not symbols (probably not coming from acts_as_enum) =>return them unchanged
          return values
        end
      end

      # add titles to Input-Tag and embed/wrap in dt/dd
      #   options: Hash with following keys
      #     :dt => options for dt
      #     :dd => options for dd
      def tag_wrapper(fieldname_or_title, tags, options = {})
        #overwrite in inherit class !!!
      end

      # Build a fields title/label with translation
      # takes the class and fieldname (like  GetText ActiveRecord-Parser )
      # ==== Parameter
      # fieldname_or_title<String,Symbol>:: A string is directly returned.
      # A Symbol is beeing looked up in I18n translation inside the models attribute namespace:
      # => class.human_attribute_name(fieldname_or_title.to_s)
      def build_title(fieldname_or_title)
        if fieldname_or_title.is_a?(Symbol)
          #i18n namespace under activerecord.attributes.model.attr_name
          current_class.human_attribute_name(fieldname_or_title.to_s) if current_class.respond_to?(:human_attribute_name)
        else
          fieldname_or_title
        end
      end

      def dt_tag(fieldname_or_title, options = {})
        fieldname_or_title.blank? ? "" : content_tag(:dt, build_title(fieldname_or_title), options)
      end

      #build a label tag
      #TODO enhance with option <label for="fieldname">
      def label_tag(fieldname_or_title, options = {})
        fieldname_or_title.blank? ? "" : content_tag(:label, build_title(fieldname_or_title), options)
      end

      # build dd-tag
      # Parameter "tags" may be a string or an array of strings
      def dd_tag(tags, options = {})
        tags.blank? ? '' : @template.content_tag(:dd, tags.to_s, options)
      end

      # Build span-tag with an info text after a field
      # ==== Parameter
      # fieldname_or_text<String/Symbol>:: static text value or a fieldname as symbol.
      # If a symbol is given the translated text is taken from I18n translation file
      def info_tag(fieldname_or_text)
        case fieldname_or_text
        when String #just use the plain string
          value = fieldname_or_text
        when Symbol # lookup the the field in i18n under activerecord.attributes.class.fieldname_info
          trans = I18n.translate("#{current_class.name.underscore}.#{fieldname_or_text.to_s}_info",
                                 :default => '',
                                 :scope => [:activerecord, :attributes])
          value = trans.blank? ? nil : trans
        else
          raise ArgumentError
        end

        value ? content_tag(:div, value, :class => 'info') : ''
      end

      ##########################################################################
      # Modified core html tag methods.
      # Because they should not be called direct, they are made private...
      ##########################################################################
      def text_field(method, options = {})
        options[:class] = (options[:class] || '')  + ' text'
        info_text = options.delete(:info)
        super(method, options) + info_tag(info_text || method)
      end

      def text_area(method, options = {})
        options[:size] ||= "20x3" # sized needed for valid html
        info_text = options.delete(:info)
        super(method, options) + info_tag(info_text || method)
      end

      def check_box(method, options = {})
        info_text = options.delete(:info)
        super(method, options) + info_tag(info_text || method)
      end

      def radio_button(method, tag_value, options = {})
        info_text = options.delete(:info)
        super(method, tag_value, options) + info_tag(info_text || method)
      end

      def select(method, choices, options = {}, html_options = {})
        info_text = options.delete(:info)
        super(method, choices || [], options, html_options) + info_tag(info_text || method)
      end

      def date_select(method, options = {}, html_options = {})
        info_text = options.delete(:info)
        super(method, options, html_options) + info_tag(info_text || method)
      end

      def password_field(method, options = {})
        info_text = options.delete(:info)
        super(method, options) + info_tag(info_text || method)
      end

      def file_field(method, options = {})
        info_text = options.delete(:info)
        super(method, options) + info_tag(info_text || method)
      end

      ###########

      def text_field_tag(name, value = nil, options = {})
        options[:class] = (options[:class] || '')  + ' text'
        options[:id] ||= build_id(name)
        info_text = options.delete(:info)
        @template.text_field_tag("#{@object_name}[#{name}]", value, options) + info_tag(info_text || name)
      end

      # Create a hidden field tag and construct its fieldname (object[name]) from
      # the current object
      # When the name is beeing passed in as string its just taken like it is
      # ==== Parameter
      # same as hidden_field_tag in Rails plus:
      # name<String>:: The name is passed right trhought to hidden_field_tag
      # name<Symbol>:: The name is put together with current object =>  object[name]
      def hidden_field_tag(name, value = nil, options = {})
        if name.is_a?(Symbol)# contruct the fieldname
          name = "#{@object_name}[#{name}]"
          options[:id] ||= build_id(name)
        else
          options[:id] ||= nil
        end
        @template.hidden_field_tag(name, value, options)
      end

      def password_field_tag(name = "password", value = nil, options = {})
        options[:class] = (options[:class] || '')  + ' text'
        options[:id] ||= build_id(name)
        info_text = options.delete(:info)
        @template.password_field_tag("#{@object_name}[#{name}]", value, options) + info_tag(info_text || name)
      end

      # Overide the native filefield tag
      # ==== Parameter
      # name<(Symbol,String)>:: The name for the field. when given as symbol, the
      # name is constructed for the current object oject[name] and an id is build.
      # If passed as string, the name is taken right away and no auto id is created
      # options<Hash{Symbol=>String}>:: All file_field options +
      #   :info which is taken for the help text
      def file_field_tag(name, options = {})
        options[:class] ||=  nil
        info_text = options.delete(:info)
        if name.is_a?(Symbol)
          name = "#{@object_name}[#{name}]"
          options[:id] ||= build_id(name)
        else
          options[:id] ||= nil
        end
        @template.file_field_tag(name, options) + info_tag(info_text || ''  )
      end

      def text_area_tag(name, value, options = {})
        options[:size] ||= "20x3" # sized needed for valid html
        options[:id] ||= build_id(name)
        info_text = options.delete(:info)

        @template.text_area_tag("#{@object_name}[#{name}]", value, options) + info_tag(info_text || name)
      end

      def check_box_tag(name, value = "1", checked = false, options = {})
        options[:id] ||= build_id(name)
        info_text = options.delete(:info)
        @template.check_box_tag("#{@object_name}[#{name}]", value, checked, options) + info_tag(info_text || name)
      end

      # Overriden rails select_tag
      # Constructs the fieldname
      # ==== Example
      # - dl_fields_for @user do |u|
      #   = u.selection :project_id, :choices => @projects, :title => "Projects"
      #   = u.selection "user[custom_field]", :choices => @some_choices
      #
      # ==== Parameter
      # name<Symbol, String>:: If symbol: the name and id is auto-constructed object[field_name]
      # and the info tag is build from translation see info_tag.
      # If String: The name is taken as it is, no id and info is auto-created.
      # They must be passed in as opts[:id], opts[:info]
      # option_tags<String>:: The options as html for the select
      # opts<Hash{Symbol=>String}>:: Rails select_tag options + :info
      def select_tag(name, option_tags = nil, opts = {})
        if name.is_a?(Symbol)
          name = "#{@object_name}[#{name}]" # contruct the fieldname
          opts[:id] ||= build_id(name)   #construct id
          infos = info_tag( opts.delete(:info) || name)  # build info tag
        else
          opts[:id] ||= false
          info_text = opts.delete(:info)
          infos = info_text ? info_tag( info_text) : ''
        end
        @template.select_tag(name, option_tags, opts) + infos
      end

      # Create the id of a field
      # ==== Parameter
      # name<String>::The name of the id
      def build_id(name)
        if current_object.blank?
          name
        else
          "#{@object_name}_#{name}"
        end
      end

    end #Class Base
  end#Module Builder
end#Module KingForm