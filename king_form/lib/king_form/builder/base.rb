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
      include KingForm::Builder::FormFields
      include KingForm::Builder::FormFieldsOverrides
      attr_accessor :no_wrap
      def initialize(object_name, object, template, options, proc)
        # Store builder configuration data (only used by "render_associated_form")
        @config = options.delete(:config) || {}

        super(object_name, object, template, options, proc)
      end

      # Create a section(fieldset) within a form
      # A section is a group of related object information with name/value pairs,
      # like all dates of an object or the users name fields(last/first/title/nick).
      def section(title = nil, options = {}, &block)
        #must be overwritten in inerit classes
      end

      # Show multiple inputs as bundle
      def bundle(title = nil, options = {}, &block)
      #must be redefined in inerit class
      end

      # For using with nested forms with associated records => contact => addresses
      # Another Builder instance will be created. Make sure it's also a DefinitionsListsFormBuilder
      #  and configuration data is available for the new created instance
      def render_nested_form(associated, opts = {})
        opts[:fields_for] = { :builder =>  KingForm::Builder::DefinitionList, :config => @config }
        super(associated, opts)
      end


      # wraps a list of action links/buttons in a td od div
      # those wrappers can then be formated with css td.actions
      # also see #ListHelper
      #
      # ===Example haml
      #   = f.actions do
      #     = link_to my_actions
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
        result = @template.capture_haml do
          @template.haml_tag :table, options.reverse_merge({ :summary => title }) do
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
        end
        @config[:table] = false

        return result
      end

      # Build a single table row, only needed to be be able to render the table
      # headers(th)
      def table_row(&block)
        @config[:row_number] += 1
        @template.concat "<tr> #{@template.capture(&block)}</tr>"
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
      # === Returns
      # <Hash{'translated fldname'=>'value'}>::
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

      # Build span-tag with an info text after a field
      # ==== Parameter
      # fieldname_or_text<String/Symbol>:: static text value or a fieldname as symbol.
      # If a symbol is given the translated text is taken from I18n translation file
      def info_tag(fieldname_or_text)
        case fieldname_or_text
        when String #just use the plain string
          value = fieldname_or_text
        when Symbol # lookup the the field in i18n under activerecord.attributes.class.fieldname_info
          key = "#{current_class.name.underscore}.#{fieldname_or_text.to_s}_info"
          trans = I18n.translate("#{key}_html",
                                 :default => I18n.translate(key,
                                   :default => '',
                                   :scope => [:activerecord, :attributes]),
                                 :scope => [:activerecord, :attributes])
          value = trans.blank? ? nil : trans
        else
          raise ArgumentError
        end

        value ? content_tag(:div, value.html_safe, :class => 'info').html_safe : ''
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
