module KingForm
  module Builder
    # Create forms with a fieldset->div->label->input structure
    # ==== Example haml
    #  - labeled_form_for(current_object) do |f|
    #    - f.section _('legend.user.details') do
    #      = f.text :first_name
    #      = f.text :last_name
    #
    # => #<form ..>
    #       <fieldset>
    #         <legend>User Details</legend>
    #         <div>
    #           <label>Firstname</label>
    #           <input type='text' value='Otto'/>
    #         </div>
    #         <div>
    #           <label>Lastname</label>
    #           <input type='text' value='Bismark'/>
    #         </div>
    #       </fieldset>
    #      </form>
    #
    class Labeled < KingForm::Builder::Base
      # Create a section(fieldset) within a form
      # A section is a group of related object information with name/value pairs,
      # like all dates of an object or the users name fields(last/first/title/nick).
      #
      # A section html consists of a fieldset > legend > div > label > input
      # The dt holds the title/description (DefinitionType) of the current field
      # The dd holds the value.
      # This wrapup is preferred over ul/li or other listing types because of
      # the semantic meaning of the html
      #
      #===Example haml
      #    - f.section _('legend.user.details') do
      #      = f.text :first_name
      #      = f.text :last_name
      #
      # => # <fieldset>
      #       <legend>User Details</legend>
      #       <div>
      #         <label>Firstname</label>
      #         <input type='text' value='Otto'/>
      #       </div>
      #       <div>
      #         <label>Lastname</label>
      #         <input type='text' value='Bismark'/>
      #       </div>  #
      #      </fieldset>
      #
      def section(title = nil, options = {}, &block)
        raise ArgumentError if title && !title.is_a?(String)
        @template.haml_tag :fieldset, options do
          @template.haml_tag :legend, title unless title.blank?
          @template.haml_concat( @template.capture_haml(&block) )
        end
      end

      # Show multiple inputs in one line (div tag)
      # === Example haml
      # - f.bundle _('Gender and Title') do
      #   = f.selection :gender
      #   = f.text :title, :medium
      # ==== Parameter
      # title<String>:: The name used as label
      def bundle(title = nil, options = {}, &block)
        @config[:bundle] = true
        @bundle_counter = 0
        tags = @template.capture(&block)
        @config[:bundle] = false
        @template.concat( tag_wrapper(title, tags, options) )
      end

      # Add titles/labels to input tag and wrap in div
      #
      # ==== Parameter
      # fieldname_or_title<String Symbol>:: The title for the field
      # tags<String>:: html tags as string
      # options<Hash{Symbold=>String}>:: options for the surrounding html
      # ==== Options
      # :label => options for label
      # :div => options for surrounding div
      # :align => alignment in table
      def tag_wrapper(fieldname_or_title, tags, options = {})
        if @config[:bundle]
          @bundle_counter += 1
          tags
        elsif @config[:table] # called from "table" => build a table cell (td)
          # Only in first row: Build column header
          if @config[:row_number] == 1
            @config[:column_header].push :title => build_title(fieldname_or_title),
                                         :options => { :align => options[:align] || 'left' }
          end
          @template.capture_haml do
            @template.haml_tag(:td, tags, options)
          end
        else
          out = if tags.match /checkbox/ # wrap only checkbox tag into to label, so it is clickable
                  label_tag(fieldname_or_title + tags, options[:label])
                else # other tags stay outside label tag, because they don't like to be wrapped sometimes
                  label_tag(fieldname_or_title, options[:label]) + tags
                end
          "<div> #{out}</div>"
        end
      end

      # Build a label tag
      #TODO enhance with option <label for="fieldname">
      def label_tag(fieldname_or_title, options = {})
        fieldname_or_title.blank? ? "" : content_tag(:label, build_title(fieldname_or_title), options)
      end

    end # labeled class
  end #module
end#module