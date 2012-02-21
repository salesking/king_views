module KingList
  # The List Helper provides methods for lists and detail views:
  # tables, action icons, action buttons and action links, definition list helper
  module ListHelper

    # Build a definition list(dl/dt/dd) for a collection
    # Usage examples:
    #   - dl_for(client)
    #   - dl_for(:client, my_client_object)
    # === Example haml
    #  - dl_for(current_object) do |f|
    #    - f.show :first_name
    #    - f.show :last_name
    #
    # =>    <dl>
    #         <dt>Firstname</dt>
    #         <dd>Otto</dd>
    #         <dt>Lastname</dt>
    #         <dd>Bismark</dd>
    #       </dl>
    #
    # Parameters are like "form_for"
    def dl_for(record_or_name, *args)
      raise ArgumentError, "Missing block" unless block_given?

      options = args.extract_options!
      case record_or_name
        when String, Symbol
          object_name = record_or_name
          object = args.first
        else
          object = record_or_name
          object_name = ActionController::RecordIdentifier.singular_class_name(object)
      end

      haml_tag :dl, options do
        yield KingList::Builder::Show.new(object_name, object, render_context)
      end
    end

    # Create a section
    # A section is a group of related object information and
    # generates a fieldset with optional legend
    #
    # === Example haml
    #  - section :caption => t('legend.user.details'), :class => 'my_css_class' do
    #    %p= "This is the content"
    #
    # => # <fieldset>
    #        <legend>User Details</legend>
    #        <p>This is the content</p>
    #      </fieldset>
    #
    def section(options = {}, &block)
      # Short form of usage
      if options.is_a?(String)
        caption = options
        options = {}
      end

      caption ||= options.delete(:caption)

      render_context.haml_tag :fieldset, options do
        render_context.haml_tag :legend, caption unless caption.blank?
        render_context.haml_concat render_context.capture_haml(&block)
      end
    end

    # Create a div for form actions
    def actions(options = {}, &block)
      render_context.haml_tag :div, options.merge(:class => 'form_actions') do
        render_context.haml_concat render_context.capture_haml(&block)
      end
    end

    # Build a table-tag for a collection
    #
    # Available option keys:
    #     :sorting    => Enable/Disable sorting for ALL columns (default is true)
    #
    # === Usage example:
    #
    # Header linking for all, default
    #   - table_for(@users) do |t, user|
    #     = t.column :name  # with sorting
    #     = t.column :email
    #
    # Header linking for all, but exclude individual columns from sorting:
    #  - table_for(@users)do |t, user|
    #    = t.column :name, :sorting => false  # without sorting
    #    = t.column :last_name
    #
    # NO header linking for all columns:
    #  - table_for(@users, :sorting => false) do |t, user|
    #    = t.column :name
    #    = t.column :email
    #
    # No header linking for all, but allow sorting for individual columns:
    #  - table_for(@users, :sorting => false) do |t, user|
    #    = t.column :name, :sorting => true # with sorting
    #    = t.column :last_name
    #
    def table_for(collection, options={}, html_options={}, &block)
      return if collection.nil? || collection.empty?
      builder = KingList::Builder::Table.new(render_context, collection)
      # extract options
      builder.sorting = options.delete(:sorting) != false # default => true
      concat("<table #{ to_attr(html_options) }><thead><tr>")
      # Build header row
      builder.mode = :header
      builder.current_record = collection.first
      yield(builder, builder.current_record)
      concat("</tr></thead><tbody>")
      builder.mode = :content
      # Build content row for each collection item
      collection.each do |c|
        builder.current_record = c
        concat("<tr>")
        yield(builder, builder.current_record)
        concat("</tr>")
      end
      concat( "</tbody></table>")
    end

    # TODO same in table class
    #== Param
    # opts<Hash{Symbol=>String}}>:. options used for html attributes
    def to_attr(opts)
      opts.collect{|k,v| "#{k}='#{v}'" }.join(' ')
    end

    # Show a list of options as ul / li list.
    # Each actions li gets a special class so image replacement can be done via css
    # ==== Example
    #  - action_group do
    #    = action_icon :edit, edit_object_path(client)
    #    = action_icon :invoice_add, new_client_invoice_path(client), :title => 'New Invoice'
    #     = action_text t(:'web_templates.new'), new_object_path,{},{ :class=>'btn_add'}
    # # <ul class="actions">
    #    <li class="button delete">
    #     <a href="delete/id">delete</a>
    def action_group(caption=nil, options={}, &block)
      if caption && !caption.empty?
        haml_tag :span, caption, { :class => 'caption' }
      end

      options[:class] ||= 'actions'
      haml_tag :ul, options do
        haml_concat capture_haml(&block)
      end
    end

    # Renders a <li> with a link shown as icon
    # The link text is hidden via css image replacement and only an icon is shown
    #
    # ==== Example
    #   action_icon :show, show_user(user), :title => "Show User details"
    # => <li class="show"><a href="/users/show" title="Show User details"><span>show</span></a></li>
    # ==== Parameter
    # name<String>:: The name of the action which is taken in the translated title,
    # and li class (if no custom class is present in li_options )
    # li_options<Hash{Symbol=>String}>:: Options for the li-element
    # link_options<Hash>:: Options passed on to rails link_to method  #
    # html_options<Hash>:: Options passed on to rails link_to method
    # ==== Options li_options
    # :title - the html title tag for the li
    # :class - the html class tag for the li
    def action_icon(name, link_options={}, li_options={}, html_options={})
      li_options[:title] ||= case name
        # Some known names with their titles
        when :edit        then t(:'link.edit')
        when :pdf         then t(:'link.pdf')
        when :show        then t(:'link.show')
        when :delete      then t(:'link.delete')
        when :copy        then t(:'link.copy')
        when :comment     then t(:'link.comment')
        when :send_email  then t(:'link.send_email')
      end
      (li_options[:class] ||= '') << " icon #{name}"

      action :icon, name, link_options, li_options, html_options
    end

    # Renders a <li> with a link shown as text
    # You can set html options for both the li and the a tag
    #
    #===Example haml
    #   action_text t('link.user.edit'), edit_object_path
    #   action_text t('link.user.edit'), edit_object_path, {li html options}, {a html options :class=>'supercssclass'}
    #
    #   =>   <li>
    #         <a href="/users/edit/12">
    #           link.user.edit
    #         </a>
    #        </li>
    #
    def action_text(title, link_options, li_options={}, html_options={})
      # Prepare the css-class for the <li>
      li_options[:class] ||= ''
      li_options[:class] << ' active' if li_options.delete(:active)

      #kill class attribute if still empty
      li_options.delete(:class) if li_options[:class].empty?
      action :text, title, link_options, li_options, html_options
    end

    # Renders a <li> with a button that will submit a form to a given url.
    # This allows to make POST/PUT/DELETE request instead of using a link which triggers a GET.
    #
    # The button tags name attribute will be set to the <tt>name</tt> paramter followed by
    # either the <tt>:id</tt> url_for_options value or a <tt>:number</tt> option either is
    # available.
    #
    # ==== Parameters
    # fieldname<String>:: the name attribute of the hidden form field f.ex. 'status' or 'invoice[status]'
    # options<Hash>:: a couple of options explained further on
    #
    # ==== Options
    #  :method<Symbol>::form request method: :post / :put / :delete
    #  :url<String>:: The url the form is submitted to
    #  :title<String>::Button title and text
    #  :value<String>::the hidden field value
    #  :class<String>::button class
    #
    # ==== Example
    #   = action_button 'order_status', {:value=>'open', :title=> "Change Status to open", :method => :put}
    #
    #
    # ==== Returns
    #   <form>
    #     <div>
    #       <input type="hidden" value="put" name="_method"/>
    #       <input type="hidden" value="939f3c1dc225bcaa2e5c2bd88910537901dc19d6" name="authenticity_token"/>
    #       <input type="hidden" value="open" name="order_status"/>
    #        <button type='submit' class="some_class" title="Change Status to open">Change Status to open</button>
    #     </div>
    #   </form>
    #
    def action_button(fieldname, options)
      render_context.capture_haml do
        li_options = options.delete(:li_options) || {}
        li_options[:class] ||= []
        li_options[:class] << " form_btn"
        haml_tag :li, li_options do
          haml_concat mini_action_form(fieldname, options)
        end
      end
    end
    def action_link(fieldname, options)
      haml_concat mini_action_form(fieldname, options)
    end

    def mini_action_form(fieldname, options)
      method_tag = ''
      if (method = options.delete(:method)) && %w{put delete}.include?(method.to_s)
        method_tag = tag('input', :type => 'hidden', :name => '_method', :value => method.to_s)
      end

      form_method = method.to_s == 'get' ? 'get' : 'post'

      request_token_tag = ''
      if form_method == 'post' && protect_against_forgery?
        request_token_tag = tag(:input, :type => "hidden", :name => request_forgery_protection_token.to_s, :value => form_authenticity_token)
      end

      hidden_tag = ''
      hidden_tag = tag(:input, :type => "hidden", :name =>fieldname, :value => options[:value]) unless options[:value].blank?

      "<form method=\"#{form_method}\" action=\"#{escape_once options[:url]}\"><div>" +
            method_tag +
            request_token_tag +
            hidden_tag +
            "<button type='submit' name='submit' title='#{options[:title]}' class='#{options[:class]}'><span>#{options[:title]}</span></button>" +
         "</div></form>"
    end

    # Renders a <ol> for a given collection and yields the block for every item
    # Options:
    #   :descending: if true, numbering is reversed (defaults to false)
    def ordered_list_for(collection, options={}, &block)
      if collection.nil? || collection.empty?
        haml_tag :p, _('list.empty')
        return
      end

      descending = options.delete(:descending)

      haml_tag :ol, options do
        collection.each_with_index do |c,i|
          li_options = {}
          li_options[:class] = render_context.cycle('odd','even')
          li_options[:value] = collection.length - i if descending
          haml_tag :li, li_options do
            yield(c)
          end
        end
      end
    end

  private

    # Internal method used by action_text, action_button and action_icon
    # Directly returns a haml string into the template
    def action(kind, name_or_title, link_options, li_options={}, html_options={})

      render_context.capture do
        concat %{ <li #{ to_attr(li_options) }>
        #{ case kind
          when :icon
            link_to('', link_options, html_options)
          when :text
            link_to(name_or_title, link_options, html_options)
          when :button
            button_to(name_or_title, link_options)
        end } </li>}
      end
    end

    def render_context
      # rails 2 || rails 3.2
      @template || self
    end

  end #ListHelper
end#module
