module KingForm
  #  was attribute_fu with changes from: http://github.com/odadata/attribute_fu/commit/a0402d12f2d380d8decc82bdfbcc5d8a0a185524
  # Methods for building forms that contain fields for associated models.
  module NestedFormHelper
    
    # Renders the form for nested objects defined via activerecord accepts_nested_attributes_for
    #
    # The associated argument can be either an object, or a collection of objects to be rendered.
    #
    # An options hash can be specified to override the default behaviors.
    # 
    # Options are:
    # * <tt>:new</tt>        - specify a certain number of new elements to be added to the form. Useful for displaying a 
    #                         few blank elements at the bottom.
    # * <tt>:name</tt>       - override the name of the association, both for the field names, and the name of the partial
    # * <tt>:partial</tt>    - specify the name of the partial in which the form is located.
    # * <tt>:fields_for</tt> - specify additional options for the fields_for_associated call
    # * <tt>:locals</tt>     - specify additional variables to be passed along to the partial
    # * <tt>:render</tt>     - specify additional options to be passed along to the render :partial call
    # * <tt>:skip</tt>       - array of elements which will be skipped, usefull if you already rendered a partial in the same form with parts of the data.
    #                       eg. obj.addresses, render the firt address on top of form, render all the other addresses at the bottom
    #
    def render_nested_form(associated, opts = {})
      associated = associated.is_a?(Array) ? associated : [associated] # preserve association proxy if this is one      
      opts.symbolize_keys!
      (opts[:new] - associated.select(&:new_record?).length).times { associated.build } if opts[:new]

      unless associated.empty?
        name              = extract_option_or_class_name(opts, :name, associated.first)
        partial           = opts[:partial] || name
        if opts[:skip]  # objects to be skipped are present
          skip_el = opts[:skip].is_a?(Array) ? opts[:skip] : [opts[:skip]]
          assoc_el = []
          associated.each { |el|  assoc_el << el unless skip_el.include?(el) }
        else # normal procedure
          assoc_el = associated
        end

        output = assoc_el.map do |element|
          fields_for(association_name(name), element, (opts[:fields_for] || {}).merge(:name => name)) do |f|

            @template.render( {:partial => "#{partial}",
                               #The current objects classname is always present in partial so:
                               #when Object is LineItem locals has :line_item => object
                               :locals => {name.to_sym => f.object, :f => f}.merge( opts[:locals] || {} )
                              }.merge( opts[:render] || {} ) )      
          end
        end
        output.join
      end
    end
    
    private
      def association_name(class_name)
        @object.respond_to?("#{class_name}_attributes=") ? class_name : class_name.pluralize
      end
      def extract_option_or_class_name(hash, option, object)
        (hash.delete(option) || object.class.name.split('::').last.underscore).to_s
      end
  end
end