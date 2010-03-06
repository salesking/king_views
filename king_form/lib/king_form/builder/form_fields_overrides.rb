module KingForm
  module Builder
    ##########################################################################
    # Modified core html tag methods.
    module FormFieldsOverrides
#    private
      def text_field(method, opts = {})
        opts[:class] = (opts[:class] || '')  + ' text'
        info_text = opts.delete(:info)
        super(method, opts) + info_tag(info_text || method)
      end

      def text_area(method, opts = {})
        opts[:size] ||= "20x3" # sized needed for valid html
        info_text = opts.delete(:info)
        super(method, opts) + info_tag(info_text || method)
      end

      def check_box(method, opts = {})
        info_text = opts.delete(:info)
        super(method, opts) + info_tag(info_text || method)
      end

      def radio_button(method, tag_value, opts = {})
        info_text = opts.delete(:info)
        super(method, tag_value, opts) + info_tag(info_text || method)
      end

      def select(method, choices, opts = {}, html_opts = {})
        info_text = opts.delete(:info)
        super(method, choices || [], opts, html_opts) + info_tag(info_text || method)
      end

      def date_select(method, opts = {}, html_opts = {})
        info_text = opts.delete(:info)
        super(method, opts, html_opts) + info_tag(info_text || method)
      end

      def password_field(method, opts = {})
        info_text = opts.delete(:info)
        super(method, opts) + info_tag(info_text || method)
      end

      def file_field(method, opts = {})
        info_text = opts.delete(:info)
        super(method, opts) + info_tag(info_text || method)
      end

      ###########

      def text_field_tag(name, value = nil, opts = {})
        opts[:class] = (opts[:class] || '')  + ' text'
        name, infos, opts = build_id_name_info(name, opts)
        @template.text_field_tag(name, value, opts) + infos
      end
      
      # Create a hidden field tag and construct its fieldname (object[name]) from
      # the current object
      # When the name is beeing passed in as string its just taken like it is
      # ==== Parameter
      # same as hidden_field_tag in Rails plus:
      # name<String>:: The name is passed right thought to hidden_field_tag
      # name<Symbol>:: The name is put together with current object =>  object[name]
      def hidden_field_tag(name, value = nil, opts = {})
        name, infos, opts = build_id_name_info(name, opts)
        @template.hidden_field_tag(name, value, opts) # obviously no infos
      end

      def password_field_tag(name = "password", value = nil, opts = {})
        opts[:class] = (opts[:class] || '')  + ' text'
        name, infos, opts = build_id_name_info(name, opts)
        @template.password_field_tag(name, value, opts) + infos
      end

      # Overide the native filefield tag
      # ==== Parameter
      # name<(Symbol,String)>:: The name for the field. when given as symbol, the
      # name is constructed for the current object oject[name] and an id is build.
      # If passed as string, the name is taken right away and no auto id is created
      # opts<Hash{Symbol=>String}>:: All file_field opts +
      #   :info which is taken for the help text
      def file_field_tag(name, opts = {})
        opts[:class] ||=  nil
        name, infos, opts = build_id_name_info(name, opts)
        @template.file_field_tag(name, opts) + infos
      end

      def text_area_tag(name, value, opts = {})
        opts[:size] ||= "20x3" # sized needed for valid html
        name, infos, opts = build_id_name_info(name, opts)
        @template.text_area_tag(name, value, opts) + infos
      end

      def check_box_tag(name, value = "1", checked = false, opts = {})
        name, infos, opts = build_id_name_info(name, opts)
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
      # option_tags<String>:: The opts as html for the select
      # opts<Hash{Symbol=>String}>:: Rails select_tag opts + :info
      def select_tag(name, option_tags = nil, opts = {})
        name, infos, opts = build_id_name_info(name, opts)
        @template.select_tag(name, option_tags, opts) + infos
      end

      # Builds name, opts, infos according to the given name type
      # ==== Parameter
      # name<Symbol>::
      # - id for an element is build => client_name_id
      # - info tag is looked up in I18n => see KingForm::Builder::Base info_tag
      # - fieldname is assumed to belong to an object => client[name]
      # name<String>::
      # - id for an element must be present in opts[:id]
      # - info tag is looked up in I18n when opts[:info] is a symbol, else string is taken #KingForm::Builder::Base info_tag
      # - fieldname is assumed to belong to an object => client[name]
      #
      def build_id_name_info(name, opts)
        if name.is_a?(Symbol)
          opts[:id] ||= build_id(name)
          # build info tag, cause info_tag(:symbol) is looking into I18n transl
          infos = info_tag( opts.delete(:info) || name)
          #now set real name as string
          name = "#{@object_name}[#{name}]"
        else
          opts[:id] ||= nil
          info_text = opts.delete(:info)
          infos = info_text ? info_tag( info_text) : ''
        end
        [name, infos, opts ]
      end

    end
  end
end