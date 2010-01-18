module KingForm
  module Builder
    ##########################################################################
    # Modified core html tag methods.
    # Because they should not be called direct, they are made private...
    module FormFieldsOverrides
#    private
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

      def text_area_tag(name, value, opts = {})
        options[:size] ||= "20x3" # sized needed for valid html
        options[:id] ||= build_id(name)
        info_text = options.delete(:info)
        @template.text_area_tag("#{@object_name}[#{name}]", value, opts) + info_tag(info_text || name)
      end

      def check_box_tag(name, value = "1", checked = false, opts = {})
        if name.is_a?(Symbol)
          opts[:id] ||= build_id(name)
          infos = info_tag( opts.delete(:info) || name) # build info tag, cause info_tag(:symbol) is looking into I18n transl
          #now set real name as string
          name = "#{@object_name}[#{name}]"
        else
          opts[:id] ||= nil
          info_text = opts.delete(:info)
          infos = info_text ? info_tag( info_text) : ''
        end
        @template.check_box_tag(name, value, checked, opts) + infos
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
          opts[:id] ||= build_id(name)   #construct id
          infos = info_tag( opts.delete(:info) || name) # build info tag, cause info_tag(:symbol) is looking into I18n transl
          name = "#{@object_name}[#{name}]" # contruct the fieldname
        else
          opts[:id] ||= nil
          info_text = opts.delete(:info)
          infos = info_text ? info_tag( info_text) : ''
        end
        @template.select_tag(name, option_tags, opts) + infos
      end


    end
  end
end