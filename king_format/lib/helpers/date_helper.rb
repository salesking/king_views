module KingFormat
  # Provides some helper functions for action controller /  view
  module DateHelper

    # define date formats to be used in date date_format_select
    DATE_FORMATS = [
                    '%Y-%m-%d',
                    '%d/%m/%Y',
                    '%d.%m.%Y',
                    '%d-%m-%Y',
                    '%m/%d/%Y',
#                    '%d %b %Y',
#                    '%d %B %Y',
#                    '%b %d, %Y',
#                    '%B %d, %Y'
                      ]


    # Default date formats to be used in select boxes => choices in rails select helper
    def date_format_options
      DATE_FORMATS.collect {|f| ["#{Date.today.strftime(f)} - #{f}", f]}
    end
    
  end
end