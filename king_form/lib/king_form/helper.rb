module KingForm
  module Helper

    # renders a form with the # KingForm::Builder::DefinitionList
    # It allows to devide the form into sections(fieldsets) where each contains
    # a definition list with dl/dd blocks for each label/field
    #
    # Read on to find out more about the available tags/fieldtypes
    #
    # === Example haml
    #  -dl_form_for(:client, :url => object_url, :html => { :method => :put }) do |f|
    #    - f.section 'Client Details' do
    #      = f.text :number
    #      - f.bundle 'Gender/Title' do
    #        = f.selection :gender
    #        = f.text :title, :class => 'medium'
    #      = f.text :position
    #      = f.text :last_name
    #      = f.date :birthday
    #   # =><form .. method..> <fieldset>
    #       <legend>Client Details</legend>
    #       <dl>
    #         <dt>Number</dt>
    #         <dd><input name=client[number] type=text></dd>
    #         ....
    #         </dl>
    #        </fieldset></form>
    #
    def dl_form_for(record_or_name_or_array, *args, &proc)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:builder] = KingForm::Builder::DefinitionList
      form_for(record_or_name_or_array, *(args << options), &proc)
    end

    def dl_fields_for(record_or_name_or_array, *args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:builder] =  KingForm::Builder::DefinitionList

      case record_or_name_or_array
      when String, Symbol
        object_name = record_or_name_or_array
        object = args.first
      else
        object = record_or_name_or_array
        object_name = ActiveModel::Naming.singular(object)
      end

      fields_for(object_name, object, options, &block)
    end

    # renders a form with the KingForm::Builder::Labeled
    # It allows to devide the form into sections(fieldsets) where each contains
    # a definition list with dl/dd blocks for each label/field
    #
    # Read on to find out more about the avalable tags/fieldtypes
    #
    # === Example haml
    #  -labeled_form_for(:client, :url => object_url, :html => { :method => :put }) do |f|
    #    - f.section 'Client Details' do
    #      = f.text :number
    #      - f.bundle 'Gender/Title' do
    #        = f.text :gender
    #        = f.text :title, :class => 'medium'
    #   # =><form ...>
    #        <fieldset>
    #         <legend>Client Details</legend>
    #         <div>
    #           <label>Number </label>
    #           <input name=client[number] type=text>
    #         </div>
    #         <div>
    #           <label>Gender/Title</label>
    #           <input type='text' name='client[gender]' value='male'/>
    #           <input type='text' name='client[title]' value='Prof.'/>
    #         </div>
    #       </fieldset>
    #      </form>
    #
    def labeled_form_for(record_or_name_or_array, *args, &proc)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:builder] = KingForm::Builder::Labeled

      case record_or_name_or_array
      when String, Symbol
        options[:as] = record_or_name_or_array
        form_for(args.shift, *(args << options), &proc)
      else
        form_for(record_or_name_or_array, *(args << options), &proc)
      end
    end

    def labeled_fields_for(record_or_name_or_array, *args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:builder] =  KingForm::Builder::Labeled
      fields_for(record_or_name_or_array, *(args << options), &block)
    end

    # Returns an array for a given settings which has comma-seperated values.
    # In the view those are used for select boxes
    # Accepts an optional block to change the array elements
    def make_select(values, &block)
      return nil unless values
      raise ArgumentError unless values.class == String

      result = []
      values.split(',').each do |s|
        s.strip!
        s = yield(s) if block_given?
        result.push(s)
      end
      result
    end
  end
end
